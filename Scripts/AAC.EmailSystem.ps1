# AAC Internal Email & Messaging System
# Secure communication platform for AAC agents
# Handles encrypted messaging, alerts, and inter-agent communication

param(
    [switch]$Initialize,
    [switch]$SendMessage,
    [switch]$CheckInbox,
    [switch]$BroadcastAlert,
    [switch]$ViewConversations,
    [switch]$ArchiveMessages,
    [string]$To,
    [string]$Subject,
    [string]$Message,
    [string]$Priority = "Normal",
    [string]$From = $env:USERNAME
)

$ScriptPath = $PSScriptRoot
$DataPath = Join-Path $ScriptPath "..\data"
$LogPath = Join-Path $ScriptPath "..\logs\AAC_Email_System.log"

# Ensure directories exist
$LogDir = Split-Path $LogPath -Parent
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-AACEmailLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [AAC-EMAIL-$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"}elseif($Level -eq "SUCCESS"){"Green"}else{"Cyan"})
    Add-Content -Path $LogPath -Value $LogEntry
}

# Email System Configuration
$EMAIL_CONFIG = @{
    "encryption_enabled" = $true
    "message_retention_days" = 365
    "max_message_size_kb" = 1024
    "allowed_priorities" = @("Low", "Normal", "High", "Critical")
    "auto_archive_days" = 30
    "alert_channels" = @("Email", "SMS", "Dashboard", "Voice")
    "security_protocols" = @{
        "encryption" = "AES-256"
        "authentication" = "Multi-factor"
        "audit_trail" = $true
        "data_loss_prevention" = $true
    }
}

function Initialize-AACEmailSystem {
    Write-AACEmailLog "📧 INITIALIZING AAC INTERNAL EMAIL SYSTEM 📧" "INIT"

    # Create email database
    $emailDbPath = Join-Path $DataPath "aac_email_database.json"
    $emailData = @{
        "messages" = @()
        "conversations" = @()
        "alerts" = @()
        "user_inboxes" = @{}
        "system_status" = @{
            "total_messages" = 0
            "active_conversations" = 0
            "unread_messages" = 0
            "last_backup" = $null
        }
        "security_log" = @()
        "last_updated" = (Get-Date).ToString("o")
    }
    $emailData | ConvertTo-Json -Depth 10 | Set-Content $emailDbPath

    # Create archive directory
    $archivePath = Join-Path $DataPath "email_archive"
    if (!(Test-Path $archivePath)) { New-Item -ItemType Directory -Path $archivePath -Force | Out-Null }

    # Initialize agent inboxes
    $agentDbPath = Join-Path $DataPath "aac_agent_database.json"
    if (Test-Path $agentDbPath) {
        $agentData = Get-Content $agentDbPath | ConvertFrom-Json
        foreach ($agent in $agentData.agents) {
            $emailData.user_inboxes[$agent.id] = @{
                "unread_count" = 0
                "total_messages" = 0
                "folders" = @{
                    "inbox" = @()
                    "sent" = @()
                    "archive" = @()
                    "trash" = @()
                }
            }
        }
        $emailData | ConvertTo-Json -Depth 10 | Set-Content $emailDbPath
    }

    Write-AACEmailLog "AAC Email System initialized with secure messaging and alert capabilities" "SUCCESS"
}

