# NCC Scheduled Tasks Manager v1.0.0
# Author: NCC Command Center
# Purpose: Manage Windows scheduled tasks for NCC system automation

param(
    [switch]$RegisterAllTasks,
    [switch]$UnregisterAllTasks,
    [switch]$ListTasks,
    [switch]$TestTasks,
    [switch]$RegisterMaintenance,
    [switch]$RegisterSystemIntegration,
    [switch]$RegisterBackup,
    [switch]$RegisterMonitoring
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Get script directory and root path
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -Parent $ScriptDir

# Task configuration
$TaskConfig = @{
    Maintenance = @{
        Name = "NCC_Daily_Maintenance"
        Script = Join-Path $ScriptDir "NCC.DailyMaintenance.ps1"
        Args = "-RunDailyMaintenance"
        Schedule = "Daily"
        Time = "02:00"
        Description = "NCC Daily Maintenance - System health checks, backups, and optimization"
    }
    SystemIntegration = @{
        Name = "NCC_System_Integration_Monitor"
        Script = Join-Path $ScriptDir "NCC.SystemIntegration.ps1"
        Args = "-Status"
        Schedule = "Hourly"
        Time = "00:00"
        Description = "NCC System Integration Monitor - Hourly status checks"
    }
    Backup = @{
        Name = "NCC_Backup_Operations"
        Script = Join-Path $ScriptDir "NCC.DailyMaintenance.ps1"
        Args = "-RunDataBackup"
        Schedule = "Daily"
        Time = "01:00"
        Description = "NCC Data Backup - Automated backup of critical system data"
    }
    Monitoring = @{
        Name = "NCC_System_Monitoring"
        Script = Join-Path $ScriptDir "NCC.DailyMaintenance.ps1"
        Args = "-RunSystemAudit"
        Schedule = "Daily"
        Time = "06:00"
        Description = "NCC System Monitoring - Daily comprehensive system audit"
    }
}

function Write-TaskLog {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [TASKS] [$Level] $Message"

    # Write to console with color coding
    switch ($Level.ToUpper()) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "INFO"    { Write-Host $logMessage -ForegroundColor Cyan }
        default   { Write-Host $logMessage }
    }
}

function Test-ScriptExists {
    param([string]$Path)

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-TaskLog "Script not found: $Path" -Level "ERROR"
        return $false
    }
    return $true
}

function Register-ScheduledTaskEx {
    param(
        [string]$TaskName,
        [string]$ScriptPath,
        [string]$Arguments,
        [string]$Schedule,
        [string]$Time,
        [string]$Description
    )

    if (-not (Test-ScriptExists -Path $ScriptPath)) {
        return $false
    }

    try {
        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-TaskLog "Task '$TaskName' already exists, updating..." -Level "INFO"
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }

        # Create task action
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" $Arguments"

        # Create task trigger based on schedule
        switch ($Schedule) {
            "Daily" {
                $trigger = New-ScheduledTaskTrigger -Daily -At $Time
            }
            "Hourly" {
                $trigger = New-ScheduledTaskTrigger -Once -At $Time -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)
            }
            "Weekly" {
                $trigger = New-ScheduledTaskTrigger -Weekly -At $Time -DaysOfWeek Monday
            }
            default {
                Write-TaskLog "Unknown schedule type: $Schedule" -Level "ERROR"
                return $false
            }
        }

        # Create task settings
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -RunOnlyIfNetworkAvailable `
            -DontStopOnIdleEnd `
            -RestartOnIdle

        # Create task principal (run as current user)
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

        # Register the task
        Register-ScheduledTask `
            -TaskName $TaskName `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Description $Description

        Write-TaskLog "Task '$TaskName' registered successfully" -Level "SUCCESS"
        Write-TaskLog "  • Schedule: $Schedule at $Time" -Level "INFO"
        Write-TaskLog "  • Script: $ScriptPath" -Level "INFO"
        Write-TaskLog "  • Args: $Arguments" -Level "INFO"

        return $true
    }
    catch {
        Write-TaskLog "Failed to register task '$TaskName': $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Unregister-ScheduledTaskEx {
    param([string]$TaskName)

    try {
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-TaskLog "Task '$TaskName' unregistered successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-TaskLog "Task '$TaskName' not found" -Level "WARNING"
            return $false
        }
    }
    catch {
        Write-TaskLog "Failed to unregister task '$TaskName': $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Register-MaintenanceTask {
    $config = $TaskConfig.Maintenance
    return Register-ScheduledTaskEx `
        -TaskName $config.Name `
        -ScriptPath $config.Script `
        -Arguments $config.Args `
        -Schedule $config.Schedule `
        -Time $config.Time `
        -Description $config.Description
}

