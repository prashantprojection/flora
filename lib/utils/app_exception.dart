import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// A friendly exception class meant to be displayed directly to the user.
class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class ErrorHandler {
  /// Parses any exception into a user-friendly AppException.
  static AppException parse(Object error, [StackTrace? stackTrace]) {
    // 1. Log the error for crash reporting (Crashlytics/Sentry placeholder)
    _logErrorToCrashReporting(error, stackTrace);

    // 2. Parse Gemini API Exceptions
    if (error is GenerativeAIException) {
      if (error.message.contains('503')) {
        return AppException(
          'The AI model is currently experiencing high demand. Please try again in a few moments.',
          code: '503',
          originalError: error,
        );
      } else if (error.message.contains('429')) {
        return AppException(
          'You have reached the API limit. Please wait a moment and try again.',
          code: '429',
          originalError: error,
        );
      }
      return AppException(
        'An error occurred while generating a response. Please try again.',
        originalError: error,
      );
    }

    // 3. Parse Network/Socket Exceptions
    if (error is SocketException) {
      return AppException(
        'Unable to connect to the server. Please check your internet connection.',
        code: 'NETWORK_ERROR',
        originalError: error,
      );
    }

    // 4. Default fallback
    return AppException(
      'An unexpected error occurred. Please try again.',
      originalError: error,
    );
  }

  /// Placeholder for future Crashlytics or Sentry integration.
  static void _logErrorToCrashReporting(Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      print('--- ERROR HANDLER CAUGHT EXCEPTION ---');
      print(error);
      if (stackTrace != null) print(stackTrace);
      print('--------------------------------------');
    }
    // TODO: Implement FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // TODO: Implement Sentry.captureException(error, stackTrace: stackTrace);
  }
}
