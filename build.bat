@echo off
setlocal enabledelayedexpansion

:: 기본 변수 설정
set "ROOT_PATH=C:/Users/User/update_test_for_flutter"
set "PROJECT_PATH=%ROOT_PATH%/simple_update_test"
set "HASH_MAKER_PATH=%ROOT_PATH%/hash-maker"
set "DUPDATER_PATH=%ROOT_PATH%/dupdater"
set "BUILD_DIR=%PROJECT_PATH%/build/windows/x64/runner/Release/."
set "VERSION_FILE=%PROJECT_PATH%/assets/version.json"

:: PowerShell을 사용하여 version.json에서 버전 정보 읽기
for /f "tokens=* usebackq" %%a in (`powershell -Command "Get-Content '%VERSION_FILE%' | ConvertFrom-Json | Select -ExpandProperty version"`) do (
    set "VERSION=%%a"
)
for /f "tokens=* usebackq" %%a in (`powershell -Command "Get-Content '%VERSION_FILE%' | ConvertFrom-Json | Select -ExpandProperty buildDate"`) do (
    set "BUILD_DATE=%%a"
)
set "ZIP_NAME=Flutter_APP_V%VERSION%(%BUILD_DATE%).zip"

:: 명령어 처리
if "%1"=="" goto help
if "%1"=="all" goto all
if "%1"=="clean" goto clean
if "%1"=="hash" goto hash
if "%1"=="build-hash-maker" goto build-hash-maker
if "%1"=="build-dupdater" goto build-dupdater
if "%1"=="build-flutter" goto build-flutter
if "%1"=="copy-updater" goto copy-updater
if "%1"=="create-zip" goto create-zip
if "%1"=="update-hash-maker" goto update-hash-maker
if "%1"=="update-flutter" goto update-flutter
if "%1"=="update-dupdater" goto update-dupdater
if "%1"=="zip-with-name" goto zip-with-name
goto help

:all
call :build-hash-maker
call :build-dupdater
call :build-flutter
call :copy-updater
call :hash
call :create-zip
goto :eof

:build-hash-maker
echo Building hash-maker...
cd %HASH_MAKER_PATH%
go build -o hash-maker.exe
goto :eof

:build-dupdater
echo Building dupdater...
cd %DUPDATER_PATH%/cmd/dupdater
go build -o ../../dupdater.exe
goto :eof

:build-flutter
echo Cleaning Flutter build...
cd %PROJECT_PATH%
flutter clean
echo Running build_runner...
flutter pub run build_runner build --delete-conflicting-outputs
echo Building Flutter Windows app...
flutter build windows --release
goto :eof

:copy-updater
echo Copying updater to build directory...
copy "%DUPDATER_PATH%\dupdater.exe" "%BUILD_DIR%"
goto :eof

:create-zip
echo Creating ZIP file...
"%HASH_MAKER_PATH%\hash-maker.exe" -zipfolder "%BUILD_DIR%" -zipname "%ZIP_NAME%" -zipoutput "%PROJECT_PATH%"
"%HASH_MAKER_PATH%\hash-maker.exe" -zip -zipPath "%PROJECT_PATH%\%ZIP_NAME%"
goto :eof

:hash
echo Generating hash for build output...
"%HASH_MAKER_PATH%\hash-maker.exe" -startPath "%BUILD_DIR%"
goto :eof

:update-hash-maker
call :build-hash-maker
if not exist "%BUILD_DIR%" (
    echo Error: Build directory does not exist. Please run full build first.
    exit /b 1
)
echo Creating new ZIP with updated hash-maker output...
"%HASH_MAKER_PATH%\hash-maker.exe" -zipfolder "%BUILD_DIR%" -zipname "%ZIP_NAME%" -zipoutput "%PROJECT_PATH%"
"%HASH_MAKER_PATH%\hash-maker.exe" -zip -zipPath "%PROJECT_PATH%\%ZIP_NAME%"
echo Update complete. New ZIP file created: %ZIP_NAME%
goto :eof

:update-flutter
echo Running build_runner...
cd %PROJECT_PATH%
flutter pub run build_runner build --delete-conflicting-outputs
echo Building Flutter Windows app...
flutter build windows --release
echo Creating new ZIP with updated Flutter app...
copy "%DUPDATER_PATH%\dupdater.exe" "%BUILD_DIR%"
"%HASH_MAKER_PATH%\hash-maker.exe" -zipfolder "%BUILD_DIR%" -zipname "%ZIP_NAME%" -zipoutput "%PROJECT_PATH%"
"%HASH_MAKER_PATH%\hash-maker.exe" -zip -zipPath "%PROJECT_PATH%\%ZIP_NAME%"
echo Update complete. New ZIP file created: %ZIP_NAME%
goto :eof

:update-dupdater
call :build-dupdater
if not exist "%BUILD_DIR%" (
    echo Error: Build directory does not exist. Please run full build first.
    exit /b 1
)
echo Updating dupdater and creating new ZIP...
copy "%DUPDATER_PATH%\dupdater.exe" "%BUILD_DIR%"
"%HASH_MAKER_PATH%\hash-maker.exe" -zipfolder "%BUILD_DIR%" -zipname "%ZIP_NAME%" -zipoutput "%PROJECT_PATH%"
"%HASH_MAKER_PATH%\hash-maker.exe" -zip -zipPath "%PROJECT_PATH%\%ZIP_NAME%"
echo Update complete. New ZIP file created: %ZIP_NAME%
goto :eof

:clean
echo Cleaning up...
if exist "%PROJECT_PATH%\%ZIP_NAME%" del "%PROJECT_PATH%\%ZIP_NAME%"
cd %PROJECT_PATH%
flutter clean
goto :eof

:zip-with-name
if "%2"=="" (
    echo Please provide a name parameter: build.bat zip-with-name your_name
    goto :eof
)
echo Creating ZIP file with name: %2.zip
"%HASH_MAKER_PATH%\hash-maker.exe" -zipfolder "%BUILD_DIR%" -zipname "%2.zip" -zipoutput "%PROJECT_PATH%"
"%HASH_MAKER_PATH%\hash-maker.exe" -zip -zipPath "%PROJECT_PATH%\%2.zip"
goto :eof

:help
echo Available commands:
echo   build.bat all              - Build everything and create ZIP with hash
echo   build.bat build-hash-maker - Build hash-maker tool
echo   build.bat build-dupdater   - Build dupdater tool
echo   build.bat build-flutter    - Build Flutter Windows app
echo   build.bat hash             - Generate hash for build output only
echo   build.bat clean            - Clean up generated files
echo   build.bat zip-with-name name - Create ZIP with specific name
echo.
echo Quick update commands:
echo   build.bat update-hash-maker - Update hash-maker and create new ZIP
echo   build.bat update-dupdater   - Update dupdater and create new ZIP
echo   build.bat update-flutter    - Update Flutter app and create new ZIP
goto :eof