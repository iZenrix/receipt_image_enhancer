import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// OpenCV 4.12.0 is vendored under third_party/opencv for Android/iOS.
/// Host (macOS/Linux) builds use a system OpenCV install (Homebrew opencv@4).
void main(List<String> args) async {
  await build(args, (input, output) async {
    final logger = Logger('')
      ..level = Level.INFO
      ..onRecord.listen((record) {
        // ignore: avoid_print
        print(record.message);
      });

    final packageRoot = Directory.fromUri(input.packageRoot);
    final os = input.config.code.targetOS;
    final sources = <String>[
      'src/receipt_image_enhancer.cpp',
      'src/internal/geometry.cpp',
      'src/internal/validation.cpp',
      'src/internal/image_io.cpp',
      'src/pipeline/document_detector.cpp',
      'src/pipeline/perspective_corrector.cpp',
      'src/pipeline/enhancer.cpp',
      'src/pipeline/pipeline.cpp',
    ];

    final includes = <String>['src', 'src/internal', 'src/pipeline'];
    final flags = <String>['-fvisibility=hidden'];
    final frameworks = <String>[];
    final libraries = <String>[];
    String? cppLinkStdLib;

    if (os == OS.android) {
      final arch = input.config.code.targetArchitecture;
      final abi = _androidAbi(arch);
      final androidRoot = packageRoot.uri
          .resolve('third_party/opencv/android/')
          .toFilePath();
      includes.add('third_party/opencv/android/include');
      final staticDir = '$androidRoot/staticlibs/$abi';
      final thirdPartyDir = '$androidRoot/3rdparty/$abi';
      flags.addAll([
        '-I$androidRoot/include',
        '-L$staticDir',
        '-L$thirdPartyDir',
        '-Wl,--start-group',
        '-lopencv_imgcodecs',
        '-lopencv_imgproc',
        '-lopencv_core',
        ..._androidThirdPartyLinkFlags(thirdPartyDir),
        '-Wl,--end-group',
        '-lz',
        '-ldl',
        '-lm',
        '-llog',
      ]);
      cppLinkStdLib = 'c++_static';
    } else if (os == OS.iOS) {
      final iosRoot = packageRoot.uri
          .resolve('third_party/opencv/ios/')
          .toFilePath();
      flags.addAll([
        '-F$iosRoot',
        '-framework',
        'opencv2',
        '-framework',
        'Accelerate',
        '-framework',
        'CoreGraphics',
        '-framework',
        'QuartzCore',
        '-framework',
        'UIKit',
        '-framework',
        'Foundation',
        '-Wl,-dead_strip',
      ]);
      frameworks.addAll([
        'Foundation',
        'Accelerate',
        'CoreGraphics',
        'QuartzCore',
        'UIKit',
      ]);
    } else if (os == OS.macOS) {
      final brewPrefix = _brewOpenCvPrefix();
      includes.add('$brewPrefix/include/opencv4');
      flags.addAll([
        '-I$brewPrefix/include/opencv4',
        '-L$brewPrefix/lib',
        '-lopencv_imgcodecs',
        '-lopencv_imgproc',
        '-lopencv_core',
        '-Wl,-rpath,$brewPrefix/lib',
      ]);
      frameworks.add('Foundation');
    } else if (os == OS.linux) {
      flags.addAll(
        _pkgConfigFlags(['opencv4', 'opencv']).isNotEmpty
            ? _pkgConfigFlags(['opencv4', 'opencv'])
            : [
                '-I/usr/include/opencv4',
                '-lopencv_imgcodecs',
                '-lopencv_imgproc',
                '-lopencv_core',
              ],
      );
    } else {
      throw UnsupportedError(
        'receipt_image_enhancer does not support target OS: $os',
      );
    }

    final builder = CBuilder.library(
      name: 'receipt_image_enhancer',
      assetName: 'src/ffi/bindings.dart',
      sources: sources,
      includes: includes,
      flags: flags,
      frameworks: frameworks,
      libraries: libraries,
      language: Language.cpp,
      std: 'c++17',
      cppLinkStdLib: cppLinkStdLib,
    );

    await builder.run(input: input, output: output, logger: logger);
  });
}

String _androidAbi(Architecture arch) {
  return switch (arch) {
    Architecture.arm64 => 'arm64-v8a',
    Architecture.arm => 'armeabi-v7a',
    Architecture.x64 => 'x86_64',
    _ => throw UnsupportedError('Unsupported Android ABI: $arch'),
  };
}

List<String> _androidThirdPartyLinkFlags(String thirdPartyDir) {
  // Prefer codec/runtime helpers commonly required by imgcodecs/core.
  final preferredFiles = <String>[
    'libIlmImf.a',
    'liblibjpeg-turbo.a',
    'liblibpng.a',
    'liblibwebp.a',
    'liblibtiff.a',
    'liblibopenjp2.a',
    'libtbb.a',
    'libkleidicv_thread.a',
    'libkleidicv.a',
    'libkleidicv_hal.a',
    'libtegra_hal.a',
    'libittnotify.a',
    'libcpufeatures.a',
    'libade.a',
  ];
  final flags = <String>[];
  for (final fileName in preferredFiles) {
    final file = File('$thirdPartyDir/$fileName');
    if (!file.existsSync()) {
      continue;
    }
    // libfoo.a -> -lfoo
    final linkName = fileName.substring(3, fileName.length - 2);
    flags.add('-l$linkName');
  }
  return flags;
}

String _brewOpenCvPrefix() {
  for (final candidate in const [
    '/opt/homebrew/opt/opencv@4',
    '/opt/homebrew/opt/opencv',
    '/usr/local/opt/opencv@4',
    '/usr/local/opt/opencv',
  ]) {
    if (Directory(candidate).existsSync()) {
      return candidate;
    }
  }
  final result = Process.runSync('brew', ['--prefix', 'opencv@4']);
  if (result.exitCode == 0) {
    return (result.stdout as String).trim();
  }
  throw StateError(
    'OpenCV not found for macOS host builds. Install with: brew install opencv@4',
  );
}

List<String> _pkgConfigFlags(List<String> packages) {
  for (final package in packages) {
    final result = Process.runSync('pkg-config', [
      '--cflags',
      '--libs',
      package,
    ]);
    if (result.exitCode == 0) {
      return (result.stdout as String)
          .trim()
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }
  return const [];
}
