<<<<<<< HEAD

=======
>>>>>>> c6b295e0d92d0143018dcdcb5ba8fd1affca0fae
# NCC System Integration Framework v2.0.0
# Author: NCC Command Center
# Purpose: Unified system launcher integrating ASG, LFG, and maintenance systems

param(
    [switch]$ASG,           # Activate Systems Go - Full system activation
    [switch]$LFG,           # Let's F***ing Go - Cycle launch
    [switch]$Maintenance,   # Run daily maintenance
    [switch]$Status,        # Show system status
    [switch]$EmergencyStop, # Emergency system shutdown
    [switch]$FullSystem,    # Complete system activation + maintenance
    [switch]$CycleMode,     # Continuous cycle mode
    [int]$CycleIntervalMinutes = 2  # Default 2-minute cycles
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
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -Parent $ScriptDir

# Import required functions
. "$ScriptDir\NCC.Utilities.ps1"

# System configuration
$SystemConfig = @{
    ASGScript = Join-Path $ScriptDir "ASG.ps1"
    LFGScript = Join-Path $ScriptDir "LFG.Activate.ps1"
    MaintenanceScript = Join-Path $ScriptDir "NCC.DailyMaintenance.ps1"
    DesktopDisplayScript = Join-Path $ScriptDir "NCC.DesktopDisplay.ps1"
    ContinuousOpsScript = Join-Path $ScriptDir "NCC.ContinuousOperations.ps1"
    SystemLog = Join-Path $RootPath "logs\NCC_System_Integration.log"
    CycleLog = Join-Path $RootPath "logs\NCC_Cycle_Activity.log"
    EmergencyStopFile = Join-Path $RootPath "temp\EMERGENCY_STOP.txt"
}

# Ensure log directories exist
New-DirectoryIfNotExists -Path (Split-Path $SystemConfig.SystemLog -Parent)
New-DirectoryIfNotExists -Path (Split-Path $SystemConfig.CycleLog -Parent)
New-DirectoryIfNotExists -Path (Split-Path $SystemConfig.EmergencyStopFile -Parent)

function Write-SystemLog {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [SYSTEM] [$Level] $Message"

    # Write to console with color coding
    switch ($Level.ToUpper()) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "INFO"    { Write-Host $logMessage -ForegroundColor Cyan }
        default   { Write-Host $logMessage }
    }

    # Write to system log file
    try {
        $logMessage | Out-File -FilePath $SystemConfig.SystemLog -Append -Encoding UTF8
    }
    catch {
        Write-Host "Failed to write to system log: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Write-CycleLog {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [CYCLE] [$Level] $Message"

    # Write to cycle log file
    try {
        $logMessage | Out-File -FilePath $SystemConfig.CycleLog -Append -Encoding UTF8
    }
    catch {
        Write-SystemLog "Failed to write to cycle log: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Test-EmergencyStop {
    return Test-FileExists -Path $SystemConfig.EmergencyStopFile
}

function Invoke-EmergencyStop {
    Write-SystemLog "EMERGENCY STOP ACTIVATED!" -Level "ERROR"

    try {
        "EMERGENCY STOP - $(Get-Date)" | Out-File -FilePath $SystemConfig.EmergencyStopFile -Encoding UTF8
        Write-SystemLog "Emergency stop file created" -Level "WARNING"
        return $true
    }
    catch {
        Write-SystemLog "Failed to create emergency stop file: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Clear-EmergencyStop {
    if (Test-EmergencyStop) {
        try {
            Remove-Item -Path $SystemConfig.EmergencyStopFile -Force
            Write-SystemLog "Emergency stop cleared" -Level "SUCCESS"
            return $true
        }
        catch {
            Write-SystemLog "Failed to clear emergency stop: $($_.Exception.Message)" -Level "ERROR"
            return $false
        }
    }
    return $true
}

function Invoke-ASG {
    Write-SystemLog "=== ACTIVATING SYSTEMS GO (ASG) ===" -Level "INFO"

    if (-not (Test-FileExists -Path $SystemConfig.ASGScript)) {
        Write-SystemLog "ASG script not found: $($SystemConfig.ASGScript)" -Level "ERROR"
        return $false
    }

    try {
        Write-SystemLog "Executing ASG activation..." -Level "INFO"
        & $SystemConfig.ASGScript

        # Start desktop display system
        if (Test-FileExists -Path $SystemConfig.DesktopDisplayScript) {
            Write-SystemLog "Starting desktop display system..." -Level "INFO"
            & $SystemConfig.DesktopDisplayScript -StartServer
        }

        # Run initial maintenance
        if (Test-FileExists -Path $SystemConfig.MaintenanceScript) {
            Write-SystemLog "Running initial system maintenance..." -Level "INFO"
            & $SystemConfig.MaintenanceScript -RunSystemAudit
        }

        Write-SystemLog "ASG activation completed successfully" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-SystemLog "ASG activation failed: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Invoke-LFG {
    Write-SystemLog "=== LET'S F***ING GO (LFG) - CYCLE LAUNCH ===" -Level "INFO"

    if (-not (Test-FileExists -Path $SystemConfig.LFGScript)) {
        Write-SystemLog "LFG script not found: $($SystemConfig.LFGScript)" -Level "ERROR"
        return $false
    }

    try {
        Write-SystemLog "Executing LFG cycle launch..." -Level "INFO"
        & $SystemConfig.LFGScript

        # Start continuous operations
        if (Test-FileExists -Path $SystemConfig.ContinuousOpsScript) {
            Write-SystemLog "Starting continuous operations..." -Level "INFO"
            & $SystemConfig.ContinuousOpsScript -Continuous -IntervalMinutes $CycleIntervalMinutes
        }

        Write-SystemLog "LFG cycle launch completed successfully" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-SystemLog "LFG cycle launch failed: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Invoke-SystemMaintenance {
    Write-SystemLog "=== RUNNING SYSTEM MAINTENANCE ===" -Level "INFO"

    if (-not (Test-FileExists -Path $SystemConfig.MaintenanceScript)) {
        Write-SystemLog "Maintenance script not found: $($SystemConfig.MaintenanceScript)" -Level "ERROR"
        return $false
    }

    try {
        Write-SystemLog "Executing daily maintenance..." -Level "INFO"
        & $SystemConfig.MaintenanceScript -RunDailyMaintenance
        Write-SystemLog "System maintenance completed successfully" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-SystemLog "System maintenance failed: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Invoke-FullSystem {
    Write-SystemLog "=== FULL SYSTEM ACTIVATION ===" -Level "INFO"

    $results = @{
        ASG = $false
        LFG = $false
        Maintenance = $false
        Success = $false
    }

    # 1. ASG - System Activation
    $results.ASG = Invoke-ASG

    # 2. Maintenance - System Health
    $results.Maintenance = Invoke-SystemMaintenance

    # 3. LFG - Cycle Launch
    $results.LFG = Invoke-LFG

    $results.Success = $results.ASG -and $results.LFG -and $results.Maintenance

    if ($results.Success) {
        Write-SystemLog "FULL SYSTEM ACTIVATION COMPLETED SUCCESSFULLY" -Level "SUCCESS"
        Write-SystemLog "All systems operational - NCC is GO!" -Level "SUCCESS"
    } else {
        Write-SystemLog "FULL SYSTEM ACTIVATION COMPLETED WITH ISSUES" -Level "WARNING"
        Write-SystemLog "ASG: $(if ($results.ASG) { 'OK' } else { 'FAILED' })" -Level "INFO"
        Write-SystemLog "Maintenance: $(if ($results.Maintenance) { 'OK' } else { 'FAILED' })" -Level "INFO"
        Write-SystemLog "LFG: $(if ($results.LFG) { 'OK' } else { 'FAILED' })" -Level "INFO"
    }

    return $results
}

function Start-CycleMode {
    param([int]$IntervalMinutes = 2)

    Write-SystemLog "=== STARTING CYCLE MODE ===" -Level "INFO"
    Write-SystemLog "Cycle interval: $IntervalMinutes minutes" -Level "INFO"

    Clear-EmergencyStop

    $cycleCount = 0
    $startTime = Get-Date

    while (-not (Test-EmergencyStop)) {
        $cycleCount++
        $cycleStart = Get-Date

        Write-CycleLog "=== CYCLE $cycleCount STARTED ===" -Level "INFO"

        try {
            # Run cycle operations
            & $SystemConfig.ContinuousOpsScript -Continuous -IntervalMinutes $IntervalMinutes

            # Pizza party - agent synchronization
            if (Test-FileExists -Path (Join-Path $ScriptDir "NCC.PizzaParty.ps1")) {
                Write-CycleLog "Running pizza party synchronization..." -Level "INFO"
                & (Join-Path $ScriptDir "NCC.PizzaParty.ps1")
            }

            # Department head reviews and updates
            if (Test-FileExists -Path (Join-Path $ScriptDir "NCC.DeptHead.ReportCompilation.ps1")) {
                Write-CycleLog "Compiling department reports..." -Level "INFO"
                & (Join-Path $ScriptDir "NCC.DeptHead.ReportCompilation.ps1")
            }

            Write-CycleLog "=== CYCLE $cycleCount COMPLETED ===" -Level "SUCCESS"

        }
        catch {
            Write-CycleLog "Cycle $cycleCount failed: $($_.Exception.Message)" -Level "ERROR"
        }

        # Calculate cycle duration and wait
        $cycleEnd = Get-Date
        $cycleDuration = $cycleEnd - $cycleStart
        $waitTime = [TimeSpan]::FromMinutes($IntervalMinutes) - $cycleDuration

        if ($waitTime.TotalSeconds -gt 0) {
            Write-CycleLog "Waiting $($waitTime.TotalSeconds.ToString('F0')) seconds until next cycle..." -Level "INFO"
            Start-Sleep -Seconds $waitTime.TotalSeconds
        } else {
            Write-CycleLog "Cycle took longer than interval, starting next cycle immediately" -Level "WARNING"
        }

        # Emergency stop check
        if (Test-EmergencyStop) {
            Write-SystemLog "EMERGENCY STOP detected - exiting cycle mode" -Level "WARNING"
            break
        }
    }

    $totalDuration = Get-Date - $startTime
    Write-SystemLog "Cycle mode completed after $cycleCount cycles" -Level "INFO"
    Write-SystemLog "Total runtime: $($totalDuration.TotalHours.ToString('F2')) hours" -Level "INFO"
}

function Show-SystemStatus {
    Write-SystemLog "NCC System Integration Status" -Level "INFO"
    Write-SystemLog "=" * 50 -Level "INFO"

    # Check emergency stop status
    if (Test-EmergencyStop) {
        Write-SystemLog "EMERGENCY STOP: ACTIVE" -Level "ERROR"
        $stopContent = Get-Content -Path $SystemConfig.EmergencyStopFile -ErrorAction SilentlyContinue
        Write-SystemLog "Stop reason: $stopContent" -Level "WARNING"
    } else {
        Write-SystemLog "Emergency Stop: CLEAR" -Level "SUCCESS"
    }

    # Check system components
    $components = @(
        @{Name = "ASG Script"; Path = $SystemConfig.ASGScript},
        @{Name = "LFG Script"; Path = $SystemConfig.LFGScript},
        @{Name = "Maintenance Script"; Path = $SystemConfig.MaintenanceScript},
        @{Name = "Desktop Display"; Path = $SystemConfig.DesktopDisplayScript},
        @{Name = "Continuous Ops"; Path = $SystemConfig.ContinuousOpsScript}
    )

    Write-SystemLog "System Components:" -Level "INFO"
    foreach ($component in $components) {
        $status = if (Test-FileExists -Path $component.Path) { "OK" } else { "MISSING" }
        $color = if ($status -eq "OK") { "SUCCESS" } else { "ERROR" }
        Write-SystemLog "  • $($component.Name): $status" -Level $color
    }

    # Check running processes
    Write-SystemLog "Running Processes:" -Level "INFO"
    $keyProcesses = @("node", "python", "NCC.ContinuousOperations")
    foreach ($process in $keyProcesses) {
        try {
            $procCount = (Get-Process -Name $process -ErrorAction SilentlyContinue).Count
            $status = if ($procCount -gt 0) { "RUNNING ($procCount)" } else { "STOPPED" }
            $color = if ($procCount -gt 0) { "SUCCESS" } else { "WARNING" }
            Write-SystemLog "  • $process`: $status" -Level $color
        }
        catch {
            Write-SystemLog "  • $process`: ERROR" -Level "ERROR"
        }
    }

    # Check logs
    $logs = @(
        @{Name = "System Log"; Path = $SystemConfig.SystemLog},
        @{Name = "Cycle Log"; Path = $SystemConfig.CycleLog}
    )

    Write-SystemLog "Log Files:" -Level "INFO"
    foreach ($log in $logs) {
        if (Test-FileExists -Path $log.Path) {
            $logInfo = Get-Item -Path $log.Path
            $size = [math]::Round($logInfo.Length / 1KB, 2)
            Write-SystemLog "  • $($log.Name): EXISTS (${size}KB)" -Level "SUCCESS"
        } else {
            Write-SystemLog "  • $($log.Name): NOT FOUND" -Level "WARNING"
        }
    }

    Write-SystemLog "" -Level "INFO"
    Write-SystemLog "Available Commands:" -Level "INFO"
    Write-SystemLog "  .\NCC.SystemIntegration.ps1 -ASG              # Activate Systems Go" -Level "INFO"
    Write-SystemLog "  .\NCC.SystemIntegration.ps1 -LFG              # Let's F***ing Go (Cycle Launch)" -Level "INFO"
    Write-SystemLog "  .\NCC.SystemIntegration.ps1 -Maintenance      # Run system maintenance" -Level "INFO"
    Write-SystemLog "  .\NCC.SystemIntegration.ps1 -FullSystem       # Complete system activation" -Level "INFO"
    Write-SystemLog "  .\NCC.SystemIntegration.ps1 -CycleMode        # Start continuous cycle mode" -Level "INFO"
    Write-SystemLog "  .\NCC.SystemIntegration.ps1 -Status           # Show system status" -Level "INFO"
    Write-SystemLog "  .\NCC.SystemIntegration.ps1 -EmergencyStop    # Emergency system shutdown" -Level "INFO"
}

# Main execution logic
if ($FullSystem) {
    Invoke-FullSystem | Out-Null
}

if ($ASG) {
    Invoke-ASG | Out-Null
}

if ($LFG) {
    Invoke-LFG | Out-Null
}

if ($Maintenance) {
    Invoke-SystemMaintenance | Out-Null
}

if ($CycleMode) {
    Start-CycleMode -IntervalMinutes $CycleIntervalMinutes
}

if ($EmergencyStop) {
    Invoke-EmergencyStop | Out-Null
}

if ($Status) {
    Show-SystemStatus
}

# Show status if no specific action requested
if (-not ($FullSystem -or $ASG -or $LFG -or $Maintenance -or $CycleMode -or $EmergencyStop -or $Status)) {
    Show-SystemStatus
<<<<<<< HEAD
}
=======
}
>>>>>>> c6b295e0d92d0143018dcdcb5ba8fd1affca0fae
