import 'package:flutter/material.dart';

import '../error/app_error.dart';

class ErrorUtils {
  static void showErrorSnackBar(
    BuildContext context,
    AppError error,
  ) {
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error.message,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onError.withOpacity(0.8),
            ),
          ),
          if (error.details != null)
            Text(
              error.details!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onError.withOpacity(0.8),
              ),
            ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
      action: error.isRetryable && error.onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: error.onRetry!,
            )
          : null,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
