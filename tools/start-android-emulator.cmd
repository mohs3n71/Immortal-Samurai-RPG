@echo off
setlocal
set "ANDROID_HOME=%~dp0..\.tools\android-sdk"
set "ANDROID_AVD_HOME=%~dp0..\.tools\android-avd"
if not exist "%ANDROID_HOME%\emulator\emulator.exe" (
  echo Android Emulator is not present in the project-local tools folder.
  exit /b 1
)
start "" "%ANDROID_HOME%\emulator\emulator.exe" -avd Godot_Test_API35 -gpu auto
