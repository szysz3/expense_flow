import 'package:domain/model/failure/failures.dart';
import 'package:flutter/material.dart';
import 'package:localization/localization_service.dart';

class AppError {
  final String message;
  final String? details;
  final bool isRetryable;
  final VoidCallback? onRetry;

  const AppError({
    required this.message,
    this.details,
    this.isRetryable = false,
    this.onRetry,
  });

  factory AppError.fromFailure(
    Failure failure, {
    required LocalizationService localizationService,
    VoidCallback? onRetry,
  }) {
    final l10n = localizationService.localizations;

    if (failure is ConnectionFailure) {
      return AppError(
        message: l10n.networkError,
        details: l10n.checkInternetConnection,
        isRetryable: true,
        onRetry: onRetry,
      );
    } else if (failure is UnauthorizedFailure) {
      return AppError(
        message: l10n.authenticationError,
        details: l10n.sessionExpired,
        isRetryable: false,
      );
    } else if (failure is NotFoundFailure) {
      return AppError(
        message: l10n.notFound,
        details: l10n.resourceNotFound,
        isRetryable: false,
      );
    } else if (failure is ValidationFailure) {
      String detailMessage = l10n.checkInputAndTryAgain;
      if (failure.details.isNotEmpty &&
          failure.details.first.containsKey('msg')) {
        detailMessage = failure.details.first['msg'] as String;
      }

      return AppError(
        message: l10n.invalidData,
        details: detailMessage,
        isRetryable: false,
      );
    } else {
      return AppError(
        message: l10n.somethingWentWrong,
        details: failure.message,
        isRetryable: true,
        onRetry: onRetry,
      );
    }
  }

  factory AppError.fromException(
    dynamic exception, {
    required LocalizationService localizationService,
    isRetryable = true,
    VoidCallback? onRetry,
  }) {
    final l10n = localizationService.localizations;

    return AppError(
      message: l10n.unexpectedError,
      details: exception.toString(),
      isRetryable: isRetryable,
      onRetry: onRetry,
    );
  }
}
