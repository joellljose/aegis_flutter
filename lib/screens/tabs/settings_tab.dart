import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/aegis_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/aegis_theme.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AegisProvider>();
    final isFirebaseActive = FirebaseService().isFirebaseReady;

    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Authenticated Account & Role
          const Text(
            'AUTHENTICATED ACCOUNT & ROLE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AegisColors.textSecondary),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AegisColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AegisColors.primaryBlueLight,
                      child: Text(
                        currentUser != null && currentUser.fullName.isNotEmpty
                            ? currentUser.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AegisColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.fullName ?? 'AEGIS User',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AegisColors.textPrimary),
                          ),
                          Text(
                            currentUser?.email ?? 'Unauthenticated',
                            style: const TextStyle(fontSize: 12, color: AegisColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AegisColors.primaryBlueLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentUser?.role.toUpperCase() ?? 'USER',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AegisColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns_outlined, size: 16, color: AegisColors.textSecondary),
                        const SizedBox(width: 6),
                        const Text(
                          'Backend Status:',
                          style: TextStyle(fontSize: 12, color: AegisColors.textSecondary),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AegisColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'FastAPI Connected',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AegisColors.successGreen),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => authProvider.logout(),
                      icon: const Icon(Icons.logout, size: 16, color: AegisColors.dangerRed),
                      label: const Text('Sign Out', style: TextStyle(color: AegisColors.dangerRed, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Alert & Safety Configuration
          const Text(
            'ALERT & SAFETY CONFIGURATION',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AegisColors.textSecondary),
          ),
          const SizedBox(height: 10),

          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AegisColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Mistouch Prevention Duration Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mistouch Cancel Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AegisColors.textPrimary)),
                    Text(
                      '${provider.mistouchDurationSec} Seconds',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AegisColors.primaryBlue, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Time window to abort an accidental press on your hardware before dispatch.',
                  style: TextStyle(color: AegisColors.textSecondary, fontSize: 12),
                ),
                Slider(
                  value: provider.mistouchDurationSec.toDouble(),
                  min: 15.0,
                  max: 120.0,
                  divisions: 7,
                  activeColor: AegisColors.primaryBlue,
                  inactiveColor: AegisColors.primaryBlueLight,
                  onChanged: (val) {
                    provider.updateSettings(mistouchSec: val.round());
                  },
                ),
                const Divider(color: AegisColors.cardBorder, height: 24),

                // Crash Detection Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vehicle Crash Detection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AegisColors.textPrimary)),
                  subtitle: const Text('Auto-triggers SOS upon sudden deceleration >9.0G.', style: TextStyle(fontSize: 12, color: AegisColors.textSecondary)),
                  value: provider.crashDetectionEnabled,
                  activeTrackColor: AegisColors.primaryBlueLight,
                  activeColor: AegisColors.primaryBlue,
                  onChanged: (val) => provider.updateSettings(crashDetection: val),
                ),
                const Divider(color: AegisColors.cardBorder, height: 16),

                // Audio Alarm Siren Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Audible Emergency Buzzer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AegisColors.textPrimary)),
                  subtitle: const Text('High-decibel acoustic beacon sounded on active alert.', style: TextStyle(fontSize: 12, color: AegisColors.textSecondary)),
                  value: true,
                  activeTrackColor: AegisColors.primaryBlueLight,
                  activeColor: AegisColors.primaryBlue,
                  onChanged: (val) => provider.updateSettings(sound: val),
                ),
                const Divider(color: AegisColors.cardBorder, height: 16),

                // Vibration Haptics Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Physical Haptic Feedback', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AegisColors.textPrimary)),
                  subtitle: const Text('Tactile vibration pulse during button hold and countdown ticks.', style: TextStyle(fontSize: 12, color: AegisColors.textSecondary)),
                  value: true,
                  activeTrackColor: AegisColors.primaryBlueLight,
                  activeColor: AegisColors.primaryBlue,
                  onChanged: (val) => provider.updateSettings(haptics: val),
                ),
                const Divider(color: AegisColors.cardBorder, height: 16),

                // Security PIN Setting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Security PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AegisColors.textPrimary)),
                        Text('Required to cancel an active emergency alert.', style: TextStyle(color: AegisColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () => _showChangePinDialog(context, provider),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AegisColors.primaryBlue,
                        side: const BorderSide(color: AegisColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('PIN: •••• (${provider.securityPin})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
          const SizedBox(height: 24),

          // Section: Firebase Cloud Database
          const Text(
            'FIREBASE CLOUD DATABASE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AegisColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AegisColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFirebaseActive ? AegisColors.medicalGreenLight : AegisColors.primaryBlueLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFirebaseActive ? Icons.cloud_done : Icons.cloud_queue,
                        color: isFirebaseActive ? AegisColors.medicalGreen : AegisColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isFirebaseActive ? 'Connected to Cloud Firestore' : 'Offline-First Local Database Active',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isFirebaseActive ? AegisColors.medicalGreen : AegisColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isFirebaseActive
                      ? 'Live emergency coordinates, contacts, and logs sync directly with Firestore collections `emergencies` and `users`.'
                      : 'All records are saved safely in local storage (SharedPreferences) and will automatically sync once your Firebase project is linked via google-services.json.',
                  style: const TextStyle(color: AegisColors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ),
          const SizedBox(height: 24),

          // Section: Technical Specifications
          const Text(
            'AEGIS ONE HARDWARE SPECIFICATIONS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AegisColors.textSecondary),
          ),
          const SizedBox(height: 10),
          _buildSpecRow('DEVICE MODEL', 'AEGIS One // Smart Personal Emergency Response Device (IPSD)'),
          _buildSpecRow('MANUFACTURER', 'KnightMaster Innovations Pvt. Ltd.'),
          _buildSpecRow('BUTTONS', '3 Dedicated Recessed Tactile Switches on Physical Hardware'),
          _buildSpecRow('CHASSIS & WEIGHT', 'Impact-resistant polycarbonate pendant, 28 grams'),
          _buildSpecRow('WATERPROOF RATING', 'IP67 Submersible (1 meter for 30 minutes)'),
          _buildSpecRow('BATTERY', '550 mAh Li-Po rechargeable, ~5-7 days standby, USB-C Fast Charge'),
          _buildSpecRow('CONNECTIVITY', 'LTE-M / NB-IoT eSIM, GNSS GPS/GLONASS, Bluetooth 5.0 Low Energy'),
          _buildSpecRow('SENSORS', '3-Axis High-G Impact Accelerometer, Gyroscope, Acoustic Locator'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AegisColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AegisColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: AegisColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, AegisProvider provider) {
    final pinCtrl = TextEditingController(text: provider.securityPin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Security PIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(labelText: 'New 4-Digit PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final pin = pinCtrl.text.trim();
              if (pin.length == 4) {
                provider.updateSettings(pin: pin);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }
}
