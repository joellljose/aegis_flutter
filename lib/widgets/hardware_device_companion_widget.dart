import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert_types.dart';
import '../models/system_state.dart';
import '../providers/aegis_provider.dart';
import '../theme/aegis_theme.dart';

class HardwareDeviceCompanionWidget extends StatefulWidget {
  const HardwareDeviceCompanionWidget({super.key});

  @override
  State<HardwareDeviceCompanionWidget> createState() => _HardwareDeviceCompanionWidgetState();
}

class _HardwareDeviceCompanionWidgetState extends State<HardwareDeviceCompanionWidget> {
  bool _showHardwareTestDeck = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AegisProvider>();
    final isSafe = provider.state == SystemState.allSafe;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSafe ? AegisColors.cardBorder : AegisColors.policeRed,
          width: isSafe ? 1.0 : 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Header: Visual, Name, Status
          Row(
            children: [
              // Hardware Pendant Icon Box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AegisColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AegisColors.primaryBlue.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.shield,
                        size: 28,
                        color: isSafe ? AegisColors.primaryBlue : AegisColors.policeRed,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSafe ? AegisColors.medicalGreen : AegisColors.policeRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Device Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.telemetry.bleDeviceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AegisColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AegisColors.medicalGreenLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AegisColors.medicalGreen.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'ARMED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AegisColors.medicalGreen,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Physical Wearable IPSD · BLE 5.0 Active',
                      style: TextStyle(fontSize: 12, color: AegisColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AegisColors.cardBorder, height: 1),
          const SizedBox(height: 16),

          // Companion Telemetry Indicators Row
          Row(
            children: [
              Expanded(
                child: _buildTelemetryPill(
                  icon: Icons.battery_charging_full,
                  label: 'BATTERY',
                  value: '${provider.telemetry.battery}%',
                  sub: '~5d Standby',
                  color: AegisColors.medicalGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryPill(
                  icon: Icons.bluetooth_connected,
                  label: 'BLE LINK',
                  value: 'Connected',
                  sub: '-58 dBm Signal',
                  color: AegisColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryPill(
                  icon: Icons.cell_tower,
                  label: 'CELLULAR',
                  value: 'LTE-M 4G',
                  sub: 'eSIM Online',
                  color: AegisColors.warningAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Physical Buttons Status Monitoring Section
          const Text(
            'PHYSICAL HARDWARE SENSORS & BUTTONS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AegisColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AegisColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AegisColors.cardBorder),
            ),
            child: Column(
              children: [
                _buildHardwareSensorLine(
                  buttonNumber: '1',
                  label: 'Button 1: Police SOS',
                  role: 'Police Control Room · Instant Dispatch',
                  color: AegisColors.policeRed,
                ),
                const Divider(color: AegisColors.cardBorder, height: 16),
                _buildHardwareSensorLine(
                  buttonNumber: '2',
                  label: 'Button 2: Medical Emergency',
                  role: 'Ambulance 108 · Medical ID Transmission',
                  color: AegisColors.medicalGreen,
                ),
                const Divider(color: AegisColors.cardBorder, height: 16),
                _buildHardwareSensorLine(
                  buttonNumber: '3',
                  label: 'Button 3: Custom Contact',
                  role: 'Family & Priority Responders Alert',
                  color: AegisColors.primaryBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hardware Companion Controls: Ping Buzzer & Re-sync
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => provider.triggerFindMyAegis(),
                  icon: const Icon(Icons.volume_up_outlined, size: 16),
                  label: const Text('Find My AEGIS (Buzzer)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AegisColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  provider.refreshLocation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Telemetry refreshed with AEGIS One hardware.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Sync', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AegisColors.textSecondary,
                  side: const BorderSide(color: AegisColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Developer / Hardware Testing Deck
          InkWell(
            onTap: () => setState(() => _showHardwareTestDeck = !_showHardwareTestDeck),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _showHardwareTestDeck ? Icons.expand_less : Icons.tune,
                        size: 16,
                        color: AegisColors.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Hardware Signal Test Simulator',
                        style: TextStyle(fontSize: 12, color: AegisColors.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    _showHardwareTestDeck ? 'Hide' : 'Test Triggers',
                    style: const TextStyle(fontSize: 11, color: AegisColors.primaryBlue, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          if (_showHardwareTestDeck) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AegisColors.primaryBlueLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AegisColors.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Simulate incoming physical button click over BLE:',
                    style: TextStyle(fontSize: 11, color: AegisColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSimulateBtn(
                          label: 'Btn 1 (Police)',
                          color: AegisColors.policeRed,
                          onTap: () => provider.triggerAlert(AlertType.police, immediate: false),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildSimulateBtn(
                          label: 'Btn 2 (Medical)',
                          color: AegisColors.medicalGreen,
                          onTap: () => provider.triggerAlert(AlertType.medical, immediate: false),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildSimulateBtn(
                          label: 'Btn 3 (Contact)',
                          color: AegisColors.primaryBlue,
                          onTap: () => provider.triggerAlert(AlertType.contact, immediate: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _buildSimulateBtn(
                      label: '💥 Simulate 9.8G Vehicle Crash Deceleration',
                      color: AegisColors.warningAmber,
                      onTap: () => provider.simulateVehicleCrash(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryPill({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AegisColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AegisColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AegisColors.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          Text(sub, style: const TextStyle(fontSize: 9, color: AegisColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildHardwareSensorLine({
    required String buttonNumber,
    required String label,
    required String role,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              buttonNumber,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AegisColors.textPrimary),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 11, color: AegisColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AegisColors.primaryBlueLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'PHYSICAL',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AegisColors.primaryBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulateBtn({required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
