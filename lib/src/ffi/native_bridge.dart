import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../enums/enhance_preset.dart';
import '../enums/error_code.dart';
import '../enums/output_format.dart';
import '../enums/warning_code.dart';
import '../exceptions/receipt_image_enhancer_exception.dart';
import '../models/document_detection_result.dart';
import '../models/enhance_options.dart';
import '../models/enhance_result.dart';
import '../models/receipt_point.dart';
import 'bindings.dart' as b;
import 'native_loader.dart';

/// Expected native ABI version mirrored from `RIE_ABI_VERSION`.
const int expectedNativeAbiVersion = 1;

/// Thin typed wrapper over the generated C ABI.
final class NativeBridge {
  NativeBridge._();

  static b.ReceiptImageEnhancerBindings get _b => NativeLoader.bindings;

  /// Verifies the loaded native library ABI.
  static void ensureAbi() {
    late final int version;
    try {
      version = _b.rie_abi_version();
    } on ReceiptImageEnhancerException {
      rethrow;
    } on ArgumentError catch (error) {
      throw ReceiptImageEnhancerException(
        code: ReceiptImageEnhancerErrorCode.nativeLibraryUnavailable,
        message: 'Native library unavailable: $error',
        cause: error,
      );
    } catch (error) {
      throw ReceiptImageEnhancerException(
        code: ReceiptImageEnhancerErrorCode.nativeLibraryUnavailable,
        message: 'Native library unavailable: $error',
        cause: error,
      );
    }
    if (version != expectedNativeAbiVersion) {
      throw ReceiptImageEnhancerException(
        code: ReceiptImageEnhancerErrorCode.nativeLibraryUnavailable,
        message:
            'Native ABI mismatch: expected $expectedNativeAbiVersion, got $version',
      );
    }
  }

  /// Synchronously enhances a file via the native pipeline.
  static ReceiptEnhanceFileResult enhanceFile({
    required String inputPath,
    required String outputPath,
    required ReceiptEnhanceOptions options,
  }) {
    ensureAbi();
    options.validate();

    final optionsPtr = _allocOptions(options);
    final resultPtr = calloc<b.rie_result_v1>();
    final errorPtr = calloc<Pointer<Char>>();
    final inputPathPtr = inputPath.toNativeUtf8();
    final outputPathPtr = outputPath.toNativeUtf8();
    try {
      final status = _b.rie_enhance_file(
        inputPathPtr.cast(),
        outputPathPtr.cast(),
        optionsPtr,
        resultPtr,
        errorPtr,
      );
      _throwIfNeeded(status, errorPtr);
      return _mapFileResult(outputPath, resultPtr.ref);
    } finally {
      _freeError(errorPtr);
      calloc.free(inputPathPtr);
      calloc.free(outputPathPtr);
      calloc.free(resultPtr);
      calloc.free(optionsPtr);
    }
  }

  /// Synchronously enhances an in-memory image via the native pipeline.
  static ReceiptEnhanceBytesResult enhanceBytes({
    required Uint8List input,
    required ReceiptEnhanceOptions options,
  }) {
    ensureAbi();
    options.validate();

    final optionsPtr = _allocOptions(options);
    final resultPtr = calloc<b.rie_result_v1>();
    final errorPtr = calloc<Pointer<Char>>();
    final outputDataPtr = calloc<Pointer<Uint8>>();
    final outputLengthPtr = calloc<Size>();
    final inputPtr = calloc<Uint8>(input.length);
    try {
      inputPtr.asTypedList(input.length).setAll(0, input);
      final status = _b.rie_enhance_bytes(
        inputPtr,
        input.length,
        optionsPtr,
        outputDataPtr,
        outputLengthPtr,
        resultPtr,
        errorPtr,
      );
      _throwIfNeeded(status, errorPtr);

      final outLen = outputLengthPtr.value;
      final outPtr = outputDataPtr.value;
      if (outPtr == nullptr || outLen == 0) {
        throw const ReceiptImageEnhancerException(
          code: ReceiptImageEnhancerErrorCode.encodeFailed,
          message: 'Native returned empty output buffer',
        );
      }
      final bytes = Uint8List.fromList(outPtr.asTypedList(outLen));
      _b.rie_free_buffer(outPtr.cast());
      return _mapBytesResult(bytes, resultPtr.ref);
    } finally {
      _freeError(errorPtr);
      calloc.free(inputPtr);
      calloc.free(outputDataPtr);
      calloc.free(outputLengthPtr);
      calloc.free(resultPtr);
      calloc.free(optionsPtr);
    }
  }

  /// Synchronously detects document corners in a file.
  static DocumentDetectionResult detectDocumentFile({
    required String inputPath,
  }) {
    ensureAbi();
    final resultPtr = calloc<b.rie_detection_result_v1>();
    final errorPtr = calloc<Pointer<Char>>();
    final pathPtr = inputPath.toNativeUtf8();
    try {
      final status = _b.rie_detect_document_file(
        pathPtr.cast(),
        resultPtr,
        errorPtr,
      );
      _throwIfNeeded(status, errorPtr);
      final native = resultPtr.ref;
      final hasCorners = native.confidence > 0;
      return DocumentDetectionResult(
        detected: native.detected != 0,
        confidence: native.confidence,
        imageWidth: native.image_width,
        imageHeight: native.image_height,
        topLeft: hasCorners
            ? ReceiptPoint(native.top_left.x, native.top_left.y)
            : null,
        topRight: hasCorners
            ? ReceiptPoint(native.top_right.x, native.top_right.y)
            : null,
        bottomRight: hasCorners
            ? ReceiptPoint(native.bottom_right.x, native.bottom_right.y)
            : null,
        bottomLeft: hasCorners
            ? ReceiptPoint(native.bottom_left.x, native.bottom_left.y)
            : null,
      );
    } finally {
      calloc.free(pathPtr);
      _freeError(errorPtr);
      calloc.free(resultPtr);
    }
  }
}

