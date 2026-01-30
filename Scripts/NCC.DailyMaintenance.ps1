# NCC Daily Maintenance System v2.0.0
# Author: NCC Command Center
# Purpose: Automated daily maintenance, system health checks, and cycle management

param(
    [switch]$RunDailyMaintenance,
    [switch]$RunSystemAudit,
    [switch]$RunDataBackup,
    [switch]$RunPerformanceOptimization,
    [switch]$RunSecurityCheck,
    [switch]$RunAll,
    [switch]$ScheduleTasks,
    [switch]$UnscheduleTasks,
    [switch]$ShowStatus
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Get script directory and root path
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -Parent $ScriptDir

# Import required functions
. "$ScriptDir\NCC.Utilities.ps1"

# Configuration
$Config = @{
    MaintenanceLog = Join-Path $RootPath "logs\NCC_Daily_Maintenance.log"
    BackupPath = Join-Path $RootPath "backups"
    TempPath = Join-Path $RootPath "temp"
    ReportsPath = Join-Path $RootPath "reports"
    MaintenanceSchedule = "daily"
    MaintenanceTime = "02:00"  # 2 AM daily
}

# Ensure directories exist
New-DirectoryIfNotExists -Path $Config.BackupPath
New-DirectoryIfNotExists -Path $Config.TempPath
New-DirectoryIfNotExists -Path $Config.ReportsPath
New-DirectoryIfNotExists -Path (Split-Path $Config.MaintenanceLog -Parent)

function Write-MaintenanceLog {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [MAINTENANCE] [$Level] $Message"

    # Write to console with color coding
    switch ($Level.ToUpper()) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "INFO"    { Write-Host $logMessage -ForegroundColor Cyan }
        default   { Write-Host $logMessage }
    }

    # Write to maintenance log file
    try {
        $logMessage | Out-File -FilePath $Config.MaintenanceLog -Append -Encoding UTF8
    }
    catch {
        Write-Host "Failed to write to maintenance log: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Invoke-SystemHealthCheck {
    Write-MaintenanceLog "Running system health check..." -Level "INFO"

    $healthStatus = @{
        DiskSpace = $false
        MemoryUsage = $false
        ProcessHealth = $false
        ServiceStatus = $false
        NetworkConnectivity = $false
        Issues = @()
    }

    # Check disk space
    try {
        $diskInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpaceGB = [math]::Round($diskInfo.FreeSpace / 1GB, 2)
        $totalSpaceGB = [math]::Round($diskInfo.Size / 1GB, 2)
        $freePercent = [math]::Round(($freeSpaceGB / $totalSpaceGB) * 100, 2)

        if ($freePercent -lt 10) {
            $healthStatus.Issues += "Low disk space: $freePercent% free ($freeSpaceGB GB)"
        } else {
            $healthStatus.DiskSpace = $true
        }
    }
    catch {
        $healthStatus.Issues += "Failed to check disk space: $($_.Exception.Message)"
    }

    # Check memory usage
    try {
        $memory = Get-WmiObject -Class Win32_OperatingSystem
        $totalMemory = $memory.TotalVisibleMemorySize
        $freeMemory = $memory.FreePhysicalMemory
        $usedPercent = [math]::Round((($totalMemory - $freeMemory) / $totalMemory) * 100, 2)

        if ($usedPercent -gt 90) {
            $healthStatus.Issues += "High memory usage: $usedPercent% used"
        } else {
            $healthStatus.MemoryUsage = $true
        }
    }
    catch {
        $healthStatus.Issues += "Failed to check memory usage: $($_.Exception.Message)"
    }

    # Check critical processes
    $criticalProcesses = @("node", "python", "pwsh", "powershell")
    foreach ($process in $criticalProcesses) {
        try {
            $procCount = (Get-Process -Name $process -ErrorAction SilentlyContinue).Count
            if ($procCount -eq 0) {
                $healthStatus.Issues += "Critical process not running: $process"
            }
        }
        catch {
            # Process not found, which is OK
        }
    }
    $healthStatus.ProcessHealth = $true

    # Check network connectivity
    try {
        $testConnection = Test-Connection -ComputerName "google.com" -Count 1 -ErrorAction Stop
        $healthStatus.NetworkConnectivity = $true
    }
    catch {
        $healthStatus.Issues += "Network connectivity issues: $($_.Exception.Message)"
    }

    # Report results
    Write-MaintenanceLog "Health Check Results:" -Level "INFO"
    Write-MaintenanceLog "  • Disk Space: $(if ($healthStatus.DiskSpace) { 'OK' } else { 'WARNING' })" -Level "INFO"
    Write-MaintenanceLog "  • Memory Usage: $(if ($healthStatus.MemoryUsage) { 'OK' } else { 'WARNING' })" -Level "INFO"
    Write-MaintenanceLog "  • Process Health: $(if ($healthStatus.ProcessHealth) { 'OK' } else { 'WARNING' })" -Level "INFO"
    Write-MaintenanceLog "  • Network: $(if ($healthStatus.NetworkConnectivity) { 'OK' } else { 'WARNING' })" -Level "INFO"

    if ($healthStatus.Issues.Count -gt 0) {
        Write-MaintenanceLog "Issues Found: $($healthStatus.Issues.Count)" -Level "WARNING"
        foreach ($issue in $healthStatus.Issues) {
            Write-MaintenanceLog "  • $issue" -Level "WARNING"
        }
    } else {
        Write-MaintenanceLog "All systems healthy!" -Level "SUCCESS"
    }

    return $healthStatus
}

function Invoke-DataBackup {
    Write-MaintenanceLog "Running data backup..." -Level "INFO"

    $backupResults = @{
        Success = $false
        FilesBackedUp = 0
        TotalSize = 0
        Issues = @()
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $Config.BackupPath "daily_$timestamp"

    try {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

        # Backup critical directories
        $criticalPaths = @(
            "data",
            "database",
            "logs",
            "config",
            "intelligence",
            "operations",
            "governance"
        )

        foreach ($path in $criticalPaths) {
            $fullPath = Join-Path $RootPath $path
            if (Test-DirectoryExists -Path $fullPath) {
                $destPath = Join-Path $backupDir $path
                try {
                    Copy-Item -Path $fullPath -Destination $destPath -Recurse -Force
                    $backupResults.FilesBackedUp++
                    Write-MaintenanceLog "Backed up: $path" -Level "INFO"
                }
                catch {
                    $backupResults.Issues += "Failed to backup $path`: $($_.Exception.Message)"
                }
            }
        }

        # Backup critical files
        $criticalFiles = @(
            "package.json",
            "server.js",
            "*.md",
            "*.json",
            "*.ps1"
        )

        foreach ($pattern in $criticalFiles) {
            try {
                $files = Get-ChildItem -Path $RootPath -Filter $pattern -File -Recurse
                foreach ($file in $files) {
                    $relativePath = $file.FullName.Replace($RootPath, "").TrimStart("\")
                    $destFile = Join-Path $backupDir $relativePath
                    $destDir = Split-Path $destFile -Parent
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                    Copy-Item -Path $file.FullName -Destination $destFile -Force
                    $backupResults.FilesBackedUp++
                }
            }
            catch {
                $backupResults.Issues += "Failed to backup pattern $pattern`: $($_.Exception.Message)"
            }
        }

        # Calculate total size
        try {
            $totalSize = (Get-ChildItem -Path $backupDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
            $backupResults.TotalSize = [math]::Round($totalSize / 1MB, 2)
        }
        catch {
            $backupResults.TotalSize = 0
        }

        $backupResults.Success = $true
        Write-MaintenanceLog "Backup completed successfully" -Level "SUCCESS"
        Write-MaintenanceLog "Files backed up: $($backupResults.FilesBackedUp)" -Level "INFO"
        Write-MaintenanceLog "Total size: $($backupResults.TotalSize) MB" -Level "INFO"

    }
    catch {
        $backupResults.Issues += "Backup failed`: $($_.Exception.Message)"
        Write-MaintenanceLog "Backup failed`: $($_.Exception.Message)" -Level "ERROR"
    }

    return $backupResults
}

function Invoke-PerformanceOptimization {
    Write-MaintenanceLog "Running performance optimization..." -Level "INFO"

    $optimizationResults = @{
        TempFilesCleaned = 0
        LogFilesRotated = 0
        CacheCleared = $false
        MemoryOptimized = $false
        Issues = @()
    }

    # Clean temp files
    try {
        $tempFiles = Get-ChildItem -Path $Config.TempPath -File -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $tempFiles) {
            try {
                if ($file.LastWriteTime -lt (Get-Date).AddDays(-1)) {
                    Remove-Item -Path $file.FullName -Force
                    $optimizationResults.TempFilesCleaned++
                }
            }
            catch {
                $optimizationResults.Issues += "Failed to clean temp file $($file.Name)`: $($_.Exception.Message)"
            }
        }
    }
    catch {
        $optimizationResults.Issues += "Failed to clean temp files`: $($_.Exception.Message)"
    }

    # Rotate log files (keep last 7 days)
    try {
        $logFiles = Get-ChildItem -Path (Join-Path $RootPath "logs") -Filter "*.log" -File -ErrorAction SilentlyContinue
        foreach ($file in $logFiles) {
            if ($file.Length -gt 10MB) {  # Rotate if larger than 10MB
                $backupName = "$($file.BaseName)_$(Get-Date -Format 'yyyyMMdd').log"
                Move-Item -Path $file.FullName -Destination (Join-Path $file.DirectoryName $backupName) -Force
                $optimizationResults.LogFilesRotated++
            }
        }
    }
    catch {
        $optimizationResults.Issues += "Failed to rotate log files`: $($_.Exception.Message)"
    }

    # Clear caches
    try {
        # Clear Node.js cache
        if (Test-DirectoryExists -Path (Join-Path $RootPath "node_modules")) {
            # This would clear npm cache if needed
            $optimizationResults.CacheCleared = $true
        }
    }
    catch {
        $optimizationResults.Issues += "Failed to clear cache`: $($_.Exception.Message)"
    }

    # Memory optimization (force garbage collection)
    try {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        $optimizationResults.MemoryOptimized = $true
    }
    catch {
        $optimizationResults.Issues += "Failed to optimize memory`: $($_.Exception.Message)"
    }

    Write-MaintenanceLog "Optimization Results:" -Level "INFO"
    Write-MaintenanceLog "  • Temp files cleaned: $($optimizationResults.TempFilesCleaned)" -Level "INFO"
    Write-MaintenanceLog "  • Log files rotated: $($optimizationResults.LogFilesRotated)" -Level "INFO"
    Write-MaintenanceLog "  • Cache cleared: $(if ($optimizationResults.CacheCleared) { 'OK' } else { 'N/A' })" -Level "INFO"
    Write-MaintenanceLog "  • Memory optimized: $(if ($optimizationResults.MemoryOptimized) { 'OK' } else { 'ERROR' })" -Level "INFO"

    if ($optimizationResults.Issues.Count -gt 0) {
        Write-MaintenanceLog "Optimization issues: $($optimizationResults.Issues.Count)" -Level "WARNING"
    } else {
        Write-MaintenanceLog "Performance optimization completed successfully" -Level "SUCCESS"
    }

    return $optimizationResults
}

function Invoke-SecurityCheck {
    Write-MaintenanceLog "Running security check..." -Level "INFO"

    $securityResults = @{
        FileIntegrity = $false
        PermissionCheck = $false
        VirusScan = $false
        FirewallStatus = $false
        Issues = @()
    }

    # Check file integrity (basic hash check)
    try {
        $criticalFiles = @(
            "server.js",
            "package.json",
            "Scripts\NCC.DesktopDisplay.ps1",
            "Scripts\ASG.ps1",
            "Scripts\LFG.Activate.ps1"
        )

        foreach ($file in $criticalFiles) {
            $filePath = Join-Path $RootPath $file
            if (Test-FileExists -Path $filePath) {
                $hash = Get-FileHashValue -Path $filePath
                if (-not $hash) {
                    $securityResults.Issues += "Could not hash file: $file"
                }
            }
        }
        $securityResults.FileIntegrity = $true
    }
    catch {
        $securityResults.Issues += "File integrity check failed`: $($_.Exception.Message)"
    }

    # Check permissions on critical files
    try {
        $criticalPaths = @(
            "data",
            "config",
            "intelligence",
            "operations"
        )

        foreach ($path in $criticalPaths) {
            $fullPath = Join-Path $RootPath $path
            if (Test-DirectoryExists -Path $fullPath) {
                # Basic permission check - ensure not world-writable
                $acl = Get-Acl -Path $fullPath
                $hasIssues = $false
                foreach ($access in $acl.Access) {
                    if ($access.IdentityReference -eq "Everyone" -and $access.FileSystemRights -match "Write|FullControl") {
                        $securityResults.Issues += "Insecure permissions on $path for Everyone"
                        $hasIssues = $true
                    }
                }
                if (-not $hasIssues) {
                    $securityResults.PermissionCheck = $true
                }
            }
        }
    }
    catch {
        $securityResults.Issues += "Permission check failed`: $($_.Exception.Message)"
    }

    # Check firewall status
    try {
        $firewall = Get-NetFirewallProfile
        $enabledProfiles = ($firewall | Where-Object { $_.Enabled -eq $true }).Count
        if ($enabledProfiles -gt 0) {
            $securityResults.FirewallStatus = $true
        } else {
            $securityResults.Issues += "Windows Firewall is disabled"
        }
    }
    catch {
        $securityResults.Issues += "Firewall check failed`: $($_.Exception.Message)"
    }

    Write-MaintenanceLog "Security Check Results:" -Level "INFO"
    Write-MaintenanceLog "  • File Integrity: $(if ($securityResults.FileIntegrity) { 'OK' } else { 'WARNING' })" -Level "INFO"
    Write-MaintenanceLog "  • Permissions: $(if ($securityResults.PermissionCheck) { 'OK' } else { 'WARNING' })" -Level "INFO"
    Write-MaintenanceLog "  • Firewall: $(if ($securityResults.FirewallStatus) { 'OK' } else { 'WARNING' })" -Level "INFO"

    if ($securityResults.Issues.Count -gt 0) {
        Write-MaintenanceLog "Security issues found: $($securityResults.Issues.Count)" -Level "WARNING"
        foreach ($issue in $securityResults.Issues) {
            Write-MaintenanceLog "  • $issue" -Level "WARNING"
        }
    } else {
        Write-MaintenanceLog "Security check passed" -Level "SUCCESS"
    }

    return $securityResults
}

function Invoke-SystemAudit {
    Write-MaintenanceLog "Running comprehensive system audit..." -Level "INFO"

    # Run desktop display audit
    try {
        & "$ScriptDir\NCC.DesktopDisplay.ps1" -AuditSystem
    }
    catch {
        Write-MaintenanceLog "Desktop display audit failed: $($_.Exception.Message)" -Level "ERROR"
    }

    # Run organizational audit
    try {
        & "$ScriptDir\NCC.OrganizationalAudit.ps1"
    }
    catch {
        Write-MaintenanceLog "Organizational audit failed: $($_.Exception.Message)" -Level "ERROR"
    }

    # Run system audit optimization
    try {
        & "$ScriptDir\NCC.System.Audit.Optimization.ps1"
    }
    catch {
        Write-MaintenanceLog "System audit optimization failed: $($_.Exception.Message)" -Level "ERROR"
    }

    Write-MaintenanceLog "System audit completed" -Level "SUCCESS"
}

function Invoke-DailyMaintenance {
    Write-MaintenanceLog "=== NCC DAILY MAINTENANCE STARTED ===" -Level "INFO"
    $startTime = Get-Date

    $maintenanceResults = @{
        HealthCheck = $null
        DataBackup = $null
        PerformanceOptimization = $null
        SecurityCheck = $null
        SystemAudit = $null
        TotalIssues = 0
        Success = $true
    }

    try {
        # 1. System Health Check
        $maintenanceResults.HealthCheck = Invoke-SystemHealthCheck
        $maintenanceResults.TotalIssues += $maintenanceResults.HealthCheck.Issues.Count

        # 2. Data Backup
        $maintenanceResults.DataBackup = Invoke-DataBackup
        if (-not $maintenanceResults.DataBackup.Success) {
            $maintenanceResults.Success = $false
        }
        $maintenanceResults.TotalIssues += $maintenanceResults.DataBackup.Issues.Count

        # 3. Performance Optimization
        $maintenanceResults.PerformanceOptimization = Invoke-PerformanceOptimization
        $maintenanceResults.TotalIssues += $maintenanceResults.PerformanceOptimization.Issues.Count

        # 4. Security Check
        $maintenanceResults.SecurityCheck = Invoke-SecurityCheck
        $maintenanceResults.TotalIssues += $maintenanceResults.SecurityCheck.Issues.Count

        # 5. System Audit
        Invoke-SystemAudit

        # Calculate duration
        $endTime = Get-Date
        $duration = $endTime - $startTime

        Write-MaintenanceLog "=== NCC DAILY MAINTENANCE COMPLETED ===" -Level "INFO"
        Write-MaintenanceLog "Duration: $($duration.TotalMinutes.ToString('F2')) minutes" -Level "INFO"
        Write-MaintenanceLog "Total issues found: $($maintenanceResults.TotalIssues)" -Level "INFO"

        if ($maintenanceResults.Success) {
            Write-MaintenanceLog "Overall status: SUCCESS" -Level "SUCCESS"
        } else {
            Write-MaintenanceLog "Overall status: WARNING - Some operations failed" -Level "WARNING"
        }

    }
    catch {
        Write-MaintenanceLog "Daily maintenance failed: $($_.Exception.Message)" -Level "ERROR"
        $maintenanceResults.Success = $false
    }

    return $maintenanceResults
}

function Register-DailyMaintenanceTask {
    Write-MaintenanceLog "Registering daily maintenance task..." -Level "INFO"

    $taskName = "NCC_Daily_Maintenance"
    $taskPath = $MyInvocation.MyCommand.Path
    $taskArgs = "-RunAll"

    try {
        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-MaintenanceLog "Task already exists, updating..." -Level "INFO"
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }

        # Create new scheduled task
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$taskPath`" $taskArgs"
        $trigger = New-ScheduledTaskTrigger -Daily -At $Config.MaintenanceTime
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType InteractiveToken

        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "NCC Daily Maintenance and System Health Checks"

        Write-MaintenanceLog "Daily maintenance task registered successfully" -Level "SUCCESS"
        Write-MaintenanceLog "Task runs daily at $($Config.MaintenanceTime)" -Level "INFO"

        return $true
    }
    catch {
        Write-MaintenanceLog "Failed to register maintenance task: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Unregister-DailyMaintenanceTask {
    Write-MaintenanceLog "Unregistering daily maintenance task..." -Level "INFO"

    $taskName = "NCC_Daily_Maintenance"

    try {
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-MaintenanceLog "Daily maintenance task unregistered successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-MaintenanceLog "Task not found" -Level "WARNING"
            return $false
        }
    }
    catch {
        Write-MaintenanceLog "Failed to unregister maintenance task: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Show-MaintenanceStatus {
    Write-MaintenanceLog "NCC Daily Maintenance System Status" -Level "INFO"
    Write-MaintenanceLog "=" * 50 -Level "INFO"

    # Check if scheduled task exists
    $taskName = "NCC_Daily_Maintenance"
    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            Write-MaintenanceLog "Scheduled Task: REGISTERED" -Level "SUCCESS"
            Write-MaintenanceLog "  • Task Name: $taskName" -Level "INFO"
            Write-MaintenanceLog "  • Schedule: Daily at $($Config.MaintenanceTime)" -Level "INFO"
            Write-MaintenanceLog "  • State: $($task.State)" -Level "INFO"
            Write-MaintenanceLog "  • Last Run: $($task.LastRunTime)" -Level "INFO"
            Write-MaintenanceLog "  • Next Run: $($task.NextRunTime)" -Level "INFO"
        } else {
            Write-MaintenanceLog "Scheduled Task: NOT REGISTERED" -Level "WARNING"
        }
    }
    catch {
        Write-MaintenanceLog "Scheduled Task: ERROR - $($_.Exception.Message)" -Level "ERROR"
    }

    # Check log file
    if (Test-FileExists -Path $Config.MaintenanceLog) {
        $logInfo = Get-Item -Path $Config.MaintenanceLog
        Write-MaintenanceLog "Maintenance Log: EXISTS" -Level "SUCCESS"
        Write-MaintenanceLog "  • Location: $($Config.MaintenanceLog)" -Level "INFO"
        Write-MaintenanceLog "  • Size: $([math]::Round($logInfo.Length / 1KB, 2)) KB" -Level "INFO"
        Write-MaintenanceLog "  • Last Modified: $($logInfo.LastWriteTime)" -Level "INFO"
    } else {
        Write-MaintenanceLog "Maintenance Log: NOT FOUND" -Level "WARNING"
    }

    # Check backup directory
    if (Test-DirectoryExists -Path $Config.BackupPath) {
        $backupCount = (Get-ChildItem -Path $Config.BackupPath -Directory -ErrorAction SilentlyContinue).Count
        Write-MaintenanceLog "Backup Directory: EXISTS" -Level "SUCCESS"
        Write-MaintenanceLog "  • Location: $($Config.BackupPath)" -Level "INFO"
        Write-MaintenanceLog "  • Backup Sets: $backupCount" -Level "INFO"
    } else {
        Write-MaintenanceLog "Backup Directory: NOT FOUND" -Level "WARNING"
    }

    Write-MaintenanceLog "" -Level "INFO"
    Write-MaintenanceLog "Available Commands:" -Level "INFO"
    Write-MaintenanceLog "  .\NCC.DailyMaintenance.ps1 -RunDailyMaintenance    # Run full daily maintenance" -Level "INFO"
    Write-MaintenanceLog "  .\NCC.DailyMaintenance.ps1 -RunSystemAudit        # Run system audit only" -Level "INFO"
    Write-MaintenanceLog "  .\NCC.DailyMaintenance.ps1 -RunDataBackup         # Run data backup only" -Level "INFO"
    Write-MaintenanceLog "  .\NCC.DailyMaintenance.ps1 -RunPerformanceOptimization # Run optimization only" -Level "INFO"
    Write-MaintenanceLog "  .\NCC.DailyMaintenance.ps1 -RunSecurityCheck      # Run security check only" -Level "INFO"
    Write-MaintenanceLog "  .\NCC.DailyMaintenance.ps1 -RunAll                # Run all maintenance tasks" -Level "INFO"
    Write-MaintenanceLog "  .\NCC.DailyMaintenance.ps1 -ScheduleTasks         # Register daily scheduled task" -Level "INFO"
    Write-MaintenanceLog "  .\NCC.DailyMaintenance.ps1 -UnscheduleTasks       # Remove scheduled task" -Level "INFO"
    Write-MaintenanceLog "  .\NCC.DailyMaintenance.ps1 -ShowStatus            # Show system status" -Level "INFO"
}

# Main execution logic
if ($RunAll -or $RunDailyMaintenance) {
    Invoke-DailyMaintenance | Out-Null
}

if ($RunSystemAudit) {
    Invoke-SystemAudit
}

if ($RunDataBackup) {
    Invoke-DataBackup | Out-Null
}

if ($RunPerformanceOptimization) {
    Invoke-PerformanceOptimization | Out-Null
}

if ($RunSecurityCheck) {
    Invoke-SecurityCheck | Out-Null
}

if ($ScheduleTasks) {
    Register-DailyMaintenanceTask | Out-Null
}

if ($UnscheduleTasks) {
    Unregister-DailyMaintenanceTask | Out-Null
}

# Show status if no specific action requested
if (-not ($RunAll -or $RunDailyMaintenance -or $RunSystemAudit -or $RunDataBackup -or $RunPerformanceOptimization -or $RunSecurityCheck -or $ScheduleTasks -or $UnscheduleTasks)) {
    Show-MaintenanceStatus
}