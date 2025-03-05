import 'package:flutter/material.dart';

import '../error/app_error.dart';

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
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
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (error.isRetryable && error.onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: error.onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInlineError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
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
                        .withOpacity(0.8),
                  ),
            ),
          ],
          if (error.isRetryable && error.onRetry != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: error.onRetry,
                child: const Text('Retry'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
