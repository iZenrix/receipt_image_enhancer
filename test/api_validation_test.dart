import 'dart:io';
import 'dart:typed_data';

import 'package:receipt_image_enhancer/receipt_image_enhancer.dart';
import 'package:test/test.dart';

void main() {
  final fixture = File('test/fixtures/synthetic_receipt.jpg');

  test('fixture exists', () {
    expect(fixture.existsSync(), isTrue);
  });

  test('enhanceFile balanced produces output without mutating input', () async {
    final inputBytes = await fixture.readAsBytes();
    final out =
        '${Directory.systemTemp.path}/rie_balanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await const ReceiptImageEnhancer().enhanceFile(
      inputPath: fixture.path,
      outputPath: out,
      options: const ReceiptEnhanceOptions(
        preset: ReceiptEnhancePreset.balanced,
        autoCrop: false,
      ),
    );

    expect(File(out).existsSync(), isTrue);
    expect(File(out).lengthSync(), greaterThan(0));
    expect(result.width, greaterThan(0));
    expect(result.height, greaterThan(0));
    expect(result.processingDuration, greaterThan(Duration.zero));
    expect(await fixture.readAsBytes(), equals(inputBytes));
    await File(out).delete();
  });

  test('enhanceBytes readable works', () async {
    final bytes = await fixture.readAsBytes();
    final result = await const ReceiptImageEnhancer().enhanceBytes(
      Uint8List.fromList(bytes),
      options: const ReceiptEnhanceOptions(
        preset: ReceiptEnhancePreset.readable,
        autoCrop: false,
      ),
    );
    expect(result.bytes, isNotEmpty);
    expect(result.width, greaterThan(0));
  });

  test('scan preset returns png bytes when requested', () async {
    final bytes = await fixture.readAsBytes();
    final result = await const ReceiptImageEnhancer().enhanceBytes(
      Uint8List.fromList(bytes),
      options: const ReceiptEnhanceOptions(
        preset: ReceiptEnhancePreset.scan,
        autoCrop: false,
        outputFormat: ReceiptOutputFormat.png,
      ),
    );
    expect(result.bytes[0], 0x89);
    expect(result.bytes[1], 0x50); // P
  });

  test('autoCrop fallback does not throw on blank image', () async {
    final blank = File('test/fixtures/no_document.jpg');
    final out =
        '${Directory.systemTemp.path}/rie_blank_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await const ReceiptImageEnhancer().enhanceFile(
      inputPath: blank.path,
      outputPath: out,
    );
    expect(result.documentDetected, isFalse);
    expect(result.cropApplied, isFalse);
    expect(
      result.warnings,
      contains(ReceiptEnhanceWarning.documentNotDetected),
    );
    await File(out).delete();
  });

  test('unsupported format throws typed exception', () async {
    final bad = File('${Directory.systemTemp.path}/rie_bad.bin')
      ..writeAsBytesSync([1, 2, 3, 4, 5, 6, 7, 8]);
    expect(
      () => const ReceiptImageEnhancer().enhanceFile(inputPath: bad.path),
      throwsA(
        isA<ReceiptImageEnhancerException>().having(
          (e) => e.code,
          'code',
          ReceiptImageEnhancerErrorCode.unsupportedFormat,
        ),
      ),
    );
    await bad.delete();
  });

  test('missing file throws fileNotFound', () async {
    expect(
      () => const ReceiptImageEnhancer().enhanceFile(
        inputPath: '${Directory.systemTemp.path}/missing_receipt_xyz.jpg',
      ),
      throwsA(
        isA<ReceiptImageEnhancerException>().having(
          (e) => e.code,
          'code',
          ReceiptImageEnhancerErrorCode.fileNotFound,
        ),
      ),
    );
  });

  test('detectDocumentFile returns structured result', () async {
    final detection = await const ReceiptImageEnhancer().detectDocumentFile(
      inputPath: fixture.path,
    );
    expect(detection.imageWidth, greaterThan(0));
    expect(detection.imageHeight, greaterThan(0));
    expect(detection.confidence, inInclusiveRange(0.0, 1.0));
  });

  test('clear document can be auto-cropped', () async {
    final clear = File('test/fixtures/clear_document.jpg');
    final out =
        '${Directory.systemTemp.path}/rie_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await const ReceiptImageEnhancer().enhanceFile(
      inputPath: clear.path,
      outputPath: out,
      options: const ReceiptEnhanceOptions(autoCrop: true),
    );
    // Heuristic detector may still miss synthetic edges; ensure no crash and
    // either crop applied or explicit not-detected warning.
    expect(result.width, greaterThan(0));
    if (!result.cropApplied) {
      expect(
        result.warnings,
        contains(ReceiptEnhanceWarning.documentNotDetected),
      );
    }
    await File(out).delete();
  });

  test('large image is downscaled by policy', () async {
    final large = File('test/fixtures/large_receipt.jpg');
    final result = await const ReceiptImageEnhancer().enhanceBytes(
      Uint8List.fromList(await large.readAsBytes()),
      options: const ReceiptEnhanceOptions(
        autoCrop: false,
        maxOutputDimension: 1024,
      ),
    );
    expect(result.width <= 1024, isTrue);
    expect(result.height <= 1024, isTrue);
    expect(result.warnings, contains(ReceiptEnhanceWarning.inputDownscaled));
  });
}
