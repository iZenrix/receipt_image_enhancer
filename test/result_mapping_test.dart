import 'package:receipt_image_enhancer/src/enums/enhance_preset.dart';
import 'package:receipt_image_enhancer/src/enums/output_format.dart';
import 'package:receipt_image_enhancer/src/enums/warning_code.dart';
import 'package:receipt_image_enhancer/src/ffi/bindings.dart' as b;
import 'package:receipt_image_enhancer/src/ffi/native_bridge.dart';
import 'package:receipt_image_enhancer/src/ffi/native_loader.dart';
import 'package:test/test.dart';

void main() {
  test('ABI version constant matches native header', () {
    expect(expectedNativeAbiVersion, b.RIE_ABI_VERSION);
    expect(NativeLoader.bindings.rie_abi_version(), expectedNativeAbiVersion);
  });

  test('preset enum mapping is stable', () {
    expect(ReceiptEnhancePreset.balanced.index, 0);
    expect(ReceiptEnhancePreset.readable.index, 1);
    expect(ReceiptEnhancePreset.scan.index, 2);
    expect(b.rie_preset.RIE_PRESET_BALANCED.value, 0);
    expect(b.rie_preset.RIE_PRESET_READABLE.value, 1);
    expect(b.rie_preset.RIE_PRESET_SCAN.value, 2);
  });

  test('output format mapping is stable', () {
    expect(ReceiptOutputFormat.jpeg.index, 0);
    expect(ReceiptOutputFormat.png.index, 1);
  });

  test('warning bitflags are distinct powers of two', () {
    expect(b.rie_warning_flags.RIE_WARN_DOCUMENT_NOT_DETECTED.value, 1);
    expect(b.rie_warning_flags.RIE_WARN_LOW_DOCUMENT_CONFIDENCE.value, 2);
    expect(b.rie_warning_flags.RIE_WARN_INPUT_DOWNSCALED.value, 4);
    expect(ReceiptEnhanceWarning.values.length, 3);
  });
}
