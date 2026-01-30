# NCC Security Threat Detection Module
# Implements intrusion detection, anomaly detection, and threat intelligence for Security 10 Directive

# Threat Detection Configuration
$ThreatConfig = @{
    ScanInterval = 300  # 5 minutes
    AnomalyThreshold = 0.8
    AlertThreshold = 0.9
    IntelligenceUpdateInterval = 3600  # 1 hour
    QuarantineThreshold = 0.95
    MaxAlertsPerHour = 100
}

# Threat intelligence database
$ThreatIntelligence = @{
    KnownMalware = @()
    SuspiciousIPs = @()
    BlockedDomains = @()
    LastUpdate = Get-Date
}

# Active alerts
$ActiveAlerts = @{}

function Initialize-ThreatDetection {
    param([string]$AgentName)

    Write-SecurityLog "Initializing threat detection for agent: $AgentName" -Component "ThreatDetection"

    # Initialize threat databases
    Initialize-ThreatDatabases

    # Start monitoring processes
    Start-ThreatMonitoring -AgentName $AgentName

    Write-SecurityLog "Threat detection initialized for $AgentName" -Level "SUCCESS" -Component "ThreatDetection"
}

function Initialize-ThreatDatabases {
    # Create threat database files
    $dataDir = Join-Path $PSScriptRoot "..\data"
    if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }

    $threatDbPath = Join-Path $dataDir "threat_intelligence.json"
    if (-not (Test-Path $threatDbPath)) {
        $ThreatIntelligence | ConvertTo-Json -Depth 10 | Out-File $threatDbPath -Encoding UTF8
    }

    $alertsPath = Join-Path $dataDir "active_alerts.json"
    if (-not (Test-Path $alertsPath)) {
        @{} | ConvertTo-Json | Out-File $alertsPath -Encoding UTF8
    }
}

function Start-ThreatMonitoring {
    param([string]$AgentName)

    Write-SecurityLog "Starting threat monitoring for $AgentName" -Component "ThreatDetection"

    # Start background monitoring job
    $job = Start-Job -ScriptBlock {
        param($AgentName, $Config)

        while ($true) {
            try {
                # Network traffic analysis
                $networkAnomalies = Test-NetworkTraffic

                # Process monitoring
                $processAnomalies = Test-ProcessActivity

                # File system monitoring
                $fileAnomalies = Test-FileSystemChanges

                # Log analysis
                $logAnomalies = Test-LogPatterns

                # Check for threats
                $threats = Find-Threats -Anomalies ($networkAnomalies + $processAnomalies + $fileAnomalies + $logAnomalies)

                # Generate alerts
                foreach ($threat in $threats) {
                    New-ThreatAlert -Threat $threat -AgentName $AgentName
                }

                Start-Sleep -Seconds $Config.ScanInterval
            }
            catch {
                Write-Host "Threat monitoring error: $($_.Exception.Message)" -ForegroundColor Red
                Start-Sleep -Seconds 60  # Wait before retry
            }
        }
    } -ArgumentList $AgentName, $ThreatConfig

    Write-SecurityLog "Threat monitoring job started (ID: $($job.Id))" -Level "SUCCESS" -Component "ThreatDetection"
}

function Test-NetworkTraffic {
    # Simulate network traffic analysis
    $anomalies = @()

    try {
        # Check for unusual connection patterns
        $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object {
            $_.State -eq "Established" -and $_.RemoteAddress -notlike "127.0.0.1" -and $_.RemoteAddress -notlike "192.168.*"
        }

        foreach ($conn in $connections) {
            $score = Get-AnomalyScore -Type "Network" -Data $conn
            if ($score -gt $ThreatConfig.AnomalyThreshold) {
                $anomalies += @{
                    Type = "NetworkAnomaly"
                    Severity = if ($score -gt $ThreatConfig.QuarantineThreshold) { "Critical" } elseif ($score -gt $ThreatConfig.AlertThreshold) { "High" } else { "Medium" }
                    Score = $score
                    Details = "Suspicious connection to $($conn.RemoteAddress):$($conn.RemotePort)"
                    Timestamp = Get-Date
                }
            }
        }
    }
    catch {
        Write-SecurityLog "Network traffic analysis failed: $($_.Exception.Message)" -Level "ERROR" -Component "ThreatDetection"
    }

    return $anomalies
}

