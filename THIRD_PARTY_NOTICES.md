# Third-party notices

## OpenCV

- Project: OpenCV
- Version: **4.12.0**
- License: Apache License 2.0
- Source: https://github.com/opencv/opencv/releases/tag/4.12.0
- Usage in this package:
  - Android: static libraries for `core`, `imgproc`, `imgcodecs` plus bundled
    third-party codec/static helpers from the official Android SDK
  - iOS: official `opencv2.framework` (thinned to `arm64` + `x86_64`)
  - Host tests: Homebrew `opencv@4` (API-compatible 4.14.x on developer machines)

OpenCV itself bundles additional third-party components (for example
libjpeg-turbo, libpng, libwebp, libtiff, openjpeg, TBB/oneTBB, and related
helpers) under their respective licenses as distributed by the OpenCV project.
Refer to the upstream OpenCV licensing documentation for the complete set:

- https://github.com/opencv/opencv/blob/4.12.0/LICENSE
- https://opencv.org/

This package does not modify OpenCV license terms. Attribution is included
here because OpenCV binaries/headers are redistributed under `third_party/opencv/`.
