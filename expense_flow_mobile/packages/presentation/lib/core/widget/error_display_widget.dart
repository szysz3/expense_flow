import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/core/widget/glass_container.dart';

import '../error/app_error.dart';
import 'animated_square_button.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final AppError error;
  final bool isFullScreen;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFullScreen) {
      return _buildFullScreenError(context);
    } else {
      return _buildInlineError(context);
    }
  }

  Widget _buildFullScreenError(BuildContext context) {
    return Column(children: [
      Expanded(
          child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'packages/presentation/assets/icon_failure.svg',
                width: 64,
                height: 64,
              ),
              const SizedBox(height: 16),
              Text(
                error.message,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (error.details != null) ...[
                const SizedBox(height: 8),
                Text(
                  error.details!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (error.isRetryable && error.onRetry != null) ...[
                const SizedBox(height: 24),
                _buildStyledButton(
                  context: context,
                  onPressed: error.onRetry!,
                  label: AppLocalizations.of(context).retry,
                  width: 100.0,
                  height: 52.0,
                ),
              ],
            ],
          ),
        ),
      ))
    ]);
  }

  Widget _buildInlineError(BuildContext context) {
    return GlassContainer(
      blur: 14,
      tint: Theme.of(context).colorScheme.error,
      tintOpacity: 0.18,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'packages/presentation/assets/icon_failure.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onErrorContainer,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error.message,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                ),
              ),
            ],
          ),
          if (error.details != null) ...[
            const SizedBox(height: 8),
            Text(
              error.details!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onErrorContainer
                        .withValues(alpha: 0.8),
                  ),
            ),
          ],
          if (error.isRetryable && error.onRetry != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: _buildStyledButton(
                context: context,
                onPressed: error.onRetry!,
                label: AppLocalizations.of(context).retry,
                width: 100.0,
                height: 52.0,
                iconSize: 20.0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStyledButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required String label,
    double width = AnimatedSquareButtonConstants.defaultSize,
    double height = AnimatedSquareButtonConstants.defaultSize,
    double iconSize = AnimatedSquareButtonConstants.defaultIconSize,
  }) {
    return AnimatedSquareButton(
      isProcessing: false,
      onPressed: onPressed,
      height: height,
      width: width,
      iconSize: iconSize,
      borderColor: Theme.of(context).colorScheme.outline,
      backgroundColor: Theme.of(context).colorScheme.surface,
      icon: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
