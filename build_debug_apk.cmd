@echo off
setlocal
cd /d "%~dp0"

flutter pub get
if errorlevel 1 exit /b %errorlevel%

flutter build apk --debug --dart-define=CHRISTIAN_GOLFERS_DEMO=true
if errorlevel 1 exit /b %errorlevel%

echo.
echo Debug APK: build\app\outputs\flutter-apk\app-debug.apk
pause
