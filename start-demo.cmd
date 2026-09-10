@echo off
setlocal
cd /d "%~dp0"
if not exist config\demo.json (
  echo Create config\demo.json using DEMO_ACCOUNTS.md first.
  exit /b 1
)
call flutter pub get
if errorlevel 1 exit /b 1
call flutter run -d chrome --dart-define-from-file=config/demo.json
endlocal
