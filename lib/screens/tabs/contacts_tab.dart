import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/emergency_contact.dart';
import '../../providers/aegis_provider.dart';
import '../../theme/aegis_theme.dart';

class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AegisProvider>();
    final contacts = provider.contacts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // National Emergency Hotlines Bar
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AegisColors.policeRedLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_in_talk, color: AegisColors.policeRed, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DIRECT NATIONAL EMERGENCY HOTLINES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AegisColors.policeRed),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDialButton(
                        label: '🚨 112 SOS',
                        color: AegisColors.policeRed,
                        onTap: () => provider.callHotline('112'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDialButton(
                        label: '🚔 100 Police',
                        color: AegisColors.primaryBlue,
                        onTap: () => provider.callHotline('100'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDialButton(
                        label: '🚑 108 EMS',
                        color: AegisColors.medicalGreen,
                        onTap: () => provider.callHotline('108'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Contacts Header & Add Contact Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EMERGENCY NETWORK',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AegisColors.textSecondary),
                  ),
                  Text(
                    '${contacts.length} Designated Responders',
                    style: const TextStyle(fontSize: 11, color: AegisColors.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddContactDialog(context, provider),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Contact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AegisColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Contacts List
          if (contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AegisColors.primaryBlueLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.contact_phone_outlined, size: 36, color: AegisColors.primaryBlue),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No Emergency Contacts Added',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AegisColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add trusted family members, colleagues, or neighbors who will receive your live GPS coordinates and instant alerts whenever you trigger your AEGIS One device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AegisColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddContactDialog(context, provider),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add First Responder Contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AegisColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...contacts.map((contact) => _buildContactCard(context, provider, contact)),
        ],
      ),
    );
  }

  Widget _buildDialButton({required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, AegisProvider provider, EmergencyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AegisColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: AegisColors.primaryBlueLight,
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AegisColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              // Contact Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            contact.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AegisColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AegisColors.primaryBlueLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'P${contact.priority}',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AegisColors.primaryBlue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${contact.phone} • ${contact.relation}',
                      style: const TextStyle(fontSize: 12, color: AegisColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Dispatch Live Status Tag
              _buildStatusTag(contact.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AegisColors.cardBorder, height: 1),
          const SizedBox(height: 10),

          // Communication Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.chat_bubble_outline,
                    color: AegisColors.medicalGreen,
                    label: 'WhatsApp',
                    onTap: () => provider.sendWhatsAppToContact(contact),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    icon: Icons.sms_outlined,
                    color: AegisColors.primaryBlue,
                    label: 'SMS',
                    onTap: () => provider.sendSmsToContact(contact),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    icon: Icons.phone_outlined,
                    color: AegisColors.warningAmber,
                    label: 'Call',
                    onTap: () => provider.callContact(contact),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => provider.deleteContact(contact.id),
                icon: const Icon(Icons.delete_outline, size: 19, color: AegisColors.textMuted),
                tooltip: 'Delete Contact',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color color;
    Color bg;
    switch (status) {
      case 'SENDING':
        color = AegisColors.warningAmber;
        bg = AegisColors.warningAmberLight;
        break;
      case 'DELIVERED':
        color = AegisColors.primaryBlue;
        bg = AegisColors.primaryBlueLight;
        break;
      case 'ACKNOWLEDGED':
        color = AegisColors.medicalGreen;
        bg = AegisColors.medicalGreenLight;
        break;
      default:
        color = AegisColors.textMuted;
        bg = const Color(0xFFF1F5F9);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, AegisProvider provider) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationCtrl = TextEditingController(text: 'Family');
    int priority = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number (e.g. +91 98765 43210)')),
                const SizedBox(height: 12),
                TextField(controller: relationCtrl, decoration: const InputDecoration(labelText: 'Relation (Family, Doctor, Friend)')),
                const SizedBox(height: 16),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Text('Priority:', style: TextStyle(fontSize: 13, color: AegisColors.textSecondary)),
                    ChoiceChip(
                      label: const Text('Priority 1'),
                      selected: priority == 1,
                      selectedColor: AegisColors.primaryBlueLight,
                      labelStyle: TextStyle(
                        color: priority == 1 ? AegisColors.primaryBlue : AegisColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => priority = 1),
                    ),
                    ChoiceChip(
                      label: const Text('Priority 2'),
                      selected: priority == 2,
                      selectedColor: AegisColors.primaryBlueLight,
                      labelStyle: TextStyle(
                        color: priority == 2 ? AegisColors.primaryBlue : AegisColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => priority = 2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isNotEmpty && phone.isNotEmpty) {
                  provider.addContact(EmergencyContact(
                    id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    phone: phone,
                    relation: relationCtrl.text.trim(),
                    priority: priority,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Contact'),
            ),
          ],
        ),
      ),
    );
  }
}
