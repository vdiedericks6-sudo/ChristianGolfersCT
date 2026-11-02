@echo off
setlocal
cd /d "%~dp0"

rem Keep Java's local sockets in a Windows path accessible to Gradle.
if not exist "%~dp0.tmp-jdk-sockets" mkdir "%~dp0.tmp-jdk-sockets"
set "JAVA_TOOL_OPTIONS=%JAVA_TOOL_OPTIONS% -Djdk.net.unixdomain.tmpdir=%~dp0.tmp-jdk-sockets"

flutter pub get
if errorlevel 1 exit /b %errorlevel%

flutter build apk --debug
if errorlevel 1 exit /b %errorlevel%

echo.
echo Debug APK: build\app\outputs\flutter-apk\app-debug.apk
pause
