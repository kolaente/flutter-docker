FROM debian:trixie-slim AS slim

ARG FLUTTER_VERSION

ENV FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/root/.pub-cache
ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        file \
        git \
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
    && flutter precache --universal

FROM slim AS android

ARG ANDROID_CMDLINE_TOOLS_VERSION=13114758

ENV ANDROID_HOME=/opt/android-sdk \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
    GRADLE_USER_HOME=/root/.gradle
ENV PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

RUN apt-get update \
    && apt-get install -y --no-install-recommends openjdk-21-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

RUN flutter precache --android

COPY android-sdk-packages /usr/local/bin/

RUN curl -fsSLo /tmp/cmdline-tools.zip "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" \
    && mkdir -p "$ANDROID_HOME/cmdline-tools" \
    && unzip -q /tmp/cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools" \
    && mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" \
    && rm /tmp/cmdline-tools.zip \
    && yes | sdkmanager --licenses > /dev/null \
    && packages=$(android-sdk-packages) \
    && sdkmanager --install $packages > /dev/null \
    && sdkmanager --list_installed
