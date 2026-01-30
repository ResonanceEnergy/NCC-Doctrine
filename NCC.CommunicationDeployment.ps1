# NCC Agent Communication Deployment System
# Automated deployment of unified communication system to all agents

param(
    [switch]$Deploy,
    [switch]$Update,
    [switch]$Verify,
    [switch]$Rollback,
    [string]$Division,
    [switch]$Force
)

$DeploymentConfig = @{
    CommunicationScript = Join-Path $PSScriptRoot "NCC.Agent.Communication.ps1"
    BackupPath = Join-Path $PSScriptRoot "backups\communication"
    LogPath = Join-Path $PSScriptRoot "logs\deployment.log"
    AgentDirectories = @(
        "agents",
        "*/Agents",
        "**/Agents"
    )
}

# Ensure directories exist
foreach ($path in @($DeploymentConfig.BackupPath, (Split-Path $DeploymentConfig.LogPath -Parent))) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

function Write-DeploymentLog {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [DEPLOYMENT] [$Level] $Message"

    switch ($Level.ToUpper()) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default   { Write-Host $logMessage }
    }

    $logMessage | Out-File -FilePath $DeploymentConfig.LogPath -Append -Encoding UTF8
}

function Get-AllAgentFiles {
    $agentFiles = @()

    # Search in various agent directories
    foreach ($pattern in $DeploymentConfig.AgentDirectories) {
        try {
            $files = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" -Recurse | Where-Object {
                $_.FullName -like "*$pattern*" -and
                $_.Name -notlike "*Communication*" -and
                $_.Name -notlike "*Deployment*" -and
                $_.Name -notlike "*Dashboard*"
            }
            $agentFiles += $files
        }
        catch {
            Write-DeploymentLog "Error searching pattern $pattern`: $($_.Exception.Message)" -Level "WARNING"
        }
    }

    # Remove duplicates
    $agentFiles = $agentFiles | Select-Object -Unique

    Write-DeploymentLog "Found $($agentFiles.Count) agent files" -Level "INFO"
    return $agentFiles
}

