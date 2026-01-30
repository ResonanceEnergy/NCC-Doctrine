# NCC Security Remediation Engine
# Faraday Fortress Automated Security Hardening

param(
    [switch]$FixPermissions,
    [switch]$EncryptFiles,
    [switch]$AuditOnly,
    [switch]$DesktopDisplay
)

# Configuration
$ScriptPath = $PSScriptRoot
$LogPath = Join-Path $ScriptPath "..\logs\NCC_Security_Remediation.log"
$DataPath = Join-Path $ScriptPath "..\data"
$BackupPath = Join-Path $DataPath "security_backups"

# Ensure directories exist
$LogDir = Split-Path $LogPath -Parent
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
if (!(Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
}

function Write-SecurityLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [SECURITY] [$Level] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogPath -Value $LogEntry
}

function Fix-FilePermissions {
    Write-SecurityLog "Initiating File Permission Remediation" "START"

    $DataFiles = Get-ChildItem $DataPath -Filter "*.json" -Recurse
    $fixedCount = 0

    foreach ($file in $DataFiles) {
        try {
            # Create backup before modifying
            $backupFile = Join-Path $BackupPath "$($file.BaseName)_backup_$((Get-Date).ToString('yyyyMMdd_HHmmss')).json"
            Copy-Item $file.FullName $backupFile -Force
            Write-SecurityLog "Created backup: $($file.Name)" "BACKUP"

            # Get current ACL
            $acl = Get-Acl $file.FullName

            # Remove excessive permissions - keep only SYSTEM and Administrators
            $excessiveRules = $acl.Access | Where-Object {
                $_.IdentityReference -notlike "*SYSTEM*" -and
                $_.IdentityReference -notlike "*Administrators*" -and
                $_.IdentityReference -notlike "*$env:USERNAME*"
            }

            if ($excessiveRules.Count -gt 0) {
                Write-SecurityLog "Removing excessive permissions from: $($file.Name)" "FIX"

                # Create new ACL with restricted permissions
                $newAcl = New-Object System.Security.AccessControl.FileSecurity
                $newAcl.SetOwner([System.Security.Principal.NTAccount]"$env:USERDOMAIN\$env:USERNAME")

                # Add back only necessary permissions
                $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    "BUILTIN\Administrators", "FullControl", "Allow"
                )
                $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    "NT AUTHORITY\SYSTEM", "FullControl", "Allow"
                )
                $ownerRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    "$env:USERDOMAIN\$env:USERNAME", "FullControl", "Allow"
                )

                $newAcl.AddAccessRule($adminRule)
                $newAcl.AddAccessRule($systemRule)
                $newAcl.AddAccessRule($ownerRule)

                # Apply the new ACL
                Set-Acl -Path $file.FullName -AclObject $newAcl
                $fixedCount++
                Write-SecurityLog "Fixed permissions for: $($file.Name)" "SUCCESS"
            } else {
                Write-SecurityLog "Permissions already secure for: $($file.Name)" "OK"
            }

        } catch {
            Write-SecurityLog "Failed to fix permissions for $($file.Name): $($_.Exception.Message)" "ERROR"
        }
    }

    Write-SecurityLog "Permission remediation complete. Fixed $fixedCount files." "COMPLETE"
}

function Encrypt-LowEntropyFiles {
    Write-SecurityLog "Initiating File Encryption for Low Entropy Files" "START"

    $DataFiles = Get-ChildItem $DataPath -Filter "*.json" -Recurse
    $encryptedCount = 0

    foreach ($file in $DataFiles) {
        try {
            $content = Get-Content $file.FullName -Raw
            if ($content.Length -gt 100) {
                # Calculate entropy
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
                $byteCounts = @{}
                foreach ($byte in $bytes) {
                    $byteCounts[$byte]++
                }

                $entropy = 0
                foreach ($count in $byteCounts.Values) {
                    $p = $count / $bytes.Length
                    $entropy -= $p * [Math]::Log($p, 2)
                }

                if ($entropy -lt 7.5) {
                    Write-SecurityLog "Encrypting low-entropy file: $($file.Name) (entropy: $([math]::Round($entropy, 2)))" "ENCRYPT"

                    # Create backup
                    $backupFile = Join-Path $BackupPath "$($file.BaseName)_unencrypted_$((Get-Date).ToString('yyyyMMdd_HHmmss')).json"
                    Copy-Item $file.FullName $backupFile -Force

                    # Simple encryption using ConvertTo-SecureString (for demonstration)
                    # In production, use proper encryption methods
                    $secureContent = ConvertTo-SecureString $content -AsPlainText -Force
                    $encryptedBytes = $secureContent | ConvertFrom-SecureString
                    $encryptedContent = "ENCRYPTED:" + ($encryptedBytes -join ",")

                    # Save encrypted content
                    $encryptedContent | Out-File $file.FullName -Encoding UTF8 -Force

                    $encryptedCount++
                    Write-SecurityLog "Successfully encrypted: $($file.Name)" "SUCCESS"
                } else {
                    Write-SecurityLog "File already has high entropy: $($file.Name)" "OK"
                }
            }
        } catch {
            Write-SecurityLog "Failed to encrypt $($file.Name): $($_.Exception.Message)" "ERROR"
        }
    }

    Write-SecurityLog "Encryption process complete. Encrypted $encryptedCount files." "COMPLETE"
}