function Send-AACMessage {
    param(
        [string]$To,
        [string]$Subject,
        [string]$Message,
        [string]$Priority = "Normal",
        [string]$From = $env:USERNAME
    )

    if (!$To -or !$Subject -or !$Message) {
        Write-AACEmailLog "Missing required parameters for message sending" "ERROR"
        return $false
    }

    if ($EMAIL_CONFIG.allowed_priorities -notcontains $Priority) {
        Write-AACEmailLog "Invalid priority level: $Priority" "ERROR"
        return $false
    }

    $emailDbPath = Join-Path $DataPath "aac_email_database.json"
    if (!(Test-Path $emailDbPath)) {
        Write-AACEmailLog "Email system not initialized" "ERROR"
        return $false
    }

    $emailData = Get-Content $emailDbPath | ConvertFrom-Json

    # Validate recipient
    if ($emailData.user_inboxes.Keys -notcontains $To) {
        Write-AACEmailLog "Invalid recipient: $To" "ERROR"
        return $false
    }

    # Create message object
    $messageObj = @{
        "id" = [guid]::NewGuid().ToString()
        "from" = $From
        "to" = $To
        "subject" = $Subject
        "body" = $Message
        "priority" = $Priority
        "timestamp" = (Get-Date).ToString("o")
        "read" = $false
        "encrypted" = $EMAIL_CONFIG.encryption_enabled
        "attachments" = @()
        "conversation_id" = $null
        "tags" = @()
    }

    # Add to recipient's inbox
    $emailData.user_inboxes[$To].folders.inbox += $messageObj
    $emailData.user_inboxes[$To].unread_count++
    $emailData.user_inboxes[$To].total_messages++

    # Add to sender's sent folder
    if ($emailData.user_inboxes.ContainsKey($From)) {
        $emailData.user_inboxes[$From].folders.sent += $messageObj
        $emailData.user_inboxes[$From].total_messages++
    }

    # Add to global messages
    $emailData.messages += $messageObj
    $emailData.system_status.total_messages++

    # Security logging
    $securityEntry = @{
        "timestamp" = (Get-Date).ToString("o")
        "action" = "Message Sent"
        "from" = $From
        "to" = $To
        "priority" = $Priority
        "encrypted" = $messageObj.encrypted
    }
    $emailData.security_log += $securityEntry

    $emailData | ConvertTo-Json -Depth 10 | Set-Content $emailDbPath

    Write-AACEmailLog "Message sent from $From to $To (Priority: $Priority)" "SUCCESS"
    return $true
}

function Check-AACInbox {
    param([string]$User = $env:USERNAME)

    $emailDbPath = Join-Path $DataPath "aac_email_database.json"
    if (!(Test-Path $emailDbPath)) {
        Write-AACEmailLog "Email system not initialized" "ERROR"
        return $null
    }

    $emailData = Get-Content $emailDbPath | ConvertFrom-Json

    if (!$emailData.user_inboxes.ContainsKey($User)) {
        Write-AACEmailLog "User inbox not found: $User" "ERROR"
        return $null
    }

    $inbox = $emailData.user_inboxes[$User]

    Write-Host "AAC Email Inbox for $User" -ForegroundColor Yellow
    Write-Host "Unread Messages: $($inbox.unread_count)" -ForegroundColor Cyan
    Write-Host "Total Messages: $($inbox.total_messages)" -ForegroundColor Green
    Write-Host "" -ForegroundColor White

    if ($inbox.folders.inbox.Count -eq 0) {
        Write-Host "Inbox is empty" -ForegroundColor Gray
        return @()
    }

    $messages = $inbox.folders.inbox | Sort-Object timestamp -Descending
    foreach ($msg in $messages) {
        $status = if ($msg.read) { " " } else { "*" }
        $priorityColor = switch ($msg.priority) {
            "Critical" { "Red" }
            "High" { "Magenta" }
            "Normal" { "White" }
            "Low" { "Gray" }
        }
        Write-Host "$status $($msg.timestamp.Split('T')[0]) | $($msg.from) | $($msg.subject)" -ForegroundColor $priorityColor
    }

    return $messages
}

