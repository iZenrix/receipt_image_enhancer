import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:receipt_image_enhancer/receipt_image_enhancer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native enhance works for bundled fixture bytes', (tester) async {
    final data = await rootBundle.load('assets/synthetic_receipt.jpg');
    final bytes = data.buffer.asUint8List();
    final before = List<int>.from(bytes);

    final result = await const ReceiptImageEnhancer().enhanceBytes(
      bytes,
      options: const ReceiptEnhanceOptions(
        preset: ReceiptEnhancePreset.balanced,
        autoCrop: true,
      ),
    );

    expect(result.bytes, isNotEmpty);
    expect(result.width, greaterThan(0));
    expect(result.height, greaterThan(0));
    expect(bytes, equals(before));

    final out = File(
      '${Directory.systemTemp.path}/rie_it_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final fileResult = await const ReceiptImageEnhancer().enhanceFile(
      inputPath: await _writeTemp(bytes),
      outputPath: out.path,
    );
    expect(out.existsSync(), isTrue);
    expect(fileResult.outputPath, out.path);
  });
}

Future<String> _writeTemp(List<int> bytes) async {
  final file = File(
    '${Directory.systemTemp.path}/rie_in_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
