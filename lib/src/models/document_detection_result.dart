import 'receipt_point.dart';

/// Result of document corner detection.
final class DocumentDetectionResult {
  /// Creates a detection result.
  const DocumentDetectionResult({
    required this.detected,
    required this.confidence,
    required this.imageWidth,
    required this.imageHeight,
    this.topLeft,
    this.topRight,
    this.bottomRight,
    this.bottomLeft,
  });

  /// True when confidence exceeded the crop threshold.
  final bool detected;

  /// Heuristic confidence score in `0..1`.
  final double confidence;

  /// Source image width after orientation normalization.
  final int imageWidth;

  /// Source image height after orientation normalization.
  final int imageHeight;

  /// Top-left corner in source coordinates, when available.
  final ReceiptPoint? topLeft;

  /// Top-right corner in source coordinates, when available.
  final ReceiptPoint? topRight;

  /// Bottom-right corner in source coordinates, when available.
  final ReceiptPoint? bottomRight;

  /// Bottom-left corner in source coordinates, when available.
  final ReceiptPoint? bottomLeft;
}
