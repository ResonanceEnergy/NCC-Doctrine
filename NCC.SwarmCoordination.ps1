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
# NCC Agent Swarm Coordination System
# Multi-agent task coordination and collaborative decision making

param(
    [string]$TaskId,
    [string]$CoordinatorAgent,
    [array]$ParticipantAgents,
    [string]$TaskDescription,
    [hashtable]$TaskParameters,
    [switch]$StartSwarm,
    [switch]$JoinSwarm,
    [switch]$ResolveConflict,
    [switch]$GetSwarmStatus,
    [switch]$EndSwarm,
    [string]$ConflictDescription,
    [array]$ConflictOptions
)

$SwarmConfig = @{
    ConfigPath = Join-Path $PSScriptRoot "network\swarm.json"
    LogPath = Join-Path $PSScriptRoot "network\swarm.log"
    MaxParticipants = 50
    DefaultTimeoutMinutes = 60
}

# Ensure swarm directory exists
$swarmDir = Split-Path $SwarmConfig.ConfigPath -Parent
if (-not (Test-Path $swarmDir)) {
    New-Item -ItemType Directory -Path $swarmDir -Force | Out-Null
}

function Write-SwarmLog {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [SWARM_COORD] [$Level] $Message"

    switch ($Level.ToUpper()) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default   { Write-Host $logMessage }
    }

    $logMessage | Out-File -FilePath $SwarmConfig.LogPath -Append -Encoding UTF8
}

function Initialize-SwarmConfig {
    if (-not (Test-Path $SwarmConfig.ConfigPath)) {
        $config = @{
            LastUpdate = Get-Date
            ActiveSwarms = @()
            CompletedSwarms = @()
            ConflictResolution = @{
                Strategy = "Democratic"
                TimeoutMinutes = 30
            }
            ResourceSharing = @{
                Enabled = $true
                MaxConcurrentTasks = 10
            }
        }
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $SwarmConfig.ConfigPath -Encoding UTF8
    }
}

function Get-SwarmConfig {
    if (Test-Path $SwarmConfig.ConfigPath) {
        return Get-Content -Path $SwarmConfig.ConfigPath -Raw | ConvertFrom-Json
    }
    return $null
}

function Save-SwarmConfig {
    param([psobject]$Config)

    $Config.LastUpdate = Get-Date
    $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $SwarmConfig.ConfigPath -Encoding UTF8
}

function New-SwarmTask {
    param([string]$TaskId, [string]$Coordinator, [array]$Participants, [string]$Description, [hashtable]$Parameters)

    $swarm = @{
        TaskId = $TaskId
        Coordinator = $Coordinator
        Participants = $Participants
        Description = $Description
        Parameters = $Parameters
        Status = "INITIALIZING"
        CreatedAt = Get-Date
        StartedAt = $null
        CompletedAt = $null
        Progress = 0
        SubTasks = @()
        Conflicts = @()
        Decisions = @()
        Resources = @{
            Allocated = @()
            Shared = @()
        }
        Metrics = @{
            MessagesSent = 0
            TasksCompleted = 0
            ConflictsResolved = 0
        }
    }

    return $swarm
}

function Start-SwarmCoordination {
    param([string]$TaskId, [string]$Coordinator, [array]$Participants, [string]$Description, [hashtable]$Parameters)

    Write-SwarmLog "Starting swarm coordination for task: $TaskId" -Level "INFO"

    Initialize-SwarmConfig
    $config = Get-SwarmConfig

    # Check if task already exists
    $existingSwarm = $config.ActiveSwarms | Where-Object { $_.TaskId -eq $TaskId }
    if ($existingSwarm) {
        Write-SwarmLog "Swarm task $TaskId already exists" -Level "WARNING"
        return $false
    }

    # Validate participants
    if ($Participants.Count -gt $SwarmConfig.MaxParticipants) {
        Write-SwarmLog "Too many participants ($($Participants.Count)). Max allowed: $($SwarmConfig.MaxParticipants)" -Level "ERROR"
        return $false
    }

    # Create new swarm
    $swarm = New-SwarmTask -TaskId $TaskId -Coordinator $Coordinator -Participants $Participants -Description $Description -Parameters $Parameters
    $swarm.Status = "ACTIVE"
    $swarm.StartedAt = Get-Date

    $config.ActiveSwarms += $swarm
    Save-SwarmConfig -Config $config

    # Notify participants via communication system
    $commScript = Join-Path $PSScriptRoot "NCC.Agent.Communication.ps1"

    foreach ($participant in $Participants) {
        $joinMessage = @{
            TaskId = $TaskId
            Coordinator = $Coordinator
            Description = $Description
            Parameters = $Parameters
            JoinDeadline = (Get-Date).AddMinutes(5)
        }

        $messageContent = $joinMessage | ConvertTo-Json -Compress

        try {
            & $commScript -AgentName $Coordinator -TargetAgent $participant -MessageType "SWARM_JOIN" -MessageContent $messageContent -Priority "High" -SendMessage
            Write-SwarmLog "Sent join invitation to $participant" -Level "INFO"
        }
        catch {
            Write-SwarmLog "Failed to send join invitation to $participant`: $($_.Exception.Message)" -Level "ERROR"
        }
    }

    Write-SwarmLog "Swarm coordination started successfully for $TaskId with $($Participants.Count) participants" -Level "SUCCESS"
    return $true
}

