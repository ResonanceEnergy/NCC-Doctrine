<<<<<<< HEAD

=======
>>>>>>> c6b295e0d92d0143018dcdcb5ba8fd1affca0fae
# NCC Master Startup Script v2.0.0
# Author: NCC Command Center
# Purpose: Master launcher for all NCC systems and operations

param(
    [switch]$StartAll,       # Start everything (ASG + LFG + Maintenance)
    [switch]$ASG,           # Activate Systems Go
    [switch]$LFG,           # Let's F***ing Go
    [switch]$Maintenance,   # Run maintenance
    [switch]$Schedule,      # Set up scheduled tasks
    [switch]$Status,        # Show system status
    [switch]$Stop,          # Emergency stop
    [switch]$Test,          # Test all systems
    [switch]$Update,        # Update all systems
    [switch]$Help           # Show help
)

<<<<<<< HEAD
# Modular Agent Framework Integration
$AgentModules = @{
    Perception = "NCC.Agent.Perception.ps1"
    Reasoning = "NCC.Agent.Reasoning.ps1"
    Action = "NCC.Agent.Action.ps1"
}

function Invoke-SubAgentDecomposition {
    param([string]$Task)

    # Decompose complex tasks into sub-agent operations
    $subTasks = @{
        Analysis = "Analyze task requirements"
        Planning = "Create execution plan"
        Execution = "Perform task operations"
        Validation = "Verify results"
    }

    foreach ($subTask in $subTasks.GetEnumerator()) {
        Write-AgentLog "Executing sub-task: $($subTask.Key)" -Level "INFO"
        # Execute sub-agent logic here
    }
}

=======
>>>>>>> c6b295e0d92d0143018dcdcb5ba8fd1affca0fae
# Set error action preference
$ErrorActionPreference = "Stop"

# Get script directory and root path
$ScriptDir = Join-Path $PSScriptRoot "Scripts"
$RootPath = $PSScriptRoot

# System paths
$SystemPaths = @{
    SystemIntegration = Join-Path $ScriptDir "NCC.SystemIntegration.ps1"
    DailyMaintenance = Join-Path $ScriptDir "NCC.DailyMaintenance.ps1"
    ScheduledTasks = Join-Path $ScriptDir "NCC.ScheduledTasks.ps1"
    DesktopDisplay = Join-Path $ScriptDir "NCC.DesktopDisplay.ps1"
    MasterLog = Join-Path $RootPath "logs\NCC_Master_Startup.log"
}