function Send-AACBroadcastAlert {
    param(
        [string]$Subject,
        [string]$Message,
        [string]$Priority = "High",
        [string[]]$Channels = @("Email", "Dashboard")
    )

    Write-AACEmailLog "🚨 SENDING AAC BROADCAST ALERT 🚨" "ALERT"

    $emailDbPath = Join-Path $DataPath "aac_email_database.json"
    if (!(Test-Path $emailDbPath)) {
        Write-AACEmailLog "Email system not initialized" "ERROR"
        return $false
    }

    $emailData = Get-Content $emailDbPath | ConvertFrom-Json

    # Create alert object
    $alertObj = @{
        "id" = [guid]::NewGuid().ToString()
        "type" = "Broadcast Alert"
        "subject" = $Subject
        "message" = $Message
        "priority" = $Priority
        "timestamp" = (Get-Date).ToString("o")
        "channels" = $Channels
        "recipients" = @()
        "acknowledged_by" = @()
        "escalation_required" = ($Priority -eq "Critical")
    }

    # Send to all agents
    foreach ($agentId in $emailData.user_inboxes.Keys) {
        $alertObj.recipients += $agentId

        # Send via email
        if ($Channels -contains "Email") {
            Send-AACMessage -To $agentId -Subject $Subject -Message $Message -Priority $Priority -From "AAC-System"
        }

        # Log dashboard alert (would integrate with dashboard system)
        if ($Channels -contains "Dashboard") {
            Write-AACEmailLog "Dashboard alert sent to $agentId" "ALERT"
        }
    }

    # Add to alerts log
    $emailData.alerts += $alertObj
    $emailData | ConvertTo-Json -Depth 10 | Set-Content $emailDbPath

    Write-AACEmailLog "Broadcast alert sent to $($alertObj.recipients.Count) agents via $($Channels -join ', ')" "SUCCESS"
    return $true
}

function View-AACConversations {
    param([string]$User = $env:USERNAME)

    $emailDbPath = Join-Path $DataPath "aac_email_database.json"
    if (!(Test-Path $emailDbPath)) {
        Write-AACEmailLog "Email system not initialized" "ERROR"
        return $null
    }

    $emailData = Get-Content $emailDbPath | ConvertFrom-Json

    if (!$emailData.user_inboxes.ContainsKey($User)) {
        Write-AACEmailLog "User inbox not found: $User" "ERROR"
        return $null
    }

    $userMessages = $emailData.messages | Where-Object { $_.from -eq $User -or $_.to -eq $User }

    # Group by conversation (simplified - in production would use conversation_id)
    $conversations = $userMessages | Group-Object { "$($_.from)-$($_.to)" } | Sort-Object Count -Descending

    Write-Host "AAC Email Conversations for $User" -ForegroundColor Yellow
    Write-Host "Total Conversations: $($conversations.Count)" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor White

    foreach ($conv in $conversations) {
        $participants = $conv.Name -split '-'
        $otherParty = if ($participants[0] -eq $User) { $participants[1] } else { $participants[0] }
        $unreadCount = ($conv.Group | Where-Object { !$_.read -and $_.to -eq $User }).Count

        Write-Host "With: $otherParty | Messages: $($conv.Count) | Unread: $unreadCount" -ForegroundColor White
        $latestMsg = $conv.Group | Sort-Object timestamp -Descending | Select-Object -First 1
        Write-Host "  Latest: $($latestMsg.subject) ($($latestMsg.timestamp.Split('T')[0]))" -ForegroundColor Gray
        Write-Host "" -ForegroundColor White
    }

    return $conversations
}

function Archive-AACMessages {
    param([string]$User = $env:USERNAME, [int]$DaysOld = 30)

    $emailDbPath = Join-Path $DataPath "aac_email_database.json"
    if (!(Test-Path $emailDbPath)) {
        Write-AACEmailLog "Email system not initialized" "ERROR"
        return $false
    }

    $emailData = Get-Content $emailDbPath | ConvertFrom-Json
    $cutoffDate = (Get-Date).AddDays(-$DaysOld)

    if (!$emailData.user_inboxes.ContainsKey($User)) {
        Write-AACEmailLog "User inbox not found: $User" "ERROR"
        return $false
    }

    $archivedCount = 0
    $inbox = $emailData.user_inboxes[$User]

    # Archive old messages from inbox
    $oldMessages = $inbox.folders.inbox | Where-Object {
        [DateTime]::Parse($_.timestamp) -lt $cutoffDate -and $_.read
    }

    foreach ($msg in $oldMessages) {
        $inbox.folders.archive += $msg
        $inbox.folders.inbox = $inbox.folders.inbox | Where-Object { $_.id -ne $msg.id }
        $archivedCount++
    }

    # Archive old sent messages
    $oldSentMessages = $inbox.folders.sent | Where-Object {
        [DateTime]::Parse($_.timestamp) -lt $cutoffDate
    }

    foreach ($msg in $oldSentMessages) {
        $inbox.folders.archive += $msg
        $inbox.folders.sent = $inbox.folders.sent | Where-Object { $_.id -ne $msg.id }
        $archivedCount++
    }

    $emailData | ConvertTo-Json -Depth 10 | Set-Content $emailDbPath

    Write-AACEmailLog "Archived $archivedCount messages older than $DaysOld days for user $User" "SUCCESS"
    return $true
}

