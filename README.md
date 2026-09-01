# receipt_image_enhancer

On-device enhancement for receipt and nota photos. Makes images cleaner and
easier to read **without sending anything to a server**, and **without OCR or
generative AI**.

Processing uses a deterministic OpenCV pipeline (contrast, denoise, conservative
sharpening, optional document crop / perspective correction).

```dart
import 'package:receipt_image_enhancer/receipt_image_enhancer.dart';

final result = await const ReceiptImageEnhancer().enhanceFile(
  inputPath: image.path,
);

print(result.outputPath);
```

## Features

- Three presets: **balanced** (natural color), **readable** (grayscale), **scan** (black & white)
- Optional auto-crop and perspective correction
- Safe fallback: if the receipt cannot be detected, the full image is still enhanced
- JPEG and PNG input / output
- Runs entirely on-device, offline
- Heavy work is off the UI isolate
- Does not overwrite the original file

## Platforms

| | |
|---|---|
| Flutter | 3.38+ |
| Android | API 24+ (`arm64-v8a`, `armeabi-v7a`, `x86_64`) |
| iOS | 15+ |

Web and desktop are not supported in v0.1.0.

## Installation

```yaml
dependencies:
  receipt_image_enhancer: ^0.1.0
```

## Usage

### Balanced (default)

Natural-looking color enhancement — better lighting, slightly cleaner text.

```dart
final result = await const ReceiptImageEnhancer().enhanceFile(
  inputPath: file.path,
);
```

### Readable

Grayscale with stronger local contrast for faded thermal print.

```dart
final result = await const ReceiptImageEnhancer().enhanceFile(
  inputPath: file.path,
  options: const ReceiptEnhanceOptions(
    preset: ReceiptEnhancePreset.readable,
  ),
);
```

### Scan

Scanner-style black and white. Prefer PNG so text edges stay sharp.

```dart
final result = await const ReceiptImageEnhancer().enhanceFile(
  inputPath: file.path,
  options: const ReceiptEnhanceOptions(
    preset: ReceiptEnhancePreset.scan,
    outputFormat: ReceiptOutputFormat.png,
  ),
);
```

### Bytes API

Use when you do not have a stable file path:

```dart
final result = await const ReceiptImageEnhancer().enhanceBytes(bytes);
```

### Disable auto-crop

```dart
final result = await const ReceiptImageEnhancer().enhanceFile(
  inputPath: file.path,
  options: const ReceiptEnhanceOptions(autoCrop: false),
);
```

### Error handling

```dart
try {
  final result = await const ReceiptImageEnhancer().enhanceFile(
    inputPath: file.path,
  );
  // result.outputPath
} on ReceiptImageEnhancerException catch (e) {
  // e.code, e.message
}
```

## Output files

If you omit `outputPath`, a new file is written to the system temp directory:

```text
receipt_enhanced_<timestamp>_<random>.jpg
```

You are responsible for deleting it when finished. The input file is never
modified.

Re-encoding **strips original EXIF / metadata**. That is intentional for v0.1.0.

## Input formats

JPEG and PNG. WebP may work depending on the linked OpenCV build. Other
formats throw `ReceiptImageEnhancerException` (`unsupportedFormat`).

## Privacy

- Offline only — the package does not make network requests
- No analytics, no uploads
- Image bytes and full file paths are not logged

## Limitations

- This is **not** OCR. It does not extract merchant, date, total, or line items.
- Document detection is heuristic. Low confidence skips crop and continues on
  the full frame (with a warning).
- Enhancement is conservative so digits and characters are not invented.

## Example

See [`example/`](example/) for a small Flutter app: pick a photo, choose a
preset, enhance, then tap the image to view it full screen.

## OpenCV

Image processing uses **OpenCV 4.12.0** (Apache 2.0). See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## License

BSD-3-Clause. See [LICENSE](LICENSE).
