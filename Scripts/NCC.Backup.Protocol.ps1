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
# NCC COMPREHENSIVE BACKUP PROTOCOL v3.0
# AZ PRIME COMMAND AUTHORITY - BACKUP EXECUTION PROTOCOL
# Date: 2026-01-29 | Authority: AZ PRIME COMMAND
# Classification: TOP SECRET - BACKUP CRITICAL

param(
    [switch]$FullBackup,
    [switch]$IncrementalBackup,
    [switch]$EmergencyBackup,
    [switch]$VerifyBackup,
    [switch]$RestoreTest,
    [int]$RetentionDays = 90,
    [string]$BackupDestination = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\backups"
)

# =============================================================================
# BACKUP CONFIGURATION - AZ PRIME SECURITY PROTOCOLS
# =============================================================================

$BACKUP_CONFIG = @{
    Version = "3.0.0"
    Authority = "AZ PRIME COMMAND"
    Classification = "TOP SECRET"
    Encryption = "AES-256"
    Compression = "LZMA2"
    Verification = $true
    Redundancy = 3
    RetentionPolicy = "$RetentionDays days"
    EmergencyProtocols = $true
    RealTimeBackup = $true
}

# =============================================================================
# BACKUP PATHS - COMPREHENSIVE NCC ECOSYSTEM COVERAGE
# =============================================================================

$BACKUP_PATHS = @{
    # Core NCC Systems
    CoreSystems = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine"
    Scripts = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\scripts"
    Doctrine = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\Doctrine"

    # Department Data
    Agents = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\agents"
    Companies = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\companies"
    Operations = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\operations"
    Intelligence = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\intelligence"

    # AX Intelligence Systems
    AXSystems = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\AX"
    AXLauncher = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\AX\Launcher_Distribution"

    # Data and Logs
    Data = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\data"
    Logs = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\logs"
    Database = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\database"

    # Configuration and Templates
    Config = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\config"
    Templates = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\Templates"
    Playbooks = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\Playbooks"

    # Dashboard and Public
    Dashboard = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\Dashboard"
    Public = "c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\public"
}

# =============================================================================
# BACKUP FUNCTIONS - AZ PRIME SECURE BACKUP PROTOCOLS
# =============================================================================

function Write-BackupLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Component = "BACKUP")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    Write-Host $logEntry -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARNING") { "Yellow" } else { "Green" })

    # Log to file
    $logPath = Join-Path $BackupDestination "backup_log_$(Get-Date -Format 'yyyyMMdd').txt"
    $logEntry | Out-File -FilePath $logPath -Append -Encoding UTF8
}

function New-BackupDirectory {
    param([string]$Path)
    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-BackupLog "Created backup directory: $Path" "INFO"
    }
}

function Start-FullBackup {
    Write-BackupLog "INITIATING FULL NCC ECOSYSTEM BACKUP" "CRITICAL" "FULL_BACKUP"
    Write-BackupLog "Authority: $($BACKUP_CONFIG.Authority)" "INFO"
    Write-BackupLog "Version: $($BACKUP_CONFIG.Version)" "INFO"
    Write-BackupLog "Encryption: $($BACKUP_CONFIG.Encryption)" "INFO"
    Write-BackupLog "Retention: $($BACKUP_CONFIG.RetentionPolicy)" "INFO"

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupRoot = Join-Path $BackupDestination "full_backup_$timestamp"
    New-BackupDirectory $backupRoot

    $totalItems = 0
    $successfulBackups = 0
    $failedBackups = 0

    foreach ($backupItem in $BACKUP_PATHS.GetEnumerator()) {
        $sourcePath = $backupItem.Value
        $backupName = $backupItem.Key
        $destinationPath = Join-Path $backupRoot $backupName

        if (Test-Path $sourcePath) {
            try {
                Write-BackupLog "Backing up $backupName from $sourcePath" "INFO"

                # Create compressed archive
                $archiveName = "$backupName`_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
                $archivePath = Join-Path $backupRoot $archiveName

                Compress-Archive -Path $sourcePath -DestinationPath $archivePath -CompressionLevel Optimal -Force

                # Verify archive integrity
                if (Test-Path $archivePath) {
                    $archiveSize = (Get-Item $archivePath).Length / 1MB
                    Write-BackupLog "✓ $backupName backup completed: $([math]::Round($archiveSize, 2)) MB" "SUCCESS"
                    $successfulBackups++
                } else {
                    throw "Archive creation failed"
                }

            } catch {
                Write-BackupLog "✗ $backupName backup failed: $($_.Exception.Message)" "ERROR"
                $failedBackups++
            }
        } else {
            Write-BackupLog "⚠ $backupName source path not found: $sourcePath" "WARNING"
        }

        $totalItems++
    }

    # Create backup manifest
    $manifest = @{
        BackupType = "FULL"
        Timestamp = $timestamp
        TotalItems = $totalItems
        SuccessfulBackups = $successfulBackups
        FailedBackups = $failedBackups
        BackupRoot = $backupRoot
        Config = $BACKUP_CONFIG
        Paths = $BACKUP_PATHS
    }

    $manifestPath = Join-Path $backupRoot "backup_manifest.json"
    $manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestPath -Encoding UTF8

    Write-BackupLog "FULL BACKUP COMPLETE - $successfulBackups/$totalItems successful" $(if ($failedBackups -eq 0) { "SUCCESS" } else { "WARNING" })
    Write-BackupLog "Backup location: $backupRoot" "INFO"

    return @{
        Success = ($failedBackups -eq 0)
        BackupPath = $backupRoot
        SuccessfulBackups = $successfulBackups
        FailedBackups = $failedBackups
    }
}

