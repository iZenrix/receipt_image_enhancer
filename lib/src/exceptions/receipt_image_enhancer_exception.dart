import '../enums/error_code.dart';

/// Exception thrown by [ReceiptImageEnhancer] for predictable failures.
final class ReceiptImageEnhancerException implements Exception {
  /// Creates an exception with a typed [code] and human-readable [message].
  const ReceiptImageEnhancerException({
    required this.code,
    required this.message,
    this.cause,
  });

  /// Machine-readable failure category.
  final ReceiptImageEnhancerErrorCode code;

  /// Human-readable description (must not include sensitive image bytes).
  final String message;

  /// Optional underlying cause.
  final Object? cause;

  @override
  String toString() => 'ReceiptImageEnhancerException($code): $message';
}
