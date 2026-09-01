#!/usr/bin/env bash
# Fetches pinned OpenCV 4.12.0 mobile artifacts into third_party/opencv.
# Maintainers/CI only — not part of app runtime. Not invoked by consumer builds.
#
# Usage: bash tool/fetch_opencv.sh [android|ios|all]
set -euo pipefail

TARGET="${1:-all}"
if [[ "$TARGET" != "android" && "$TARGET" != "ios" && "$TARGET" != "all" ]]; then
  echo "Usage: $0 [android|ios|all]" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TP="$ROOT/third_party/opencv"
VER=4.12.0
TMP="${TMPDIR:-/tmp}/opencv_rie_${VER}"
mkdir -p "$TMP" "$TP"

ANDROID_URL="https://github.com/opencv/opencv/releases/download/${VER}/opencv-${VER}-android-sdk.zip"
IOS_URL="https://github.com/opencv/opencv/releases/download/${VER}/opencv-${VER}-ios-framework.zip"

_sha256() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$@"
  else
    sha256sum "$@"
  fi
}

if [[ "$TARGET" == "android" || "$TARGET" == "all" ]]; then
  echo "Downloading OpenCV ${VER} Android SDK..."
  curl -L --fail -o "$TMP/android.zip" "$ANDROID_URL"
  rm -rf "$TMP/android_extract"
  mkdir -p "$TMP/android_extract"
  unzip -q -o "$TMP/android.zip" -d "$TMP/android_extract"

  SDK="$TMP/android_extract/OpenCV-android-sdk/sdk/native"
  rm -rf "$TP/android"
  mkdir -p "$TP/android/include"
  cp -R "$SDK/jni/include/opencv2" "$TP/android/include/"

  for ABI in arm64-v8a armeabi-v7a x86_64; do
    mkdir -p "$TP/android/staticlibs/$ABI" "$TP/android/3rdparty/$ABI"
    cp "$SDK/staticlibs/$ABI/libopencv_"{core,imgproc,imgcodecs}.a "$TP/android/staticlibs/$ABI/"
    cp "$SDK/3rdparty/libs/$ABI/"*.a "$TP/android/3rdparty/$ABI/" || true
  done
fi

if [[ "$TARGET" == "ios" || "$TARGET" == "all" ]]; then
  if ! command -v lipo >/dev/null 2>&1; then
    echo "Skipping iOS OpenCV: lipo is not available (macOS only)." >&2
    if [[ "$TARGET" == "ios" ]]; then
      exit 1
    fi
  else
    echo "Downloading OpenCV ${VER} iOS framework..."
    curl -L --fail -o "$TMP/ios.zip" "$IOS_URL"
    rm -rf "$TMP/ios_extract"
    mkdir -p "$TMP/ios_extract"
    unzip -q -o "$TMP/ios.zip" -d "$TMP/ios_extract"

    rm -rf "$TP/ios"
    mkdir -p "$TP/ios"
    cp -R "$TMP/ios_extract/opencv2.framework" "$TP/ios/"
    BIN="$TP/ios/opencv2.framework/Versions/A/opencv2"
    lipo "$BIN" -thin arm64 -output "$TMP/opencv_arm64.a"
    if lipo "$BIN" -thin x86_64 -output "$TMP/opencv_x86_64.a" 2>/dev/null; then
      lipo -create "$TMP/opencv_arm64.a" "$TMP/opencv_x86_64.a" -output "$BIN"
    else
      cp "$TMP/opencv_arm64.a" "$BIN"
    fi
  fi
fi

cat > "$TP/VERSION.txt" <<EOF
OpenCV ${VER}
Prepared by tool/fetch_opencv.sh (${TARGET})
EOF

(
  cd "$TP"
  if [[ -d android ]]; then
    while IFS= read -r -d '' file; do
      _sha256 "$file"
    done < <(find android/staticlibs android/3rdparty -type f -name '*.a' -print0 | sort -z)
  fi
  if [[ -f ios/opencv2.framework/Versions/A/opencv2 ]]; then
    _sha256 ios/opencv2.framework/Versions/A/opencv2
  fi
) > "$TP/CHECKSUMS.sha256"

echo "OpenCV artifacts ready under $TP"
du -sh "$TP" "$TP/android" "$TP/ios" 2>/dev/null || true