function Register-SystemIntegrationTask {
    $config = $TaskConfig.SystemIntegration
    return Register-ScheduledTaskEx `
        -TaskName $config.Name `
        -ScriptPath $config.Script `
        -Arguments $config.Args `
        -Schedule $config.Schedule `
        -Time $config.Time `
        -Description $config.Description
}

function Register-BackupTask {
    $config = $TaskConfig.Backup
    return Register-ScheduledTaskEx `
        -TaskName $config.Name `
        -ScriptPath $config.Script `
        -Arguments $config.Args `
        -Schedule $config.Schedule `
        -Time $config.Time `
        -Description $config.Description
}

function Register-MonitoringTask {
    $config = $TaskConfig.Monitoring
    return Register-ScheduledTaskEx `
        -TaskName $config.Name `
        -ScriptPath $config.Script `
        -Arguments $config.Args `
        -Schedule $config.Schedule `
        -Time $config.Time `
        -Description $config.Description
}

function Register-AllTasks {
    Write-TaskLog "=== REGISTERING ALL NCC SCHEDULED TASKS ===" -Level "INFO"

    $results = @{
        Maintenance = $false
        SystemIntegration = $false
        Backup = $false
        Monitoring = $false
        Success = $false
    }

    $results.Maintenance = Register-MaintenanceTask
    $results.SystemIntegration = Register-SystemIntegrationTask
    $results.Backup = Register-BackupTask
    $results.Monitoring = Register-MonitoringTask

    $results.Success = $results.Maintenance -and $results.SystemIntegration -and $results.Backup -and $results.Monitoring

    if ($results.Success) {
        Write-TaskLog "All NCC scheduled tasks registered successfully" -Level "SUCCESS"
    } else {
        Write-TaskLog "Some tasks failed to register" -Level "WARNING"
        Write-TaskLog "Maintenance: $(if ($results.Maintenance) { 'OK' } else { 'FAILED' })" -Level "INFO"
        Write-TaskLog "System Integration: $(if ($results.SystemIntegration) { 'OK' } else { 'FAILED' })" -Level "INFO"
        Write-TaskLog "Backup: $(if ($results.Backup) { 'OK' } else { 'FAILED' })" -Level "INFO"
        Write-TaskLog "Monitoring: $(if ($results.Monitoring) { 'OK' } else { 'FAILED' })" -Level "INFO"
    }

    return $results
}

function Unregister-AllTasks {
    Write-TaskLog "=== UNREGISTERING ALL NCC SCHEDULED TASKS ===" -Level "INFO"

    $taskNames = $TaskConfig.Keys | ForEach-Object { $TaskConfig.$_.Name }
    $unregisteredCount = 0

    foreach ($taskName in $taskNames) {
        if (Unregister-ScheduledTaskEx -TaskName $taskName) {
            $unregisteredCount++
        }
    }

    Write-TaskLog "Unregistered $unregisteredCount NCC scheduled tasks" -Level "SUCCESS"
    return $true
}

function List-NCCTasks {
    Write-TaskLog "NCC Scheduled Tasks Status" -Level "INFO"
    Write-TaskLog "=" * 50 -Level "INFO"

    $taskNames = $TaskConfig.Keys | ForEach-Object { $TaskConfig.$_.Name }

    foreach ($taskName in $taskNames) {
        try {
            $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($task) {
                Write-TaskLog "Task: $taskName" -Level "SUCCESS"
                Write-TaskLog "  • State: $($task.State)" -Level "INFO"
                Write-TaskLog "  • Last Run: $($task.LastRunTime)" -Level "INFO"
                Write-TaskLog "  • Next Run: $($task.NextRunTime)" -Level "INFO"
                Write-TaskLog "  • Last Result: $($task.LastTaskResult)" -Level "INFO"
            } else {
                Write-TaskLog "Task: $taskName" -Level "WARNING"
                Write-TaskLog "  • Status: NOT REGISTERED" -Level "WARNING"
            }
        }
        catch {
            Write-TaskLog "Task: $taskName" -Level "ERROR"
            Write-TaskLog "  • Error: $($_.Exception.Message)" -Level "ERROR"
        }
        Write-TaskLog "" -Level "INFO"
    }
}

