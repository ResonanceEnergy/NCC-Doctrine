# NCC Security Monitoring Module
# Implements security monitoring dashboard and reporting for Security 10 Directive

# Monitoring Configuration
$MonitoringConfig = @{
    DashboardUpdateInterval = 30  # seconds
    AlertRetentionDays = 30
    ReportGenerationInterval = 3600  # 1 hour
    HealthCheckInterval = 300  # 5 minutes
    MaxLogEntries = 10000
}

# Security metrics
$SecurityMetrics = @{
    TotalAgents = 0
    ActiveAgents = 0
    SecurityScore = 0
    CriticalAlerts = 0
    FailedAuthAttempts = 0
    EncryptionStatus = "Unknown"
    LastUpdate = Get-Date
}

function Initialize-SecurityMonitoring {
    param([string]$AgentName)

    Write-SecurityLog "Initializing security monitoring for agent: $AgentName" -Component "Monitoring"

    # Initialize monitoring databases
    Initialize-MonitoringDatabases

    # Start dashboard updates
    Start-MonitoringDashboard

    Write-SecurityLog "Security monitoring initialized for $AgentName" -Level "SUCCESS" -Component "Monitoring"
}

function Initialize-MonitoringDatabases {
    # Create monitoring database files
    $dataDir = Join-Path $PSScriptRoot "..\data"
    if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }

    $metricsPath = Join-Path $dataDir "security_metrics.json"
    if (-not (Test-Path $metricsPath)) {
        $SecurityMetrics | ConvertTo-Json -Depth 10 | Out-File $metricsPath -Encoding UTF8
    }

    $reportsPath = Join-Path $dataDir "security_reports.json"
    if (-not (Test-Path $reportsPath)) {
        @{Reports = @(); LastGenerated = Get-Date} | ConvertTo-Json | Out-File $reportsPath -Encoding UTF8
    }
}

function Start-MonitoringDashboard {
    Write-SecurityLog "Starting security monitoring dashboard..." -Component "Monitoring"

    # Start background dashboard update job
    $job = Start-Job -ScriptBlock {
        param($Config)

        while ($true) {
            try {
                Update-SecurityMetrics
                Update-DashboardData
                Generate-HealthReport

                Start-Sleep -Seconds $Config.DashboardUpdateInterval
            }
            catch {
                Write-Host "Dashboard update error: $($_.Exception.Message)" -ForegroundColor Red
                Start-Sleep -Seconds 60
            }
        }
    } -ArgumentList $MonitoringConfig

    Write-SecurityLog "Monitoring dashboard started (ID: $($job.Id))" -Level "SUCCESS" -Component "Monitoring"
}

function Update-SecurityMetrics {
    # Collect security metrics from all components
    $metrics = @{
        Timestamp = Get-Date
        AgentMetrics = Get-AgentMetrics
        AccessControlMetrics = Get-AccessControlMetrics
        EncryptionMetrics = Get-EncryptionMetrics
        ThreatDetectionMetrics = Get-ThreatDetectionMetrics
        ComplianceMetrics = Get-ComplianceMetrics
    }

    # Calculate overall security score
    $metrics.SecurityScore = Calculate-SecurityScore -Metrics $metrics

    # Update global metrics
    $SecurityMetrics.TotalAgents = $metrics.AgentMetrics.Total
    $SecurityMetrics.ActiveAgents = $metrics.AgentMetrics.Active
    $SecurityMetrics.SecurityScore = $metrics.SecurityScore
    $SecurityMetrics.CriticalAlerts = $metrics.ThreatDetectionMetrics.CriticalAlerts
    $SecurityMetrics.FailedAuthAttempts = $metrics.AccessControlMetrics.FailedAttempts
    $SecurityMetrics.EncryptionStatus = $metrics.EncryptionMetrics.Status
    $SecurityMetrics.LastUpdate = Get-Date

    # Save metrics
    $metricsPath = Join-Path $PSScriptRoot "..\data\security_metrics.json"
    $SecurityMetrics | ConvertTo-Json -Depth 10 | Out-File $metricsPath -Encoding UTF8
}

function Get-AgentMetrics {
    $agentsPath = Join-Path $PSScriptRoot "..\data\registered_agents.json"
    if (Test-Path $agentsPath) {
        $agents = Get-Content $agentsPath | ConvertFrom-Json
        return @{
            Total = $agents.Count
            Active = ($agents | Where-Object { $_.Status -eq "Active" }).Count
            Inactive = ($agents | Where-Object { $_.Status -eq "Inactive" }).Count
        }
    }

    return @{ Total = 0; Active = 0; Inactive = 0 }
}

function Get-AccessControlMetrics {
    # Collect access control metrics
    return @{
        ActiveSessions = 0  # Would be populated from access control module
        FailedAttempts = 0
        LockedAccounts = 0
        MFAAdoption = 0.0
    }
}

