import 'package:flutter/material.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

class DescriptionSection extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onDescriptionChanged;

  const DescriptionSection({
    super.key,
    required this.controller,
    required this.onDescriptionChanged,
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
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).description,
            hintText: AppLocalizations.of(context).enterItemDescription,
            border: InputBorder.none,
          ),
        ),
      );
}
