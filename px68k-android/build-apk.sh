#!/bin/bash
# Builds px68k.apk without Gradle / Android Studio.
#
#   NDK         Android NDK r27 or later (r28+ recommended: 16KB pages by default)
#   BUILD_TOOLS Android SDK build-tools directory (aapt2, d8, zipalign, apksigner)
#   ANDROID_JAR android.jar of API level 35 or later
#   SDL2_DIR    SDL2 2.30+ source tree (https://github.com/libsdl-org/SDL, SDL2 branch)
#   KEYSTORE    (optional) your keystore; a debug key is generated if missing
set -euo pipefail
cd "$(dirname "$0")"

: "${NDK:?set NDK}" "${BUILD_TOOLS:?set BUILD_TOOLS}" "${ANDROID_JAR:?set ANDROID_JAR}" "${SDL2_DIR:?set SDL2_DIR}"
KEYSTORE="${KEYSTORE:-$PWD/debug.keystore}"
KS_PASS="${KS_PASS:-android}"
KS_ALIAS="${KS_ALIAS:-androiddebugkey}"
OUT="$PWD/build"
APK="$PWD/px68k.apk"

# --- SDL2 (native source + Java glue of the same version)
[ -e jni/SDL ] || ln -s "$SDL2_DIR" jni/SDL
mkdir -p src/org/libsdl/app
cp "$SDL2_DIR"/android-project/app/src/main/java/org/libsdl/app/*.java src/org/libsdl/app/

# --- native libraries
"$NDK/ndk-build" -j"$(nproc)"

rm -rf "$OUT"; mkdir -p "$OUT/res" "$OUT/gen" "$OUT/classes" "$OUT/dex" "$OUT/apk"

# --- resources
"$BUILD_TOOLS/aapt2" compile --dir res -o "$OUT/res/res.zip"
"$BUILD_TOOLS/aapt2" link -o "$OUT/base.apk" -I "$ANDROID_JAR" \
	--manifest AndroidManifest.xml --java "$OUT/gen" "$OUT/res/res.zip"

# --- Java -> dex
javac -nowarn -Xlint:-options -source 8 -target 8 -encoding UTF-8 \
	-bootclasspath "$ANDROID_JAR" -classpath "$BUILD_TOOLS/core-lambda-stubs.jar" -d "$OUT/classes" \
	$(find src "$OUT/gen" -name '*.java')
"$BUILD_TOOLS/d8" --release --min-api 23 --lib "$ANDROID_JAR" --output "$OUT/dex" \
	$(find "$OUT/classes" -name '*.class')

# --- package (native libs are stored uncompressed and 16KB aligned)
cp "$OUT/base.apk" "$OUT/unaligned.apk"
( cd "$OUT/dex" && zip -q "$OUT/unaligned.apk" classes.dex )
mkdir -p "$OUT/apk/lib"
cp -r libs/* "$OUT/apk/lib/"
( cd "$OUT/apk" && zip -q -0 -r "$OUT/unaligned.apk" lib )
"$BUILD_TOOLS/zipalign" -f -P 16 4 "$OUT/unaligned.apk" "$OUT/aligned.apk"

# --- sign
if [ ! -f "$KEYSTORE" ]; then
	keytool -genkeypair -keystore "$KEYSTORE" -storepass "$KS_PASS" -keypass "$KS_PASS" \
		-alias "$KS_ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
		-dname "CN=Android Debug,O=Android,C=US"
fi
"$BUILD_TOOLS/apksigner" sign --ks "$KEYSTORE" --ks-pass "pass:$KS_PASS" --ks-key-alias "$KS_ALIAS" \
	--out "$APK" "$OUT/aligned.apk"
"$BUILD_TOOLS/zipalign" -c -P 16 4 "$APK"
"$BUILD_TOOLS/apksigner" verify --print-certs "$APK" | head -3
ls -la "$APK"
