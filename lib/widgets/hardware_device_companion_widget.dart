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

  void _showPairDialog(BuildContext context, AegisProvider provider) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AegisColors.primaryBlueLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bluetooth_searching, color: AegisColors.primaryBlue, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Pair AEGIS One',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AegisColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the Device ID printed on the back of your physical AEGIS One wearable (e.g. AEGIS-ONE-XXXX):',
              style: TextStyle(fontSize: 13, color: AegisColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'Device Serial / ID',
                hintText: 'e.g. AEGIS-ONE-01',
                prefixIcon: const Icon(Icons.qr_code, color: AegisColors.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AegisColors.background,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AegisColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final id = textController.text.trim();
              if (id.isNotEmpty) {
                provider.pairDevice(id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AegisColors.primaryBlue,
                    content: Text('AEGIS One ($id) successfully paired and linked.'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AegisColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Pair Device'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AegisProvider>();
    final telemetry = provider.telemetry;
    final isSafe = provider.state == SystemState.allSafe;

    // --- UNPAIRED STATE ---
    if (!telemetry.isPaired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AegisColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AegisColors.primaryBlueLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bluetooth_searching, color: AegisColors.primaryBlue, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'No AEGIS One Device Paired',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AegisColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pair your physical emergency response wearable via BLE 5.0 to activate hardware button alerts and telemetry.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AegisColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPairDialog(context, provider),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Pair AEGIS One ', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AegisColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // --- PAIRED STATE ---
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
          // Device Header: Icon, Name, Link Status
          Row(
            children: [
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
                            color: telemetry.bleConnected ? AegisColors.medicalGreen : AegisColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            telemetry.bleDeviceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AegisColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: telemetry.bleConnected ? AegisColors.medicalGreenLight : AegisColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: telemetry.bleConnected
                                  ? AegisColors.medicalGreen.withValues(alpha: 0.4)
                                  : AegisColors.cardBorder,
                            ),
                          ),
                          child: Text(
                            telemetry.bleConnected ? 'CONNECTED' : 'DISCONNECTED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: telemetry.bleConnected ? AegisColors.medicalGreen : AegisColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${telemetry.deviceId ?? "N/A"} · Firmware: ${telemetry.firmwareVersion}',
                      style: const TextStyle(fontSize: 11, color: AegisColors.textSecondary),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () => provider.toggleBleConnection(),
                icon: Icon(
                  telemetry.bleConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: telemetry.bleConnected ? AegisColors.primaryBlue : AegisColors.textMuted,
                ),
                tooltip: telemetry.bleConnected ? 'Disconnect BLE' : 'Reconnect BLE',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AegisColors.cardBorder, height: 1),
          const SizedBox(height: 16),

          // Telemetry Indicators Row
          Row(
            children: [
              Expanded(
                child: _buildTelemetryPill(
                  icon: Icons.battery_charging_full,
                  label: 'BATTERY',
                  value: '${telemetry.battery}%',
                  sub: '~${telemetry.batteryDaysRemaining}d Standby',
                  color: AegisColors.medicalGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryPill(
                  icon: Icons.bluetooth,
                  label: 'SIGNAL',
                  value: telemetry.bleConnected ? '${telemetry.rssi} dBm' : 'Lost',
                  sub: telemetry.bleConnected ? 'BLE 5.0 Link' : 'No Signal',
                  color: telemetry.bleConnected ? AegisColors.primaryBlue : AegisColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryPill(
                  icon: Icons.gps_fixed,
                  label: 'GPS LOCK',
                  value: provider.currentLat != null ? 'Acquired' : 'Standby',
                  sub: provider.currentAccuracy != null ? '±${provider.currentAccuracy!.toStringAsFixed(1)}m' : 'Searching',
                  color: provider.currentLat != null ? AegisColors.primaryBlue : AegisColors.warningAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Wearable Hardware Toggles (Fall Detection & Silent Alarm)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AegisColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AegisColors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.directions_run, size: 18, color: AegisColors.textPrimary),
                        SizedBox(width: 8),
                        Text('Hardware Fall Detection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AegisColors.textPrimary)),
                      ],
                    ),
                    Switch(
                      value: telemetry.fallDetectionEnabled,
                      onChanged: (_) => provider.toggleFallDetection(),
                      activeColor: AegisColors.primaryBlue,
                    ),
                  ],
                ),
                const Divider(color: AegisColors.cardBorder, height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.volume_off, size: 18, color: AegisColors.textPrimary),
                        SizedBox(width: 8),
                        Text('Silent Emergency Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AegisColors.textPrimary)),
                      ],
                    ),
                    Switch(
                      value: telemetry.silentAlarm,
                      onChanged: (_) => provider.toggleSilentAlarm(),
                      activeColor: AegisColors.policeRed,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hardware Buttons Status Monitoring Section
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

          // Hardware Controls: Ping Buzzer, Sync, and Unpair
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => provider.triggerFindMyAegis(),
                  icon: const Icon(Icons.volume_up_outlined, size: 16),
                  label: const Text('Test Buzzer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AegisColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  provider.refreshLocation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hardware telemetry and GPS synced.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Sync', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AegisColors.textSecondary,
                  side: const BorderSide(color: AegisColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => provider.unpairDevice(),
                icon: const Icon(Icons.link_off, size: 16, color: AegisColors.dangerRed),
                label: const Text('Unpair', style: TextStyle(fontSize: 12, color: AegisColors.dangerRed)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AegisColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hardware Trigger Testing Deck
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
                        'Hardware Button Simulation Deck',
                        style: TextStyle(fontSize: 12, color: AegisColors.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    _showHardwareTestDeck ? 'Hide' : 'Test Hardware',
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
                    'Simulate incoming physical button presses from the AEGIS One wearable:',
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
              Text(
                label,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AegisColors.textMuted, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AegisColors.textPrimary),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: AegisColors.textSecondary),
          ),
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
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              buttonNumber,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AegisColors.textPrimary),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 11, color: AegisColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSimulateBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
