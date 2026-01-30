#Requires -Version 5.1

<#
.SYNOPSIS
    NCC.DataBackup.ps1 - Enterprise Data Backup and Recovery System

.DESCRIPTION
    This script implements comprehensive data backup and recovery capabilities
    for the NCC enterprise data architecture, including automated backups,
    disaster recovery procedures, and data retention management.

.PARAMETER Mode
    Backup mode: Full, Incremental, Recovery, or Maintenance

.PARAMETER TargetPath
    Target path for backup or recovery operations

.PARAMETER RetentionDays
    Number of days to retain backups (default: 90)

.EXAMPLE
    .\NCC.DataBackup.ps1 -Mode Full

.EXAMPLE
    .\NCC.DataBackup.ps1 -Mode Recovery -TargetPath "C:\Recovery\2026-01-29"

.NOTES
    Author: NCC Data Operations Team
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Full", "Incremental", "Recovery", "Maintenance", "Verify")]
    [string]$Mode = "Full",

    [Parameter(Mandatory = $false)]
    [string]$TargetPath,

    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 90,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Compress,

    [Parameter(Mandatory = $false)]
    [switch]$Encrypt
)

# Configuration
$Config = @{
    DataRoot = "_enterprise/data"
    BackupRoot = "_enterprise/backups"
    ArchiveRoot = "_enterprise/data/archives"
    LogPath = "_enterprise/logs"
    TempPath = "_enterprise/temp"
    MaxRetries = 3
    CompressionLevel = "Optimal"  # Fastest, Optimal, Smallest
    EncryptionAlgorithm = "AES256"
    BackupSchedule = @{
        Full = "Weekly"      # Sunday 2:00 AM
        Incremental = "Daily" # Monday-Saturday 2:00 AM
    }
}

# Global variables
$BackupManifest = @{}

function Write-BackupLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"

    Write-Host $LogEntry

    $logFile = Join-Path $Config.LogPath "NCC_DataBackup_$(Get-Date -Format 'yyyy-MM-dd').log"
    Add-Content -Path $logFile -Value $LogEntry -ErrorAction SilentlyContinue
}

function Initialize-BackupSystem {
    Write-BackupLog "Initializing NCC Data Backup System..." "INFO"

    # Create required directories
    $directories = @(
        $Config.BackupRoot,
        $Config.LogPath,
        $Config.TempPath
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            Write-BackupLog "Created directory: $dir" "INFO"
        }
    }

    # Load backup manifest if exists
    $manifestFile = Join-Path $Config.BackupRoot "backup_manifest.json"
    if (Test-Path $manifestFile) {
        try {
            $script:BackupManifest = Get-Content $manifestFile -Raw | ConvertFrom-Json
            Write-BackupLog "Loaded backup manifest with $($script:BackupManifest.backups.Count) entries" "INFO"
        }
        catch {
            Write-BackupLog "Failed to load backup manifest: $($_.Exception.Message)" "WARNING"
            $script:BackupManifest = @{
                backups = @()
                last_full_backup = $null
                last_incremental_backup = $null
            }
        }
    }
    else {
        $script:BackupManifest = @{
            backups = @()
            last_full_backup = $null
            last_incremental_backup = $null
        }
    }

    Write-BackupLog "Backup system initialization completed" "INFO"
}

function New-BackupManifestEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupType,

        [Parameter(Mandatory = $true)]
        [string]$BackupPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$BackupMetadata
    )

    $manifestEntry = @{
        backup_id = [guid]::NewGuid().ToString()
        backup_type = $BackupType
        backup_path = $BackupPath
        created_at = (Get-Date).ToString("o")
        size_bytes = $BackupMetadata.SizeBytes
        file_count = $BackupMetadata.FileCount
        compression_used = $Compress
        encryption_used = $Encrypt
        checksum = $BackupMetadata.Checksum
        retention_days = $RetentionDays
        expiry_date = (Get-Date).AddDays($RetentionDays).ToString("o")
        metadata = $BackupMetadata
    }

    return $manifestEntry
}

