#!/usr/bin/env bash
set -euo pipefail

variant=${1:?usage: smoke-test.sh slim|android}

flutter --version
dart --version
flutter doctor -v | tee /tmp/doctor.txt

case "$variant" in
    slim)
        ;;
    android)
        java -version
        grep -q '^\[✓\] Android toolchain' /tmp/doctor.txt

        # precache skips downloads it considers up to date, and the slim stage already filled the cache
        test -d "$FLUTTER_HOME/bin/cache/artifacts/engine/android-arm64-release" \
            || { echo "Android engine artifacts missing"; exit 1; }

        installed=$(sdkmanager --list_installed | awk -F'|' '{ gsub(/ /, "", $1); print $1 }')
        for package in $(android-sdk-packages); do
            grep -qxF "$package" <<< "$installed" || { echo "Missing SDK package $package"; exit 1; }
        done
        ;;
    *)
        echo "Unknown variant $variant"
        exit 2
        ;;
esac