function Join-SwarmTask {
    param([string]$TaskId, [string]$AgentName)

    Write-SwarmLog "Agent $AgentName joining swarm task: $TaskId" -Level "INFO"

    $config = Get-SwarmConfig
    $swarm = $config.ActiveSwarms | Where-Object { $_.TaskId -eq $TaskId }

    if (-not $swarm) {
        Write-SwarmLog "Swarm task $TaskId not found" -Level "ERROR"
        return $false
    }

    if ($swarm.Participants -notcontains $AgentName) {
        Write-SwarmLog "Agent $AgentName is not a participant in task $TaskId" -Level "ERROR"
        return $false
    }

    # Update swarm with join confirmation
    $joinRecord = @{
        Agent = $AgentName
        JoinedAt = Get-Date
        Status = "ACTIVE"
    }

    if (-not $swarm.JoinedParticipants) {
        $swarm.JoinedParticipants = @()
    }

    $swarm.JoinedParticipants += $joinRecord
    Save-SwarmConfig -Config $config

    # Send confirmation to coordinator
    $commScript = Join-Path $PSScriptRoot "NCC.Agent.Communication.ps1"
    $confirmMessage = "Agent $AgentName has joined swarm task $TaskId"

    try {
        & $commScript -AgentName $AgentName -TargetAgent $swarm.Coordinator -MessageType "SWARM_JOINED" -MessageContent $confirmMessage -Priority "Normal" -SendMessage
        Write-SwarmLog "Join confirmation sent to coordinator" -Level "SUCCESS"
    }
    catch {
        Write-SwarmLog "Failed to send join confirmation`: $($_.Exception.Message)" -Level "ERROR"
    }

    return $true
}

function Resolve-SwarmConflict {
    param([string]$TaskId, [string]$Description, [array]$Options)

    Write-SwarmLog "Resolving conflict in swarm task $TaskId" -Level "WARNING"

    $config = Get-SwarmConfig
    $swarm = $config.ActiveSwarms | Where-Object { $_.TaskId -eq $TaskId }

    if (-not $swarm) {
        Write-SwarmLog "Swarm task $TaskId not found" -Level "ERROR"
        return $null
    }

    # Record the conflict
    $conflict = @{
        Description = $Description
        Options = $Options
        RaisedAt = Get-Date
        Resolved = $false
        Resolution = $null
        Votes = @{}
    }

    $swarm.Conflicts += $conflict

    # Use conflict resolution strategy
    switch ($config.ConflictResolution.Strategy) {
        "Coordinator" {
            # Coordinator makes the decision
            $resolution = $Options[0]  # Default to first option
            $conflict.Resolved = $true
            $conflict.Resolution = $resolution
            $conflict.ResolvedAt = Get-Date
        }
        "Democratic" {
            # Send voting request to participants
            Send-VotingRequest -Swarm $swarm -Conflict $conflict
            return "Voting initiated"
        }
        "Priority" {
            # Use priority-based resolution
            $resolution = $Options | Sort-Object -Property Priority -Descending | Select-Object -First 1
            $conflict.Resolved = $true
            $conflict.Resolution = $resolution
            $conflict.ResolvedAt = Get-Date
        }
    }

    if ($conflict.Resolved) {
        $decision = @{
            Type = "ConflictResolution"
            Description = $Description
            Decision = $conflict.Resolution
            Timestamp = Get-Date
        }
        $swarm.Decisions += $decision
        $swarm.Metrics.ConflictsResolved++

        Save-SwarmConfig -Config $config

        Write-SwarmLog "Conflict resolved: $($conflict.Resolution)" -Level "SUCCESS"
        return $conflict.Resolution
    }

    Save-SwarmConfig -Config $config
    return $null
}

