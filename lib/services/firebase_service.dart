import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/emergency_record.dart';
import '../models/emergency_contact.dart';
import '../models/medical_profile.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isFirebaseReady = false;
  bool get isFirebaseReady => _isFirebaseReady;

  FirebaseFirestore? _firestore;

  /// Initializes Firebase if not already initialized
  Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        // Will initialize default app if google-services.json / GoogleService-Info.plist is configured
        await Firebase.initializeApp();
      }
      _firestore = FirebaseFirestore.instance;
      _isFirebaseReady = true;
      debugPrint('[FirebaseService] Cloud Firestore connected successfully.');
    } catch (e) {
      _isFirebaseReady = false;
      debugPrint('[FirebaseService] Firebase init notice (will run in offline-first mode): $e');
    }
  }

  /// Saves or updates an Emergency record in Firestore
  Future<bool> saveEmergencyRecord(EmergencyRecord record) async {
    if (!_isFirebaseReady || _firestore == null) {
      debugPrint('[FirebaseService] Offline-first: Emergency stored locally: ${record.emergencyId}');
      return false;
    }

    try {
      await _firestore!
          .collection('emergencies')
          .doc(record.emergencyId)
          .set(record.toJson(), SetOptions(merge: true));
      debugPrint('[FirebaseService] Firestore saved emergency: ${record.emergencyId}');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error saving emergency to Firestore: $e');
      return false;
    }
  }

  /// Updates emergency reverse-geocoded readable address
  Future<void> updateEmergencyAddress(String emergencyId, String address) async {
    if (!_isFirebaseReady || _firestore == null) return;
    try {
      await _firestore!
          .collection('emergencies')
          .doc(emergencyId)
          .update({
        'readable_address': address,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('[FirebaseService] Address update error: $e');
    }
  }

  /// Marks an emergency record as resolved
  Future<void> resolveEmergency(String emergencyId) async {
    if (!_isFirebaseReady || _firestore == null) return;
    try {
      await _firestore!
          .collection('emergencies')
          .doc(emergencyId)
          .update({
        'emergency_status': 'RESOLVED',
        'resolved_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('[FirebaseService] Resolve error: $e');
    }
  }

  /// Real-time stream of all emergencies (for recipient/patrol monitors)
  Stream<List<EmergencyRecord>>? streamEmergencies() {
    if (!_isFirebaseReady || _firestore == null) return null;
    return _firestore!
        .collection('emergencies')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyRecord.fromJson(doc.data()))
            .toList());
  }

  /// Syncs user's medical profile to Firestore
  Future<void> syncMedicalProfile(String userId, MedicalProfile profile) async {
    if (!_isFirebaseReady || _firestore == null) return;
    try {
      await _firestore!
          .collection('users')
          .doc(userId)
          .set({'medical_profile': profile.toJson()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirebaseService] Medical sync error: $e');
    }
  }

  /// Syncs emergency contacts to Firestore
  Future<void> syncContacts(String userId, List<EmergencyContact> contacts) async {
    if (!_isFirebaseReady || _firestore == null) return;
    try {
      await _firestore!
          .collection('users')
          .doc(userId)
          .set({
        'contacts': contacts.map((c) => c.toJson()).toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirebaseService] Contacts sync error: $e');
    }
  }
}
