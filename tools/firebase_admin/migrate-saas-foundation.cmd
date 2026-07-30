@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo.
echo CARTZ Link School ERP - Migrate SaaS Foundation
echo ------------------------------------------------

if "%FIREBASE_PROJECT_ID%"=="" set /p FIREBASE_PROJECT_ID=Firebase project ID: 
if "%GOOGLE_APPLICATION_CREDENTIALS%"=="" (
  echo ERROR: GOOGLE_APPLICATION_CREDENTIALS is not set.
  exit /b 1
)
if "%DEFAULT_SAAS_TIER%"=="" set "DEFAULT_SAAS_TIER=enterprise"

call npm run migrate:saas
exit /b %ERRORLEVEL%
