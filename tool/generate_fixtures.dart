import 'dart:io';

import 'package:image/image.dart';

void main() {
  Directory('test/fixtures').createSync(recursive: true);

  Image makeReceipt(int w, int h, {bool strongBorder = true}) {
    final img = Image(width: w, height: h);
    fill(img, color: ColorRgb8(25, 25, 25));
    final left = (w * 0.18).round();
    final right = (w * 0.82).round();
    final top = (h * 0.10).round();
    final bottom = (h * 0.90).round();
    fillRect(
      img,
      x1: left,
      y1: top,
      x2: right,
      y2: bottom,
      color: ColorRgb8(245, 245, 240),
    );
    if (strongBorder) {
      drawRect(
        img,
        x1: left,
        y1: top,
        x2: right,
        y2: bottom,
        color: ColorRgb8(0, 0, 0),
        thickness: 4,
      );
    }
    for (var y = top + 40; y < bottom - 40; y += 26) {
      for (var x = left + 24; x < right - 24; x++) {
        if ((y % 26) < 3) {
          img.setPixelRgb(x, y, 50, 50, 50);
        }
      }
    }
    // Total bar
    fillRect(
      img,
      x1: left + 40,
      y1: bottom - 70,
      x2: left + (w * 0.4).round(),
      y2: bottom - 40,
      color: ColorRgb8(20, 20, 20),
    );
    return img;
  }

  final receipt = makeReceipt(600, 800);
  File('test/fixtures/synthetic_receipt.png')
      .writeAsBytesSync(encodePng(receipt));
  File('test/fixtures/synthetic_receipt.jpg')
      .writeAsBytesSync(encodeJpg(receipt, quality: 95));

  final faded = adjustColor(receipt, contrast: 0.75, brightness: 1.1);
  File('test/fixtures/faded_thermal.jpg')
      .writeAsBytesSync(encodeJpg(faded, quality: 90));

  final blank = Image(width: 400, height: 400);
  fill(blank, color: ColorRgb8(180, 180, 180));
  File('test/fixtures/no_document.jpg')
      .writeAsBytesSync(encodeJpg(blank, quality: 90));

  final tiny = copyResize(receipt, width: 64, height: 48);
  File('test/fixtures/tiny.jpg').writeAsBytesSync(encodeJpg(tiny, quality: 90));

  final large = copyResize(receipt, width: 3000, height: 4000);
  File('test/fixtures/large_receipt.jpg')
      .writeAsBytesSync(encodeJpg(large, quality: 75));

  final skewed = copyResize(receipt, width: 600, height: 800);
  // Keep a clear document for perspective fixtures.
  File('test/fixtures/clear_document.jpg')
      .writeAsBytesSync(encodeJpg(skewed, quality: 95));

  // ignore: avoid_print
  print('fixtures ready');
}
