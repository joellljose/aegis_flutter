import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_flutter/models/alert_types.dart';
import 'package:aegis_flutter/models/emergency_record.dart';
import 'package:aegis_flutter/models/emergency_contact.dart';
import 'package:aegis_flutter/models/medical_profile.dart';
import 'package:aegis_flutter/services/dispatch_service.dart';

void main() {
  group('AEGIS One Core Models & Dispatch Tests', () {
    test('AlertType enum helper formatting', () {
      expect(AlertType.police.displayName, 'POLICE EMERGENCY');
      expect(AlertType.medical.shortCode, 'MEDICAL');
      expect(AlertType.fromString('CRASH'), AlertType.crash);
    });

    test('EmergencyContact serialization', () {
      final contact = EmergencyContact(
        id: 'c_test_1',
        name: 'Elena Vance',
        phone: '+1 555 123 4567',
        relation: 'Mother',
        priority: 1,
      );

      final json = contact.toJson();
      expect(json['name'], 'Elena Vance');
      expect(json['priority'], 1);

      final decoded = EmergencyContact.fromJson(json);
      expect(decoded.id, 'c_test_1');
      expect(decoded.name, 'Elena Vance');
    });

    test('MedicalProfile formatting & QR string generation', () {
      final profile = MedicalProfile(
        fullName: 'Alex Morgan',
        bloodGroup: 'O+ Positive',
        allergies: 'Penicillin',
        conditions: 'Asthma',
        nationalId: 'AEGIS-9821',
      );

      final qrText = profile.toQrString();
      expect(qrText.contains('Alex Morgan'), true);
      expect(qrText.contains('O+ Positive'), true);
      expect(qrText.contains('AEGIS-9821'), true);
    });

    test('DispatchService payload generator produces authoritative emergency dispatch', () {
      final service = DispatchService();
      final med = MedicalProfile(fullName: 'Alex Morgan', nationalId: 'AEGIS-9821');

      final payload = service.generatePayload(
        alertType: AlertType.police,
        lat: 12.9716,
        lng: 77.5946,
        accuracy: 5.0,
        address: 'MG Road, Bengaluru',
        medicalProfile: med,
        battery: 94,
      );

      expect(payload.category, 'POLICE');
      expect(payload.smsText.contains('POLICE EMERGENCY ALERT'), true);
      expect(payload.smsText.contains('https://maps.google.com/?q=12.97160,77.59460'), true);
      expect(payload.smsText.contains('AEGIS-9821'), true);
    });

    test('EmergencyRecord serialization for Cloud Firestore', () {
      final record = EmergencyRecord(
        emergencyId: 'emg_123',
        userId: 'user_alex',
        latitude: 12.9716,
        longitude: 77.5946,
        accuracy: 4.5,
        timestamp: 1698500000000,
        alertType: 'CRASH',
        readableAddress: 'Highway 44',
        emergencyStatus: 'DISPATCHED',
        createdAt: 1698500000000,
      );

      final json = record.toJson();
      expect(json['emergency_id'], 'emg_123');
      expect(json['alert_type'], 'CRASH');
      expect(json['emergency_status'], 'DISPATCHED');

      final deserialized = EmergencyRecord.fromJson(json);
      expect(deserialized.latitude, 12.9716);
      expect(deserialized.readableAddress, 'Highway 44');
    });
  });
}