function Run-SecurityAudit {
    Write-SecurityLog "Running Comprehensive Security Audit" "AUDIT"

    $DataFiles = Get-ChildItem $DataPath -Filter "*.json" -Recurse
    $totalFiles = $DataFiles.Count
    $vulnerablePermissions = 0
    $lowEntropyFiles = 0
    $auditResults = @()

    foreach ($file in $DataFiles) {
        $fileResult = @{
            FileName = $file.Name
            Path = $file.FullName
            Size = [math]::Round($file.Length / 1KB, 2)
            PermissionsIssue = $false
            EntropyIssue = $false
            Entropy = 0
        }

        # Check permissions
        try {
            $acl = Get-Acl $file.FullName
            $excessiveRules = $acl.Access | Where-Object {
                $_.IdentityReference -notlike "*SYSTEM*" -and
                $_.IdentityReference -notlike "*Administrators*" -and
                $_.IdentityReference -notlike "*$env:USERNAME*"
            }

            if ($excessiveRules.Count -gt 0) {
                $fileResult.PermissionsIssue = $true
                $vulnerablePermissions++
            }
        } catch {
            Write-SecurityLog "Could not check permissions for $($file.Name): $($_.Exception.Message)" "WARNING"
        }

        # Check entropy
        try {
            $content = Get-Content $file.FullName -Raw
            if ($content.Length -gt 100) {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
                $byteCounts = @{}
                foreach ($byte in $bytes) {
                    $byteCounts[$byte]++
                }

                $entropy = 0
                foreach ($count in $byteCounts.Values) {
                    $p = $count / $bytes.Length
                    $entropy -= $p * [Math]::Log($p, 2)
                }

                $fileResult.Entropy = [math]::Round($entropy, 2)
                if ($entropy -lt 7.5) {
                    $fileResult.EntropyIssue = $true
                    $lowEntropyFiles++
                }
            }
        } catch {
            Write-SecurityLog "Could not check entropy for $($file.Name): $($_.Exception.Message)" "WARNING"
        }

        $auditResults += $fileResult
    }

    # Generate audit report
    $auditReport = @"
# NCC Security Audit Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary
- Total Files Audited: $totalFiles
- Files with Permission Issues: $vulnerablePermissions
- Files with Low Entropy: $lowEntropyFiles
- Security Score: $([math]::Round((($totalFiles - $vulnerablePermissions - $lowEntropyFiles) / $totalFiles) * 100, 1))%

## Detailed Results
"@

    foreach ($result in $auditResults) {
        $status = "SECURE"
        if ($result.PermissionsIssue -and $result.EntropyIssue) {
            $status = "CRITICAL"
        } elseif ($result.PermissionsIssue -or $result.EntropyIssue) {
            $status = "WARNING"
        }

        $auditReport += @"

### $($result.FileName)
- **Status**: $status
- **Size**: $($result.Size) KB
- **Entropy**: $($result.Entropy)
- **Permission Issue**: $($result.PermissionsIssue)
- **Entropy Issue**: $($result.EntropyIssue)
"@
    }

    $auditReportPath = Join-Path $ScriptPath "..\data\ncc_security_audit_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').md"
    $auditReport | Out-File $auditReportPath -Encoding UTF8
    Write-SecurityLog "Security audit report generated: $auditReportPath" "COMPLETE"

    # Display summary
    Write-Host "`n=== SECURITY AUDIT SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Total Files: $totalFiles" -ForegroundColor White
    Write-Host "Permission Issues: $vulnerablePermissions" -ForegroundColor Red
    Write-Host "Low Entropy Files: $lowEntropyFiles" -ForegroundColor Yellow
    Write-Host "Security Score: $([math]::Round((($totalFiles - $vulnerablePermissions - $lowEntropyFiles) / $totalFiles) * 100, 1))%" -ForegroundColor Green
    Write-Host "Report saved to: $auditReportPath" -ForegroundColor White
}

