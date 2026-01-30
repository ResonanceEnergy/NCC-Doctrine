# NCC Agent Communication Protocol v3.0.0 - Enterprise Edition
# Unified Cross-Agent Communication and Coordination Framework

param(
    [Parameter(Mandatory=$false)]
    [string]$AgentName,

    [Parameter(Mandatory=$false)]
    [string]$Division,

    [Parameter(Mandatory=$false)]
    [ValidateSet("STATUS", "COMMAND", "DATA_REQUEST", "ALERT", "COORDINATE", "EMERGENCY", "BROADCAST")]
    [string]$MessageType = "STATUS",

    [Parameter(Mandatory=$false)]
    [string]$TargetAgent,

    [Parameter(Mandatory=$false)]
    [string]$MessageContent,

    [Parameter(Mandatory=$false)]
    [ValidateSet("Critical", "High", "Normal", "Low")]
    [string]$Priority = "Normal",

    [switch]$SendMessage,
    [switch]$ReceiveMessages,
    [switch]$Broadcast,
    [switch]$ListAgents,
    [switch]$CheckConnectivity,
    [switch]$InitializeNetwork,
    [switch]$MonitorNetwork,
    [switch]$SwarmCoordinate,
    [switch]$EmergencyBroadcast
)

# Enterprise Communication Configuration
$CommConfig = @{
    ProtocolVersion = "3.0.0"
    NetworkPath = Join-Path $PSScriptRoot "network"
    MessageQueue = Join-Path $PSScriptRoot "network\messages"
    AgentRegistry = Join-Path $PSScriptRoot "network\agents.json"
    LogPath = Join-Path $PSScriptRoot "network\logs"
    EncryptionKey = "NCC-Enterprise-Key-2026"  # In production, use proper key management
    MaxRetries = 3
    RetryDelaySeconds = 5
    MessageTimeoutHours = 24
    SwarmConfig = Join-Path $PSScriptRoot "network\swarm.json"
    MonitoringData = Join-Path $PSScriptRoot "network\monitoring.json"
}

# Priority Levels
$PriorityLevels = @{
    "Critical" = 4
    "High" = 3
    "Normal" = 2
    "Low" = 1
}

# Ensure network directories exist
$directories = @($CommConfig.NetworkPath, $CommConfig.MessageQueue, $CommConfig.LogPath,
                (Join-Path $CommConfig.MessageQueue "processed"),
                (Join-Path $CommConfig.MessageQueue "failed"),
                (Join-Path $CommConfig.MessageQueue "archive"))

