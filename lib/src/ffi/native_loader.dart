import 'dart:ffi';
import 'dart:io';

import '../enums/error_code.dart';
import '../exceptions/receipt_image_enhancer_exception.dart';
import 'bindings.dart';

/// Loads the shared native library produced by `hook/build.dart`.
///
/// Uses [DynamicLibrary.open] (not `@Native`) so lookups work inside helper
/// isolates created by [Isolate.run] in Flutter apps.
final class NativeLoader {
  NativeLoader._();

  static DynamicLibrary? _library;
  static ReceiptImageEnhancerBindings? _bindings;

  /// Shared bindings instance for the current process/isolate.
  static ReceiptImageEnhancerBindings get bindings {
    final existing = _bindings;
    if (existing != null) {
      return existing;
    }
    final loaded = ReceiptImageEnhancerBindings(_openLibrary());
    _bindings = loaded;
    return loaded;
  }

  static DynamicLibrary _openLibrary() {
    final cached = _library;
    if (cached != null) {
      return cached;
    }

    final errors = <String>[];
    for (final candidate in _candidateNames()) {
      try {
        final lib = DynamicLibrary.open(candidate);
        _library = lib;
        return lib;
      } catch (error) {
        errors.add('$candidate → $error');
      }
    }

    throw ReceiptImageEnhancerException(
      code: ReceiptImageEnhancerErrorCode.nativeLibraryUnavailable,
      message:
          'Failed to load receipt_image_enhancer native library. '
          'Tried: ${errors.join(' | ')}',
    );
  }

  static List<String> _candidateNames() {
    if (Platform.isAndroid) {
      return const ['libreceipt_image_enhancer.so'];
    }
    if (Platform.isIOS) {
      return const [
        'receipt_image_enhancer.framework/receipt_image_enhancer',
        'libreceipt_image_enhancer.dylib',
      ];
    }
    if (Platform.isMacOS) {
      return [
        'libreceipt_image_enhancer.dylib',
        'receipt_image_enhancer.dylib',
        // Host/unit-test output used by Dart hooks runner.
        '${Directory.current.path}/.dart_tool/lib/libreceipt_image_enhancer.dylib',
        '${Directory.current.path}/../.dart_tool/lib/libreceipt_image_enhancer.dylib',
      ];
    }
    if (Platform.isLinux) {
      return [
        'libreceipt_image_enhancer.so',
        '${Directory.current.path}/.dart_tool/lib/libreceipt_image_enhancer.so',
      ];
    }
    if (Platform.isWindows) {
      return const ['receipt_image_enhancer.dll'];
    }
    return const ['libreceipt_image_enhancer.so'];
  }
}
