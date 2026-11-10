@echo off
setlocal
REM Suraksha Agent Skills Installer wrapper for Windows Command Prompt (CMD)
REM Delegates safely to install.ps1 with ExecutionPolicy Bypass scoped to this process.

set "SCRIPT_DIR=%~dp0"
where powershell >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] PowerShell is required to run Suraksha installer on Windows.
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install.ps1" %*
exit /b %ERRORLEVEL%

