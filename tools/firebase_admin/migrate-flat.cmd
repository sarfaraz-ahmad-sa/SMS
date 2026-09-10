@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo.
echo EXAMPLE School ERP - Migrate Legacy Flat Collections
 echo -------------------------------------------------

if "%FIREBASE_PROJECT_ID%"=="" set /p FIREBASE_PROJECT_ID=Firebase project ID: 
if "%TENANT_ID%"=="" set /p TENANT_ID=Target tenant ID: 
if "%ACTOR_UID%"=="" set /p ACTOR_UID=Firebase Auth UID performing migration: 
if "%DRY_RUN%"=="" set "DRY_RUN=true"
if "%DELETE_SOURCE%"=="" set "DELETE_SOURCE=false"

if "%GOOGLE_APPLICATION_CREDENTIALS%"=="" (
  echo.
  echo ERROR: GOOGLE_APPLICATION_CREDENTIALS is not set.
  echo Set it to the full path of your Firebase service-account JSON, for example:
  echo set "GOOGLE_APPLICATION_CREDENTIALS=C:\secure\firebase-service-account.json"
  echo.
  exit /b 1
)

echo.
echo DRY_RUN=%DRY_RUN%
echo DELETE_SOURCE=%DELETE_SOURCE%
echo.
call npm run migrate:flat
set EXIT_CODE=%ERRORLEVEL%
if not "%EXIT_CODE%"=="0" (
  echo.
  echo Migration failed with exit code %EXIT_CODE%.
  exit /b %EXIT_CODE%
)

echo.
echo Migration command completed successfully.
endlocal
