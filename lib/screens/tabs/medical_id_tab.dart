import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/medical_profile.dart';
import '../../providers/aegis_provider.dart';
import '../../theme/aegis_theme.dart';

class MedicalIdTab extends StatelessWidget {
  const MedicalIdTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AegisProvider>();
    final med = provider.medicalProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AegisColors.primaryBlueLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.health_and_safety, color: AegisColors.primaryBlue, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.fullName.isNotEmpty ? med.fullName : 'AEGIS User',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AegisColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${med.nationalId.isNotEmpty ? med.nationalId : "UNPAIRED"}',
                              style: const TextStyle(fontSize: 12, color: AegisColors.textSecondary, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _showEditMedicalDialog(context, provider, med),
                      icon: const Icon(Icons.edit_note, color: AegisColors.primaryBlue, size: 24),
                      tooltip: 'Edit Profile',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AegisColors.cardBorder, height: 1),
                const SizedBox(height: 16),

                // Medical Fields Grid
                Row(
                  children: [
                    Expanded(child: _buildInfoItem('BLOOD GROUP', med.bloodGroup, isHighlight: true)),
                    Expanded(child: _buildInfoItem('ALLERGIES', med.allergies)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildInfoItem('CONDITIONS', med.conditions)),
                    Expanded(child: _buildInfoItem('EMERGENCY NOTES', med.emergencyNotes)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // First Responders Dynamic QR Code Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AegisColors.primaryBlueLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_2, color: AegisColors.primaryBlue, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PARAMEDIC ON-SCENE SCANNER CODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AegisColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'First responders can scan this code from your smartphone screen to access critical health details instantly.',
                  style: TextStyle(color: AegisColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // QR Code Container
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AegisColors.cardBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: med.toQrString(),
                    version: QrVersions.auto,
                    size: 190,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),

                // Copy Medical ID text
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: med.toQrString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Medical ID summary copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Medical ID Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AegisColors.primaryBlue,
                    side: const BorderSide(color: AegisColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AegisColors.textMuted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 3),
        Text(
          value.isNotEmpty ? value : 'None',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AegisColors.policeRed : AegisColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showEditMedicalDialog(BuildContext context, AegisProvider provider, MedicalProfile med) {
    final nameCtrl = TextEditingController(text: med.fullName);
    final bloodCtrl = TextEditingController(text: med.bloodGroup);
    final allergiesCtrl = TextEditingController(text: med.allergies);
    final conditionsCtrl = TextEditingController(text: med.conditions);
    final notesCtrl = TextEditingController(text: med.emergencyNotes);
    final idCtrl = TextEditingController(text: med.nationalId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Medical Profile & ID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: bloodCtrl, decoration: const InputDecoration(labelText: 'Blood Group (e.g. O+ Positive)')),
              const SizedBox(height: 12),
              TextField(controller: allergiesCtrl, decoration: const InputDecoration(labelText: 'Allergies')),
              const SizedBox(height: 12),
              TextField(controller: conditionsCtrl, decoration: const InputDecoration(labelText: 'Medical Conditions')),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Emergency Notes / Instructions')),
              const SizedBox(height: 12),
              TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'National / AEGIS ID')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.updateMedicalProfile(MedicalProfile(
                fullName: nameCtrl.text.trim(),
                bloodGroup: bloodCtrl.text.trim(),
                allergies: allergiesCtrl.text.trim(),
                conditions: conditionsCtrl.text.trim(),
                emergencyNotes: notesCtrl.text.trim(),
                nationalId: idCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }
}
