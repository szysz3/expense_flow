import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../bloc/add_item_bloc.dart';
import '../bloc/add_item_event.dart';

// TODO: decouple view from BLoC
class DescriptionSection extends StatelessWidget {
  final TextEditingController controller;

  const DescriptionSection({
    super.key,
    required this.controller,
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
          onChanged: (value) => context.read<AddItemBloc>().add(
                AddItemEvent.descriptionChanged(value),
              ),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).description,
            hintText: AppLocalizations.of(context).enterItemDescription,
            border: InputBorder.none,
          ),
        ),
      );
}
