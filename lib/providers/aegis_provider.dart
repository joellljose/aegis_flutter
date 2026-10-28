import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_types.dart';
import '../models/system_state.dart';
import '../models/emergency_contact.dart';
import '../models/medical_profile.dart';
import '../models/emergency_record.dart';
import '../models/telemetry.dart';
import '../models/log_entry.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/sound_service.dart';
import '../services/dispatch_service.dart';
import '../services/storage_service.dart';

class AegisProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();
  final SoundService _soundService = SoundService();
  final DispatchService _dispatchService = DispatchService();
  final StorageService _storageService = StorageService();

  // State
  SystemState _state = SystemState.allSafe;
  SystemState get state => _state;

  AlertType? _activeAlertType;
  AlertType? get activeAlertType => _activeAlertType;

  // Settings
  int _mistouchDurationSec = 120;
  int get mistouchDurationSec => _mistouchDurationSec;

  final double _immediateLongPressSec = 5.0;
  double get immediateLongPressSec => _immediateLongPressSec;

  bool _crashDetectionEnabled = true;
  bool get crashDetectionEnabled => _crashDetectionEnabled;

  String _securityPin = '1234';
  String get securityPin => _securityPin;

  // Countdown & Long Press
  int _countdownRemaining = 0;
  int get countdownRemaining => _countdownRemaining;

  double get countdownPercent => _mistouchDurationSec > 0
      ? (_countdownRemaining / _mistouchDurationSec).clamp(0.0, 1.0)
      : 0.0;

  Timer? _countdownTimer;

  AlertType? _holdingButton;
  AlertType? get holdingButton => _holdingButton;

  double _holdProgress = 0.0;
  double get holdProgress => _holdProgress;
  Timer? _holdTimer;

  // Medical & Contacts
  MedicalProfile _medicalProfile = MedicalProfile();
  MedicalProfile get medicalProfile => _medicalProfile;

  List<EmergencyContact> _contacts = [];
  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);

  // Telemetry & Hardware
  final TelemetryData _telemetry = TelemetryData();
  TelemetryData get telemetry => _telemetry;

  // Real GPS & Location Status
  double? _currentLat = 12.9716;
  double? get currentLat => _currentLat;

  double? _currentLng = 77.5946;
  double? get currentLng => _currentLng;

  double? _currentAccuracy = 8.0;
  double? get currentAccuracy => _currentAccuracy;

  double _currentSpeed = 0.0;
  double get currentSpeed => _currentSpeed;

  String _currentAddress = 'Bengaluru Central Command Sector, KA';
  String get currentAddress => _currentAddress;

  String _locationStatusText = 'Ready';
  String get locationStatusText => _locationStatusText;

  // Safe Zones
  final List<Map<String, dynamic>> _safeZones = [
    {'id': 'z1', 'name': 'Home Safe Haven', 'lat': 12.9716, 'lng': 77.5946, 'radius': 250},
    {'id': 'z2', 'name': 'Tech Campus Zone', 'lat': 12.9352, 'lng': 77.6245, 'radius': 500},
  ];
  List<Map<String, dynamic>> get safeZones => List.unmodifiable(_safeZones);

  // Active Emergency Record
  EmergencyRecord? _lastEmergencyRecord;
  EmergencyRecord? get lastEmergencyRecord => _lastEmergencyRecord;

  // Logs
  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);

  AegisProvider() {
    _initData();
  }

  Future<void> _initData() async {
    await _firebaseService.init();

    final loadedContacts = await _storageService.loadContacts();
    _contacts = loadedContacts;

    _medicalProfile = await _storageService.loadMedicalProfile();

    final settings = await _storageService.loadSettings();
    _mistouchDurationSec = settings['mistouchSec'] as int;
    _securityPin = settings['pin'] as String;

    logEvent(LogType.info, 'AEGIS One System initialized. Hardware sensors standby.');
    notifyListeners();

    // Fetch initial GPS lock
    refreshLocation();
  }

  void logEvent(LogType type, String message) {
    final entry = LogEntry(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}_${_logs.length}',
      time: DateFormat('HH:mm:ss').format(DateTime.now()),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: type,
      message: message,
    );
    _logs.insert(0, entry);
    if (_logs.length > 80) _logs.removeLast();
    notifyListeners();
  }

  // --- LOCATION ACQUISITION ---
  Future<void> refreshLocation() async {
    _locationStatusText = 'Getting your location...';
    notifyListeners();

    final result = await _locationService.getCurrentLocation();
    if (result.success && result.latitude != null && result.longitude != null) {
      _currentLat = result.latitude;
      _currentLng = result.longitude;
      _currentAccuracy = result.accuracy;
      _currentSpeed = result.speed ?? 0.0;
      _telemetry.gpsLocked = true;
      _locationStatusText = 'Location acquired';
      notifyListeners();

      // Async reverse geocoding
      final addr = await _locationService.reverseGeocode(_currentLat!, _currentLng!);
      if (addr != null) {
        _currentAddress = addr;
        notifyListeners();
      }
    } else {
      _locationStatusText = 'Unable to access location';
      _telemetry.gpsLocked = false;
      notifyListeners();
    }
  }

  // --- TRIGGER ALERT (Button click or Crash) ---
  void triggerAlert(AlertType alertType, {bool immediate = false}) {
    if (_state == SystemState.activeDispatch) return;

    _activeAlertType = alertType;
    _telemetry.incidentStartTime = DateTime.now().millisecondsSinceEpoch;

    if (immediate) {
      logEvent(LogType.danger, '🚨 IMMEDIATE ALERT SENT (5s Long Press Bypass): ${alertType.displayName}');
      confirmEmergencyDispatch();
      return;
    }

    _state = SystemState.mistouchWindow;
    _countdownRemaining = _mistouchDurationSec;
    logEvent(LogType.warn, '⚠️ ${alertType.displayName} Triggered. $_mistouchDurationSec s mistouch cancellation window active.');

    _startCountdownTimer();
    notifyListeners();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownRemaining > 0) {
        _countdownRemaining--;
        if (_countdownRemaining % 10 == 0 && _countdownRemaining > 0) {
          _soundService.playWarningBeep();
        }
        notifyListeners();
      } else {
        timer.cancel();
        _countdownTimer = null;
        confirmEmergencyDispatch();
      }
    });
  }

  // --- BUTTON HOLD (5s Immediate Trigger) ---
  void startButtonHold(AlertType alertType) {
    _holdingButton = alertType;
    _holdProgress = 0.0;
    _soundService.playClick();
    notifyListeners();

    final start = DateTime.now();
    final durationMs = (_immediateLongPressSec * 1000).toInt();

    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      _holdProgress = (elapsed / durationMs).clamp(0.0, 1.0);

      if (_holdProgress >= 1.0) {
        timer.cancel();
        _holdTimer = null;
        _holdProgress = 0.0;
        _holdingButton = null;
        triggerAlert(alertType, immediate: true);
      }
      notifyListeners();
    });
  }

  void endButtonHold(AlertType alertType) {
    if (_holdTimer != null) {
      _holdTimer?.cancel();
      _holdTimer = null;
    }

    // If released before 5s, trigger normal mistouch flow (single click)
    if (_holdProgress < 1.0 && _holdingButton == alertType) {
      triggerAlert(alertType, immediate: false);
    }

    _holdProgress = 0.0;
    _holdingButton = null;
    notifyListeners();
  }

  // --- CONFIRMED EMERGENCY DISPATCH ---
  Future<void> confirmEmergencyDispatch() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownRemaining = 0;

    _state = SystemState.activeDispatch;
    _soundService.playEmergencyAlarm();

    final alertName = _activeAlertType?.shortCode ?? 'POLICE';
    logEvent(LogType.danger, '💥 CONFIRMED EMERGENCY DISPATCH: $alertName Dispatched with Live GPS Coordinates!');

    // Build authoritative emergency record
    final recordId = 'emg_${DateTime.now().millisecondsSinceEpoch}';
    final hasCoords = _currentLat != null && _currentLng != null;
    final mapUrl = hasCoords
        ? 'https://maps.google.com/?q=${_currentLat!.toStringAsFixed(5)},${_currentLng!.toStringAsFixed(5)}'
        : null;

    final record = EmergencyRecord(
      emergencyId: recordId,
      userId: _medicalProfile.nationalId,
      latitude: _currentLat,
      longitude: _currentLng,
      accuracy: _currentAccuracy,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      alertType: alertName,
      readableAddress: _currentAddress,
      emergencyStatus: hasCoords ? 'DISPATCHED' : 'LOCATION_UNAVAILABLE',
      googleMapsUrl: mapUrl,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    _lastEmergencyRecord = record;
    _locationStatusText = 'Emergency alert sent';
    notifyListeners();

    // Sync to Firebase Cloud Firestore
    await _firebaseService.saveEmergencyRecord(record);

    // Simulate contacts dispatch delivery
    _dispatchToContacts();
  }

  // --- CANCELLATION FLOW ---
  bool cancelAlert({required String enteredPin, bool skipPin = false}) {
    if (!skipPin && enteredPin != _securityPin) {
      logEvent(LogType.danger, '❌ Mistouch cancellation denied: Incorrect Security PIN.');
      return false;
    }

    _countdownTimer?.cancel();
    _countdownTimer = null;

    final wasCountdown = _state == SystemState.mistouchWindow;
    _state = SystemState.allSafe;
    _countdownRemaining = 0;
    _holdProgress = 0.0;
    _holdingButton = null;

    _soundService.playSafeChime();

    if (wasCountdown) {
      logEvent(LogType.success, '✅ Mistouch Alert Cancelled. System returned to All Safe standby.');
    } else {
      logEvent(LogType.success, '🛡️ Active ${_activeAlertType?.shortCode ?? "Emergency"} Resolved. Responders stood down.');
      if (_lastEmergencyRecord != null) {
        _firebaseService.resolveEmergency(_lastEmergencyRecord!.emergencyId);
      }
    }

    _activeAlertType = null;
    _resetContactStatuses();
    notifyListeners();
    return true;
  }

  // --- VEHICLE CRASH SIMULATION ---
  void simulateVehicleCrash() {
    if (!_crashDetectionEnabled) return;
    logEvent(LogType.danger, '🚗💥 CRASH IMPACT DETECTED! Accelerometer: 9.8G Impact Vector. Initiating emergency response.');
    triggerAlert(AlertType.crash, immediate: false);
  }

  // --- FIND MY AEGIS BUZZER ---
  void triggerFindMyAegis() {
    logEvent(LogType.info, '🔊 "Find My AEGIS" command sent. Hardware acoustic beacon sounding...');
    _soundService.playEmergencyAlarm();
  }

  // --- DISPATCH SIMULATION PROGRESSION ---
  void _dispatchToContacts() {
    for (int i = 0; i < _contacts.length; i++) {
      final contact = _contacts[i];
      contact.status = 'SENDING';

      // Delivered delay
      Future.delayed(Duration(milliseconds: 1200 + i * 800), () {
        if (_state == SystemState.activeDispatch) {
          contact.status = 'DELIVERED';
          notifyListeners();
        }
      });

      // Acknowledged delay
      Future.delayed(Duration(milliseconds: 4000 + i * 2000), () {
        if (_state == SystemState.activeDispatch) {
          contact.status = 'ACKNOWLEDGED';
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  void _resetContactStatuses() {
    for (var c in _contacts) {
      c.status = 'STANDBY';
    }
  }

  // --- CONTACTS MANAGEMENT ---
  void addContact(EmergencyContact contact) {
    _contacts.add(contact);
    _storageService.saveContacts(_contacts);
    _firebaseService.syncContacts(_medicalProfile.nationalId, _contacts);
    notifyListeners();
  }

  void updateContact(EmergencyContact updated) {
    final idx = _contacts.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _contacts[idx] = updated;
      _storageService.saveContacts(_contacts);
      _firebaseService.syncContacts(_medicalProfile.nationalId, _contacts);
      notifyListeners();
    }
  }

  void deleteContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
    _storageService.saveContacts(_contacts);
    _firebaseService.syncContacts(_medicalProfile.nationalId, _contacts);
    notifyListeners();
  }

  // --- MEDICAL PROFILE ---
  void updateMedicalProfile(MedicalProfile profile) {
    _medicalProfile = profile;
    _storageService.saveMedicalProfile(_medicalProfile);
    _firebaseService.syncMedicalProfile(_medicalProfile.nationalId, _medicalProfile);
    notifyListeners();
  }

  // --- SETTINGS ---
  void updateSettings({int? mistouchSec, String? pin, bool? crashDetection, bool? sound, bool? haptics}) {
    if (mistouchSec != null) _mistouchDurationSec = mistouchSec;
    if (pin != null) _securityPin = pin;
    if (crashDetection != null) _crashDetectionEnabled = crashDetection;
    if (sound != null) _soundService.isSoundEnabled = sound;
    if (haptics != null) _soundService.isHapticEnabled = haptics;

    _storageService.saveSettings(mistouchSec: _mistouchDurationSec, pin: _securityPin);
    notifyListeners();
  }

  // --- SAFE ZONES ---
  void addSafeZone(String name, double lat, double lng, int radius) {
    _safeZones.add({
      'id': 'z_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'lat': lat,
      'lng': lng,
      'radius': radius,
    });
    logEvent(LogType.info, '🛡️ Safe Zone added: $name (${radius}m radius)');
    notifyListeners();
  }

  void removeSafeZone(String id) {
    _safeZones.removeWhere((z) => z['id'] == id);
    notifyListeners();
  }

  // --- DISPATCH LAUNCHERS ---
  DispatchPayload getDispatchPayload() {
    return _dispatchService.generatePayload(
      alertType: _activeAlertType ?? AlertType.police,
      lat: _currentLat,
      lng: _currentLng,
      accuracy: _currentAccuracy,
      address: _currentAddress,
      medicalProfile: _medicalProfile,
      battery: _telemetry.battery,
    );
  }

  Future<void> sendWhatsAppToContact(EmergencyContact contact) async {
    final payload = getDispatchPayload();
    await _dispatchService.sendWhatsApp(contact.phone, payload.smsText);
  }

  Future<void> sendSmsToContact(EmergencyContact contact) async {
    final payload = getDispatchPayload();
    await _dispatchService.sendSms(contact.phone, payload.smsText);
  }

  Future<void> callContact(EmergencyContact contact) async {
    await _dispatchService.makePhoneCall(contact.phone);
  }

  Future<void> callHotline(String number) async {
    await _dispatchService.makePhoneCall(number);
  }

  Future<void> executeNativeShare() async {
    final payload = getDispatchPayload();
    await _dispatchService.shareNative(payload.title, payload.smsText);
  }
}
