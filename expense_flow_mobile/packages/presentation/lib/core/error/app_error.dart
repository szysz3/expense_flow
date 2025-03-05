import 'package:domain/model/failure/failures.dart';
import 'package:flutter/material.dart';

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
    VoidCallback? onRetry,
  }) {
    if (failure is ConnectionFailure) {
      return AppError(
        message: 'Network error',
        details: 'Please check your internet connection and try again.',
        isRetryable: true,
        onRetry: onRetry,
      );
    } else if (failure is UnauthorizedFailure) {
      return AppError(
        message: 'Authentication error',
        details: 'Your session has expired. Please sign in again.',
        isRetryable: false,
      );
    } else if (failure is NotFoundFailure) {
      return AppError(
        message: 'Not found',
        details: 'The requested resource could not be found.',
        isRetryable: false,
      );
    } else if (failure is ValidationFailure) {
      String detailMessage = 'Please check your input and try again.';
      if (failure.details.isNotEmpty &&
          failure.details.first.containsKey('msg')) {
        detailMessage = failure.details.first['msg'] as String;
      }

      return AppError(
        message: 'Invalid data',
        details: detailMessage,
        isRetryable: false,
      );
    } else {
      return AppError(
        message: 'Something went wrong',
        details: failure.message,
        isRetryable: true,
        onRetry: onRetry,
      );
    }
  }

  factory AppError.fromException(
    dynamic exception, {
    VoidCallback? onRetry,
  }) {
    return AppError(
      message: 'Unexpected error',
      details: exception.toString(),
      isRetryable: true,
      onRetry: onRetry,
    );
  }
}
