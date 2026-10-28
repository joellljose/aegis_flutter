import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aegis_provider.dart';
import '../theme/aegis_theme.dart';

class PinDialog extends StatefulWidget {
  final bool isResolvingActive;
  const PinDialog({super.key, this.isResolvingActive = false});

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AegisProvider>();

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isResolvingActive ? Icons.verified_user : Icons.lock_outline,
            color: widget.isResolvingActive ? AegisColors.medicalGreen : AegisColors.warningAmber,
          ),
          const SizedBox(width: 8),
          Text(
            widget.isResolvingActive ? 'Resolve Emergency' : 'Cancel Mistouch Alert',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isResolvingActive
                ? 'Enter your 4-digit Security PIN to confirm safe resolution and notify responders.'
                : 'Enter your 4-digit Security PIN (Default: 1234) to cancel this alert and return to All Safe.',
            style: const TextStyle(color: AegisColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 12,
              fontWeight: FontWeight.bold,
              color: AegisColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              errorText: _errorMessage,
              filled: true,
              fillColor: AegisColors.primaryBlueLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AegisColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AegisColors.primaryBlue, width: 1.5),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back', style: TextStyle(color: AegisColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final pin = _pinController.text.trim();
            final success = provider.cancelAlert(enteredPin: pin);
            if (success) {
              Navigator.pop(context);
            } else {
              setState(() {
                _errorMessage = 'Incorrect PIN. Try again.';
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isResolvingActive ? AegisColors.medicalGreen : AegisColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirm PIN'),
        ),
      ],
    );
  }
}
