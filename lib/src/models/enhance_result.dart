import 'dart:typed_data';

import '../enums/warning_code.dart';

/// Result of enhancing an image on disk.
final class ReceiptEnhanceFileResult {
  /// Creates a file enhancement result.
  const ReceiptEnhanceFileResult({
    required this.outputPath,
    required this.width,
    required this.height,
    required this.documentDetected,
    required this.cropApplied,
    required this.detectionConfidence,
    required this.processingDuration,
    required this.warnings,
  });

  /// Path to the newly written enhanced image.
  final String outputPath;

  /// Output width in pixels.
  final int width;

  /// Output height in pixels.
  final int height;

  /// Whether document corners passed the confidence threshold.
  final bool documentDetected;

  /// Whether crop/perspective correction was applied.
  final bool cropApplied;

  /// Heuristic detection confidence in `0..1`, or null when unused.
  final double? detectionConfidence;

  /// End-to-end native processing duration.
  final Duration processingDuration;

  /// Non-fatal warnings.
  final List<ReceiptEnhanceWarning> warnings;
}

/// Result of enhancing an in-memory image.
final class ReceiptEnhanceBytesResult {
  /// Creates a bytes enhancement result.
  const ReceiptEnhanceBytesResult({
    required this.bytes,
    required this.width,
    required this.height,
    required this.documentDetected,
    required this.cropApplied,
    required this.detectionConfidence,
    required this.processingDuration,
    required this.warnings,
  });

  /// Encoded enhanced image bytes.
  final Uint8List bytes;

  /// Output width in pixels.
  final int width;

  /// Output height in pixels.
  final int height;

  /// Whether document corners passed the confidence threshold.
  final bool documentDetected;

  /// Whether crop/perspective correction was applied.
  final bool cropApplied;

  /// Heuristic detection confidence in `0..1`, or null when unused.
  final double? detectionConfidence;

  /// End-to-end native processing duration.
  final Duration processingDuration;

  /// Non-fatal warnings.
  final List<ReceiptEnhanceWarning> warnings;
}
