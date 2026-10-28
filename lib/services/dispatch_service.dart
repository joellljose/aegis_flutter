import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/alert_types.dart';
import '../models/medical_profile.dart';

class DispatchPayload {
  final String title;
  final String recipient;
  final String smsText;
  final String category;

  DispatchPayload({
    required this.title,
    required this.recipient,
    required this.smsText,
    required this.category,
  });
}

class DispatchService {
  static final DispatchService _instance = DispatchService._internal();
  factory DispatchService() => _instance;
  DispatchService._internal();

  DispatchPayload generatePayload({
    required AlertType alertType,
    required double? lat,
    required double? lng,
    required double? accuracy,
    required String? address,
    required MedicalProfile medicalProfile,
    required int battery,
  }) {
    final hasCoords = lat != null && lng != null;
    final mapUrl = hasCoords
        ? 'https://maps.google.com/?q=${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}'
        : 'Location unavailable';
    final accStr = accuracy != null ? '±${accuracy.round()}m' : 'GPS lock pending';
    final addrStr = address ?? 'Live Phone Coordinates';

    switch (alertType) {
      case AlertType.police:
        return DispatchPayload(
          title: '🚨 POLICE EMERGENCY SOS BROADCAST',
          recipient: 'Police Control Room (112 / 100) & PCR Patrol Units',
          smsText: '🚨 POLICE EMERGENCY ALERT: AEGIS One user has triggered an SOS beacon! '
              'Location: $mapUrl (Address: $addrStr, Accuracy: $accStr). '
              'User ID: ${medicalProfile.nationalId}. Urgent Police Assistance Required!',
          category: 'POLICE',
        );

      case AlertType.medical:
      case AlertType.crash:
        final isCrash = alertType == AlertType.crash;
        return DispatchPayload(
          title: isCrash ? '💥 VEHICLE CRASH EMERGENCY' : '🚑 MEDICAL EMERGENCY BROADCAST',
          recipient: 'Emergency Medical Services (EMS 108) & Nearby Hospitals',
          smsText: '🚑 MEDICAL EMERGENCY: AEGIS One user requires urgent ambulance response! '
              'Location: $mapUrl (Accuracy: $accStr).\n'
              'PATIENT MEDICAL ID: ${medicalProfile.fullName} | Blood Group: ${medicalProfile.bloodGroup} | '
              'Allergies: ${medicalProfile.allergies} | Conditions: ${medicalProfile.conditions}. '
              'Notes: ${medicalProfile.emergencyNotes}. Dispatch paramedics immediately!',
          category: 'MEDICAL',
        );

      case AlertType.contact:
        return DispatchPayload(
          title: '👥 EMERGENCY ALERT TO FAMILY & FRIENDS',
          recipient: 'Designated Family Members & Emergency Network',
          smsText: '🚨 SOS EMERGENCY: I have activated my AEGIS One Personal Safety Device! '
              'My current live location: $mapUrl ($addrStr). '
              'Battery: $battery%. Please contact me or send help immediately!',
          category: 'CONTACT',
        );
    }
  }

  /// Launches WhatsApp with pre-filled message
  Future<bool> sendWhatsApp(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[DispatchService] WhatsApp launch error: $e');
    }
    return false;
  }

  /// Launches native SMS application with pre-filled message
  Future<bool> sendSms(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': message,
      },
    );
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('[DispatchService] SMS launch error: $e');
    }
    return false;
  }

  /// Initiates direct phone call (e.g., 112, 100, 108 or contact)
  Future<bool> makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('[DispatchService] Phone call launch error: $e');
    }
    return false;
  }

  /// Triggers native OS Share Sheet (WhatsApp, Telegram, Messages, Mail)
  Future<void> shareNative(String title, String text) async {
    try {
      await Share.share(text, subject: title);
    } catch (e) {
      debugPrint('[DispatchService] Native share error: $e');
    }
  }
}
