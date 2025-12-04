@echo off
REM Uncrumpled Context Switcher - Windows Installation Wrapper
REM This batch file launches the PowerShell installation script

setlocal

set SCRIPT_DIR=%~dp0

REM Check for PowerShell
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: PowerShell is required but not found.
    echo Please install PowerShell or run the install.ps1 script directly.
    exit /b 1
)

REM Parse arguments
set "ARGS="
:parse_args
if "%~1"=="" goto run_script
if /i "%~1"=="--service" set "ARGS=%ARGS% -Service" & shift & goto parse_args
if /i "%~1"=="-service" set "ARGS=%ARGS% -Service" & shift & goto parse_args
if /i "%~1"=="--startup" set "ARGS=%ARGS% -Startup" & shift & goto parse_args
if /i "%~1"=="-startup" set "ARGS=%ARGS% -Startup" & shift & goto parse_args
if /i "%~1"=="--uninstall" set "ARGS=%ARGS% -Uninstall" & shift & goto parse_args
if /i "%~1"=="-uninstall" set "ARGS=%ARGS% -Uninstall" & shift & goto parse_args
if /i "%~1"=="--help" set "ARGS=%ARGS% -Help" & shift & goto parse_args
if /i "%~1"=="-h" set "ARGS=%ARGS% -Help" & shift & goto parse_args
if /i "%~1"=="/?" set "ARGS=%ARGS% -Help" & shift & goto parse_args
shift
goto parse_args

:run_script
REM Run PowerShell script
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install.ps1" %ARGS%

endlocal
