@echo off
REM NCC LFG! Protocol Executable Launcher
REM Activates ALL NCC Agents into LFG! Mode

title NCC LFG! Protocol Activation
color 0C

echo.
echo 🔥🔥🔥 NCC LFG! PROTOCOL ACTIVATION - LET'S FUCKING GO! 🔥🔥🔥
echo ════════════════════════════════════════════════════════════════
echo.

REM Change to the script directory and run the PowerShell activation script
cd /d "%~dp0"

echo 📊 Activating LFG! Protocol for ALL NCC Agents...
echo.

powershell.exe -ExecutionPolicy Bypass -Command "& { . '.\LFG.Activate.ps1' }"

echo.
echo ════════════════════════════════════════════════════════════════
echo 🎯 LFG! Protocol Activation Complete!
echo 🎯 ALL 1200+ NCC Agents now operating in Supreme LFG! Mode!
echo.
echo Press any key to exit...
pause >nul