function Backup-AgentFile {
    param([string]$FilePath)

    $fileName = Split-Path $FilePath -Leaf
    $backupFile = Join-Path $DeploymentConfig.BackupPath "$fileName.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"

    try {
        Copy-Item -Path $FilePath -Destination $backupFile -Force
        Write-DeploymentLog "Backed up $fileName to $backupFile" -Level "SUCCESS"
        return $backupFile
    }
    catch {
        Write-DeploymentLog "Failed to backup $fileName`: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Add-CommunicationToAgent {
    param([string]$AgentFilePath)

    try {
        $content = Get-Content -Path $AgentFilePath -Raw

        # Check if communication is already integrated
        if ($content -match "NCC\.Agent\.Communication\.ps1") {
            Write-DeploymentLog "Communication already integrated in $(Split-Path $AgentFilePath -Leaf)" -Level "INFO"
            return $true
        }

        # Extract agent information from the file
        $agentName = $null
        $division = $null

        if ($content -match '\$AgentConfig\s*=\s*@\s*\{\s*Name\s*=\s*"([^"]+)"') {
            $agentName = $matches[1]
        }

        if ($content -match 'Division\s*=\s*"([^"]+)"') {
            $division = $matches[1]
        }

        if (-not $agentName) {
            $fileName = Split-Path $AgentFilePath -Leaf
            $agentName = $fileName -replace '\.ps1$', ''
        }

        if (-not $division) {
            $division = Split-Path (Split-Path $AgentFilePath -Parent) -Leaf
        }

        # Create communication integration code
        $commCode = @"

# NCC Communication Integration
`$AgentCommPath = Join-Path `$PSScriptRoot "NCC.Agent.Communication.ps1"
if (Test-Path `$AgentCommPath) {
    # Register agent with communication system
    & `$AgentCommPath -AgentName "$agentName" -Division "$division" -InitializeNetwork

    # Communication functions for agent use
    function Send-AgentMessage {
        param([string]`$To, [string]`$Type, [string]`$Content, [string]`$Priority = "Normal")
        & `$AgentCommPath -AgentName "$agentName" -TargetAgent `$To -MessageType `$Type -MessageContent `$Content -Priority `$Priority -SendMessage
    }

    function Receive-AgentMessages {
        return & `$AgentCommPath -AgentName "$agentName" -ReceiveMessages
    }

    function Broadcast-Message {
        param([string]`$Type, [string]`$Content, [string]`$Priority = "Normal")
        & `$AgentCommPath -AgentName "$agentName" -MessageType `$Type -MessageContent `$Content -Priority `$Priority -Broadcast
    }

    function Check-Connectivity {
        param([string]`$TargetAgent)
        return & `$AgentCommPath -TargetAgent `$TargetAgent -CheckConnectivity
    }

    # Initialize communication on agent startup
    Write-Host "🔗 Agent communication system initialized for $agentName" -ForegroundColor Cyan
}
"@

        # Find a good place to insert the communication code (after param block or initial setup)
        $lines = $content -split "`n"
        $insertIndex = 0

        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^param\(" -or $lines[$i] -match "^# Agent-specific configuration") {
                # Find the end of this block
                $braceCount = 0
                for ($j = $i; $j -lt $lines.Count; $j++) {
                    if ($lines[$j] -match "\{") { $braceCount++ }
                    if ($lines[$j] -match "\}") { $braceCount-- }
                    if ($braceCount -eq 0 -and $j -gt $i) {
                        $insertIndex = $j + 2
                        break
                    }
                }
                break
            }
        }

        if ($insertIndex -eq 0) {
            $insertIndex = [math]::Min(20, $lines.Count)
        }

        # Insert communication code
        $newContent = $lines[0..($insertIndex-1)] -join "`n"
        $newContent += "`n`n$commCode`n"
        $newContent += $lines[$insertIndex..($lines.Count-1)] -join "`n"

        # Save the updated file
        $newContent | Out-File -FilePath $AgentFilePath -Encoding UTF8

        Write-DeploymentLog "Successfully integrated communication system into $(Split-Path $AgentFilePath -Leaf)" -Level "SUCCESS"
        return $true

    }
    catch {
        Write-DeploymentLog "Failed to update $(Split-Path $AgentFilePath -Leaf)`: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Verify-AgentCommunication {
    param([string]$AgentFilePath)

    try {
        $content = Get-Content -Path $AgentFilePath -Raw

        $checks = @(
            @{ Name = "Communication Script Reference"; Pattern = "NCC\.Agent\.Communication\.ps1" },
            @{ Name = "Send Function"; Pattern = "function Send-AgentMessage" },
            @{ Name = "Receive Function"; Pattern = "function Receive-AgentMessages" },
            @{ Name = "Broadcast Function"; Pattern = "function Broadcast-Message" }
        )

        $results = @{}
        foreach ($check in $checks) {
            $results[$check.Name] = $content -match $check.Pattern
        }

        $passed = ($results.Values | Where-Object { $_ -eq $true }).Count
        $total = $results.Count

        Write-DeploymentLog "Verification for $(Split-Path $AgentFilePath -Leaf)`: $passed/$total checks passed" -Level $(if ($passed -eq $total) { "SUCCESS" } else { "WARNING" })

        return $results

    }
    catch {
        Write-DeploymentLog "Verification failed for $(Split-Path $AgentFilePath -Leaf)`: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Deploy-CommunicationSystem {
    Write-DeploymentLog "Starting communication system deployment" -Level "INFO"

    $agentFiles = Get-AllAgentFiles

    if ($Division) {
        $agentFiles = $agentFiles | Where-Object { $_.FullName -like "*$Division*" }
        Write-DeploymentLog "Filtered to division: $Division ($($agentFiles.Count) agents)" -Level "INFO"
    }

    $successCount = 0
    $totalCount = $agentFiles.Count

    foreach ($agentFile in $agentFiles) {
        Write-DeploymentLog "Processing $(Split-Path $agentFile.FullName -Leaf)" -Level "INFO"

        # Backup the file
        $backup = Backup-AgentFile -FilePath $agentFile.FullName
        if (-not $backup) {
            Write-DeploymentLog "Skipping $(Split-Path $agentFile.FullName -Leaf) due to backup failure" -Level "ERROR"
            continue
        }

        # Add communication integration
        $result = Add-CommunicationToAgent -AgentFilePath $agentFile.FullName
        if ($result) {
            $successCount++
        }
    }

    Write-DeploymentLog "Deployment completed: $successCount/$totalCount agents successfully updated" -Level $(if ($successCount -eq $totalCount) { "SUCCESS" } else { "WARNING" })
}

function Update-CommunicationSystem {
    Write-DeploymentLog "Starting communication system update" -Level "INFO"

    # This would check for updates to the communication script and redeploy if needed
    Write-DeploymentLog "Update functionality not yet implemented" -Level "WARNING"
}

function Verify-Deployment {
    Write-DeploymentLog "Starting deployment verification" -Level "INFO"

    $agentFiles = Get-AllAgentFiles
    $verificationResults = @()

    foreach ($agentFile in $agentFiles) {
        $result = Verify-AgentCommunication -AgentFilePath $agentFile.FullName
        if ($result) {
            $verificationResults += @{
                File = Split-Path $agentFile.FullName -Leaf
                Results = $result
            }
        }
    }

    $totalAgents = $verificationResults.Count
    $fullyVerified = ($verificationResults | Where-Object {
        ($_.Results.Values | Where-Object { $_ -eq $true }).Count -eq $_.Results.Count
    }).Count

    Write-DeploymentLog "Verification completed: $fullyVerified/$totalAgents agents fully verified" -Level $(if ($fullyVerified -eq $totalAgents) { "SUCCESS" } else { "WARNING" })

    return $verificationResults
}

function Rollback-Deployment {
    Write-DeploymentLog "Starting deployment rollback" -Level "WARNING"

    # This would restore from backups
    Write-DeploymentLog "Rollback functionality not yet implemented" -Level "WARNING"
}

# Main execution
if ($Deploy) {
    Deploy-CommunicationSystem
}

if ($Update) {
    Update-CommunicationSystem
}

if ($Verify) {
    $results = Verify-Deployment
    return $results
}

if ($Rollback) {
    Rollback-Deployment
}