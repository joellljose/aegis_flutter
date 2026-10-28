import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/aegis_provider.dart';
import '../theme/aegis_theme.dart';

class DispatchDialog extends StatelessWidget {
  const DispatchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AegisProvider>();
    final payload = provider.getDispatchPayload();
    final contacts = provider.contacts;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payload.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AegisColors.policeRed,
                          ),
                        ),
                        Text(
                          payload.recipient,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AegisColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AegisColors.textMuted),
                  ),
                ],
              ),
              const Divider(color: AegisColors.cardBorder, height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payload Preview Card
                      const Text(
                        'OUTGOING EMERGENCY TRANSMISSION PAYLOAD:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AegisColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AegisColors.primaryBlueLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AegisColors.primaryBlue.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          payload.smsText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AegisColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Copy & Native Share
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: payload.smsText));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied payload to clipboard!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy Text'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AegisColors.textPrimary,
                                side: const BorderSide(color: AegisColors.cardBorder),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => provider.executeNativeShare(),
                              icon: const Icon(Icons.share, size: 16),
                              label: const Text('Share Sheet'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AegisColors.primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Contacts Direct Dispatch List
                      const Text(
                        'DIRECT CONTACT DISPATCH CHANNELS:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AegisColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...contacts.map((c) => _buildContactDispatchTile(context, provider, c)),

                      const SizedBox(height: 16),
                      // National Emergency Hotlines
                      const Text(
                        'NATIONAL EMERGENCY HOTLINES:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AegisColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildHotlineButton(
                              label: '112 SOS',
                              color: AegisColors.policeRed,
                              onTap: () => provider.callHotline('112'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHotlineButton(
                              label: '100 Police',
                              color: AegisColors.primaryBlue,
                              onTap: () => provider.callHotline('100'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHotlineButton(
                              label: '108 EMS',
                              color: AegisColors.medicalGreen,
                              onTap: () => provider.callHotline('108'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactDispatchTile(BuildContext context, AegisProvider provider, dynamic contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AegisColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AegisColors.textPrimary),
                ),
                Text(
                  '${contact.phone} • ${contact.relation}',
                  style: const TextStyle(color: AegisColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => provider.sendWhatsAppToContact(contact),
            icon: const Icon(Icons.chat_bubble_outline, color: AegisColors.medicalGreen, size: 20),
            tooltip: 'WhatsApp',
          ),
          IconButton(
            onPressed: () => provider.sendSmsToContact(contact),
            icon: const Icon(Icons.sms_outlined, color: AegisColors.primaryBlue, size: 20),
            tooltip: 'SMS',
          ),
          IconButton(
            onPressed: () => provider.callContact(contact),
            icon: const Icon(Icons.phone_outlined, color: AegisColors.warningAmber, size: 20),
            tooltip: 'Phone Call',
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineButton({required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
