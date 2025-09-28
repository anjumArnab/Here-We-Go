import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final bool isPrimary;
  final bool isLoading;

  const ActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final childWidget =
        isLoading
            ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
            : Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            );

    return SizedBox(
      height: 56,
      child:
          isPrimary
              ? ElevatedButton(
                onPressed:
                    isLoading ? null : () async => await onPressed?.call(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: childWidget,
              )
              : OutlinedButton(
                onPressed:
                    isLoading ? null : () async => await onPressed?.call(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4A90E2),
                  side: const BorderSide(color: Color(0xFF4A90E2), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: childWidget,
              ),
    );
  }
}
