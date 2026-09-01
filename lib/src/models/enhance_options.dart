import '../enums/enhance_preset.dart';
import '../enums/output_format.dart';
import '../enums/error_code.dart';
import '../exceptions/receipt_image_enhancer_exception.dart';

/// Options controlling receipt enhancement behavior.
final class ReceiptEnhanceOptions {
  /// Creates enhancement options.
  ///
  /// Throws [ReceiptImageEnhancerException] when values are out of range.
  const ReceiptEnhanceOptions({
    this.preset = ReceiptEnhancePreset.balanced,
    this.autoCrop = true,
    this.correctPerspective = true,
    this.maxOutputDimension = 4096,
    this.outputFormat = ReceiptOutputFormat.jpeg,
    this.jpegQuality = 92,
  });

  /// Enhancement preset.
  final ReceiptEnhancePreset preset;

  /// When true, attempt document detection and crop.
  final bool autoCrop;

  /// When true and [autoCrop] succeeds, apply perspective warp.
  ///
  /// When false with a successful detection, a simple axis-aligned bounding
  /// crop is applied instead of perspective correction.
  final bool correctPerspective;

  /// Long-edge limit for output images (1024–6000).
  final int maxOutputDimension;

  /// Encoded output format.
  final ReceiptOutputFormat outputFormat;

  /// JPEG quality 1–100. Ignored for PNG.
  final int jpegQuality;

  /// Validates runtime values and throws a typed exception on failure.
  void validate() {
    if (maxOutputDimension < 1024 || maxOutputDimension > 6000) {
      throw const ReceiptImageEnhancerException(
        code: ReceiptImageEnhancerErrorCode.invalidArgument,
        message: 'maxOutputDimension must be between 1024 and 6000',
      );
    }
    if (jpegQuality < 1 || jpegQuality > 100) {
      throw const ReceiptImageEnhancerException(
        code: ReceiptImageEnhancerErrorCode.invalidArgument,
        message: 'jpegQuality must be between 1 and 100',
      );
    }
  }
}
