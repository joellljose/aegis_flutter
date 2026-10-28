import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_contact.dart';
import '../models/medical_profile.dart';

class StorageService {
  static const String _keyContacts = 'aegis_contacts_v1';
  static const String _keyMedical = 'aegis_medical_v1';
  static const String _keyMistouchSec = 'aegis_mistouch_duration';
  static const String _keyPin = 'aegis_pin';

  Future<void> saveContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = contacts.map((c) => c.toJson()).toList();
    await prefs.setString(_keyContacts, jsonEncode(jsonList));
  }

  Future<List<EmergencyContact>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyContacts);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        return decoded.map((e) => EmergencyContact.fromJson(e)).toList();
      } catch (_) {}
    }
    // Return empty list so only real user-added contacts are loaded
    return [];
  }

  static const String _keyPairedDevice = 'aegis_paired_device_id';
  static const String _keyPairedDeviceName = 'aegis_paired_device_name';

  Future<void> savePairedDevice(String deviceId, String deviceName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPairedDevice, deviceId);
    await prefs.setString(_keyPairedDeviceName, deviceName);
  }

  Future<Map<String, String?>?> loadPairedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString(_keyPairedDevice);
    if (deviceId == null || deviceId.isEmpty) return null;
    return {
      'deviceId': deviceId,
      'deviceName': prefs.getString(_keyPairedDeviceName) ?? 'AEGIS One ($deviceId)',
    };
  }

  Future<void> clearPairedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPairedDevice);
    await prefs.remove(_keyPairedDeviceName);
  }

  Future<void> saveMedicalProfile(MedicalProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMedical, jsonEncode(profile.toJson()));
  }

  Future<MedicalProfile> loadMedicalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyMedical);
    if (data != null) {
      try {
        return MedicalProfile.fromJson(jsonDecode(data));
      } catch (_) {}
    }
    return MedicalProfile();
  }

  Future<void> saveSettings({required int mistouchSec, required String pin}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMistouchSec, mistouchSec);
    await prefs.setString(_keyPin, pin);
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'mistouchSec': prefs.getInt(_keyMistouchSec) ?? 120,
      'pin': prefs.getString(_keyPin) ?? '1234',
    };
  }
}