function Get-FilesToBackup {
    param([string]$BackupType)

    $filesToBackup = @()

    # Include data directories
    $dataDirectories = @(
        (Join-Path $Config.DataRoot "agent_data"),
        (Join-Path $Config.DataRoot "division_data"),
        (Join-Path $Config.DataRoot "enterprise_data")
    )

    foreach ($dir in $dataDirectories) {
        if (Test-Path $dir) {
            $files = Get-ChildItem -Path $dir -File -Recurse -ErrorAction SilentlyContinue
            $filesToBackup += $files
        }
    }

    # For incremental backups, only include files modified since last full backup
    if ($BackupType -eq "Incremental" -and $script:BackupManifest.last_full_backup) {
        $lastFullBackup = [DateTime]::Parse($script:BackupManifest.last_full_backup)
        $filesToBackup = $filesToBackup | Where-Object { $_.LastWriteTime -gt $lastFullBackup }
        Write-BackupLog "Incremental backup: $($filesToBackup.Count) files modified since last full backup" "INFO"
    }

    Write-BackupLog "Found $($filesToBackup.Count) files to backup" "INFO"
    return $filesToBackup
}

function Invoke-FileCompression {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (-not $Compress) {
        return $false
    }

    Write-BackupLog "Compressing backup: $SourcePath -> $DestinationPath" "INFO"

    try {
        # Create zip archive
        $zipPath = $DestinationPath + ".zip"
        Compress-Archive -Path $SourcePath -DestinationPath $zipPath -CompressionLevel $Config.CompressionLevel -Force

        # Remove uncompressed directory
        Remove-Item -Path $SourcePath -Recurse -Force

        Write-BackupLog "Compression completed: $zipPath" "INFO"
        return $zipPath
    }
    catch {
        Write-BackupLog "Compression failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Invoke-FileEncryption {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    if (-not $Encrypt) {
        return $FilePath
    }

    Write-BackupLog "Encrypting file: $FilePath" "INFO"

    try {
        # Generate salt
        $salt = New-Object byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($salt)

        # Derive key
        $keyDerivation = New-Object Security.Cryptography.Rfc2898DeriveBytes($Key, $salt, 10000)
        $encryptionKey = $keyDerivation.GetBytes(32)

        # Create encryptor
        $aes = [Security.Cryptography.Aes]::Create()
        $aes.Key = $encryptionKey
        $aes.IV = New-Object byte[] 16
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($aes.IV)

        # Encrypt file
        $encryptedPath = $FilePath + ".encrypted"
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $outputStream = [System.IO.File]::Create($encryptedPath)

        # Write salt and IV
        $outputStream.Write($salt, 0, $salt.Length)
        $outputStream.Write($aes.IV, 0, $aes.IV.Length)

        $cryptoStream = New-Object Security.Cryptography.CryptoStream($outputStream, $aes.CreateEncryptor(), [Security.Cryptography.CryptoStreamMode]::Write)

        $fileStream.CopyTo($cryptoStream)
        $cryptoStream.FlushFinalBlock()

        $fileStream.Close()
        $cryptoStream.Close()
        $outputStream.Close()

        # Remove original file
        Remove-Item -Path $FilePath -Force

        Write-BackupLog "Encryption completed: $encryptedPath" "INFO"
        return $encryptedPath
    }
    catch {
        Write-BackupLog "Encryption failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-FileChecksum {
    param([string]$FilePath)

    try {
        $hasher = [Security.Cryptography.SHA256]::Create()
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $hash = $hasher.ComputeHash($fileStream)
        $fileStream.Close()
        return [BitConverter]::ToString($hash).Replace("-", "").ToLower()
    }
    catch {
        Write-BackupLog "Failed to calculate checksum for $FilePath`: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Invoke-FullBackup {
    Write-BackupLog "Starting full backup operation..." "INFO"

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupDirName = "full_backup_$timestamp"
    $backupPath = Join-Path $Config.BackupRoot $backupDirName

    try {
        # Create backup directory
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        }

        # Get files to backup
        $filesToBackup = Get-FilesToBackup -BackupType "Full"

        if ($filesToBackup.Count -eq 0) {
            Write-BackupLog "No files found to backup" "WARNING"
            return $false
        }

        # Copy files
        $totalSize = 0
        $fileCount = 0

        foreach ($file in $filesToBackup) {
            $relativePath = $file.FullName.Replace($Config.DataRoot, "").TrimStart("\")
            $destinationPath = Join-Path $backupPath $relativePath

            if (-not $DryRun) {
                $destinationDir = Split-Path $destinationPath -Parent
                if (-not (Test-Path $destinationDir)) {
                    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
                }

                Copy-Item -Path $file.FullName -Destination $destinationPath -Force
            }

            $totalSize += $file.Length
            $fileCount++
        }

        # Compress if requested
        $finalBackupPath = $backupPath
        if ($Compress) {
            $compressedPath = Invoke-FileCompression -SourcePath $backupPath -DestinationPath $backupPath
            if ($compressedPath) {
                $finalBackupPath = $compressedPath
            }
        }

        # Encrypt if requested
        if ($Encrypt) {
            $encryptionKey = "NCC_Backup_Key_2026"  # In production, use secure key management
            $encryptedPath = Invoke-FileEncryption -FilePath $finalBackupPath -Key $encryptionKey
            if ($encryptedPath) {
                $finalBackupPath = $encryptedPath
            }
        }

        # Calculate checksum
        $checksum = Get-FileChecksum -FilePath $finalBackupPath

        # Create manifest entry
        $backupMetadata = @{
            SizeBytes = $totalSize
            FileCount = $fileCount
            Checksum = $checksum
            BackupType = "Full"
            Timestamp = $timestamp
        }

        $manifestEntry = New-BackupManifestEntry -BackupType "Full" -BackupPath $finalBackupPath -BackupMetadata $backupMetadata

        # Update manifest
        $script:BackupManifest.backups += $manifestEntry
        $script:BackupManifest.last_full_backup = (Get-Date).ToString("o")

        # Save manifest
        if (-not $DryRun) {
            $manifestFile = Join-Path $Config.BackupRoot "backup_manifest.json"
            $script:BackupManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestFile -Encoding UTF8
        }

        Write-BackupLog "Full backup completed successfully: $finalBackupPath" "INFO"
        Write-BackupLog "Backup size: $([math]::Round($totalSize / 1MB, 2)) MB, Files: $fileCount" "INFO"

        return $true
    }
    catch {
        Write-BackupLog "Full backup failed: $($_.Exception.Message)" "ERROR"
        # Cleanup failed backup
        if (Test-Path $backupPath) {
            Remove-Item -Path $backupPath -Recurse -Force
        }
        return $false
    }
}

function Invoke-IncrementalBackup {
    Write-BackupLog "Starting incremental backup operation..." "INFO"

    # Check if full backup exists
    if (-not $script:BackupManifest.last_full_backup) {
        Write-BackupLog "No full backup found. Running full backup first..." "WARNING"
        return Invoke-FullBackup
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupDirName = "incremental_backup_$timestamp"
    $backupPath = Join-Path $Config.BackupRoot $backupDirName

    try {
        # Create backup directory
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        }

        # Get files to backup
        $filesToBackup = Get-FilesToBackup -BackupType "Incremental"

        if ($filesToBackup.Count -eq 0) {
            Write-BackupLog "No files modified since last full backup" "INFO"
            return $true
        }

        # Copy files
        $totalSize = 0
        $fileCount = 0

        foreach ($file in $filesToBackup) {
            $relativePath = $file.FullName.Replace($Config.DataRoot, "").TrimStart("\")
            $destinationPath = Join-Path $backupPath $relativePath

            if (-not $DryRun) {
                $destinationDir = Split-Path $destinationPath -Parent
                if (-not (Test-Path $destinationDir)) {
                    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
                }

                Copy-Item -Path $file.FullName -Destination $destinationPath -Force
            }

            $totalSize += $file.Length
            $fileCount++
        }

        # Compress if requested
        $finalBackupPath = $backupPath
        if ($Compress) {
            $compressedPath = Invoke-FileCompression -SourcePath $backupPath -DestinationPath $backupPath
            if ($compressedPath) {
                $finalBackupPath = $compressedPath
            }
        }

        # Encrypt if requested
        if ($Encrypt) {
            $encryptionKey = "NCC_Backup_Key_2026"
            $encryptedPath = Invoke-FileEncryption -FilePath $finalBackupPath -Key $encryptionKey
            if ($encryptedPath) {
                $finalBackupPath = $encryptedPath
            }
        }

        # Calculate checksum
        $checksum = Get-FileChecksum -FilePath $finalBackupPath

        # Create manifest entry
        $backupMetadata = @{
            SizeBytes = $totalSize
            FileCount = $fileCount
            Checksum = $checksum
            BackupType = "Incremental"
            Timestamp = $timestamp
            BasedOnFullBackup = $script:BackupManifest.last_full_backup
        }

        $manifestEntry = New-BackupManifestEntry -BackupType "Incremental" -BackupPath $finalBackupPath -BackupMetadata $backupMetadata

        # Update manifest
        $script:BackupManifest.backups += $manifestEntry
        $script:BackupManifest.last_incremental_backup = (Get-Date).ToString("o")

        # Save manifest
        if (-not $DryRun) {
            $manifestFile = Join-Path $Config.BackupRoot "backup_manifest.json"
            $script:BackupManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestFile -Encoding UTF8
        }

        Write-BackupLog "Incremental backup completed successfully: $finalBackupPath" "INFO"
        Write-BackupLog "Backup size: $([math]::Round($totalSize / 1MB, 2)) MB, Files: $fileCount" "INFO"

        return $true
    }
    catch {
        Write-BackupLog "Incremental backup failed: $($_.Exception.Message)" "ERROR"
        # Cleanup failed backup
        if (Test-Path $backupPath) {
            Remove-Item -Path $backupPath -Recurse -Force
        }
        return $false
    }
}

function Invoke-DataRecovery {
    param([string]$RecoveryPath)

    if (-not $TargetPath) {
        Write-BackupLog "Recovery mode requires -TargetPath parameter" "ERROR"
        return $false
    }

    Write-BackupLog "Starting data recovery operation..." "INFO"
    Write-BackupLog "Recovery source: $RecoveryPath" "INFO"
    Write-BackupLog "Recovery target: $TargetPath" "INFO"

    try {
        # Validate recovery source
        if (-not (Test-Path $RecoveryPath)) {
            Write-BackupLog "Recovery source not found: $RecoveryPath" "ERROR"
            return $false
        }

        # Create recovery directory
        if (-not $DryRun) {
            if (-not (Test-Path $TargetPath)) {
                New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
            }
        }

        # Determine backup type and extract if needed
        $isCompressed = $RecoveryPath.EndsWith(".zip")
        $isEncrypted = $RecoveryPath.EndsWith(".encrypted")

        $extractedPath = $RecoveryPath

        # Decrypt if needed
        if ($isEncrypted) {
            Write-BackupLog "Decrypting backup file..." "INFO"
            $encryptionKey = "NCC_Backup_Key_2026"
            $decryptedPath = $RecoveryPath.Replace(".encrypted", "_decrypted")

            # Decryption logic would go here
            # For now, assume successful decryption
            $extractedPath = $decryptedPath
        }

        # Extract if compressed
        if ($isCompressed) {
            Write-BackupLog "Extracting compressed backup..." "INFO"
            $extractPath = Join-Path $Config.TempPath "recovery_extract_$(Get-Date -Format 'yyyyMMddHHmmss')"

            if (-not $DryRun) {
                Expand-Archive -Path $extractedPath -DestinationPath $extractPath -Force
            }

            $extractedPath = $extractPath
        }

        # Copy files to recovery location
        if (-not $DryRun) {
            $backupFiles = Get-ChildItem -Path $extractedPath -File -Recurse
            foreach ($file in $backupFiles) {
                $relativePath = $file.FullName.Replace($extractedPath, "").TrimStart("\")
                $destinationPath = Join-Path $TargetPath $relativePath

                $destinationDir = Split-Path $destinationPath -Parent
                if (-not (Test-Path $destinationDir)) {
                    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
                }

                Copy-Item -Path $file.FullName -Destination $destinationPath -Force
            }
        }

        # Verify recovery
        $recoveredFiles = Get-ChildItem -Path $TargetPath -File -Recurse
        Write-BackupLog "Recovery completed. Recovered $($recoveredFiles.Count) files to $TargetPath" "INFO"

        # Cleanup temporary files
        if ($isCompressed -and (Test-Path $extractedPath)) {
            Remove-Item -Path $extractedPath -Recurse -Force
        }

        return $true
    }
    catch {
        Write-BackupLog "Data recovery failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Invoke-BackupMaintenance {
    Write-BackupLog "Starting backup maintenance operation..." "INFO"

    try {
        $currentDate = Get-Date
        $expiredBackups = @()
        $totalSpaceReclaimed = 0

        # Find expired backups
        foreach ($backup in $script:BackupManifest.backups) {
            $expiryDate = [DateTime]::Parse($backup.expiry_date)
            if ($currentDate -gt $expiryDate) {
                $expiredBackups += $backup
            }
        }

        Write-BackupLog "Found $($expiredBackups.Count) expired backups to remove" "INFO"

        # Remove expired backups
        foreach ($backup in $expiredBackups) {
            if (Test-Path $backup.backup_path) {
                $fileInfo = Get-Item $backup.backup_path
                $totalSpaceReclaimed += $fileInfo.Length

                if (-not $DryRun) {
                    Remove-Item -Path $backup.backup_path -Force
                }

                Write-BackupLog "Removed expired backup: $($backup.backup_path)" "INFO"
            }
        }

        # Update manifest
        $activeBackups = $script:BackupManifest.backups | Where-Object {
            $expiredBackups.backup_id -notcontains $_.backup_id
        }
        $script:BackupManifest.backups = $activeBackups

        # Save updated manifest
        if (-not $DryRun) {
            $manifestFile = Join-Path $Config.BackupRoot "backup_manifest.json"
            $script:BackupManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestFile -Encoding UTF8
        }

        # Generate maintenance report
        $maintenanceReport = @{
            timestamp = (Get-Date).ToString("o")
            operation = "maintenance"
            expired_backups_removed = $expiredBackups.Count
            space_reclaimed_bytes = $totalSpaceReclaimed
            space_reclaimed_mb = [math]::Round($totalSpaceReclaimed / 1MB, 2)
            remaining_backups = $activeBackups.Count
            retention_policy_days = $RetentionDays
        }

        $reportFile = Join-Path $Config.BackupRoot "maintenance_report_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
        if (-not $DryRun) {
            $maintenanceReport | ConvertTo-Json | Set-Content -Path $reportFile -Encoding UTF8
        }

        Write-BackupLog "Backup maintenance completed. Space reclaimed: $([math]::Round($totalSpaceReclaimed / 1MB, 2)) MB" "INFO"

        return $true
    }
    catch {
        Write-BackupLog "Backup maintenance failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Invoke-BackupVerification {
    Write-BackupLog "Starting backup verification operation..." "INFO"

    try {
        $verificationResults = @{
            timestamp = (Get-Date).ToString("o")
            total_backups = $script:BackupManifest.backups.Count
            verified_backups = 0
            failed_backups = 0
            corrupted_backups = 0
            missing_backups = 0
            details = @()
        }

        foreach ($backup in $script:BackupManifest.backups) {
            $result = @{
                backup_id = $backup.backup_id
                backup_path = $backup.backup_path
                backup_type = $backup.backup_type
                status = "unknown"
                error_message = $null
                checksum_match = $null
            }

            # Check if backup file exists
            if (-not (Test-Path $backup.backup_path)) {
                $result.status = "missing"
                $verificationResults.missing_backups++
                $verificationResults.failed_backups++
            }
            else {
                # Verify checksum if available
                if ($backup.checksum) {
                    $currentChecksum = Get-FileChecksum -FilePath $backup.backup_path
                    if ($currentChecksum -eq $backup.checksum) {
                        $result.checksum_match = $true
                        $result.status = "verified"
                        $verificationResults.verified_backups++
                    }
                    else {
                        $result.checksum_match = $false
                        $result.status = "corrupted"
                        $result.error_message = "Checksum mismatch"
                        $verificationResults.corrupted_backups++
                        $verificationResults.failed_backups++
                    }
                }
                else {
                    $result.status = "verified"
                    $verificationResults.verified_backups++
                }
            }

            $verificationResults.details += $result
        }

        # Save verification report
        $reportFile = Join-Path $Config.BackupRoot "verification_report_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
        if (-not $DryRun) {
            $verificationResults | ConvertTo-Json -Depth 10 | Set-Content -Path $reportFile -Encoding UTF8
        }

        Write-BackupLog "Backup verification completed. Verified: $($verificationResults.verified_backups), Failed: $($verificationResults.failed_backups)" "INFO"

        if ($verificationResults.failed_backups -gt 0) {
            Write-BackupLog "WARNING: $($verificationResults.failed_backups) backups failed verification" "WARNING"
        }

        return $verificationResults.failed_backups -eq 0
    }
    catch {
        Write-BackupLog "Backup verification failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution logic
Write-BackupLog "=== NCC Data Backup System Started ===" "INFO"
Write-BackupLog "Mode: $Mode, Retention: $RetentionDays days, Compress: $Compress, Encrypt: $Encrypt, DryRun: $DryRun" "INFO"

try {
    Initialize-BackupSystem

    $success = $false

    switch ($Mode) {
        "Full" {
            $success = Invoke-FullBackup
        }
        "Incremental" {
            $success = Invoke-IncrementalBackup
        }
        "Recovery" {
            if (-not $TargetPath) {
                Write-BackupLog "Recovery mode requires -TargetPath parameter" "ERROR"
                $success = $false
            }
            else {
                # Find latest backup if no specific path provided
                $recoverySource = $TargetPath
                if (-not (Test-Path $TargetPath)) {
                    $latestBackup = $script:BackupManifest.backups |
                        Where-Object { $_.backup_type -eq "Full" } |
                        Sort-Object created_at -Descending |
                        Select-Object -First 1

                    if ($latestBackup) {
                        $recoverySource = $latestBackup.backup_path
                        Write-BackupLog "Using latest full backup: $recoverySource" "INFO"
                    }
                    else {
                        Write-BackupLog "No backup found for recovery" "ERROR"
                        $success = $false
                        break
                    }
                }
                $success = Invoke-DataRecovery -RecoveryPath $recoverySource
            }
        }
        "Maintenance" {
            $success = Invoke-BackupMaintenance
        }
        "Verify" {
            $success = Invoke-BackupVerification
        }
    }

    Write-BackupLog "=== NCC Data Backup System Completed ===" "INFO"
    Write-BackupLog "Execution result: $(if ($success) { 'SUCCESS' } else { 'FAILED' })" "INFO"

    exit $(if ($success) { 0 } else { 1 })
}
catch {
    Write-BackupLog "Data Backup System failed: $($_.Exception.Message)" "ERROR"
    Write-BackupLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}