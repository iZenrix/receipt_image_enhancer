## OpenCV packaging notes

### Decision

v1 vendors official OpenCV **4.12.0** mobile artifacts:

- Android: static `core` + `imgproc` + `imgcodecs` (+ 3rdparty codec libs) for
  `arm64-v8a`, `armeabi-v7a`, `x86_64`
- iOS: `opencv2.framework` thinned to `arm64` + `x86_64`

Artifacts live in `third_party/opencv/` and are linked by `hook/build.dart`.
Consumer Flutter builds do **not** download OpenCV.

### Why not MethodChannel duplicates?

A single C++ pipeline avoids Android/iOS tuning drift. MethodChannel remains a
documented fallback only if packaging/linking becomes an unrecoverable blocker;
the public Dart API stays unchanged.

### Size / GitHub / pub.dev

The iOS `opencv2` binary is ~210MB (over GitHub’s 100MB file limit). Android
static libs are also large. Both GitHub and pub.dev **exclude**
`third_party/opencv/android` and `…/ios`.

Restore locally / in CI with:

```bash
bash tool/fetch_opencv.sh
```

Checksums: `third_party/opencv/CHECKSUMS.sha256`.

Internal design/benchmark notes under `doc/` (design spec, CSV, size report)
are excluded from the pub.dev archive.

### Host tests

macOS unit tests link against Homebrew `opencv@4` for developer convenience.
Mobile release binaries always use the pinned 4.12.0 vendored artifacts.
