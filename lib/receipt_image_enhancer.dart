/// On-device receipt/nota image enhancement using OpenCV through Dart FFI.
library;

export 'src/enums/enhance_preset.dart';
export 'src/enums/error_code.dart';
export 'src/enums/output_format.dart';
export 'src/enums/warning_code.dart';
export 'src/exceptions/receipt_image_enhancer_exception.dart';
export 'src/models/document_detection_result.dart';
export 'src/models/enhance_options.dart';
export 'src/models/enhance_result.dart';
export 'src/models/receipt_point.dart';

import 'dart:typed_data';

import 'src/models/document_detection_result.dart';
import 'src/models/enhance_options.dart';
import 'src/models/enhance_result.dart';
import 'src/receipt_image_enhancer_impl.dart';

/// Entry point for on-device receipt image enhancement.
final class ReceiptImageEnhancer {
  /// Creates an enhancer instance.
  const ReceiptImageEnhancer();

  /// Enhances a receipt image from [inputPath].
  ///
  /// When [outputPath] is omitted, a new file is created under the system
  /// temporary directory. The input file is never overwritten.
  Future<ReceiptEnhanceFileResult> enhanceFile({
    required String inputPath,
    String? outputPath,
    ReceiptEnhanceOptions options = const ReceiptEnhanceOptions(),
  }) {
    return const ReceiptImageEnhancerImpl().enhanceFile(
      inputPath: inputPath,
      outputPath: outputPath,
      options: options,
    );
  }

  /// Enhances a receipt image provided as encoded [input] bytes.
  Future<ReceiptEnhanceBytesResult> enhanceBytes(
    Uint8List input, {
    ReceiptEnhanceOptions options = const ReceiptEnhanceOptions(),
  }) {
    return const ReceiptImageEnhancerImpl().enhanceBytes(
      input,
      options: options,
    );
  }

  /// Detects document corners without writing an enhanced image.
  Future<DocumentDetectionResult> detectDocumentFile({
    required String inputPath,
  }) {
    return const ReceiptImageEnhancerImpl().detectDocumentFile(
      inputPath: inputPath,
    );
  }
}