function Get-EncryptionMetrics {
    # Collect encryption metrics
    $health = @{ Status = "Unknown"; KeysRotated = 0; ExpiredCerts = 0 }

    try {
        # Check encryption health
        $keyDir = Join-Path $PSScriptRoot "..\keys"
        if (Test-Path $keyDir) {
            $keyCount = (Get-ChildItem $keyDir -Filter "*.key").Count
            $health.KeysRotated = $keyCount
        }

        $certPath = Join-Path $PSScriptRoot "..\certificates\agent_certificates.json"
        if (Test-Path $certPath) {
            $certs = Get-Content $certPath | ConvertFrom-Json
            $expiredCount = 0
            foreach ($cert in $certs.Values) {
                if ((Get-Date) -gt $cert.Expires) { $expiredCount++ }
            }
            $health.ExpiredCerts = $expiredCount
        }

        $health.Status = if ($health.ExpiredCerts -eq 0) { "Healthy" } else { "Warning" }
    }
    catch {
        $health.Status = "Error"
    }

    return $health
}

function Get-ThreatDetectionMetrics {
    # Collect threat detection metrics
    $alertsPath = Join-Path $PSScriptRoot "..\data\active_alerts.json"
    if (Test-Path $alertsPath) {
        try {
            $alerts = Get-Content $alertsPath | ConvertFrom-Json
            $criticalCount = ($alerts.Values | Where-Object { $_.Severity -eq "Critical" }).Count
            $totalCount = $alerts.Count

            return @{
                TotalAlerts = $totalCount
                CriticalAlerts = $criticalCount
                ActiveScans = 1  # Simplified
                ThreatsBlocked = 0
            }
        }
        catch {
            return @{ TotalAlerts = 0; CriticalAlerts = 0; ActiveScans = 0; ThreatsBlocked = 0 }
        }
    }

    return @{ TotalAlerts = 0; CriticalAlerts = 0; ActiveScans = 0; ThreatsBlocked = 0 }
}

function Get-ComplianceMetrics {
    # Collect compliance metrics
    return @{
        CompliantAgents = 0
        NonCompliantAgents = 0
        PendingAudits = 0
        LastAuditDate = Get-Date
        ComplianceScore = 0.0
    }
}

function Calculate-SecurityScore {
    param($Metrics)

    # Calculate weighted security score
    $weights = @{
        AgentHealth = 0.2
        AccessControl = 0.25
        Encryption = 0.2
        ThreatDetection = 0.25
        Compliance = 0.1
    }

    $score = 0

    # Agent health score
    $agentScore = if ($Metrics.AgentMetrics.Total -gt 0) {
        $Metrics.AgentMetrics.Active / $Metrics.AgentMetrics.Total
    } else { 0 }
    $score += $agentScore * $weights.AgentHealth

    # Access control score (simplified)
    $accessScore = 0.8  # Would be calculated from actual metrics
    $score += $accessScore * $weights.AccessControl

    # Encryption score
    $encryptionScore = if ($Metrics.EncryptionMetrics.Status -eq "Healthy") { 1.0 }
                      elseif ($Metrics.EncryptionMetrics.Status -eq "Warning") { 0.7 }
                      else { 0.3 }
    $score += $encryptionScore * $weights.Encryption

    # Threat detection score
    $threatScore = if ($Metrics.ThreatDetectionMetrics.CriticalAlerts -eq 0) { 1.0 }
                   elseif ($Metrics.ThreatDetectionMetrics.CriticalAlerts -le 5) { 0.7 }
                   else { 0.4 }
    $score += $threatScore * $weights.ThreatDetection

    # Compliance score (simplified)
    $complianceScore = 0.85
    $score += $complianceScore * $weights.Compliance

    return [math]::Round($score * 100, 1)
}

function Update-DashboardData {
    # Generate dashboard HTML
    $dashboardPath = Join-Path $PSScriptRoot "..\dashboard\security_dashboard.html"

    if (-not (Test-Path (Split-Path $dashboardPath))) {
        New-Item -ItemType Directory -Path (Split-Path $dashboardPath) -Force | Out-Null
    }

    $dashboardHtml = Generate-DashboardHTML
    $dashboardHtml | Out-File $dashboardPath -Encoding UTF8
}