function Test-NCCTasks {
    Write-TaskLog "=== TESTING NCC SCHEDULED TASKS ===" -Level "INFO"

    $taskNames = $TaskConfig.Keys | ForEach-Object { $TaskConfig.$_.Name }
    $testResults = @{}

    foreach ($taskName in $taskNames) {
        try {
            $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($task) {
                # Try to run the task manually
                Write-TaskLog "Testing task: $taskName" -Level "INFO"
                Start-ScheduledTask -TaskName $taskName

                # Wait a moment for task to start
                Start-Sleep -Seconds 2

                # Check if task is running
                $updatedTask = Get-ScheduledTask -TaskName $taskName
                $isRunning = $updatedTask.State -eq "Running"

                if ($isRunning) {
                    Write-TaskLog "Task '$taskName' started successfully" -Level "SUCCESS"
                    $testResults[$taskName] = $true

                    # Stop the test task
                    Stop-ScheduledTask -TaskName $taskName
                } else {
                    Write-TaskLog "Task '$taskName' failed to start" -Level "ERROR"
                    $testResults[$taskName] = $false
                }
            } else {
                Write-TaskLog "Task '$taskName' not found" -Level "WARNING"
                $testResults[$taskName] = $false
            }
        }
        catch {
            Write-TaskLog "Failed to test task '$taskName': $($_.Exception.Message)" -Level "ERROR"
            $testResults[$taskName] = $false
        }
    }

    $passedTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
    $totalTests = $testResults.Count

    Write-TaskLog "Task testing completed: $passedTests/$totalTests tests passed" -Level $(if ($passedTests -eq $totalTests) { "SUCCESS" } else { "WARNING" })

    return $testResults
}

# Main execution logic
if ($RegisterAllTasks) {
    Register-AllTasks | Out-Null
}

if ($UnregisterAllTasks) {
    Unregister-AllTasks | Out-Null
}

if ($ListTasks) {
    List-NCCTasks
}

if ($TestTasks) {
    Test-NCCTasks | Out-Null
}

if ($RegisterMaintenance) {
    Register-MaintenanceTask | Out-Null
}

if ($RegisterSystemIntegration) {
    Register-SystemIntegrationTask | Out-Null
}

if ($RegisterBackup) {
    Register-BackupTask | Out-Null
}

if ($RegisterMonitoring) {
    Register-MonitoringTask | Out-Null
}

# Show usage if no specific action requested
if (-not ($RegisterAllTasks -or $UnregisterAllTasks -or $ListTasks -or $TestTasks -or $RegisterMaintenance -or $RegisterSystemIntegration -or $RegisterBackup -or $RegisterMonitoring)) {
    Write-TaskLog "NCC Scheduled Tasks Manager" -Level "INFO"
    Write-TaskLog "Available Commands:" -Level "INFO"
    Write-TaskLog "  .\NCC.ScheduledTasks.ps1 -RegisterAllTasks      # Register all NCC scheduled tasks" -Level "INFO"
    Write-TaskLog "  .\NCC.ScheduledTasks.ps1 -UnregisterAllTasks   # Remove all NCC scheduled tasks" -Level "INFO"
    Write-TaskLog "  .\NCC.ScheduledTasks.ps1 -ListTasks            # List status of all NCC tasks" -Level "INFO"
    Write-TaskLog "  .\NCC.ScheduledTasks.ps1 -TestTasks            # Test all NCC scheduled tasks" -Level "INFO"
    Write-TaskLog "  .\NCC.ScheduledTasks.ps1 -RegisterMaintenance  # Register daily maintenance task" -Level "INFO"
    Write-TaskLog "  .\NCC.ScheduledTasks.ps1 -RegisterSystemIntegration # Register system monitor task" -Level "INFO"
    Write-TaskLog "  .\NCC.ScheduledTasks.ps1 -RegisterBackup       # Register backup task" -Level "INFO"
    Write-TaskLog "  .\NCC.ScheduledTasks.ps1 -RegisterMonitoring   # Register monitoring task" -Level "INFO"
}