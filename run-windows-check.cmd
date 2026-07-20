@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if not exist "pubspec.yaml" (
  echo ERROR: pubspec.yaml was not found. Extract this project completely first.
  exit /b 1
)

if not exist "lib\firebase_options.dart" (
  echo ERROR: lib\firebase_options.dart is missing.
  echo Run: flutterfire configure
  exit /b 1
)

call flutter clean || exit /b 1
call flutter pub get || exit /b 1
call flutter analyze || exit /b 1
call flutter test || exit /b 1

echo.
echo Flutter project checks completed successfully.
endlocal
