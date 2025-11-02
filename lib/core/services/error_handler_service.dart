import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

enum ErrorType {
  network,
  authentication,
  authorization,
  notFound,
  validation,
  server,
  permission,
  unknown,
}

class AppException implements Exception {
  final ErrorType type;
  final String technicalMessage;
  final String? userMessage;
  final int? statusCode;

  AppException({
    required this.type,
    required this.technicalMessage,
    this.userMessage,
    this.statusCode,
  });

  String get message => userMessage ?? _getDefaultUserMessage();

  String _getDefaultUserMessage() {
    switch (type) {
      case ErrorType.network:
        return 'Unable to connect. Please check your internet connection.';
      case ErrorType.authentication:
        return 'Invalid credentials. Please check your email and password.';
      case ErrorType.authorization:
        return 'You do not have permission to perform this action.';
      case ErrorType.notFound:
        return 'The requested resource was not found.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      case ErrorType.server:
        return 'Something went wrong on our end. Please try again later.';
      case ErrorType.permission:
        return 'Permission denied. Please grant the required permission.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

class ErrorHandlerService {
  static AppException handleError(dynamic error) {
    // Handle AppException directly
    if (error is AppException) {
      return error;
    }

    // Handle SocketException (network errors)
    if (error is SocketException) {
      return AppException(
        type: ErrorType.network,
        technicalMessage: error.toString(),
        userMessage: 'No internet connection. Please check your network settings.',
      );
    }

    // Handle HttpException
    if (error is http.ClientException) {
      return AppException(
        type: ErrorType.network,
        technicalMessage: error.toString(),
        userMessage: 'Failed to connect to the server. Please try again.',
      );
    }

    // Handle String errors (from catch blocks)
    if (error is String) {
      return _parseStringError(error);
    }

    // Handle other exceptions
    return AppException(
      type: ErrorType.unknown,
      technicalMessage: error.toString(),
    );
  }

  static AppException handleHttpError(http.Response response) {
    final statusCode = response.statusCode;
    
    switch (statusCode) {
      case 400:
        return AppException(
          type: ErrorType.validation,
          technicalMessage: 'Bad Request: ${response.body}',
          statusCode: statusCode,
          userMessage: 'Invalid request. Please check your input.',
        );
      case 401:
        return AppException(
          type: ErrorType.authentication,
          technicalMessage: 'Unauthorized: ${response.body}',
          statusCode: statusCode,
          userMessage: 'Invalid credentials. Please check your email and password.',
        );
      case 403:
        return AppException(
          type: ErrorType.authorization,
          technicalMessage: 'Forbidden: ${response.body}',
          statusCode: statusCode,
          userMessage: 'You do not have permission to access this resource.',
        );
      case 404:
        return AppException(
          type: ErrorType.notFound,
          technicalMessage: 'Not Found: ${response.body}',
          statusCode: statusCode,
          userMessage: 'The requested resource was not found.',
        );
      case 500:
      case 502:
      case 503:
        return AppException(
          type: ErrorType.server,
          technicalMessage: 'Server Error: ${response.body}',
          statusCode: statusCode,
          userMessage: 'Server error. Please try again later.',
        );
      default:
        return AppException(
          type: ErrorType.unknown,
          technicalMessage: 'HTTP $statusCode: ${response.body}',
          statusCode: statusCode,
        );
    }
  }

  static AppException _parseStringError(String error) {
    final lowerError = error.toLowerCase();

    // Network-related errors
    if (lowerError.contains('socketexception') ||
        lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('failed host lookup')) {
      return AppException(
        type: ErrorType.network,
        technicalMessage: error,
        userMessage: 'No internet connection. Please check your network settings.',
      );
    }

    // Authentication errors
    if (lowerError.contains('invalid credentials') ||
        lowerError.contains('unauthorized') ||
        lowerError.contains('authentication')) {
      return AppException(
        type: ErrorType.authentication,
        technicalMessage: error,
        userMessage: 'Invalid credentials. Please check your email and password.',
      );
    }

    // Permission errors
    if (lowerError.contains('permission') ||
        lowerError.contains('denied') ||
        lowerError.contains('access denied')) {
      return AppException(
        type: ErrorType.permission,
        technicalMessage: error,
        userMessage: 'Permission denied. Please grant the required permission.',
      );
    }

    // Validation errors
    if (lowerError.contains('validation') ||
        lowerError.contains('invalid') ||
        lowerError.contains('required') ||
        lowerError.contains('empty')) {
      return AppException(
        type: ErrorType.validation,
        technicalMessage: error,
        userMessage: 'Please check your input and try again.',
      );
    }

    // Default to unknown
    return AppException(
      type: ErrorType.unknown,
      technicalMessage: error,
    );
  }

  static AppException handlePermissionError(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.denied:
        return AppException(
          type: ErrorType.permission,
          technicalMessage: 'Permission denied',
          userMessage: 'Permission was denied. Please enable it in settings.',
        );
      case PermissionStatus.permanentlyDenied:
        return AppException(
          type: ErrorType.permission,
          technicalMessage: 'Permission permanently denied',
          userMessage: 'Permission is permanently denied. Please enable it in app settings.',
        );
      case PermissionStatus.restricted:
        return AppException(
          type: ErrorType.permission,
          technicalMessage: 'Permission restricted',
          userMessage: 'Permission is restricted. You may need parental controls or administrator approval.',
        );
      default:
        return AppException(
          type: ErrorType.permission,
          technicalMessage: 'Permission error: $status',
          userMessage: 'Permission error. Please try again.',
        );
    }
  }

  static String getUserFriendlyMessage(dynamic error) {
    final appException = handleError(error);
    return appException.message;
  }
}

