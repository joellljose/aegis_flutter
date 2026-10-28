import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/system_state.dart';
import '../providers/aegis_provider.dart';
import '../theme/aegis_theme.dart';
import 'pin_dialog.dart';

class MistouchCountdownCard extends StatelessWidget {
  const MistouchCountdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AegisProvider>();

    if (provider.state != SystemState.mistouchWindow && provider.state != SystemState.activeDispatch) {
      return const SizedBox.shrink();
    }

    final isCountdown = provider.state == SystemState.mistouchWindow;
    final alertName = provider.activeAlertType?.displayName ?? 'EMERGENCY ALERT';
    final remaining = provider.countdownRemaining;
    final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (remaining % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCountdown ? AegisColors.warningAmberLight : AegisColors.policeRedLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCountdown ? AegisColors.warningAmber : AegisColors.policeRed,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Banner Alert Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCountdown ? Icons.warning_amber_rounded : Icons.crisis_alert,
                color: isCountdown ? AegisColors.warningAmber : AegisColors.policeRed,
                size: 24,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  alertName,
                  style: TextStyle(
                    color: isCountdown ? AegisColors.warningAmber : AegisColors.policeRed,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (isCountdown) ...[
            Text(
              'Alert Will Be Sent After ${provider.mistouchDurationSec} Seconds',
              style: const TextStyle(
                color: AegisColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mistouch Prevention Active. Cancel if triggered accidentally on hardware.',
              style: TextStyle(color: AegisColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Digital Clock
            Text(
              '$minutes:$seconds',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AegisColors.warningAmber,
                fontFamily: 'monospace',
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),

            // Linear Progress Track
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: provider.countdownPercent,
                minHeight: 8,
                backgroundColor: const Color(0xFFFDE68A),
                valueColor: const AlwaysStoppedAnimation<Color>(AegisColors.warningAmber),
              ),
            ),
            const SizedBox(height: 18),

            // Actions: Cancel Alert or Send Immediately
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const PinDialog(),
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel Alert'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AegisColors.textPrimary,
                      side: const BorderSide(color: AegisColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.confirmEmergencyDispatch(),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send Alert Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AegisColors.policeRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'LIVE EMERGENCY DISPATCH CONFIRMED',
              style: TextStyle(
                color: AegisColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'GPS coordinates and medical ID have been transmitted to First Responders & Emergency Contacts.',
              style: TextStyle(color: AegisColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const PinDialog(isResolvingActive: true),
                );
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Resolve Emergency / Stand Down'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AegisColors.medicalGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
