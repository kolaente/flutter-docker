FROM debian:trixie-slim

ARG FLUTTER_VERSION
ARG ANDROID_CMDLINE_TOOLS_VERSION=13114758
# compileSdk 37 isn't Flutter's default yet, AGP 9.1 wants build-tools 36.0.0
ARG ANDROID_PACKAGES="platform-tools platforms;android-37.0 build-tools;36.0.0"

ENV FLUTTER_HOME=/opt/flutter \
    ANDROID_HOME=/opt/android-sdk \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
    PUB_CACHE=/root/.pub-cache \
    GRADLE_USER_HOME=/root/.gradle
ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        file \
        git \
        openjdk-21-jdk-headless \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

# CI checkouts are often owned by another uid than the root user running the job
RUN test -n "$FLUTTER_VERSION" \
    && git config --system --add safe.directory '*' \
    && git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME" \
    && flutter --disable-analytics \
    && dart --disable-analytics \
    && flutter config --no-cli-animations \
    && flutter precache --android

# The NDK and default compileSdk follow whatever the pinned Flutter version expects
RUN curl -fsSLo /tmp/cmdline-tools.zip "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" \
    && mkdir -p "$ANDROID_HOME/cmdline-tools" \
    && unzip -q /tmp/cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools" \
    && mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" \
    && rm /tmp/cmdline-tools.zip \
    && yes | sdkmanager --licenses > /dev/null \
    && flutter_extension="$FLUTTER_HOME/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt" \
    && ndk_version=$(sed -n 's/.*val ndkVersion: String = "\(.*\)"/\1/p' "$flutter_extension") \
    && compile_sdk=$(sed -n 's/.*val compileSdkVersion: Int = \([0-9]*\).*/\1/p' "$flutter_extension") \
    && test -n "$ndk_version" -a -n "$compile_sdk" \
    && sdkmanager --install $ANDROID_PACKAGES "platforms;android-$compile_sdk" "ndk;$ndk_version" > /dev/null \
    && sdkmanager --list_installed