function Test-ProcessActivity {
    # Simulate process monitoring
    $anomalies = @()

    try {
        $processes = Get-Process | Where-Object {
            $_.CPU -gt 80 -or $_.WorkingSet -gt 1GB
        }

        foreach ($process in $processes) {
            $score = Get-AnomalyScore -Type "Process" -Data $process
            if ($score -gt $ThreatConfig.AnomalyThreshold) {
                $anomalies += @{
                    Type = "ProcessAnomaly"
                    Severity = if ($score -gt $ThreatConfig.QuarantineThreshold) { "Critical" } elseif ($score -gt $ThreatConfig.AlertThreshold) { "High" } else { "Medium" }
                    Score = $score
                    Details = "Suspicious process: $($process.Name) (CPU: $($process.CPU), Memory: $([math]::Round($process.WorkingSet / 1MB, 2))MB)"
                    Timestamp = Get-Date
                }
            }
        }
    }
    catch {
        Write-SecurityLog "Process monitoring failed: $($_.Exception.Message)" -Level "ERROR" -Component "ThreatDetection"
    }

    return $anomalies
}

function Test-FileSystemChanges {
    # Simulate file system monitoring
    $anomalies = @()

    try {
        # Check for suspicious file modifications
        $recentFiles = Get-ChildItem -Path $env:TEMP -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) }

        foreach ($file in $recentFiles) {
            if ($file.Extension -match '\.(exe|dll|bat|cmd|ps1)$' -and $file.Length -gt 1MB) {
                $score = Get-AnomalyScore -Type "File" -Data $file
                if ($score -gt $ThreatConfig.AnomalyThreshold) {
                    $anomalies += @{
                        Type = "FileAnomaly"
                        Severity = "High"
                        Score = $score
                        Details = "Suspicious file: $($file.FullName) ($([math]::Round($file.Length / 1MB, 2))MB)"
                        Timestamp = Get-Date
                    }
                }
            }
        }
    }
    catch {
        Write-SecurityLog "File system monitoring failed: $($_.Exception.Message)" -Level "ERROR" -Component "ThreatDetection"
    }

    return $anomalies
}

function Test-LogPatterns {
    # Simulate log analysis
    $anomalies = @()

    try {
        # Check security logs for patterns
        $logPath = Join-Path $PSScriptRoot "..\logs\security_events.log"
        if (Test-Path $logPath) {
            $recentLogs = Get-Content $logPath -Tail 100 -ErrorAction SilentlyContinue |
                Where-Object { $_ -match "ERROR|WARNING|FAILED" }

            if ($recentLogs.Count -gt 10) {
                $anomalies += @{
                    Type = "LogAnomaly"
                    Severity = "Medium"
                    Score = 0.7
                    Details = "High volume of error/warning logs detected ($($recentLogs.Count) entries)"
                    Timestamp = Get-Date
                }
            }
        }
    }
    catch {
        Write-SecurityLog "Log analysis failed: $($_.Exception.Message)" -Level "ERROR" -Component "ThreatDetection"
    }

    return $anomalies
}

function Get-AnomalyScore {
    param([string]$Type, $Data)

    # Simplified anomaly scoring (in production, this would use ML models)
    $score = 0

    switch ($Type) {
        "Network" {
            # Score based on connection properties
            if ($Data.RemoteAddress -match "^(?:10\.|172\.(?:1[6-9]|2[0-9]|3[0-1])\.|192\.168\.|127\.|0\.)") {
                $score = 0.1  # Local network
            } elseif ($Data.RemotePort -in @(22, 23, 3389, 5900)) {
                $score = 0.9  # Suspicious ports
            } else {
                $score = 0.3
            }
        }
        "Process" {
            # Score based on resource usage
            $cpuScore = [math]::Min($Data.CPU / 100, 1)
            $memScore = [math]::Min(($Data.WorkingSet / 4GB), 1)
            $score = ($cpuScore + $memScore) / 2
        }
        "File" {
            # Score based on file properties
            $sizeScore = [math]::Min($Data.Length / 100MB, 1)
            $extScore = if ($Data.Extension -match '\.(exe|dll|scr|com)$') { 0.8 } else { 0.2 }
            $score = ($sizeScore + $extScore) / 2
        }
    }

    return [math]::Min($score, 1.0)
}

