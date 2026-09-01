#!/usr/bin/env bash
# Fetches pinned OpenCV 4.12.0 mobile artifacts into third_party/opencv.
# Maintainers/CI only — not part of app runtime. Not invoked by consumer builds.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TP="$ROOT/third_party/opencv"
VER=4.12.0
TMP="${TMPDIR:-/tmp}/opencv_rie_${VER}"
mkdir -p "$TMP" "$TP"

ANDROID_URL="https://github.com/opencv/opencv/releases/download/${VER}/opencv-${VER}-android-sdk.zip"
IOS_URL="https://github.com/opencv/opencv/releases/download/${VER}/opencv-${VER}-ios-framework.zip"

echo "Downloading OpenCV ${VER} Android SDK..."
curl -L --fail -o "$TMP/android.zip" "$ANDROID_URL"
echo "Downloading OpenCV ${VER} iOS framework..."
curl -L --fail -o "$TMP/ios.zip" "$IOS_URL"

rm -rf "$TMP/android_extract" "$TMP/ios_extract"
mkdir -p "$TMP/android_extract" "$TMP/ios_extract"
unzip -q -o "$TMP/android.zip" -d "$TMP/android_extract"
unzip -q -o "$TMP/ios.zip" -d "$TMP/ios_extract"

SDK="$TMP/android_extract/OpenCV-android-sdk/sdk/native"
rm -rf "$TP/android" "$TP/ios"
mkdir -p "$TP/android/include"
cp -R "$SDK/jni/include/opencv2" "$TP/android/include/"

for ABI in arm64-v8a armeabi-v7a x86_64; do
  mkdir -p "$TP/android/staticlibs/$ABI" "$TP/android/3rdparty/$ABI"
  cp "$SDK/staticlibs/$ABI/libopencv_"{core,imgproc,imgcodecs}.a "$TP/android/staticlibs/$ABI/"
  cp "$SDK/3rdparty/libs/$ABI/"*.a "$TP/android/3rdparty/$ABI/" || true
done

mkdir -p "$TP/ios"
cp -R "$TMP/ios_extract/opencv2.framework" "$TP/ios/"
BIN="$TP/ios/opencv2.framework/Versions/A/opencv2"
lipo "$BIN" -thin arm64 -output "$TMP/opencv_arm64.a"
lipo "$BIN" -thin x86_64 -output "$TMP/opencv_x86_64.a" || true
if [[ -f "$TMP/opencv_x86_64.a" ]]; then
  lipo -create "$TMP/opencv_arm64.a" "$TMP/opencv_x86_64.a" -output "$BIN"
else
  cp "$TMP/opencv_arm64.a" "$BIN"
fi

cat > "$TP/VERSION.txt" <<EOF
OpenCV ${VER}
Prepared by tool/fetch_opencv.sh
EOF
( cd "$TP" && find android/staticlibs android/3rdparty -type f -name '*.a' -exec shasum -a 256 {} \; ; shasum -a 256 ios/opencv2.framework/Versions/A/opencv2 ) > "$TP/CHECKSUMS.sha256"
echo "OpenCV artifacts ready under $TP"
du -sh "$TP" "$TP/android" "$TP/ios"
