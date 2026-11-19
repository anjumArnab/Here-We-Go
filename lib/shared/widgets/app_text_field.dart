import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextInputType keyboardType;
  final int? maxLength;
  final double? minValue;
  final double? maxValue;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.onSaved,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onSaved: onSaved,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[300],
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
