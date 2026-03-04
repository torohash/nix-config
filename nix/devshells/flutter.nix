{ mkShell, flutter, jdk17, androidenv }:

let
  androidSdk = (androidenv.composeAndroidPackages {
    platformVersions = [ "35" ];
    buildToolsVersions = [ "35.0.0" ];
    includeEmulator = false;
    includeSources = false;
  }).androidsdk;
in
mkShell {
  packages = [
    flutter
    jdk17
  ];

  ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
  ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
  JAVA_HOME = "${jdk17}";
}