Pointer<b.rie_options_v1> _allocOptions(ReceiptEnhanceOptions options) {
  final ptr = calloc<b.rie_options_v1>();
  ptr.ref
    ..struct_size = sizeOf<b.rie_options_v1>()
    ..abi_version = expectedNativeAbiVersion
    ..preset = switch (options.preset) {
      ReceiptEnhancePreset.balanced => b.rie_preset.RIE_PRESET_BALANCED.value,
      ReceiptEnhancePreset.readable => b.rie_preset.RIE_PRESET_READABLE.value,
      ReceiptEnhancePreset.scan => b.rie_preset.RIE_PRESET_SCAN.value,
    }
    ..auto_crop = options.autoCrop ? 1 : 0
    ..correct_perspective = options.correctPerspective ? 1 : 0
    ..max_output_dimension = options.maxOutputDimension
    ..output_format = switch (options.outputFormat) {
      ReceiptOutputFormat.jpeg => b.rie_output_format.RIE_OUTPUT_JPEG.value,
      ReceiptOutputFormat.png => b.rie_output_format.RIE_OUTPUT_PNG.value,
    }
    ..jpeg_quality = options.jpegQuality;
  return ptr;
}

void _throwIfNeeded(int status, Pointer<Pointer<Char>> errorPtr) {
  if (status == b.rie_status.RIE_OK.value) {
    return;
  }
  final messagePtr = errorPtr.value;
  final message = messagePtr == nullptr
      ? 'native status $status'
      : messagePtr.cast<Utf8>().toDartString();
  if (messagePtr != nullptr) {
    NativeLoader.bindings.rie_free_buffer(messagePtr.cast());
    errorPtr.value = nullptr;
  }
  throw ReceiptImageEnhancerException(
    code: _mapStatus(status),
    message: message,
  );
}

void _freeError(Pointer<Pointer<Char>> errorPtr) {
  final messagePtr = errorPtr.value;
  if (messagePtr != nullptr) {
    NativeLoader.bindings.rie_free_buffer(messagePtr.cast());
    errorPtr.value = nullptr;
  }
  calloc.free(errorPtr);
}

ReceiptImageEnhancerErrorCode _mapStatus(int status) {
  return switch (status) {
    _ when status == b.rie_status.RIE_INVALID_ARGUMENT.value =>
      ReceiptImageEnhancerErrorCode.invalidArgument,
    _ when status == b.rie_status.RIE_FILE_NOT_FOUND.value =>
      ReceiptImageEnhancerErrorCode.fileNotFound,
    _ when status == b.rie_status.RIE_UNSUPPORTED_FORMAT.value =>
      ReceiptImageEnhancerErrorCode.unsupportedFormat,
    _ when status == b.rie_status.RIE_DECODE_FAILED.value =>
      ReceiptImageEnhancerErrorCode.decodeFailed,
    _ when status == b.rie_status.RIE_ENCODE_FAILED.value =>
      ReceiptImageEnhancerErrorCode.encodeFailed,
    _ when status == b.rie_status.RIE_OUT_OF_MEMORY.value =>
      ReceiptImageEnhancerErrorCode.outOfMemory,
    _ when status == b.rie_status.RIE_NATIVE_LIBRARY_UNAVAILABLE.value =>
      ReceiptImageEnhancerErrorCode.nativeLibraryUnavailable,
    _ => ReceiptImageEnhancerErrorCode.processingFailed,
  };
}

List<ReceiptEnhanceWarning> _mapWarnings(int flags) {
  final warnings = <ReceiptEnhanceWarning>[];
  if ((flags & b.rie_warning_flags.RIE_WARN_DOCUMENT_NOT_DETECTED.value) != 0) {
    warnings.add(ReceiptEnhanceWarning.documentNotDetected);
  }
  if ((flags & b.rie_warning_flags.RIE_WARN_LOW_DOCUMENT_CONFIDENCE.value) !=
      0) {
    warnings.add(ReceiptEnhanceWarning.lowDocumentConfidence);
  }
  if ((flags & b.rie_warning_flags.RIE_WARN_INPUT_DOWNSCALED.value) != 0) {
    warnings.add(ReceiptEnhanceWarning.inputDownscaled);
  }
  return List.unmodifiable(warnings);
}

ReceiptEnhanceFileResult _mapFileResult(
  String outputPath,
  b.rie_result_v1 native,
) {
  return ReceiptEnhanceFileResult(
    outputPath: outputPath,
    width: native.width,
    height: native.height,
    documentDetected: native.document_detected != 0,
    cropApplied: native.crop_applied != 0,
    detectionConfidence: native.detection_confidence,
    processingDuration: Duration(microseconds: native.processing_time_us),
    warnings: _mapWarnings(native.warning_flags),
  );
}

ReceiptEnhanceBytesResult _mapBytesResult(
  Uint8List bytes,
  b.rie_result_v1 native,
) {
  return ReceiptEnhanceBytesResult(
    bytes: bytes,
    width: native.width,
    height: native.height,
    documentDetected: native.document_detected != 0,
    cropApplied: native.crop_applied != 0,
    detectionConfidence: native.detection_confidence,
    processingDuration: Duration(microseconds: native.processing_time_us),
    warnings: _mapWarnings(native.warning_flags),
  );
}
