import 'package:flutter/material.dart';

class BaseReceiptDetailScreen extends StatelessWidget {
  final Widget content;
  final Widget actionButtons;
  final bool isDeleting;
  final bool isSaving;
  final String deletingMessage;
  final String savingMessage;

  const BaseReceiptDetailScreen({
    super.key,
    required this.content,
    required this.actionButtons,
    required this.isDeleting,
    required this.isSaving,
    required this.deletingMessage,
    required this.savingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildDragHandle(context),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: content,
                      ),
                    ),
                  ],
                ),
                actionButtons,
              ],
            ),
          ),
          if (isDeleting) _buildLoadingOverlay(context, deletingMessage),
          if (isSaving) _buildLoadingOverlay(context, savingMessage),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context, String message) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }
}
