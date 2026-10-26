#!/usr/bin/env bash
# Builds a tiny trampoline APK that puts the stock AOSP Settings app on the
# TV home screen. No Gradle: aapt2 + javac + d8 + zipalign + apksigner only.
set -euo pipefail

SDK="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
BT="$(ls -d "$SDK"/build-tools/* | sort -V | tail -1)"
PLATFORM="$(ls -d "$SDK"/platforms/android-* | sort -V | tail -1)"
OUT=dist
rm -rf build "$OUT"
mkdir -p build/classes "$OUT"

echo "build-tools : $BT"
echo "platform    : $PLATFORM"

# 1. Compile and link resources + manifest.
"$BT/aapt2" compile --dir . -o build/res.zip
"$BT/aapt2" link \
  -I "$PLATFORM/android.jar" \
  --manifest AndroidManifest.xml \
  -o build/base.apk \
  --java build/gen \
  --min-sdk-version 21 \
  --target-sdk-version 34 \
  build/res.zip

# 2. Compile the Java source against the framework.
javac -source 17 -target 17 \
  -bootclasspath "$PLATFORM/android.jar" \
  -classpath "$PLATFORM/android.jar" \
  -d build/classes \
  MainActivity.java

# 3. Dex the classes.
"$BT/d8" --lib "$PLATFORM/android.jar" \
  --min-api 21 \
  --output build/dex \
  build/classes/com/local/nativesettings/*.class

# 4. Add the dex to the APK.
cd build
zip -q -u base.apk dex/classes.dex
cd ..

# 5. Align and sign with the debug key (fine for sideloading).
"$BT/zipalign" -f 4 build/base.apk "$OUT/native-settings-launcher.apk"

KEYSTORE="${HOME}/.android/debug.keystore"
if [ ! -f "$KEYSTORE" ]; then
  mkdir -p "$(dirname "$KEYSTORE")"
  keytool -genkeypair -keystore "$KEYSTORE" -storepass android -keypass android \
    -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" \
    -keyalg RSA -keysize 2048 -validity 10000 >/dev/null 2>&1
fi

"$BT/apksigner" sign \
  --ks "$KEYSTORE" \
  --ks-pass pass:android \
  --key-pass pass:android \
  --ks-key-alias androiddebugkey \
  --out "$OUT/native-settings-launcher-signed.apk" \
  "$OUT/native-settings-launcher.apk"

echo "built:"
ls -l "$OUT"