function Show-DesktopDisplay {
    Write-SecurityLog "Launching NCC Desktop Display" "DISPLAY"

    # Create a simple desktop GUI using Windows Forms
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "NCC Enterprise Command Center"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 30)

    # Title Label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "NATHAN COMMAND CORPORATION"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::Cyan
    $titleLabel.AutoSize = $true
    $titleLabel.Location = New-Object System.Drawing.Point(250, 20)
    $form.Controls.Add($titleLabel)

    # Status Panel
    $statusPanel = New-Object System.Windows.Forms.GroupBox
    $statusPanel.Text = "System Status"
    $statusPanel.Location = New-Object System.Drawing.Point(20, 60)
    $statusPanel.Size = New-Object System.Drawing.Size(350, 200)
    $statusPanel.ForeColor = [System.Drawing.Color]::White
    $form.Controls.Add($statusPanel)

    # Status Text Box
    $statusText = New-Object System.Windows.Forms.TextBox
    $statusText.Multiline = $true
    $statusText.ScrollBars = "Vertical"
    $statusText.Location = New-Object System.Drawing.Point(10, 20)
    $statusText.Size = New-Object System.Drawing.Size(330, 170)
    $statusText.BackColor = [System.Drawing.Color]::Black
    $statusText.ForeColor = [System.Drawing.Color]::Green
    $statusText.Font = New-Object System.Drawing.Font("Consolas", 9)
    $statusText.ReadOnly = $true
    $statusPanel.Controls.Add($statusText)

    # Control Panel
    $controlPanel = New-Object System.Windows.Forms.GroupBox
    $controlPanel.Text = "Control Center"
    $controlPanel.Location = New-Object System.Drawing.Point(400, 60)
    $controlPanel.Size = New-Object System.Drawing.Size(350, 200)
    $controlPanel.ForeColor = [System.Drawing.Color]::White
    $form.Controls.Add($controlPanel)

    # Buttons
    $auditButton = New-Object System.Windows.Forms.Button
    $auditButton.Text = "Run Security Audit"
    $auditButton.Location = New-Object System.Drawing.Point(20, 25)
    $auditButton.Size = New-Object System.Drawing.Size(150, 30)
    $auditButton.BackColor = [System.Drawing.Color]::DarkBlue
    $auditButton.ForeColor = [System.Drawing.Color]::White
    $auditButton.Add_Click({
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): Running security audit...`r`n")
        & $PSScriptRoot\NCC.Security.Remediation.ps1 -AuditOnly
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): Security audit completed.`r`n")
    })
    $controlPanel.Controls.Add($auditButton)

    $fixButton = New-Object System.Windows.Forms.Button
    $fixButton.Text = "Fix Permissions"
    $fixButton.Location = New-Object System.Drawing.Point(180, 25)
    $fixButton.Size = New-Object System.Drawing.Size(150, 30)
    $fixButton.BackColor = [System.Drawing.Color]::DarkGreen
    $fixButton.ForeColor = [System.Drawing.Color]::White
    $fixButton.Add_Click({
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): Fixing file permissions...`r`n")
        & $PSScriptRoot\NCC.Security.Remediation.ps1 -FixPermissions
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): Permission fixes completed.`r`n")
    })
    $controlPanel.Controls.Add($fixButton)

    $encryptButton = New-Object System.Windows.Forms.Button
    $encryptButton.Text = "Encrypt Files"
    $encryptButton.Location = New-Object System.Drawing.Point(20, 65)
    $encryptButton.Size = New-Object System.Drawing.Size(150, 30)
    $encryptButton.BackColor = [System.Drawing.Color]::DarkRed
    $encryptButton.ForeColor = [System.Drawing.Color]::White
    $encryptButton.Add_Click({
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): Encrypting sensitive files...`r`n")
        & $PSScriptRoot\NCC.Security.Remediation.ps1 -EncryptFiles
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): File encryption completed.`r`n")
    })
    $controlPanel.Controls.Add($encryptButton)

    $masterBrainButton = New-Object System.Windows.Forms.Button
    $masterBrainButton.Text = "Master Brain Analysis"
    $masterBrainButton.Location = New-Object System.Drawing.Point(180, 65)
    $masterBrainButton.Size = New-Object System.Drawing.Size(150, 30)
    $masterBrainButton.BackColor = [System.Drawing.Color]::Purple
    $masterBrainButton.ForeColor = [System.Drawing.Color]::White
    $masterBrainButton.Add_Click({
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): Running Master Brain analysis...`r`n")
        & $PSScriptRoot\Master_Brain_Storage_Analysis.ps1
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): Master Brain analysis completed.`r`n")
    })
    $controlPanel.Controls.Add($masterBrainButton)

    $activateButton = New-Object System.Windows.Forms.Button
    $activateButton.Text = "Activate Systems Go"
    $activateButton.Location = New-Object System.Drawing.Point(20, 105)
    $activateButton.Size = New-Object System.Drawing.Size(310, 30)
    $activateButton.BackColor = [System.Drawing.Color]::DarkOrange
    $activateButton.ForeColor = [System.Drawing.Color]::White
    $activateButton.Add_Click({
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): Activating NCC Systems...`r`n")
        & $PSScriptRoot\..\ASG.ps1
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): NCC Systems activated.`r`n")
    })
    $controlPanel.Controls.Add($activateButton)

    $dashboardButton = New-Object System.Windows.Forms.Button
    $dashboardButton.Text = "Open Dashboard"
    $dashboardButton.Location = New-Object System.Drawing.Point(20, 145)
    $dashboardButton.Size = New-Object System.Drawing.Size(150, 30)
    $dashboardButton.BackColor = [System.Drawing.Color]::Teal
    $dashboardButton.ForeColor = [System.Drawing.Color]::White
    $dashboardButton.Add_Click({
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): Opening NCC Dashboard...`r`n")
        Start-Process "http://localhost:3000"
        $statusText.AppendText("$(Get-Date -Format 'HH:mm:ss'): Dashboard opened in browser.`r`n")
    })
    $controlPanel.Controls.Add($dashboardButton)

    $exitButton = New-Object System.Windows.Forms.Button
    $exitButton.Text = "Exit"
    $exitButton.Location = New-Object System.Drawing.Point(180, 145)
    $exitButton.Size = New-Object System.Drawing.Size(150, 30)
    $exitButton.BackColor = [System.Drawing.Color]::Gray
    $exitButton.ForeColor = [System.Drawing.Color]::White
    $exitButton.Add_Click({ $form.Close() })
    $controlPanel.Controls.Add($exitButton)

    # Log Panel
    $logPanel = New-Object System.Windows.Forms.GroupBox
    $logPanel.Text = "Activity Log"
    $logPanel.Location = New-Object System.Drawing.Point(20, 280)
    $logPanel.Size = New-Object System.Drawing.Size(730, 250)
    $logPanel.ForeColor = [System.Drawing.Color]::White
    $form.Controls.Add($logPanel)

    # Log Text Box
    $logText = New-Object System.Windows.Forms.TextBox
    $logText.Multiline = $true
    $logText.ScrollBars = "Vertical"
    $logText.Location = New-Object System.Drawing.Point(10, 20)
    $logText.Size = New-Object System.Drawing.Size(710, 220)
    $logText.BackColor = [System.Drawing.Color]::Black
    $logText.ForeColor = [System.Drawing.Color]::White
    $logText.Font = New-Object System.Drawing.Font("Consolas", 8)
    $logText.ReadOnly = $true
    $logPanel.Controls.Add($logText)

    # Initialize status
    $statusText.Text = "NCC Enterprise Command Center initialized at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n"
    $statusText.Text += "System ready for operations.`r`n`r`n"

    # Show recent log entries
    $recentLogs = Get-Content $LogPath -Tail 10 -ErrorAction SilentlyContinue
    if ($recentLogs) {
        $logText.Text = "Recent Security Activity:`r`n" + ($recentLogs -join "`r`n")
    } else {
        $logText.Text = "No recent security activity found.`r`n"
    }

    # Show the form
    $form.ShowDialog() | Out-Null
}

# Main execution logic
if ($AuditOnly) {
    Run-SecurityAudit
}

if ($FixPermissions) {
    Fix-FilePermissions
}

if ($EncryptFiles) {
    Encrypt-LowEntropyFiles
}

if ($DesktopDisplay) {
    Show-DesktopDisplay
}

if (-not ($AuditOnly -or $FixPermissions -or $EncryptFiles -or $DesktopDisplay)) {
    Write-SecurityLog "No operation specified. Running full security remediation..." "INFO"
    Run-SecurityAudit
    Fix-FilePermissions
    Encrypt-LowEntropyFiles
}

Write-SecurityLog "NCC Security Remediation Engine execution complete" "COMPLETE"