function Generate-DashboardHTML {
    $metrics = $SecurityMetrics

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NCC Security Monitoring Dashboard - Security 10 Directive</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .header { background: linear-gradient(135deg, #1e3c72, #2a5298); color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 20px; }
        .metric-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric-title { font-size: 14px; color: #666; margin-bottom: 10px; text-transform: uppercase; }
        .metric-value { font-size: 32px; font-weight: bold; color: #333; }
        .status-healthy { color: #28a745; }
        .status-warning { color: #ffc107; }
        .status-critical { color: #dc3545; }
        .alerts-list { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .alert-item { padding: 10px; border-bottom: 1px solid #eee; }
        .alert-critical { border-left: 4px solid #dc3545; }
        .alert-high { border-left: 4px solid #ffc107; }
        .alert-medium { border-left: 4px solid #28a745; }
        .timestamp { color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>ðŸ”— NCC Security Monitoring Dashboard</h1>
        <p>Security 10 Directive Compliance | Last Updated: $($metrics.LastUpdate)</p>
    </div>

    <div class="metrics-grid">
        <div class="metric-card">
            <div class="metric-title">Overall Security Score</div>
            <div class="metric-value $(if ($metrics.SecurityScore -ge 90) { 'status-healthy' } elseif ($metrics.SecurityScore -ge 70) { 'status-warning' } else { 'status-critical' })">$($metrics.SecurityScore)%</div>
        </div>

        <div class="metric-card">
            <div class="metric-title">Active Agents</div>
            <div class="metric-value status-healthy">$($metrics.ActiveAgents)/$($metrics.TotalAgents)</div>
        </div>

        <div class="metric-card">
            <div class="metric-title">Critical Alerts</div>
            <div class="metric-value $(if ($metrics.CriticalAlerts -eq 0) { 'status-healthy' } else { 'status-critical' })">$($metrics.CriticalAlerts)</div>
        </div>

        <div class="metric-card">
            <div class="metric-title">Encryption Status</div>
            <div class="metric-value $(if ($metrics.EncryptionStatus -eq 'Healthy') { 'status-healthy' } elseif ($metrics.EncryptionStatus -eq 'Warning') { 'status-warning' } else { 'status-critical' })">$($metrics.EncryptionStatus)</div>
        </div>

        <div class="metric-card">
            <div class="metric-title">Failed Auth Attempts</div>
            <div class="metric-value $(if ($metrics.FailedAuthAttempts -eq 0) { 'status-healthy' } elseif ($metrics.FailedAuthAttempts -le 5) { 'status-warning' } else { 'status-critical' })">$($metrics.FailedAuthAttempts)</div>
        </div>
    </div>

    <div class="alerts-list">
        <h2>Recent Security Alerts</h2>
        <div id="alerts-container">
            <!-- Alerts will be populated here -->
        </div>
    </div>

    <script>
        // Auto-refresh dashboard
        setTimeout(function() {
            location.reload();
        }, 30000); // Refresh every 30 seconds
    </script>
</body>
</html>
"@

    return $html
}

function Generate-HealthReport {
    $report = @{
        ReportId = [Guid]::NewGuid().ToString()
        Generated = Get-Date
        Period = "Last 24 Hours"
        Metrics = $SecurityMetrics
        Recommendations = Generate-SecurityRecommendations
    }

    # Save report
    $reportsPath = Join-Path $PSScriptRoot "..\data\security_reports.json"
    $reports = Get-Content $reportsPath | ConvertFrom-Json
    $reports.Reports += $report
    $reports.LastGenerated = Get-Date

    # Keep only last 30 reports
    if ($reports.Reports.Count -gt 30) {
        $reports.Reports = $reports.Reports | Select-Object -Last 30
    }

    $reports | ConvertTo-Json -Depth 10 | Out-File $reportsPath -Encoding UTF8
}

function Generate-SecurityRecommendations {
    $recommendations = @()

    if ($SecurityMetrics.SecurityScore -lt 80) {
        $recommendations += "Overall security score is below acceptable threshold. Immediate review required."
    }

    if ($SecurityMetrics.CriticalAlerts -gt 0) {
        $recommendations += "Critical security alerts detected. Immediate investigation required."
    }

    if ($SecurityMetrics.EncryptionStatus -ne "Healthy") {
        $recommendations += "Encryption system requires attention. Check certificate validity and key rotation."
    }

    if ($SecurityMetrics.FailedAuthAttempts -gt 10) {
        $recommendations += "High number of failed authentication attempts. Review access control policies."
    }

    if ($recommendations.Count -eq 0) {
        $recommendations += "All security metrics within acceptable parameters. Continue monitoring."
    }

    return $recommendations
}

function Get-SecurityDashboardData {
    return @{
        Metrics = $SecurityMetrics
        LastUpdate = Get-Date
        Status = "Active"
    }
}

function Write-SecurityLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Component = "Monitoring")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [MONITOR] [$Component] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(switch($Level){"ERROR"{"Red"}"WARNING"{"Yellow"}"SUCCESS"{"Green"}default{"Cyan"}})

    # Log to file
    $logPath = Join-Path $PSScriptRoot "..\logs\security_monitoring.log"
    $logMessage | Out-File $logPath -Append -Encoding UTF8
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-SecurityMonitoring',
    'Update-SecurityMetrics',
    'Get-SecurityDashboardData',
    'Generate-HealthReport',
    'Write-SecurityLog'
)