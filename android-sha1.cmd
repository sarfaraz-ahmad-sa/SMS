@echo off
setlocal EnableExtensions
set "KEYSTORE=%USERPROFILE%\.android\debug.keystore"

where keytool >nul 2>nul
if errorlevel 1 (
  echo ERROR: keytool was not found. Install or configure JDK 17 first.
  exit /b 1
)

if not exist "%USERPROFILE%\.android" mkdir "%USERPROFILE%\.android"
if not exist "%KEYSTORE%" (
  echo Creating the standard Android debug keystore...
  keytool -genkeypair -v -keystore "%KEYSTORE%" -storepass android -alias androiddebugkey -keypass android -dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -keysize 2048 -validity 10000
  if errorlevel 1 exit /b 1
)

keytool -list -v -alias androiddebugkey -keystore "%KEYSTORE%" -storepass android -keypass android | findstr /I "SHA1 SHA-256"
endlocal
