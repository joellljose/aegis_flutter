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
    // Default initial contacts matching project specs
    return [
      EmergencyContact(
        id: 'c1',
        name: 'Elena Vance (Mother)',
        phone: '+1 (555) 234-8901',
        relation: 'Family',
        priority: 1,
        channels: ['SMS', 'WhatsApp', 'CALL'],
      ),
      EmergencyContact(
        id: 'c2',
        name: 'Campus Safety & Patrol HQ',
        phone: '+1 (555) 889-4400',
        relation: 'Security',
        priority: 1,
        channels: ['SMS', 'CALL'],
      ),
      EmergencyContact(
        id: 'c3',
        name: 'Marcus Brody (Roommate)',
        phone: '+1 (555) 345-6712',
        relation: 'Friend',
        priority: 2,
        channels: ['SMS', 'WhatsApp'],
      ),
    ];
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
