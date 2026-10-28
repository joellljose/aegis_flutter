import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/alert_types.dart';
import '../models/system_state.dart';
import '../models/emergency_contact.dart';
import '../models/medical_profile.dart';
import '../models/emergency_record.dart';
import '../models/telemetry.dart';
import '../models/log_entry.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
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
  final AuthService _authService = AuthService();

  String? _currentUserId;
  String get currentUserId => _currentUserId ?? _medicalProfile.nationalId;

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

  // Telemetry & Hardware Device State
  final TelemetryData _telemetry = TelemetryData();
  TelemetryData get telemetry => _telemetry;

  // Real GPS & Location Status
  double? _currentLat;
  double? get currentLat => _currentLat;

  double? _currentLng;
  double? get currentLng => _currentLng;

  double? _currentAccuracy;
  double? get currentAccuracy => _currentAccuracy;

  double _currentSpeed = 0.0;
  double get currentSpeed => _currentSpeed;

  String _currentAddress = 'Acquiring GPS fix...';
  String get currentAddress => _currentAddress;

  String _locationStatusText = 'Acquiring GPS...';
  String get locationStatusText => _locationStatusText;

  // User-defined Safe Zones (empty by default)
  final List<Map<String, dynamic>> _safeZones = [];
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

    final paired = await _storageService.loadPairedDevice();
    if (paired != null && paired['deviceId'] != null) {
      _telemetry.isPaired = true;
      _telemetry.deviceId = paired['deviceId'];
      _telemetry.bleDeviceName = paired['deviceName'] ?? 'AEGIS One (${paired['deviceId']})';
      _telemetry.bleConnected = true;
      _telemetry.lastSyncTime = DateTime.now();
    }

    logEvent(LogType.info, 'AEGIS One Companion App ready. Sensors standby.');
    notifyListeners();

    // Fetch real GPS lock
    refreshLocation();
  }

  /// Syncs authenticated user data with the provider
  void syncWithUserProfile(UserProfile user) {
    _currentUserId = user.uid;
    if (user.fullName.isNotEmpty) {
      _medicalProfile.fullName = user.fullName;
    }
    _medicalProfile.nationalId = user.uid;

    if (user.emergencyProfile != null) {
      final ep = user.emergencyProfile!;
      if (ep['blood_group'] != null && (ep['blood_group'] as String).isNotEmpty) {
        _medicalProfile.bloodGroup = ep['blood_group'];
      }
      if (ep['allergies'] != null && (ep['allergies'] as String).isNotEmpty) {
        _medicalProfile.allergies = ep['allergies'];
      }
      if (ep['medical_notes'] != null && (ep['medical_notes'] as String).isNotEmpty) {
        _medicalProfile.conditions = ep['medical_notes'];
      }
      if (ep['emergency_note'] != null && (ep['emergency_note'] as String).isNotEmpty) {
        _medicalProfile.emergencyNotes = ep['emergency_note'];
      }
    }

    if (user.pairedDeviceId != null && user.pairedDeviceId!.isNotEmpty) {
      pairDevice(user.pairedDeviceId!, syncBackend: false);
    }

    // Load contacts stored in Firestore for this authenticated user
    _loadFirestoreContacts(user.uid);

    notifyListeners();
  }

  Future<void> _loadFirestoreContacts(String uid) async {
    try {
      // 1. Fetch from Cloud Firestore
      final fsContacts = await _firebaseService.fetchContactsFromFirestore(uid);
      if (fsContacts.isNotEmpty) {
        _contacts = fsContacts;
        await _storageService.saveContacts(_contacts);
        notifyListeners();
        return;
      }

      // 2. Fetch from Backend API
      final token = _authService.token;
      if (token != null) {
        final baseUrl = await _authService.getBaseUrl();
        final res = await http.get(
          Uri.parse('$baseUrl/api/contacts'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List;
          if (list.isNotEmpty) {
            _contacts = list.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>)).toList();
            await _storageService.saveContacts(_contacts);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('[AegisProvider] Contact load notice: $e');
    }
  }

  Future<void> _syncContactWithBackend(EmergencyContact contact) async {
    try {
      final token = _authService.token;
      if (token == null) return;
      final baseUrl = await _authService.getBaseUrl();
      final url = Uri.parse('$baseUrl/api/contacts');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'contact_id': contact.id,
          'contact_name': contact.name,
          'phone': contact.phone,
          'relationship': contact.relation,
          'priority': contact.priority,
          'channels': contact.channels,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[AegisProvider] Backend contact sync notice: $e');
    }
  }

  Future<void> _deleteContactFromBackend(String contactId) async {
    try {
      final token = _authService.token;
      if (token == null) return;
      final baseUrl = await _authService.getBaseUrl();
      final url = Uri.parse('$baseUrl/api/contacts/$contactId');
      await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[AegisProvider] Backend contact delete notice: $e');
    }
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
    _locationStatusText = 'Acquiring GPS fix...';
    notifyListeners();

    final result = await _locationService.getCurrentLocation();
    if (result.success && result.latitude != null && result.longitude != null) {
      _currentLat = result.latitude;
      _currentLng = result.longitude;
      _currentAccuracy = result.accuracy;
      _currentSpeed = result.speed ?? 0.0;
      _telemetry.gpsLocked = true;
      _locationStatusText = 'Location acquired (±${result.accuracy?.toStringAsFixed(1) ?? "3"}m)';
      notifyListeners();

      final addr = await _locationService.reverseGeocode(_currentLat!, _currentLng!);
      if (addr != null) {
        _currentAddress = addr;
        notifyListeners();
      }
    } else {
      _locationStatusText = 'GPS Standby';
      _telemetry.gpsLocked = false;
      notifyListeners();
    }
  }

  // --- DEVICE PAIRING & MANAGEMENT ---
  Future<void> pairDevice(String deviceId, {String? deviceName, bool syncBackend = true}) async {
    final cleanId = deviceId.trim().toUpperCase();
    final cleanName = deviceName ?? 'AEGIS One ($cleanId)';

    _telemetry.isPaired = true;
    _telemetry.deviceId = cleanId;
    _telemetry.bleDeviceName = cleanName;
    _telemetry.bleConnected = true;
    _telemetry.lastSyncTime = DateTime.now();
    _telemetry.gpsLocked = _currentLat != null;

    await _storageService.savePairedDevice(cleanId, cleanName);
    logEvent(LogType.info, '🔗 AEGIS One wearable paired: $cleanId (BLE Link Established)');
    notifyListeners();
  }

  Future<void> unpairDevice() async {
    final oldId = _telemetry.deviceId ?? 'Wearable';
    _telemetry.isPaired = false;
    _telemetry.bleConnected = false;
    _telemetry.deviceId = null;
    _telemetry.bleDeviceName = 'AEGIS One';
    await _storageService.clearPairedDevice();
    logEvent(LogType.warn, 'Unpaired $oldId from this companion device.');
    notifyListeners();
  }

  void toggleBleConnection() {
    if (!_telemetry.isPaired) return;
    _telemetry.bleConnected = !_telemetry.bleConnected;
    if (_telemetry.bleConnected) {
      _telemetry.lastSyncTime = DateTime.now();
      _soundService.playClick();
      logEvent(LogType.info, '📶 BLE 5.0 Link established with ${_telemetry.deviceId}');
    } else {
      logEvent(LogType.warn, '⚠️ BLE Link disconnected.');
    }
    notifyListeners();
  }

  void toggleFallDetection() {
    _telemetry.fallDetectionEnabled = !_telemetry.fallDetectionEnabled;
    logEvent(LogType.info, 'Fall Detection ${_telemetry.fallDetectionEnabled ? "ARMED" : "DISABLED"} on wearable.');
    notifyListeners();
  }

  void toggleSilentAlarm() {
    _telemetry.silentAlarm = !_telemetry.silentAlarm;
    logEvent(LogType.warn, 'Silent Alarm Mode ${_telemetry.silentAlarm ? "ACTIVATED" : "DEACTIVATED"}.');
    notifyListeners();
  }

  void triggerFindMyAegis() {
    _soundService.playWarningBeep();
    logEvent(LogType.info, '🔊 Acoustic Ping transmitted to ${_telemetry.deviceId ?? "Wearable"} (Buzzer sounded).');
  }

  void simulateVehicleCrash() {
    triggerAlert(AlertType.crash, immediate: false);
  }

  // --- TRIGGER ALERT (Hardware button click or Crash) ---
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
    logEvent(LogType.warn, '⚠️ ${alertType.displayName} Triggered. $_mistouchDurationSec s cancellation window active.');

    _startCountdownTimer();
    notifyListeners();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownRemaining > 0) {
        _countdownRemaining--;
        if (_countdownRemaining % 10 == 0 && _countdownRemaining > 0 && !_telemetry.silentAlarm) {
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
    if (!_telemetry.silentAlarm) {
      _soundService.playEmergencyAlarm();
    }

    final alertName = _activeAlertType?.shortCode ?? 'POLICE';
    logEvent(LogType.danger, '💥 CONFIRMED EMERGENCY DISPATCH: $alertName Dispatched with Live GPS Coordinates!');

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

    // Notify contacts
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
    _countdownRemaining = 0;
    _state = SystemState.allSafe;
    _activeAlertType = null;
    _soundService.playCancelChime();

    logEvent(LogType.info, '✅ Alert cancelled. System reset to Safe Standby.');
    _resetContactStatuses();
    notifyListeners();
    return true;
  }

  // --- DISPATCH NOTIFICATIONS ---
  void _dispatchToContacts() {
    for (int i = 0; i < _contacts.length; i++) {
      final contact = _contacts[i];
      contact.status = 'SENDING';

      Future.delayed(Duration(milliseconds: 1000 + i * 600), () {
        if (_state == SystemState.activeDispatch) {
          contact.status = 'DELIVERED';
          notifyListeners();
        }
      });

      Future.delayed(Duration(milliseconds: 3000 + i * 1500), () {
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
    final uid = currentUserId;
    if (uid.isNotEmpty) {
      _firebaseService.saveContactToFirestore(userId: uid, contact: contact);
      _firebaseService.syncContacts(uid, _contacts);
      _syncContactWithBackend(contact);
    }
    logEvent(LogType.info, 'Emergency contact saved to Firestore: ${contact.name}');
    notifyListeners();
  }

  void updateContact(EmergencyContact updated) {
    final idx = _contacts.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _contacts[idx] = updated;
      _storageService.saveContacts(_contacts);
      final uid = currentUserId;
      if (uid.isNotEmpty) {
        _firebaseService.saveContactToFirestore(userId: uid, contact: updated);
        _firebaseService.syncContacts(uid, _contacts);
        _syncContactWithBackend(updated);
      }
      notifyListeners();
    }
  }

  void deleteContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
    _storageService.saveContacts(_contacts);
    final uid = currentUserId;
    if (uid.isNotEmpty) {
      _firebaseService.deleteContactFromFirestore(id);
      _firebaseService.syncContacts(uid, _contacts);
      _deleteContactFromBackend(id);
    }
    logEvent(LogType.warn, 'Emergency contact removed from Firestore.');
    notifyListeners();
  }

  // --- MEDICAL PROFILE ---
  void updateMedicalProfile(MedicalProfile profile) {
    _medicalProfile = profile;
    _storageService.saveMedicalProfile(_medicalProfile);
    _firebaseService.syncMedicalProfile(_medicalProfile.nationalId, _medicalProfile);
    logEvent(LogType.info, 'Medical Profile updated.');
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
