this is updog
rehydrated


is like vs impostor but new


ME AND DATA AND ORBY AND LOGGO AND DUSKIE WE CODED IT

Duskiewhy made the engine /////////// some stuff by data5 
(Nightmare Vision)


## set ur libs ok.

In a cmd within the project directory, in order run...

> haxelib install hxpkg --global

> haxelib run hxpkg setup --global

> hxpkg install

### Quick Note
- this engine ENFORCES use of hxpkg for libraries to prevent issues in relation to `hxvlc`
- if u have .haxelibs installed already delete em probably lol


After that is complete, run `lime test windows` and you should be compiling
## Android (ARM64)

The **Android APK** GitHub Actions workflow builds an installable test APK on
pull requests and pushes to `main`, or manually through **Actions → Android APK →
Run workflow** once the workflow is on the default branch. Download
`UPDOG-Android-arm64` from the successful run's **Artifacts** section and unzip it.
The APK uses Android's debug signing key; it is not a Play Store release.

Requirements: Android 6.0+ (API 23), a 64-bit ARM device, and enough free internal
storage for both the APK and its extracted game files. The first launch displays
file preparation progress. Updates replace changed bundled files; game saves are
kept separately. No shared-storage permission or manual asset download is needed.

Touch controls: four bottom buttons navigate menus and play notes (including
simultaneous notes and holds). **OK/BACK** navigate menus; **PAUSE**, **BACK** and
**DODGE** are at the top during gameplay. The buttons follow the configured key
bindings. Keyboard/gamepad support remains available. Desktop editors are not
optimized for touch. Discord RPC and desktop Lua support are disabled on Android;
this mod's bundled scripts use HScript. Video playback remains enabled via hxvlc.

### Local build

Use Haxe **4.3.4**, Java **17**, Android platform/build-tools **34**, and NDK
**25.2.9519653**. The `.hxpkg` file pins the engine libraries and Git revisions.
Install the Android command-line tools and accept the SDK licenses, then run:

```sh
sdkmanager 'platforms;android-34' 'build-tools;34.0.0' 'ndk;25.2.9519653'
haxelib --global install hxpkg 1.6.2 --quiet
haxelib --global run hxpkg install --quiet
haxelib run lime config ANDROID_SETUP true
haxelib run lime config ANDROID_SDK "$ANDROID_HOME"
haxelib run lime config ANDROID_NDK_ROOT "$ANDROID_HOME/ndk/25.2.9519653"
haxelib run lime config JAVA_HOME "$JAVA_HOME"
python3 scripts/prepare-android-assets.py
# Linux x86_64 host (match your NDK prebuilt directory on other systems):
export ANDROID_HOST=linux-x86_64
export HXCPP_STRIP=llvm-strip
haxelib run lime build android -release
```

The APK is under `export/release/android/bin/app/build/outputs/apk/debug/`.
Lime builds optimized Haxe code with `-release` but uses a debug-signed Gradle APK
when no release keystore is configured. Regenerate the asset manifest after
changing bundled files, including for Android debug builds. The manifest maps the
asset declarations in `Project.xml`; update the generator if those mappings change.

Before distributing, test all three songs on a real device, including holds,
chords, dodging, cutscenes, pause/resume, background/foreground transitions and
save persistence. A successful build does not verify graphics, audio timing or
performance on hardware. The old desktop workflow remains manual-only.
