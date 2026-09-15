# Flutter Docker Image

A Flutter + Android SDK image for building Android apps in CI, so jobs don't have to install Flutter, the SDK and a JDK on every run.

Images are published only on GitHub Container Registry (GHCR) as `ghcr.io/kolaente/flutter-docker`, for `linux/amd64`.

## What's in the image

- Debian trixie (slim)
- Flutter stable, cloned from its git tag, with Android artifacts precached and analytics disabled
- OpenJDK 21
- Android SDK: `platform-tools`, `platforms;android-37.0`, `build-tools;36.0.0`, plus the default `compileSdk` platform and NDK of the bundled Flutter version. Licenses are accepted.

Environment: `FLUTTER_HOME=/opt/flutter`, `ANDROID_HOME=/opt/android-sdk`, `JAVA_HOME`, `PUB_CACHE=/root/.pub-cache`, `GRADLE_USER_HOME=/root/.gradle`. Flutter, Dart and the SDK tools are on `PATH`.

## Tags

- `3.47.4` - the Flutter version (see [`FLUTTER_VERSION`](FLUTTER_VERSION))
- `latest` - the most recent build of `main`
- `sha-<commit>` - the build of a specific commit of this repo

Pull requests build and test the image but never publish it.

## Verifying the signature

Images are signed keylessly with [cosign](https://github.com/sigstore/cosign) from this repo's build workflow:

```shell
cosign verify ghcr.io/kolaente/flutter-docker:3.47.4 \
  --certificate-identity https://github.com/kolaente/flutter-docker/.github/workflows/build.yml@refs/heads/main \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## Using this image in GitLab CI

Point `PUB_CACHE` and `GRADLE_USER_HOME` into the project dir so GitLab can cache them:

```yaml
build-android:
  image: ghcr.io/kolaente/flutter-docker:3.47.4
  variables:
    PUB_CACHE: "$CI_PROJECT_DIR/.cache/pub"
    GRADLE_USER_HOME: "$CI_PROJECT_DIR/.cache/gradle"
  cache:
    key: flutter-android
    paths:
      - .cache/pub
      - .cache/gradle
  script:
    - flutter pub get
    - flutter build apk --release
  artifacts:
    paths:
      - build/app/outputs/flutter-apk/app-release.apk
```

## How updates work

- A daily workflow checks Flutter's release feed. When there is a new stable version, it bumps `FLUTTER_VERSION`, commits to `main` and builds and publishes the image in the same run.
- The image is rebuilt weekly to pick up base image and security updates, and on every push to `main` that touches the image.
- Every build checks the toolchain inside the image (`flutter doctor`, Java, installed SDK packages) before anything is pushed, so a broken image is never published.