function Find-Threats {
    param($Anomalies)

    $threats = @()

    foreach ($anomaly in $Anomalies) {
        # Check against threat intelligence
        if (Test-ThreatIntelligence -Anomaly $anomaly) {
            $threats += @{
                Type = "KnownThreat"
                Severity = "Critical"
                Confidence = 0.95
                Details = $anomaly.Details
                Source = "ThreatIntelligence"
                Timestamp = Get-Date
            }
        }
        elseif ($anomaly.Score -gt $ThreatConfig.AlertThreshold) {
            $threats += @{
                Type = "Anomaly"
                Severity = $anomaly.Severity
                Confidence = $anomaly.Score
                Details = $anomaly.Details
                Source = "AnomalyDetection"
                Timestamp = Get-Date
            }
        }
    }

    return $threats
}

function Test-ThreatIntelligence {
    param($Anomaly)

    # Check against known threat indicators
    # This is simplified - in production, this would query threat intelligence feeds

    if ($Anomaly.Type -eq "NetworkAnomaly") {
        # Check if IP is in threat intelligence
        return $false  # Simplified
    }

    return $false
}

function New-ThreatAlert {
    param($Threat, [string]$AgentName)

    $alertId = [Guid]::NewGuid().ToString()

    $alert = @{
        AlertId = $alertId
        AgentName = $AgentName
        Type = $Threat.Type
        Severity = $Threat.Severity
        Confidence = $Threat.Confidence
        Details = $Threat.Details
        Source = $Threat.Source
        Timestamp = $Threat.Timestamp
        Status = "Active"
        Escalated = $false
    }

    $ActiveAlerts[$alertId] = $alert

    # Log alert
    Write-SecurityLog "THREAT ALERT: $($Threat.Type) - $($Threat.Details)" -Level "ALERT" -Component "ThreatDetection"

    # Auto-escalate critical threats
    if ($Threat.Severity -eq "Critical") {
        Escalate-Threat -AlertId $alertId
    }

    # Save alerts
    Save-ThreatAlerts
}

function Escalate-Threat {
    param([string]$AlertId)

    if ($ActiveAlerts.ContainsKey($AlertId)) {
        $ActiveAlerts[$AlertId].Escalated = $true
        $ActiveAlerts[$AlertId].Status = "Escalated"

        Write-SecurityLog "THREAT ESCALATED: $AlertId" -Level "ALERT" -Component "ThreatDetection"

        # Trigger incident response
        Start-IncidentResponse -AlertId $AlertId
    }
}

function Start-IncidentResponse {
    param([string]$AlertId)

    Write-SecurityLog "INITIATING INCIDENT RESPONSE for alert: $AlertId" -Level "ALERT" -Component "ThreatDetection"

    # Automated response actions would go here
    # - Isolate affected systems
    # - Collect forensics
    # - Notify security team
    # - Implement containment measures
}

function Save-ThreatAlerts {
    $alertsPath = Join-Path $PSScriptRoot "..\data\active_alerts.json"
    $ActiveAlerts | ConvertTo-Json -Depth 10 | Out-File $alertsPath -Encoding UTF8
}

function Update-ThreatIntelligence {
    Write-SecurityLog "Updating threat intelligence..." -Component "ThreatDetection"

    # In production, this would fetch from threat intelligence feeds
    $ThreatIntelligence.LastUpdate = Get-Date

    $threatDbPath = Join-Path $PSScriptRoot "..\data\threat_intelligence.json"
    $ThreatIntelligence | ConvertTo-Json -Depth 10 | Out-File $threatDbPath -Encoding UTF8

    Write-SecurityLog "Threat intelligence updated" -Level "SUCCESS" -Component "ThreatDetection"
}

function Get-ThreatDetectionHealth {
    $health = @{
        ActiveAlerts = $ActiveAlerts.Count
        CriticalThreats = ($ActiveAlerts.Values | Where-Object { $_.Severity -eq "Critical" }).Count
        EscalatedThreats = ($ActiveAlerts.Values | Where-Object { $_.Escalated }).Count
        LastIntelligenceUpdate = $ThreatIntelligence.LastUpdate
        DetectionStatus = "Active"
    }

    return $health
}

function Write-SecurityLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Component = "ThreatDetection")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [THREAT] [$Component] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(switch($Level){"ERROR"{"Red"}"WARNING"{"Yellow"}"SUCCESS"{"Green"}"ALERT"{"Magenta"}default{"Cyan"}})

    # Log to file
    $logPath = Join-Path $PSScriptRoot "..\logs\threat_detection.log"
    $logMessage | Out-File $logPath -Append -Encoding UTF8
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-ThreatDetection',
    'Start-ThreatMonitoring',
    'New-ThreatAlert',
    'Update-ThreatIntelligence',
    'Get-ThreatDetectionHealth',
    'Write-SecurityLog'
)