import 'package:receipt_image_enhancer/receipt_image_enhancer.dart';
import 'package:test/test.dart';

void main() {
  group('ReceiptEnhanceOptions', () {
    test('defaults are conservative', () {
      const options = ReceiptEnhanceOptions();
      expect(options.preset, ReceiptEnhancePreset.balanced);
      expect(options.autoCrop, isTrue);
      expect(options.correctPerspective, isTrue);
      expect(options.maxOutputDimension, 4096);
      expect(options.outputFormat, ReceiptOutputFormat.jpeg);
      expect(options.jpegQuality, 92);
    });

    test('validate rejects out-of-range maxOutputDimension', () {
      const options = ReceiptEnhanceOptions(maxOutputDimension: 100);
      expect(
        options.validate,
        throwsA(
          isA<ReceiptImageEnhancerException>().having(
            (e) => e.code,
            'code',
            ReceiptImageEnhancerErrorCode.invalidArgument,
          ),
        ),
      );
    });

    test('validate rejects out-of-range jpegQuality', () {
      const options = ReceiptEnhanceOptions(jpegQuality: 0);
      expect(options.validate, throwsA(isA<ReceiptImageEnhancerException>()));
    });

    test('validate accepts boundary values', () {
      const low = ReceiptEnhanceOptions(
        maxOutputDimension: 1024,
        jpegQuality: 1,
      );
      const high = ReceiptEnhanceOptions(
        maxOutputDimension: 6000,
        jpegQuality: 100,
      );
      expect(low.validate, returnsNormally);
      expect(high.validate, returnsNormally);
    });
  });
}
