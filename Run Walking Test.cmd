@echo off
setlocal EnableDelayedExpansion
rem Runs the Meadowlands walking and enemy tests on this PC without a game window and
rem faster than real time. Results go to walking-test-log.txt in this folder.

set "GODOT=%~dp0.tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe"
set "GAME=%~dp0game"
set "LOG=%~dp0walking-test-log.txt"

if not exist "%GODOT%" (
  echo Godot 4.7.2 console was not found at:
  echo   %GODOT%
  pause
  exit /b 1
)

echo Walking test started %date% %time% > "%LOG%"
echo Importing assets...
"%GODOT%" --headless --path "%GAME%" --import >> "%LOG%" 2>&1

set FAILED=0
for %%T in (check_meadow_traversal check_ramp_edges check_meadow_wander check_auto_attack check_enemies check_progression check_boss check_tutorial check_regions check_frost_traversal) do (
  echo Running %%T ...
  echo. >> "%LOG%"
  echo ==== %%T >> "%LOG%"
  "%GODOT%" --headless --fixed-fps 60 --path "%GAME%" --script res://tests/%%T.gd -- uncapped >> "%LOG%" 2>&1
  if errorlevel 1 (
    echo    FAILED
    set FAILED=1
  ) else (
    echo    passed
  )
)

echo. >> "%LOG%"
echo Walking test finished %date% %time% >> "%LOG%"
echo.
if "!FAILED!"=="1" (
  echo Some checks FAILED. Details are in walking-test-log.txt
) else (
  echo All tests passed.
)
echo Results saved to walking-test-log.txt
pause
