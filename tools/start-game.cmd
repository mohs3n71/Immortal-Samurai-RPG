@echo off
setlocal
set "GODOT=%~dp0..\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe"
set "GAME=%~dp0..\game"
if not exist "%GODOT%" (
  echo Godot 4.7.2 is not present in the project-local tools folder.
  exit /b 1
)
rem Import new or changed assets first; launching the game alone skips this step.
set "GODOT_CONSOLE=%~dp0..\.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if exist "%GODOT_CONSOLE%" "%GODOT_CONSOLE%" --headless --path "%GAME%" --import
start "" "%GODOT%" --path "%GAME%"
