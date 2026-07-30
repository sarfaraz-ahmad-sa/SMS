@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo.
echo CARTZ Link School ERP - Seed Enterprise Master Data
echo ---------------------------------------------

if "%FIREBASE_PROJECT_ID%"=="" set /p FIREBASE_PROJECT_ID=Firebase project ID: 
if "%TENANT_ID%"=="" set /p TENANT_ID=Tenant ID: 
if "%ACADEMIC_YEAR_ID%"=="" set "ACADEMIC_YEAR_ID=2026-2027"
if "%ACTOR_UID%"=="" set "ACTOR_UID=system-seeder"

if "%GOOGLE_APPLICATION_CREDENTIALS%"=="" (
  echo ERROR: GOOGLE_APPLICATION_CREDENTIALS is not set.
  exit /b 1
)

call npm run seed:enterprise
exit /b %ERRORLEVEL%
