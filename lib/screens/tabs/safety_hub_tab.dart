import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/log_entry.dart';
import '../../providers/aegis_provider.dart';
import '../../theme/aegis_theme.dart';
import '../../widgets/hardware_device_companion_widget.dart';
import '../../widgets/mistouch_countdown_card.dart';
import '../../widgets/dispatch_dialog.dart';

class SafetyHubTab extends StatelessWidget {
  const SafetyHubTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AegisProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Countdown / Emergency Banner (Activates when hardware button is triggered)
          const MistouchCountdownCard(),

          // Hardware Device Companion Card (Monitors physical AEGIS One wearable)
          const Text(
            'PAIRED HARDWARE DEVICE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AegisColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const HardwareDeviceCompanionWidget(),
          const SizedBox(height: 12),

          // Companion Device Instruction Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AegisColors.primaryBlueLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AegisColors.primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sensors, color: AegisColors.primaryBlue, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: AegisColors.textSecondary, fontSize: 12, height: 1.4),
                      children: [
                        TextSpan(
                          text: 'Hardware Standby: ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AegisColors.textPrimary),
                        ),
                        TextSpan(
                          text: 'Emergency alerts are initiated directly via physical buttons on your AEGIS One device. When pressed, this companion app handles mistouch cancellation, GPS sync, and contact notifications.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Quick Hardware Actions
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Crash Impact',
                  subtitle: 'Simulate 9.8G vehicle impact',
                  icon: Icons.car_crash_outlined,
                  color: AegisColors.policeRed,
                  onTap: () => provider.simulateVehicleCrash(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Find My AEGIS',
                  subtitle: 'Sound acoustic locator',
                  icon: Icons.volume_up_outlined,
                  color: AegisColors.primaryBlue,
                  onTap: () => provider.triggerFindMyAegis(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dispatch Channels Modal Trigger
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const DispatchDialog(),
                );
              },
              icon: const Icon(Icons.broadcast_on_personal, size: 18),
              label: const Text('Open Emergency Dispatch & Broadcast Sheet', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AegisColors.primaryBlue,
                side: BorderSide(color: AegisColors.primaryBlue.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Hardware Telemetry Specifications Grid
          const Text(
            'HARDWARE TELEMETRY & SENSORS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AegisColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _buildTelemetryGrid(provider),

          const SizedBox(height: 22),

          // Live Event & Incident Logs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SYSTEM & INCIDENT LOGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AegisColors.textSecondary,
                ),
              ),
              Text(
                '${provider.logs.length} events',
                style: const TextStyle(fontSize: 11, color: AegisColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLogsList(provider),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AegisColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AegisColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryGrid(AegisProvider provider) {
    final t = provider.telemetry;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildTelTile('BATTERY', '${t.battery}%', '~${t.batteryDaysRemaining} Days Standby', AegisColors.medicalGreen),
        _buildTelTile('NETWORK', t.network, 'eSIM Active', AegisColors.primaryBlue),
        _buildTelTile('WATERPROOF', t.waterproofRating, 'Shockproof · 28g', AegisColors.textPrimary),
        _buildTelTile('BLUETOOTH', t.bleDeviceName, 'BLE 5.0 Low Power', AegisColors.warningAmber),
      ],
    );
  }

  Widget _buildTelTile(String label, String value, String sub, Color valColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AegisColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AegisColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valColor)),
          Text(sub, style: const TextStyle(fontSize: 9, color: AegisColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLogsList(AegisProvider provider) {
    if (provider.logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('No incident logs recorded yet.', style: TextStyle(color: AegisColors.textMuted, fontSize: 12)),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AegisColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        itemCount: provider.logs.length,
        separatorBuilder: (ctx, index) => const Divider(color: AegisColors.cardBorder, height: 1),
        itemBuilder: (context, index) {
          final log = provider.logs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.time,
                  style: const TextStyle(fontSize: 10, color: AegisColors.textMuted, fontFamily: 'monospace'),
                ),
                const SizedBox(width: 8),
                _buildLogBadge(log.type),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.message,
                    style: const TextStyle(fontSize: 11, color: AegisColors.textPrimary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogBadge(LogType type) {
    Color color;
    Color bg;
    String text;
    switch (type) {
      case LogType.info:
        color = AegisColors.primaryBlue;
        bg = AegisColors.primaryBlueLight;
        text = 'INFO';
        break;
      case LogType.warn:
        color = AegisColors.warningAmber;
        bg = AegisColors.warningAmberLight;
        text = 'WARN';
        break;
      case LogType.danger:
        color = AegisColors.policeRed;
        bg = AegisColors.policeRedLight;
        text = 'ALERT';
        break;
      case LogType.success:
        color = AegisColors.medicalGreen;
        bg = AegisColors.medicalGreenLight;
        text = 'SAFE';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
