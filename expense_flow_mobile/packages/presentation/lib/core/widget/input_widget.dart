import 'package:flutter/material.dart';

class InputWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onDescriptionChanged;
  final String labelText;
  final String hintText;
  final TextInputType? keyboardType;

  const InputWidget({
    super.key,
    required this.controller,
    required this.onDescriptionChanged,
    required this.labelText,
    required this.hintText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.4),
        ),
        child: TextField(
          controller: controller,
          onChanged: onDescriptionChanged,
          keyboardType: keyboardType ?? TextInputType.text,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: InputBorder.none,
          ),
        ),
      );
}
