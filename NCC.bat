@echo off
REM NCC Master Startup Launcher
REM Quick access to NCC Master Startup System

echo ============================================
echo  NCC MASTER STARTUP LAUNCHER
echo ============================================
echo.

if "%1"=="" goto :menu
if "%1"=="ASG" goto :asg
if "%1"=="LFG" goto :lfg
if "%1"=="STATUS" goto :status
if "%1"=="STOP" goto :stop
if "%1"=="MAINTENANCE" goto :maintenance
if "%1"=="SCHEDULE" goto :schedule
if "%1"=="TEST" goto :test
if "%1"=="UPDATE" goto :update
if "%1"=="STARTALL" goto :startall
if "%1"=="HELP" goto :help

:menu
echo NCC Quick Commands:
echo.
echo   NCC ASG        - Activate Systems Go
echo   NCC LFG        - Let's F***ing Go (Cycle Launch)
echo   NCC STATUS     - System Status
echo   NCC STOP       - Emergency Stop
echo   NCC MAINTENANCE- Run Maintenance
echo   NCC SCHEDULE   - Setup Scheduled Tasks
echo   NCC TEST       - Test All Systems
echo   NCC UPDATE     - Update All Systems
echo   NCC STARTALL   - Launch Complete System
echo   NCC HELP       - Show Help
echo.
echo Usage: NCC [command]
echo.
goto :end

:asg
powershell -ExecutionPolicy Bypass -File "%~dp0NCC.MasterStartup.ps1" -ASG
goto :end

:lfg
powershell -ExecutionPolicy Bypass -File "%~dp0NCC.MasterStartup.ps1" -LFG
goto :end

:status
powershell -ExecutionPolicy Bypass -File "%~dp0NCC.MasterStartup.ps1" -Status
goto :end

:stop
powershell -ExecutionPolicy Bypass -File "%~dp0NCC.MasterStartup.ps1" -Stop
goto :end

:maintenance
powershell -ExecutionPolicy Bypass -File "%~dp0NCC.MasterStartup.ps1" -Maintenance
goto :end

:schedule
powershell -ExecutionPolicy Bypass -File "%~dp0NCC.MasterStartup.ps1" -Schedule
goto :end

:test
powershell -ExecutionPolicy Bypass -File "%~dp0NCC.MasterStartup.ps1" -Test
goto :end

:update
powershell -ExecutionPolicy Bypass -File "%~dp0NCC.MasterStartup.ps1" -Update
goto :end

:startall
powershell -ExecutionPolicy Bypass -File "%~dp0NCC.MasterStartup.ps1" -StartAll
goto :end

:help
powershell -ExecutionPolicy Bypass -File "%~dp0NCC.MasterStartup.ps1" -Help
goto :end

:end
echo.
pause