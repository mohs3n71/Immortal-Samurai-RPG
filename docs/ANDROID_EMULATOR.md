# Android emulator

Last updated: 2026-10-29. The user selected Google's Android Emulator for initial testing (D-017).

The project-local test device is `Godot_Test_API35`, a Pixel 7 profile with Android 15 (API 35), x86_64, 1080 × 2400. Its standard Android image does not include Google Play services. The emulator, SDK platform tools, command-line tools and virtual device are in ignored `.tools/android-sdk/` and `.tools/android-avd/`; they are local setup, not source assets. AVD files contain local absolute paths and may need recreation if the project moves.

On this Windows machine, double-click `tools/start-android-emulator.cmd` to start it. Close the emulator window to stop it. To list connected devices from the project root:

```powershell
& '.tools/android-sdk/platform-tools/adb.exe' devices -l
```

The emulator version is 37.2.12 (build 16428233); Windows Hypervisor Platform passed `-accel-check`. Android 15 boot completed and adb connected. An initial Godot debug APK was exported and installed for the movement prototype; the compatibility renderer displayed a landscape scene and a simulated touch drag moved it. This does not establish actual phone performance, thermals or battery life. The user now requests routine Godot-only testing, with Android builds only on request (D-019).

Godot 4.7.2's debug template, project-local Android build-tools 35.0.1 and a local debug keystore were configured for that initial export. Godot's user editor settings point to the local SDK and an existing Java 17 runtime; their prior contents are backed up under `.tools/`. Build-tools emitted a target-SDK version warning, and no release signing is configured. Android Studio and its Device Manager are not installed: its download was stopped after slow transfers, so the launcher above is the available management path. SDK Manager could not fetch remote manifests during setup.

## Android debug build - 2026-10-30

The requested current debug-signed APK is `builds/android-2026-10-30/MovementPrototype-Android-debug.apk` (D-066). It targets ARM64 phones and x86-64 emulators, requires Android 7.0/API 24 or later, and has target SDK 36. The APK signature verified; the bundled runtime catalog was confirmed. The Android 15 x86-64 emulator installed it, displayed the hero menu and field, and responded to a simulated joystick swipe with `-gpu host`; captures are in `previews/android-build-2026-10-30/`. Initial `-gpu swiftshader_indirect` rendering failed shader linking due to the emulator's fragment uniform limit; host mode displayed correctly and logged a shader-cache recompilation warning. This does not establish physical-phone compatibility or performance.

The previous Java path no longer existed, so Godot's user editor settings now point to the OpenJDK 17 bundled with Unity 6000.6.7f1 at `C:/Program Files/Unity/Hub/Editor/6000.6.7f1/Editor/Data/PlaybackEngines/AndroidPlayer/OpenJDK`; this path is machine-specific. Godot used project-local Android SDK build-tools 35.0.1 with a target-SDK version warning. Release signing remains unconfigured.

## ARM64-only phone APK

The user requested ARM v8 only; `builds/android-2026-10-30/MovementPrototype-Android-arm64-debug.apk` is the current phone build (D-067), 161,677,589 bytes. Android package metadata and ZIP entries confirm `arm64-v8a` is the only ABI, the catalog is present, and apksigner verifies its debug signature. The previous combined APK and `Android test` export preset remain available for the x86-64 emulator. No ARM64 phone was connected, so this APK has not been run on a device.
