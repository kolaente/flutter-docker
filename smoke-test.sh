#!/usr/bin/env bash
set -euo pipefail

flutter --version
java -version
flutter doctor -v | tee /tmp/doctor.txt
grep -q '^\[✓\] Android toolchain' /tmp/doctor.txt

installed=$(sdkmanager --list_installed | awk -F'|' '{ gsub(/ /, "", $1); print $1 }')
for package in $(android-sdk-packages); do
    grep -qxF "$package" <<< "$installed" || { echo "Missing SDK package $package"; exit 1; }
done