function Send-VotingRequest {
    param([psobject]$Swarm, [psobject]$Conflict)

    $commScript = Join-Path $PSScriptRoot "NCC.Agent.Communication.ps1"

    $votingData = @{
        TaskId = $Swarm.TaskId
        ConflictId = $Conflict.Id
        Description = $Conflict.Description
        Options = $Conflict.Options
        VotingDeadline = (Get-Date).AddMinutes($SwarmConfig.DefaultTimeoutMinutes)
    }

    $messageContent = $votingData | ConvertTo-Json -Compress

    foreach ($participant in $Swarm.JoinedParticipants) {
        if ($participant.Status -eq "ACTIVE") {
            try {
                & $commScript -AgentName $Swarm.Coordinator -TargetAgent $participant.Agent -MessageType "SWARM_VOTE" -MessageContent $messageContent -Priority "High" -SendMessage
            }
            catch {
                Write-SwarmLog "Failed to send voting request to $($participant.Agent)`: $($_.Exception.Message)" -Level "ERROR"
            }
        }
    }
}

function Get-SwarmStatus {
    param([string]$TaskId)

    $config = Get-SwarmConfig

    if ($TaskId) {
        $swarm = $config.ActiveSwarms | Where-Object { $_.TaskId -eq $TaskId }
        if (-not $swarm) {
            $swarm = $config.CompletedSwarms | Where-Object { $_.TaskId -eq $TaskId }
        }
        return $swarm
    }

    return @{
        ActiveSwarms = $config.ActiveSwarms.Count
        CompletedSwarms = $config.CompletedSwarms.Count
        SwarmDetails = $config.ActiveSwarms
    }
}

function End-SwarmTask {
    param([string]$TaskId)

    Write-SwarmLog "Ending swarm task: $TaskId" -Level "INFO"

    $config = Get-SwarmConfig
    $swarm = $config.ActiveSwarms | Where-Object { $_.TaskId -eq $TaskId }

    if (-not $swarm) {
        Write-SwarmLog "Swarm task $TaskId not found or already completed" -Level "WARNING"
        return $false
    }

    # Mark as completed
    $swarm.Status = "COMPLETED"
    $swarm.CompletedAt = Get-Date
    $swarm.Progress = 100

    # Move to completed
    $config.CompletedSwarms += $swarm
    $config.ActiveSwarms = $config.ActiveSwarms | Where-Object { $_.TaskId -ne $TaskId }

    Save-SwarmConfig -Config $config

    # Notify participants
    $commScript = Join-Path $PSScriptRoot "NCC.Agent.Communication.ps1"
    $completionMessage = "Swarm task $TaskId has been completed"

    foreach ($participant in $swarm.JoinedParticipants) {
        if ($participant.Status -eq "ACTIVE") {
            try {
                & $commScript -AgentName $swarm.Coordinator -TargetAgent $participant.Agent -MessageType "SWARM_COMPLETED" -MessageContent $completionMessage -Priority "Normal" -SendMessage
            }
            catch {
                Write-SwarmLog "Failed to notify $($participant.Agent) of completion`: $($_.Exception.Message)" -Level "ERROR"
            }
        }
    }

    Write-SwarmLog "Swarm task $TaskId completed successfully" -Level "SUCCESS"
    return $true
}

# Main execution
if ($StartSwarm) {
    if (-not $TaskId -or -not $CoordinatorAgent -or -not $ParticipantAgents) {
        Write-SwarmLog "Missing required parameters for StartSwarm" -Level "ERROR"
        exit 1
    }

    Start-SwarmCoordination -TaskId $TaskId -Coordinator $CoordinatorAgent -Participants $ParticipantAgents -Description $TaskDescription -Parameters $TaskParameters
}

if ($JoinSwarm) {
    if (-not $TaskId -or -not $CoordinatorAgent) {
        Write-SwarmLog "Missing required parameters for JoinSwarm" -Level "ERROR"
        exit 1
    }

    Join-SwarmTask -TaskId $TaskId -AgentName $CoordinatorAgent
}

if ($ResolveConflict) {
    if (-not $TaskId -or -not $ConflictDescription -or -not $ConflictOptions) {
        Write-SwarmLog "Missing required parameters for ResolveConflict" -Level "ERROR"
        exit 1
    }

    Resolve-SwarmConflict -TaskId $TaskId -Description $ConflictDescription -Options $ConflictOptions
}

if ($GetSwarmStatus) {
    $status = Get-SwarmStatus -TaskId $TaskId
    return $status
}

if ($EndSwarm) {
    if (-not $TaskId) {
        Write-SwarmLog "TaskId required for EndSwarm" -Level "ERROR"
        exit 1
    }

    End-SwarmTask -TaskId $TaskId
<<<<<<< HEAD
}
=======
}
>>>>>>> c6b295e0d92d0143018dcdcb5ba8fd1affca0fae