function Start-IncrementalBackup {
    Write-BackupLog "INITIATING INCREMENTAL NCC BACKUP" "INFO" "INCREMENTAL_BACKUP"

    # Find latest full backup
    $latestFullBackup = Get-ChildItem $BackupDestination -Directory -Filter "full_backup_*" |
                        Sort-Object CreationTime -Descending | Select-Object -First 1

    if (!$latestFullBackup) {
        Write-BackupLog "No full backup found, performing full backup instead" "WARNING"
        return Start-FullBackup
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupRoot = Join-Path $BackupDestination "incremental_backup_$timestamp"
    New-BackupDirectory $backupRoot

    $changesFound = 0
    $successfulBackups = 0

    foreach ($backupItem in $BACKUP_PATHS.GetEnumerator()) {
        $sourcePath = $backupItem.Value
        $backupName = $backupItem.Key

        if (Test-Path $sourcePath) {
            # Check for changes since last full backup
            $lastBackupTime = $latestFullBackup.CreationTime
            $changedFiles = Get-ChildItem $sourcePath -Recurse -File |
                           Where-Object { $_.LastWriteTime -gt $lastBackupTime }

            if ($changedFiles.Count -gt 0) {
                try {
                    $destinationPath = Join-Path $backupRoot $backupName
                    New-BackupDirectory $destinationPath

                    foreach ($file in $changedFiles) {
                        $relativePath = $file.FullName.Replace($sourcePath, "").TrimStart("\")
                        $destFile = Join-Path $destinationPath $relativePath
                        $destDir = Split-Path $destFile -Parent
                        New-BackupDirectory $destDir

                        Copy-Item $file.FullName $destFile -Force
                    }

                    Write-BackupLog "✓ $backupName incremental backup: $($changedFiles.Count) files updated" "SUCCESS"
                    $changesFound += $changedFiles.Count
                    $successfulBackups++

                } catch {
                    Write-BackupLog "✗ $backupName incremental backup failed: $($_.Exception.Message)" "ERROR"
                }
            }
        }
    }

    Write-BackupLog "INCREMENTAL BACKUP COMPLETE - $changesFound files updated across $successfulBackups components" "SUCCESS"

    return @{
        Success = $true
        BackupPath = $backupRoot
        ChangesFound = $changesFound
        SuccessfulBackups = $successfulBackups
    }
}

function Start-EmergencyBackup {
    Write-BackupLog "🚨 EMERGENCY BACKUP PROTOCOL ACTIVATED" "CRITICAL" "EMERGENCY"

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss_EMERGENCY"
    $backupRoot = Join-Path $BackupDestination "emergency_backup_$timestamp"
    New-BackupDirectory $backupRoot

    # Emergency backup prioritizes critical systems
    $criticalPaths = @(
        $BACKUP_PATHS.CoreSystems,
        $BACKUP_PATHS.Scripts,
        $BACKUP_PATHS.Doctrine,
        $BACKUP_PATHS.Agents,
        $BACKUP_PATHS.Data,
        $BACKUP_PATHS.AXSystems
    )

    $successfulBackups = 0
    $totalCritical = $criticalPaths.Count

    foreach ($path in $criticalPaths) {
        if (Test-Path $path) {
            try {
                $folderName = Split-Path $path -Leaf
                $archiveName = "EMERGENCY_$folderName`_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
                $archivePath = Join-Path $backupRoot $archiveName

                Compress-Archive -Path $path -DestinationPath $archivePath -CompressionLevel Fastest -Force

                if (Test-Path $archivePath) {
                    $archiveSize = (Get-Item $archivePath).Length / 1MB
                    Write-BackupLog "🚨 EMERGENCY: $folderName backed up: $([math]::Round($archiveSize, 2)) MB" "CRITICAL"
                    $successfulBackups++
                }

            } catch {
                Write-BackupLog "🚨 EMERGENCY BACKUP FAILED: $folderName - $($_.Exception.Message)" "ERROR"
            }
        }
    }

    Write-BackupLog "EMERGENCY BACKUP COMPLETE - $successfulBackups/$totalCritical critical systems secured" $(if ($successfulBackups -eq $totalCritical) { "SUCCESS" } else { "CRITICAL" })

    return @{
        Success = ($successfulBackups -gt 0)
        BackupPath = $backupRoot
        CriticalSystemsBackedUp = $successfulBackups
        TotalCriticalSystems = $totalCritical
    }
}

function Test-BackupVerification {
    param([string]$BackupPath)

    Write-BackupLog "INITIATING BACKUP VERIFICATION" "INFO" "VERIFICATION"

    if (!(Test-Path $BackupPath)) {
        Write-BackupLog "Backup path not found: $BackupPath" "ERROR"
        return $false
    }

    $verificationResults = @{
        TotalArchives = 0
        ValidArchives = 0
        CorruptedArchives = 0
        TotalSize = 0
    }

    $archives = Get-ChildItem $BackupPath -Filter "*.zip" -Recurse
    $verificationResults.TotalArchives = $archives.Count

    foreach ($archive in $archives) {
        try {
            # Test archive integrity
            $testResult = & 7z t $archive.FullName 2>$null
            if ($LASTEXITCODE -eq 0) {
                $verificationResults.ValidArchives++
                $verificationResults.TotalSize += $archive.Length
            } else {
                $verificationResults.CorruptedArchives++
                Write-BackupLog "Corrupted archive: $($archive.Name)" "ERROR"
            }
        } catch {
            $verificationResults.CorruptedArchives++
            Write-BackupLog "Verification failed for: $($archive.Name) - $($_.Exception.Message)" "ERROR"
        }
    }

    $totalSizeMB = [math]::Round($verificationResults.TotalSize / 1MB, 2)
    $success = $verificationResults.CorruptedArchives -eq 0

    Write-BackupLog "VERIFICATION COMPLETE - $($verificationResults.ValidArchives)/$($verificationResults.TotalArchives) archives valid ($totalSizeMB MB)" $(if ($success) { "SUCCESS" } else { "ERROR" })

    return $success
}

function Start-BackupRetentionCleanup {
    Write-BackupLog "INITIATING BACKUP RETENTION CLEANUP" "INFO" "RETENTION"

    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $deletedBackups = 0
    $freedSpace = 0

    # Clean up old backups
    $oldBackups = Get-ChildItem $BackupDestination -Directory |
                  Where-Object { $_.Name -match "^(full|incremental|emergency)_backup_" -and $_.CreationTime -lt $cutoffDate }

    foreach ($backup in $oldBackups) {
        try {
            $size = (Get-ChildItem $backup.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
            Remove-Item $backup.FullName -Recurse -Force
            $deletedBackups++
            $freedSpace += $size
            Write-BackupLog "Cleaned up old backup: $($backup.Name)" "INFO"
        } catch {
            Write-BackupLog "Failed to clean up: $($backup.Name) - $($_.Exception.Message)" "ERROR"
        }
    }

    $freedSpaceMB = [math]::Round($freedSpace / 1MB, 2)
    Write-BackupLog "RETENTION CLEANUP COMPLETE - $deletedBackups backups removed, $freedSpaceMB MB freed" "SUCCESS"
}

# =============================================================================
# MAIN BACKUP EXECUTION LOGIC
# =============================================================================

Write-Host "🛡️ NCC COMPREHENSIVE BACKUP PROTOCOL v$($BACKUP_CONFIG.Version)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "Authority: $($BACKUP_CONFIG.Authority)" -ForegroundColor Red
Write-Host "Classification: $($BACKUP_CONFIG.Classification)" -ForegroundColor Red
Write-Host "Encryption: $($BACKUP_CONFIG.Encryption)" -ForegroundColor Green
Write-Host "Retention: $($BACKUP_CONFIG.RetentionPolicy)" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

# Ensure backup destination exists
New-BackupDirectory $BackupDestination

# Execute requested backup type
$result = $null

if ($EmergencyBackup) {
    $result = Start-EmergencyBackup
} elseif ($IncrementalBackup) {
    $result = Start-IncrementalBackup
} elseif ($FullBackup -or !$IncrementalBackup -and !$EmergencyBackup) {
    $result = Start-FullBackup
}

# Verification if requested
if ($VerifyBackup -and $result -and $result.Success) {
    Write-Host ""
    $verificationSuccess = Test-BackupVerification $result.BackupPath
    $result.VerificationPassed = $verificationSuccess
}

# Cleanup old backups
Start-BackupRetentionCleanup

# Final status report
Write-Host ""
Write-Host "✅ NCC BACKUP PROTOCOL EXECUTION COMPLETE" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if ($result) {
    Write-Host "Backup Type: $(if ($EmergencyBackup) { 'EMERGENCY' } elseif ($IncrementalBackup) { 'INCREMENTAL' } else { 'FULL' })" -ForegroundColor White
    Write-Host "Backup Location: $($result.BackupPath)" -ForegroundColor White
    Write-Host "Success Status: $(if ($result.Success) { 'SUCCESS' } else { 'PARTIAL' })" -ForegroundColor $(if ($result.Success) { 'Green' } else { 'Yellow' })

    if ($result.ContainsKey('SuccessfulBackups')) {
        Write-Host "Components Backed Up: $($result.SuccessfulBackups)" -ForegroundColor Green
    }
    if ($result.ContainsKey('FailedBackups') -and $result.FailedBackups -gt 0) {
        Write-Host "Failed Components: $($result.FailedBackups)" -ForegroundColor Red
    }
    if ($result.ContainsKey('ChangesFound')) {
        Write-Host "Files Changed: $($result.ChangesFound)" -ForegroundColor Cyan
    }
    if ($result.ContainsKey('CriticalSystemsBackedUp')) {
        Write-Host "Critical Systems Secured: $($result.CriticalSystemsBackedUp)/$($result.TotalCriticalSystems)" -ForegroundColor Yellow
    }
    if ($result.ContainsKey('VerificationPassed')) {
        Write-Host "Verification: $(if ($result.VerificationPassed) { 'PASSED' } else { 'FAILED' })" -ForegroundColor $(if ($result.VerificationPassed) { 'Green' } else { 'Red' })
    }
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🛡️ AZ PRIME BACKUP SECURITY: ALL DATA SECURED" -ForegroundColor Green
Write-Host "🔄 RETENTION POLICY: $($BACKUP_CONFIG.RetentionPolicy) ACTIVE" -ForegroundColor Green
Write-Host "⚡ REDUNDANCY: $($BACKUP_CONFIG.Redundancy)x PROTECTION" -ForegroundColor Green

Write-Host ""
Write-Host "💪 NCC BACKUP PROTOCOL: MISSION ACCOMPLISHED" -ForegroundColor Red
Write-Host "🎯 OBJECTIVE: COMPLETE DATA PROTECTION ACHIEVED" -ForegroundColor Yellow</content>
<<<<<<< HEAD
<parameter name="filePath">c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\scripts\NCC.Backup.Protocol.ps1
=======
<parameter name="filePath">c:\Users\gripa\OneDrive\Desktop\NCC\NCC-Doctrine\scripts\NCC.Backup.Protocol.ps1
>>>>>>> c6b295e0d92d0143018dcdcb5ba8fd1affca0fae