foreach ($path in $directories) {
    if (-not (Test-Path -Path $path -PathType Container)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# Communication Logging
function Write-CommLog {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [AGENT_COMM] [$Level] $Message"
    $logFile = Join-Path $CommConfig.LogPath "agent_communication.log"

    # Write to console with color coding
    switch ($Level.ToUpper()) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "INFO"    { Write-Host $logMessage -ForegroundColor Cyan }
        default   { Write-Host $logMessage }
    }

    # Write to log file
    try {
        $logMessage | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
    catch {
        Write-Host "Failed to write to communication log: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Secure Messaging Functions
function Encrypt-Message {
    param([string]$PlainText)

    try {
        $key = [System.Text.Encoding]::UTF8.GetBytes($CommConfig.EncryptionKey.PadRight(32).Substring(0,32))
        $iv = New-Object byte[] 16
        [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($iv)

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key
        $aes.IV = $iv

        $encryptor = $aes.CreateEncryptor()
        $memoryStream = New-Object System.IO.MemoryStream
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($memoryStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
        $streamWriter = New-Object System.IO.StreamWriter($cryptoStream)

        $streamWriter.Write($PlainText)
        $streamWriter.Close()
        $cryptoStream.Close()

        $encryptedBytes = $memoryStream.ToArray()
        $memoryStream.Close()

        $combinedBytes = $iv + $encryptedBytes
        return [Convert]::ToBase64String($combinedBytes)
    }
    catch {
        Write-CommLog "Encryption failed: $($_.Exception.Message)" -Level "ERROR"
        return $PlainText  # Fallback to plain text
    }
}

function Decrypt-Message {
    param([string]$EncryptedText)

    try {
        $combinedBytes = [Convert]::FromBase64String($EncryptedText)
        $iv = $combinedBytes[0..15]
        $encryptedBytes = $combinedBytes[16..($combinedBytes.Length - 1)]

        $key = [System.Text.Encoding]::UTF8.GetBytes($CommConfig.EncryptionKey.PadRight(32).Substring(0,32))

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key
        $aes.IV = $iv

        $decryptor = $aes.CreateDecryptor()
        $memoryStream = New-Object System.IO.MemoryStream($encryptedBytes)
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($memoryStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)
        $streamReader = New-Object System.IO.StreamReader($cryptoStream)

        $decryptedText = $streamReader.ReadToEnd()
        $streamReader.Close()
        $cryptoStream.Close()
        $memoryStream.Close()

        return $decryptedText
    }
    catch {
        Write-CommLog "Decryption failed: $($_.Exception.Message)" -Level "ERROR"
        return $EncryptedText  # Return as-is if decryption fails
    }
}

# Message Structure
function New-AgentMessage {
    param(
        [string]$From,
        [string]$To,
        [string]$Type,
        [string]$Content,
        [ValidateSet("Critical", "High", "Normal", "Low")]
        [string]$Priority = "Normal",
        [hashtable]$Metadata = @{},
        [switch]$Encrypt
    )

    $priorityValue = $PriorityLevels[$Priority]

    $message = @{
        Id = [guid]::NewGuid().ToString()
        Timestamp = Get-Date
        From = $From
        To = $To
        Type = $Type
        Content = if ($Encrypt) { Encrypt-Message -PlainText $Content } else { $Content }
        Priority = $priorityValue
        PriorityLabel = $Priority
        Status = "PENDING"
        Encrypted = $Encrypt.IsPresent
        RetryCount = 0
        MaxRetries = $CommConfig.MaxRetries
        Metadata = $Metadata
        ProtocolVersion = $CommConfig.ProtocolVersion
        ExpiresAt = (Get-Date).AddHours($CommConfig.MessageTimeoutHours)
    }

    return $message
}

# Agent Registry Management
function Initialize-AgentRegistry {
    Write-CommLog "Initializing agent registry..." -Level "INFO"

    if (-not (Test-Path -Path $CommConfig.AgentRegistry)) {
        $registry = @{
            LastUpdate = Get-Date
            Agents = @()
            NetworkStatus = "INITIALIZED"
        }
        $registry | ConvertTo-Json -Depth 10 | Out-File -FilePath $CommConfig.AgentRegistry -Encoding UTF8
        Write-CommLog "Agent registry created successfully" -Level "SUCCESS"
    }
}

function Register-Agent {
    param([string]$AgentName, [string]$Division, [string]$Role = "General", [string]$Status = "Active")

    Write-CommLog "Registering agent: $AgentName ($Division - $Role)" -Level "INFO"

    $registry = Get-Content -Path $CommConfig.AgentRegistry -Raw | ConvertFrom-Json

    $existingAgent = $registry.Agents | Where-Object { $_.Name -eq $AgentName }
    if ($existingAgent) {
        $existingAgent.Status = $Status
        $existingAgent.LastSeen = Get-Date
    } else {
        $newAgent = @{
            Name = $AgentName
            Division = $Division
            Role = $Role
            Status = $Status
            Registered = Get-Date
            LastSeen = Get-Date
            Capabilities = @()
        }
        $registry.Agents += $newAgent
    }

    $registry.LastUpdate = Get-Date
    $registry | ConvertTo-Json -Depth 10 | Out-File -FilePath $CommConfig.AgentRegistry -Encoding UTF8

    Write-CommLog "Agent registered successfully" -Level "SUCCESS"
}

function Get-RegisteredAgents {
    if (Test-Path -Path $CommConfig.AgentRegistry) {
        $registry = Get-Content -Path $CommConfig.AgentRegistry -Raw | ConvertFrom-Json
        return $registry.Agents
    }
    return @()
}

# Message Handling
function Send-AgentMessage {
    param([hashtable]$Message)

    Write-CommLog "Sending message from $($Message.From) to $($Message.To) [Type: $($Message.Type), Priority: $($Message.PriorityLabel)]" -Level "INFO"

    $messageFile = Join-Path $CommConfig.MessageQueue "$($Message.Id).json"

    # Implement retry logic
    $success = $false
    for ($attempt = 1; $attempt -le ($Message.MaxRetries + 1); $attempt++) {
        try {
            $Message.RetryCount = $attempt - 1
            $Message.LastAttempt = Get-Date
            $Message | ConvertTo-Json -Depth 10 | Out-File -FilePath $messageFile -Encoding UTF8
            $success = $true
            break
        }
        catch {
            Write-CommLog "Send attempt $attempt failed: $($_.Exception.Message)" -Level "WARNING"
            if ($attempt -le $Message.MaxRetries) {
                Start-Sleep -Seconds $CommConfig.RetryDelaySeconds
            }
        }
    }

    if ($success) {
        Write-CommLog "Message sent successfully (attempt $attempt)" -Level "SUCCESS"
        Update-MonitoringData -Metric "MessagesSent" -Value 1
    } else {
        Write-CommLog "Message send failed after $($Message.MaxRetries + 1) attempts" -Level "ERROR"
        Move-MessageToFailed -Message $Message
        Update-MonitoringData -Metric "MessagesFailed" -Value 1
    }

    return $success
}

function Receive-AgentMessages {
    param([string]$TargetAgent)

    Write-CommLog "Checking for messages to $TargetAgent" -Level "INFO"

    $messages = @()
    $messageFiles = Get-ChildItem -Path $CommConfig.MessageQueue -Filter "*.json" -File

    foreach ($file in $messageFiles) {
        try {
            $message = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            if ($message.To -eq $TargetAgent -or $message.To -eq "ALL" -or $message.To -eq "DIVISION:$Division") {

                # Decrypt content if encrypted
                if ($message.Encrypted) {
                    $message.Content = Decrypt-Message -EncryptedText $message.Content
                }

                $messages += $message

                # Mark as received
                $message.Status = "RECEIVED"
                $message.ReceivedAt = Get-Date
                $message | ConvertTo-Json -Depth 10 | Out-File -FilePath $file.FullName -Encoding UTF8

                Update-MonitoringData -Metric "MessagesReceived" -Value 1
            }
        }
        catch {
            Write-CommLog "Error processing message file $($file.Name): $($_.Exception.Message)" -Level "ERROR"
        }
    }

    # Sort by priority (highest first)
    $messages = $messages | Sort-Object -Property Priority -Descending

    Write-CommLog "Retrieved $($messages.Count) messages for $TargetAgent" -Level "INFO"
    return $messages
}

function Send-BroadcastMessage {
    param(
        [string]$From,
        [string]$Type,
        [string]$Content,
        [ValidateSet("Critical", "High", "Normal", "Low")]
        [string]$Priority = "Normal",
        [switch]$Encrypt,
        [string]$TargetDivision = "ALL"
    )

    Write-CommLog "Broadcasting message from $From [Type: $Type, Priority: $Priority]" -Level "INFO"

    $target = if ($TargetDivision -eq "ALL") { "ALL" } else { "DIVISION:$TargetDivision" }
    $message = New-AgentMessage -From $From -To $target -Type $Type -Content $Content -Priority $Priority -Encrypt:$Encrypt
    $success = Send-AgentMessage -Message $message

    if ($success) {
        Write-CommLog "Broadcast message sent successfully" -Level "SUCCESS"
    }

    return $success
}

function Send-EmergencyBroadcast {
    param([string]$From, [string]$Content)

    Write-CommLog "EMERGENCY BROADCAST from $From" -Level "ERROR"

    $message = New-AgentMessage -From $From -To "ALL" -Type "EMERGENCY" -Content $Content -Priority "Critical" -Encrypt
    $success = Send-AgentMessage -Message $message

    # Send to all registered agents individually for redundancy
    $agents = Get-RegisteredAgents
    foreach ($agent in $agents) {
        $backupMessage = New-AgentMessage -From $From -To $agent.Name -Type "EMERGENCY" -Content $Content -Priority "Critical" -Encrypt
        Send-AgentMessage -Message $backupMessage
    }

    Write-CommLog "Emergency broadcast completed" -Level "SUCCESS"
    return $success
}

function Invoke-MessageQueue {
    Write-CommLog "Processing message queue..." -Level "INFO"

    $messageFiles = Get-ChildItem -Path $CommConfig.MessageQueue -Filter "*.json" -File
    $processedCount = 0

    foreach ($file in $messageFiles) {
        try {
            $message = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json

            # Process based on message type
            switch ($message.Type) {
                "STATUS_REQUEST" {
                    # Send status response
                    $response = New-AgentMessage -From $message.To -To $message.From -Type "STATUS_RESPONSE" -Content "Agent is operational"
                    Send-AgentMessage -Message $response
                }
                "COMMAND" {
                    # Execute command (with security checks)
                    Write-CommLog "Processing command: $($message.Content)" -Level "WARNING"
                }
                "DATA_REQUEST" {
                    # Provide requested data
                    Write-CommLog "Processing data request from $($message.From)" -Level "INFO"
                }
                default {
                    Write-CommLog "Unknown message type: $($message.Type)" -Level "WARNING"
                }
            }

            # Mark as processed and archive
            $message.Status = "PROCESSED"
            $message.ProcessedAt = Get-Date

            $processedFile = Join-Path $CommConfig.MessageQueue "processed\$($file.Name)"
            $message | ConvertTo-Json -Depth 10 | Out-File -FilePath $processedFile -Encoding UTF8

            Remove-Item -Path $file.FullName -Force
            $processedCount++

        }
        catch {
            Write-CommLog "Error processing message $($file.Name): $($_.Exception.Message)" -Level "ERROR"
        }
    }

    Write-CommLog "Processed $processedCount messages" -Level "SUCCESS"
}

# Network Operations
function Test-AgentConnectivity {
    param([string]$TargetAgent)

    Write-CommLog "Testing connectivity to $TargetAgent" -Level "INFO"

    $pingMessage = New-AgentMessage -From $AgentName -To $TargetAgent -Type "PING" -Content "Connectivity test"
    Send-AgentMessage -Message $pingMessage

    # Wait for response (simplified)
    Start-Sleep -Seconds 2

    $responses = Receive-AgentMessages -TargetAgent $AgentName
    $pongResponse = $responses | Where-Object { $_.Type -eq "PONG" -and $_.From -eq $TargetAgent }

    if ($pongResponse) {
        Write-CommLog "Connectivity to ${TargetAgent}: SUCCESS" -Level "SUCCESS"
        return $true
    } else {
        Write-CommLog "Connectivity to ${TargetAgent}: FAILED" -Level "ERROR"
        return $false
    }
}

function Initialize-CommunicationNetwork {
    Write-CommLog "Initializing enterprise agent communication network..." -Level "INFO"

    Initialize-AgentRegistry

    # Create additional directories
    $dirs = @("processed", "failed", "archive")
    foreach ($dir in $dirs) {
        $dirPath = Join-Path $CommConfig.MessageQueue $dir
        if (-not (Test-Path -Path $dirPath -PathType Container)) {
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        }
    }

    # Initialize monitoring data
    if (-not (Test-Path $CommConfig.MonitoringData)) {
        $initialMonitoring = @{
            LastUpdate = Get-Date
            Metrics = @{}
            AgentHealth = @{}
            NetworkStats = @{
                TotalMessages = 0
                MessagesSent = 0
                MessagesReceived = 0
                MessagesFailed = 0
                ActiveAgents = 0
                ConnectivityChecks = 0
            }
        }
        $initialMonitoring | ConvertTo-Json -Depth 10 | Out-File -FilePath $CommConfig.MonitoringData -Encoding UTF8
    }

    Write-CommLog "Enterprise communication network initialized successfully" -Level "SUCCESS"
}

# Swarm Coordination Functions
function Initialize-SwarmConfig {
    if (-not (Test-Path $CommConfig.SwarmConfig)) {
        $swarmConfig = @{
            LastUpdate = Get-Date
            ActiveSwarms = @()
            ConflictResolution = @{
                Strategy = "PriorityBased"
                TimeoutMinutes = 30
            }
            ResourceSharing = @{
                Enabled = $true
                MaxConcurrentTasks = 10
            }
        }
        $swarmConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $CommConfig.SwarmConfig -Encoding UTF8
    }
}

function Start-SwarmCoordination {
    param([string]$TaskId, [string]$CoordinatorAgent, [array]$ParticipantAgents, [hashtable]$TaskData)

    Write-CommLog "Starting swarm coordination for task $TaskId" -Level "INFO"

    Initialize-SwarmConfig
    $swarmConfig = Get-Content -Path $CommConfig.SwarmConfig -Raw | ConvertFrom-Json

    $swarm = @{
        TaskId = $TaskId
        Coordinator = $CoordinatorAgent
        Participants = $ParticipantAgents
        TaskData = $TaskData
        Status = "ACTIVE"
        StartedAt = Get-Date
        Conflicts = @()
        Decisions = @()
    }

    $swarmConfig.ActiveSwarms += $swarm
    $swarmConfig.LastUpdate = Get-Date
    $swarmConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $CommConfig.SwarmConfig -Encoding UTF8

    # Notify participants
    foreach ($agent in $ParticipantAgents) {
        $coordMessage = New-AgentMessage -From $CoordinatorAgent -To $agent -Type "COORDINATE" -Content "Join swarm task $TaskId" -Priority "High" -Metadata @{ TaskId = $TaskId; Coordinator = $CoordinatorAgent }
        Send-AgentMessage -Message $coordMessage
    }

    Write-CommLog "Swarm coordination started for $TaskId with $($ParticipantAgents.Count) participants" -Level "SUCCESS"
}

function Resolve-Conflict {
    param([string]$TaskId, [string]$ConflictDescription, [array]$Options)

    Write-CommLog "Resolving conflict in swarm task $TaskId" -Level "WARNING"

    $swarmConfig = Get-Content -Path $CommConfig.SwarmConfig -Raw | ConvertFrom-Json
    $swarm = $swarmConfig.ActiveSwarms | Where-Object { $_.TaskId -eq $TaskId }

    if ($swarm) {
        $conflict = @{
            Description = $ConflictDescription
            Options = $Options
            Resolved = $false
            Resolution = $null
            Timestamp = Get-Date
        }
        $swarm.Conflicts += $conflict

        # Priority-based resolution (simplified)
        $resolution = $Options[0]  # Default to first option
        $conflict.Resolved = $true
        $conflict.Resolution = $resolution

        $decision = @{
            Type = "ConflictResolution"
            Description = $ConflictDescription
            Decision = $resolution
            Timestamp = Get-Date
        }
        $swarm.Decisions += $decision

        $swarmConfig.LastUpdate = Get-Date
        $swarmConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $CommConfig.SwarmConfig -Encoding UTF8

        Write-CommLog "Conflict resolved: $resolution" -Level "SUCCESS"
        return $resolution
    }

    return $null
}

# Monitoring Functions
function Get-NetworkMonitoringData {
    if (Test-Path $CommConfig.MonitoringData) {
        return Get-Content -Path $CommConfig.MonitoringData -Raw | ConvertFrom-Json
    }
    return $null
}

function Update-AgentHealth {
    param([string]$AgentName, [string]$Status, [hashtable]$Metrics = @{})

    $monitoring = Get-NetworkMonitoringData
    if ($monitoring) {
        $monitoring.AgentHealth[$AgentName] = @{
            Status = $Status
            LastUpdate = Get-Date
            Metrics = $Metrics
        }
        $monitoring.LastUpdate = Get-Date
        $monitoring | ConvertTo-Json -Depth 10 | Out-File -FilePath $CommConfig.MonitoringData -Encoding UTF8
    }
}

function Get-CommunicationHealth {
    $monitoring = Get-NetworkMonitoringData
    if (-not $monitoring) { return @{ Status = "UNKNOWN"; Score = 0 } }

    $stats = $monitoring.NetworkStats
    $totalMessages = $stats.MessagesSent + $stats.MessagesReceived
    $successRate = if ($totalMessages -gt 0) { ($totalMessages - $stats.MessagesFailed) / $totalMessages } else { 1 }

    $health = @{
        Status = if ($successRate -gt 0.95) { "EXCELLENT" } elseif ($successRate -gt 0.85) { "GOOD" } elseif ($successRate -gt 0.70) { "FAIR" } else { "POOR" }
        Score = [math]::Round($successRate * 100, 2)
        TotalMessages = $totalMessages
        FailedMessages = $stats.MessagesFailed
        ActiveAgents = $stats.ActiveAgents
        LastUpdate = $monitoring.LastUpdate
    }

    return $health
}

# Main Execution Logic
if ($InitializeNetwork) {
    Initialize-CommunicationNetwork
}

if ($SendMessage) {
    if (-not $AgentName -or -not $TargetAgent -or -not $MessageContent) {
        Write-CommLog "Missing required parameters for SendMessage" -Level "ERROR"
        exit 1
    }

    $message = New-AgentMessage -From $AgentName -To $TargetAgent -Type $MessageType -Content $MessageContent -Priority $Priority
    Send-AgentMessage -Message $message
}

if ($ReceiveMessages) {
    if (-not $AgentName) {
        Write-CommLog "AgentName required for ReceiveMessages" -Level "ERROR"
        exit 1
    }

    $messages = Receive-AgentMessages -TargetAgent $AgentName
    return $messages
}

if ($Broadcast) {
    if (-not $AgentName -or -not $MessageContent) {
        Write-CommLog "Missing required parameters for Broadcast" -Level "ERROR"
        exit 1
    }

    Send-BroadcastMessage -From $AgentName -Type $MessageType -Content $MessageContent -Priority $Priority
}

if ($EmergencyBroadcast) {
    if (-not $AgentName -or -not $MessageContent) {
        Write-CommLog "Missing required parameters for EmergencyBroadcast" -Level "ERROR"
        exit 1
    }

    Send-EmergencyBroadcast -From $AgentName -Content $MessageContent
}

if ($ListAgents) {
    $agents = Get-RegisteredAgents
    Write-CommLog "Registered Agents:" -Level "INFO"
    foreach ($agent in $agents) {
        Write-CommLog "  - $($agent.Name) ($($agent.Division) - $($agent.Role)) - $($agent.Status)" -Level "INFO"
    }
    return $agents
}

if ($CheckConnectivity) {
    if (-not $TargetAgent) {
        Write-CommLog "TargetAgent required for connectivity check" -Level "ERROR"
        exit 1
    }

    Update-MonitoringData -Metric "ConnectivityChecks" -Value 1
    return Test-AgentConnectivity -TargetAgent $TargetAgent
}

if ($MonitorNetwork) {
    $health = Get-CommunicationHealth
    Write-CommLog "Network Health: $($health.Status) (Score: $($health.Score)%)" -Level "INFO"
    Write-CommLog "Total Messages: $($health.TotalMessages), Failed: $($health.FailedMessages), Active Agents: $($health.ActiveAgents)" -Level "INFO"
    return $health
}

if ($SwarmCoordinate) {
    if (-not $AgentName) {
        Write-CommLog "AgentName required for SwarmCoordinate" -Level "ERROR"
        exit 1
    }

    # This would be called by coordinator agents
    Write-CommLog "Swarm coordination initiated by $AgentName" -Level "INFO"
    # Implementation would depend on specific swarm task
}

# Default: Process message queue
Invoke-MessageQueue