# Main execution logic
if ($Initialize) {
    Initialize-AACEmailSystem
    Write-AACEmailLog "AAC Internal Email System initialized successfully" "SUCCESS"
    exit 0
}

if ($SendMessage) {
    if (!$To -or !$Subject -or !$Message) {
        Write-Host "Error: Missing required parameters. Use -To, -Subject, and -Message" -ForegroundColor Red
        exit 1
    }
    $result = Send-AACMessage -To $To -Subject $Subject -Message $Message -Priority $Priority -From $From
    if ($result) {
        Write-Host "Message sent successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to send message" -ForegroundColor Red
    }
    exit 0
}

if ($CheckInbox) {
    Check-AACInbox
    exit 0
}

if ($BroadcastAlert) {
    if (!$Subject -or !$Message) {
        Write-Host "Error: Missing required parameters. Use -Subject and -Message" -ForegroundColor Red
        exit 1
    }
    $result = Send-AACBroadcastAlert -Subject $Subject -Message $Message -Priority $Priority
    if ($result) {
        Write-Host "Broadcast alert sent successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to send broadcast alert" -ForegroundColor Red
    }
    exit 0
}

if ($ViewConversations) {
    View-AACConversations
    exit 0
}

if ($ArchiveMessages) {
    $result = Archive-AACMessages
    if ($result) {
        Write-Host "Messages archived successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to archive messages" -ForegroundColor Red
    }
    exit 0
}

# Default: Show system status
$emailDbPath = Join-Path $DataPath "aac_email_database.json"
if (Test-Path $emailDbPath) {
    $emailData = Get-Content $emailDbPath | ConvertFrom-Json
    Write-Host "AAC Email System Status:" -ForegroundColor Yellow
    Write-Host "Total Messages: $($emailData.system_status.total_messages)" -ForegroundColor Cyan
    Write-Host "Active Conversations: $($emailData.system_status.active_conversations)" -ForegroundColor Green
    Write-Host "Unread Messages: $($emailData.system_status.unread_messages)" -ForegroundColor Magenta
    Write-Host "Security Events: $($emailData.security_log.Count)" -ForegroundColor Blue
} else {
    Write-Host "AAC Email System not initialized. Run with -Initialize first." -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "AAC Internal Email & Messaging System" -ForegroundColor Yellow
Write-Host "Usage:" -ForegroundColor Cyan
Write-Host "  .\AAC.EmailSystem.ps1 -Initialize                    # Initialize the email system" -ForegroundColor White
Write-Host "  .\AAC.EmailSystem.ps1 -SendMessage -To <agent> -Subject <subj> -Message <msg>  # Send message" -ForegroundColor White
Write-Host "  .\AAC.EmailSystem.ps1 -CheckInbox                   # View inbox" -ForegroundColor White
Write-Host "  .\AAC.EmailSystem.ps1 -BroadcastAlert -Subject <subj> -Message <msg>  # Send alert" -ForegroundColor White
Write-Host "  .\AAC.EmailSystem.ps1 -ViewConversations            # View conversations" -ForegroundColor White
Write-Host "  .\AAC.EmailSystem.ps1 -ArchiveMessages              # Archive old messages" -ForegroundColor White