@echo off
setlocal EnableExtensions
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo ERROR: Flutter is not available in PATH.
  exit /b 1
)

set "TMP_PROJECT=%TEMP%\cartz_sms_wrapper_%RANDOM%_%RANDOM%"
echo Creating a temporary Flutter project to restore the Android Gradle wrapper...
call flutter create --platforms=android --project-name wrapper_seed "%TMP_PROJECT%"
if errorlevel 1 exit /b 1

if not exist "android\gradle\wrapper" mkdir "android\gradle\wrapper"
copy /Y "%TMP_PROJECT%\android\gradlew" "android\gradlew" >nul
copy /Y "%TMP_PROJECT%\android\gradlew.bat" "android\gradlew.bat" >nul
copy /Y "%TMP_PROJECT%\android\gradle\wrapper\gradle-wrapper.jar" "android\gradle\wrapper\gradle-wrapper.jar" >nul

rmdir /S /Q "%TMP_PROJECT%"
echo Android Gradle wrapper restored successfully.
endlocal
