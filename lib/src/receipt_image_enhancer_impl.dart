import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'ffi/native_bridge.dart';
import 'models/document_detection_result.dart';
import 'models/enhance_options.dart';
import 'models/enhance_result.dart';
import 'enums/output_format.dart';

/// Public facade used by [ReceiptImageEnhancer].
final class ReceiptImageEnhancerImpl {
  /// Creates the implementation.
  const ReceiptImageEnhancerImpl();

  /// Enhances an image file and writes a new output file.
  Future<ReceiptEnhanceFileResult> enhanceFile({
    required String inputPath,
    String? outputPath,
    ReceiptEnhanceOptions options = const ReceiptEnhanceOptions(),
  }) async {
    final resolvedOutput = outputPath ?? _defaultOutputPath(options);
    return Isolate.run(
      () => NativeBridge.enhanceFile(
        inputPath: inputPath,
        outputPath: resolvedOutput,
        options: options,
      ),
    );
  }

  /// Enhances an in-memory image and returns encoded bytes.
  Future<ReceiptEnhanceBytesResult> enhanceBytes(
    Uint8List input, {
    ReceiptEnhanceOptions options = const ReceiptEnhanceOptions(),
  }) {
    return Isolate.run(
      () => NativeBridge.enhanceBytes(input: input, options: options),
    );
  }

  /// Detects document corners for an image file.
  Future<DocumentDetectionResult> detectDocumentFile({
    required String inputPath,
  }) {
    return Isolate.run(
      () => NativeBridge.detectDocumentFile(inputPath: inputPath),
    );
  }

  String _defaultOutputPath(ReceiptEnhanceOptions options) {
    final ext = options.outputFormat == ReceiptOutputFormat.png ? 'png' : 'jpg';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1 << 32).toRadixString(16);
    return '${Directory.systemTemp.path}/receipt_enhanced_${stamp}_$random.$ext';
  }
}
