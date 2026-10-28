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

  /// Syncs emergency contacts to Firestore ('trusted_contacts' and 'users' collections)
  Future<void> syncContacts(String userId, List<EmergencyContact> contacts) async {
    if (!_isFirebaseReady || _firestore == null) return;
    try {
      // 1. Update contacts array on the user document
      await _firestore!
          .collection('users')
          .doc(userId)
          .set({
        'contacts': contacts.map((c) => c.toJson()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // 2. Write each contact to the 'trusted_contacts' collection
      final batch = _firestore!.batch();
      for (final contact in contacts) {
        final docRef = _firestore!.collection('trusted_contacts').doc(contact.id);
        batch.set(docRef, {
          'contact_id': contact.id,
          'owner_uid': userId,
          'contact_name': contact.name,
          'phone': contact.phone,
          'relationship': contact.relation,
          'priority': contact.priority,
          'channels': contact.channels,
          'status': contact.status,
          'invitation_status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('[FirebaseService] Synced ${contacts.length} contacts to Cloud Firestore.');
    } catch (e) {
      debugPrint('[FirebaseService] Contacts sync error: $e');
    }
  }

  /// Adds or updates an individual contact in Firestore
  Future<bool> saveContactToFirestore({
    required String userId,
    required EmergencyContact contact,
  }) async {
    if (!_isFirebaseReady || _firestore == null) return false;
    try {
      await _firestore!
          .collection('trusted_contacts')
          .doc(contact.id)
          .set({
        'contact_id': contact.id,
        'owner_uid': userId,
        'contact_name': contact.name,
        'phone': contact.phone,
        'relationship': contact.relation,
        'priority': contact.priority,
        'channels': contact.channels,
        'status': contact.status,
        'invitation_status': 'accepted',
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      debugPrint('[FirebaseService] Saved contact to Firestore: ${contact.id}');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error saving contact to Firestore: $e');
      return false;
    }
  }

  /// Deletes a contact from Firestore 'trusted_contacts' collection
  Future<bool> deleteContactFromFirestore(String contactId) async {
    if (!_isFirebaseReady || _firestore == null) return false;
    try {
      await _firestore!.collection('trusted_contacts').doc(contactId).delete();
      debugPrint('[FirebaseService] Deleted contact from Firestore: $contactId');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting contact from Firestore: $e');
      return false;
    }
  }

  /// Fetches contacts from Cloud Firestore
  Future<List<EmergencyContact>> fetchContactsFromFirestore(String userId) async {
    if (!_isFirebaseReady || _firestore == null) return [];
    try {
      final query = await _firestore!
          .collection('trusted_contacts')
          .where('owner_uid', isEqualTo: userId)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.map((doc) => EmergencyContact.fromJson(doc.data())).toList();
      }

      final userDoc = await _firestore!.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        if (data['contacts'] is List) {
          return (data['contacts'] as List)
              .map((c) => EmergencyContact.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[FirebaseService] Error fetching contacts from Firestore: $e');
    }
    return [];
  }

  /// Checks if a user document exists in Cloud Firestore 'users' collection
  Future<Map<String, dynamic>?> checkUserInFirestore(String uid) async {
    if (!_isFirebaseReady || _firestore == null) return null;
    try {
      final doc = await _firestore!.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('[FirebaseService] Error checking user in Firestore: $e');
    }
    return null;
  }

  /// Checks if an email is already registered in Cloud Firestore 'users' collection
  Future<bool> checkEmailExistsInFirestore(String email) async {
    if (!_isFirebaseReady || _firestore == null) return false;
    try {
      final query = await _firestore!
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[FirebaseService] Error querying email in Firestore: $e');
      return false;
    }
  }

  /// Saves or updates a user document in Cloud Firestore
  Future<bool> saveUserToFirestore(String uid, Map<String, dynamic> userData) async {
    if (!_isFirebaseReady || _firestore == null) return false;
    try {
      await _firestore!.collection('users').doc(uid).set(userData, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error saving user to Firestore: $e');
      return false;
    }
  }
}
