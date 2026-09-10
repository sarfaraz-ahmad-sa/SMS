@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo.
echo EXAMPLE School ERP - Seed School Tenant
 echo -----------------------------------

if "%FIREBASE_PROJECT_ID%"=="" set /p FIREBASE_PROJECT_ID=Firebase project ID: 
if "%TENANT_ID%"=="" set /p TENANT_ID=Tenant ID (example school_demo): 
if "%TENANT_NAME%"=="" set /p TENANT_NAME=School name: 
if "%TENANT_CODE%"=="" set /p TENANT_CODE=School code: 
if "%USER_EMAIL%"=="" set /p USER_EMAIL=Owner email: 
if "%USER_NAME%"=="" set /p USER_NAME=Owner display name: 
if "%USER_PASSWORD%"=="" set /p USER_PASSWORD=Temporary password (minimum 8 characters): 
if "%ROLES%"=="" set "ROLES=schoolOwner"
if "%CAMPUS_IDS%"=="" set "CAMPUS_IDS=main-campus"
if "%ACADEMIC_YEAR_ID%"=="" set "ACADEMIC_YEAR_ID=2026-2027"
if "%TIMEZONE%"=="" set "TIMEZONE=Asia/Karachi"
if "%CURRENCY%"=="" set "CURRENCY=PKR"

if "%GOOGLE_APPLICATION_CREDENTIALS%"=="" (
  echo.
  echo ERROR: GOOGLE_APPLICATION_CREDENTIALS is not set.
  echo Set it to the full path of your Firebase service-account JSON, for example:
  echo set "GOOGLE_APPLICATION_CREDENTIALS=C:\secure\firebase-service-account.json"
  echo.
  exit /b 1
)

call npm run seed:tenant
set EXIT_CODE=%ERRORLEVEL%
if not "%EXIT_CODE%"=="0" (
  echo.
  echo Tenant seed failed with exit code %EXIT_CODE%.
  exit /b %EXIT_CODE%
)

echo.
echo Tenant seed completed successfully.
endlocal
