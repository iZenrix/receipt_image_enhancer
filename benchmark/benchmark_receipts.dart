import 'dart:io';
import 'dart:typed_data';

import 'package:receipt_image_enhancer/receipt_image_enhancer.dart';

Future<void> main(List<String> args) async {
  final fixturesDir = Directory(args.isNotEmpty ? args.first : 'test/fixtures');
  if (!fixturesDir.existsSync()) {
    stderr.writeln('Fixtures directory not found: ${fixturesDir.path}');
    exitCode = 1;
    return;
  }

  final enhancer = const ReceiptImageEnhancer();
  final presets = [
    ReceiptEnhancePreset.balanced,
    ReceiptEnhancePreset.readable,
    ReceiptEnhancePreset.scan,
  ];

  stdout.writeln(
    'fixture,preset,autoCrop,width,height,durationMs,cropApplied,detected,bytes',
  );

  for (final file in fixturesDir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.jpg') && !file.path.endsWith('.png')) {
      continue;
    }
    final input = Uint8List.fromList(await file.readAsBytes());
    for (final preset in presets) {
      for (final autoCrop in [true, false]) {
        final result = await enhancer.enhanceBytes(
          input,
          options: ReceiptEnhanceOptions(
            preset: preset,
            autoCrop: autoCrop,
            outputFormat: preset == ReceiptEnhancePreset.scan
                ? ReceiptOutputFormat.png
                : ReceiptOutputFormat.jpeg,
          ),
        );
        stdout.writeln(
          '${file.uri.pathSegments.last},${preset.name},$autoCrop,'
          '${result.width},${result.height},${result.processingDuration.inMilliseconds},'
          '${result.cropApplied},${result.documentDetected},${result.bytes.length}',
        );
      }
    }
  }
}