# Ensure log directory exists
$logDir = Split-Path $SystemPaths.MasterLog -Parent
if (-not (Test-Path -Path $logDir -PathType Container)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-MasterLog {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [MASTER] [$Level] $Message"

    # Write to console with color coding
    switch ($Level.ToUpper()) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "INFO"    { Write-Host $logMessage -ForegroundColor Cyan }
        default   { Write-Host $logMessage }
    }

    # Write to master log file
    try {
        $logMessage | Out-File -FilePath $SystemPaths.MasterLog -Append -Encoding UTF8
    }
    catch {
        Write-Host "Failed to write to master log: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-NCCBanner {
    Write-MasterLog "==================================================================" -Level "INFO"
    Write-MasterLog "  N A T R I X   C O M M A N D   C O R P - M A S T E R   S Y S T E M " -Level "INFO"
    Write-MasterLog "==================================================================" -Level "INFO"
}

function Invoke-SystemTest {
    Write-MasterLog "=== RUNNING NCC SYSTEM TEST ===" -Level "INFO"

    $testResults = @{
        SystemIntegration = $false
        DailyMaintenance = $false
        DesktopDisplay = $false
        ScheduledTasks = $false
        OverallHealth = $false
    }

    # Test System Integration
    if (Test-Path -Path $SystemPaths.SystemIntegration -PathType Leaf) {
        try {
            & $SystemPaths.SystemIntegration -Status
            $testResults.SystemIntegration = $true
            Write-MasterLog "System Integration: OK" -Level "SUCCESS"
        }
        catch {
            Write-MasterLog "System Integration test failed: $($_.Exception.Message)" -Level "ERROR"
        }
    } else {
        Write-MasterLog "System Integration script not found" -Level "ERROR"
    }

    # Test Daily Maintenance
    if (Test-Path -Path $SystemPaths.DailyMaintenance -PathType Leaf) {
        try {
            & $SystemPaths.DailyMaintenance -ShowStatus
            $testResults.DailyMaintenance = $true
            Write-MasterLog "Daily Maintenance: OK" -Level "SUCCESS"
        }
        catch {
            Write-MasterLog "Daily Maintenance test failed: $($_.Exception.Message)" -Level "ERROR"
        }
    } else {
        Write-MasterLog "Daily Maintenance script not found" -Level "ERROR"
    }

    # Test Desktop Display
    if (Test-Path -Path $SystemPaths.DesktopDisplay -PathType Leaf) {
        try {
            & $SystemPaths.DesktopDisplay -AuditSystem
            $testResults.DesktopDisplay = $true
            Write-MasterLog "Desktop Display: OK" -Level "SUCCESS"
        }
        catch {
            Write-MasterLog "Desktop Display test failed: $($_.Exception.Message)" -Level "ERROR"
        }
    } else {
        Write-MasterLog "Desktop Display script not found" -Level "ERROR"
    }

    # Test Scheduled Tasks
    if (Test-Path -Path $SystemPaths.ScheduledTasks -PathType Leaf) {
        try {
            & $SystemPaths.ScheduledTasks -ListTasks
            $testResults.ScheduledTasks = $true
            Write-MasterLog "Scheduled Tasks: OK" -Level "SUCCESS"
        }
        catch {
            Write-MasterLog "Scheduled Tasks test failed: $($_.Exception.Message)" -Level "ERROR"
        }
    } else {
        Write-MasterLog "Scheduled Tasks script not found" -Level "ERROR"
    }

    # Overall health assessment
    $passedTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
    $totalTests = $testResults.Count
    $testResults.OverallHealth = $passedTests -eq $totalTests

    Write-MasterLog "=== SYSTEM TEST COMPLETED ===" -Level "INFO"
    Write-MasterLog "Results: $passedTests/$totalTests systems operational" -Level $(if ($testResults.OverallHealth) { "SUCCESS" } else { "WARNING" })

    return $testResults
}

function Invoke-SystemUpdate {
    Write-MasterLog "=== RUNNING NCC SYSTEM UPDATE ===" -Level "INFO"

    # Update Node.js dependencies
    if (Test-Path -Path (Join-Path $RootPath "package.json") -PathType Leaf) {
        Write-MasterLog "Updating Node.js dependencies..." -Level "INFO"
        try {
            Push-Location $RootPath
            npm update
            Write-MasterLog "Node.js dependencies updated" -Level "SUCCESS"
        }
        catch {
            Write-MasterLog "Failed to update Node.js dependencies: $($_.Exception.Message)" -Level "ERROR"
        }
        finally {
            Pop-Location
        }
    }

    # Update PowerShell modules (if any)
    Write-MasterLog "Checking for PowerShell module updates..." -Level "INFO"
    try {
        Update-Module -ErrorAction SilentlyContinue
        Write-MasterLog "PowerShell modules updated" -Level "SUCCESS"
    }
    catch {
        Write-MasterLog "PowerShell module update failed: $($_.Exception.Message)" -Level "WARNING"
    }

    # Clean up old log files
    Write-MasterLog "Cleaning up old log files..." -Level "INFO"
    try {
        $logFiles = Get-ChildItem -Path (Join-Path $RootPath "logs") -Filter "*.log" -File -ErrorAction SilentlyContinue
        foreach ($file in $logFiles) {
            if ($file.LastWriteTime -lt (Get-Date).AddDays(-30)) {
                Remove-Item -Path $file.FullName -Force
                Write-MasterLog "Removed old log file: $($file.Name)" -Level "INFO"
            }
        }
        Write-MasterLog "Log cleanup completed" -Level "SUCCESS"
    }
    catch {
        Write-MasterLog "Log cleanup failed: $($_.Exception.Message)" -Level "WARNING"
    }

    Write-MasterLog "=== SYSTEM UPDATE COMPLETED ===" -Level "SUCCESS"
}

function Show-SystemStatus {
    Show-NCCBanner

    Write-MasterLog "NCC Master System Status" -Level "INFO"
    Write-MasterLog "=" * 50 -Level "INFO"

    # Check system components
    $components = @(
        @{Name = "System Integration"; Path = $SystemPaths.SystemIntegration},
        @{Name = "Daily Maintenance"; Path = $SystemPaths.DailyMaintenance},
        @{Name = "Scheduled Tasks"; Path = $SystemPaths.ScheduledTasks},
        @{Name = "Desktop Display"; Path = $SystemPaths.DesktopDisplay}
    )

    Write-MasterLog "Core Components:" -Level "INFO"
    foreach ($component in $components) {
        $status = if (Test-Path -Path $component.Path -PathType Leaf) { "PRESENT" } else { "MISSING" }
        $color = if ($status -eq "PRESENT") { "SUCCESS" } else { "ERROR" }
        Write-MasterLog "  • $($component.Name): $status" -Level $color
    }

    # Check scheduled tasks
    Write-MasterLog "Scheduled Tasks:" -Level "INFO"
    $taskNames = @("NCC_Daily_Maintenance", "NCC_System_Integration_Monitor", "NCC_Backup_Operations", "NCC_System_Monitoring")
    foreach ($taskName in $taskNames) {
        try {
            $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            $status = if ($task) { "REGISTERED" } else { "NOT REGISTERED" }
            $color = if ($task) { "SUCCESS" } else { "WARNING" }
            Write-MasterLog "  • $taskName`: $status" -Level $color
        }
        catch {
            Write-MasterLog "  • $taskName`: ERROR" -Level "ERROR"
        }
    }

    # Check running services
    Write-MasterLog "Running Services:" -Level "INFO"
    $services = @("node", "NCC.ContinuousOperations")
    foreach ($service in $services) {
        try {
            $procCount = (Get-Process -Name $service -ErrorAction SilentlyContinue).Count
            $status = if ($procCount -gt 0) { "RUNNING ($procCount)" } else { "STOPPED" }
            $color = if ($procCount -gt 0) { "SUCCESS" } else { "WARNING" }
            Write-MasterLog "  • $service`: $status" -Level $color
        }
        catch {
            Write-MasterLog "  • $service`: ERROR" -Level "ERROR"
        }
    }

    Write-MasterLog "" -Level "INFO"
}

function Show-Help {
    Show-NCCBanner

    Write-MasterLog "NCC Master Startup Commands:" -Level "INFO"
    Write-MasterLog "=" * 50 -Level "INFO"
    Write-MasterLog "  .\NCC.MasterStartup.ps1 -StartAll        # Launch complete NCC system (ASG + LFG + Maintenance)" -Level "INFO"
    Write-MasterLog "  .\NCC.MasterStartup.ps1 -ASG             # Activate Systems Go - System initialization" -Level "INFO"
    Write-MasterLog "  .\NCC.MasterStartup.ps1 -LFG             # Let's F***ing Go - Cycle operations launch" -Level "INFO"
    Write-MasterLog "  .\NCC.MasterStartup.ps1 -Maintenance     # Run system maintenance and health checks" -Level "INFO"
    Write-MasterLog "  .\NCC.MasterStartup.ps1 -Schedule        # Set up all automated scheduled tasks" -Level "INFO"
    Write-MasterLog "  .\NCC.MasterStartup.ps1 -Status          # Show comprehensive system status" -Level "INFO"
    Write-MasterLog "  .\NCC.MasterStartup.ps1 -Stop            # Emergency system shutdown" -Level "INFO"
    Write-MasterLog "  .\NCC.MasterStartup.ps1 -Test            # Test all system components" -Level "INFO"
    Write-MasterLog "  .\NCC.MasterStartup.ps1 -Update          # Update all system components" -Level "INFO"
    Write-MasterLog "  .\NCC.MasterStartup.ps1 -Help            # Show this help information" -Level "INFO"
    Write-MasterLog "" -Level "INFO"
    Write-MasterLog "Quick Start Commands:" -Level "INFO"
    Write-MasterLog "  'ASG' - Activate Systems Go" -Level "INFO"
    Write-MasterLog "  'LFG' - Let's F***ing Go (Cycle Launch)" -Level "INFO"
    Write-MasterLog "  'STATUS' - System Status" -Level "INFO"
    Write-MasterLog "  'STOP' - Emergency Stop" -Level "INFO"
    Write-MasterLog "" -Level "INFO"
}

# Main execution logic
Show-NCCBanner

if ($StartAll) {
    Write-MasterLog "=== NCC MASTER STARTUP - FULL SYSTEM ACTIVATION ===" -Level "INFO"

    # 1. ASG - System Activation
    if (Test-Path -Path $SystemPaths.SystemIntegration -PathType Leaf) {
        & $SystemPaths.SystemIntegration -ASG
    }

    # 2. Maintenance - System Health
    if (Test-Path -Path $SystemPaths.DailyMaintenance -PathType Leaf) {
        & $SystemPaths.DailyMaintenance -RunDailyMaintenance
    }

    # 3. LFG - Cycle Launch
    if (Test-Path -Path $SystemPaths.SystemIntegration -PathType Leaf) {
        & $SystemPaths.SystemIntegration -LFG
    }

<<<<<<< HEAD
    # 4. Ultimate Display Monitor - Real-time monitoring
    Write-MasterLog "Launching NCC Ultimate Display Monitor..." -Level "INFO"
    try {
        # Start the display server in background
        $displayServerPath = Join-Path $RootPath "NCC_Display_Server.js"
        if (Test-Path $displayServerPath) {
            Start-Process -FilePath "node" -ArgumentList $displayServerPath -NoNewWindow
            Write-MasterLog "Display server started successfully" -Level "SUCCESS"
        }

        # Start the display orchestrator
        $displayMasterPath = Join-Path $RootPath "NCC_Display_Master.ps1"
        if (Test-Path $displayMasterPath) {
            & $displayMasterPath -Start -HighPerformance
            Write-MasterLog "Display orchestrator started successfully" -Level "SUCCESS"
        }

        # Open display in browser after a short delay
        Start-Job -ScriptBlock {
            Start-Sleep -Seconds 3
            Start-Process "http://localhost:3000"
        } | Out-Null

        Write-MasterLog "Ultimate Display Monitor launched at http://localhost:3000" -Level "SUCCESS"
    } catch {
        Write-MasterLog "Failed to launch Ultimate Display Monitor: $($_.Exception.Message)" -Level "ERROR"
    }

=======
>>>>>>> c6b295e0d92d0143018dcdcb5ba8fd1affca0fae
    Write-MasterLog "=== NCC SYSTEM FULLY OPERATIONAL ===" -Level "SUCCESS"
}

if ($ASG) {
    if (Test-Path -Path $SystemPaths.SystemIntegration -PathType Leaf) {
        & $SystemPaths.SystemIntegration -ASG
    } else {
        Write-MasterLog "System Integration script not found" -Level "ERROR"
    }
}

if ($LFG) {
    if (Test-Path -Path $SystemPaths.SystemIntegration -PathType Leaf) {
        & $SystemPaths.SystemIntegration -LFG
    } else {
        Write-MasterLog "System Integration script not found" -Level "ERROR"
    }
}

if ($Maintenance) {
    if (Test-Path -Path $SystemPaths.DailyMaintenance -PathType Leaf) {
        & $SystemPaths.DailyMaintenance -RunDailyMaintenance
    } else {
        Write-MasterLog "Daily Maintenance script not found" -Level "ERROR"
    }
}

if ($Schedule) {
    if (Test-Path -Path $SystemPaths.ScheduledTasks -PathType Leaf) {
        & $SystemPaths.ScheduledTasks -RegisterAllTasks
    } else {
        Write-MasterLog "Scheduled Tasks script not found" -Level "ERROR"
    }
}

if ($Status) {
    Show-SystemStatus
}

if ($Stop) {
    if (Test-Path -Path $SystemPaths.SystemIntegration -PathType Leaf) {
        & $SystemPaths.SystemIntegration -EmergencyStop
    } else {
        Write-MasterLog "System Integration script not found" -Level "ERROR"
    }
}

if ($Test) {
    Invoke-SystemTest | Out-Null
}

if ($Update) {
    Invoke-SystemUpdate
}

if ($Help) {
    Show-Help
}

# Show status if no specific action requested
if (-not ($StartAll -or $ASG -or $LFG -or $Maintenance -or $Schedule -or $Status -or $Stop -or $Test -or $Update -or $Help)) {
    Show-SystemStatus
    Write-MasterLog "" -Level "INFO"
    Write-MasterLog "Use -Help for command reference" -Level "INFO"
<<<<<<< HEAD
}
=======
}
>>>>>>> c6b295e0d92d0143018dcdcb5ba8fd1affca0fae
