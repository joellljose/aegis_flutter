import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool isSoundEnabled = true;
  bool isHapticEnabled = true;

  void playClick() {
    if (isHapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void playWarningBeep() {
    if (isSoundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
    if (isHapticEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  void playEmergencyAlarm() {
    if (isSoundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
    if (isHapticEnabled) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.heavyImpact());
      Future.delayed(const Duration(milliseconds: 400), () => HapticFeedback.heavyImpact());
    }
  }

  void playSafeChime() {
    if (isSoundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (isHapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void playCancelChime() => playSafeChime();
}
