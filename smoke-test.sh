#!/usr/bin/env bash
set -euo pipefail

flutter --version
flutter doctor -v | tee /tmp/doctor.txt
grep -q '^\[✓\] Android toolchain' /tmp/doctor.txt

list_sdk_packages() {
    find "$ANDROID_HOME" -mindepth 2 -maxdepth 2 -type d -not -path '*/.*' | sort
}

sdk_before=$(list_sdk_packages)

cd "$(mktemp -d)"
flutter create --platforms=android --project-name smoke .
flutter build apk --debug
# Release strips native libs, which needs the NDK
flutter build apk --release
test -f build/app/outputs/flutter-apk/app-debug.apk
test -f build/app/outputs/flutter-apk/app-release.apk

# Gradle silently installs missing SDK packages, which would hide gaps in the image
diff <(echo "$sdk_before") <(list_sdk_packages)
