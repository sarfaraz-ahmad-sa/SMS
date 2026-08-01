@echo off
setlocal
cd /d "%~dp0"

echo Starting SEEF School ERP demo...
call flutter pub get
if errorlevel 1 exit /b 1

call flutter run -d chrome --dart-define=ENABLE_DEV_LOGIN=true
endlocal
