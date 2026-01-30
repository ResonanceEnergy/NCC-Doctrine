# NCC Communication Monitoring Dashboard
# Real-time Communication Health and Performance Monitoring

param(
    [switch]$Start,
    [switch]$GenerateReport,
    [switch]$CheckHealth,
    [switch]$ViewMetrics,
    [int]$RefreshInterval = 30
)

$DashboardConfig = @{
    DataPath = Join-Path $PSScriptRoot "network\monitoring.json"
    ReportPath = Join-Path $PSScriptRoot "network\reports"
    DashboardPath = Join-Path $PSScriptRoot "Dashboard\communication-dashboard.html"
}

# Ensure directories exist
if (-not (Test-Path $DashboardConfig.ReportPath)) {
    New-Item -ItemType Directory -Path $DashboardConfig.ReportPath -Force | Out-Null
}

function Write-DashboardLog {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [COMM_DASHBOARD] [$Level] $Message"

    switch ($Level.ToUpper()) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default   { Write-Host $logMessage }
    }
}

function Get-MonitoringData {
    if (Test-Path $DashboardConfig.DataPath) {
        return Get-Content -Path $DashboardConfig.DataPath -Raw | ConvertFrom-Json
    }
    return $null
}

function Calculate-HealthScore {
    param([psobject]$Data)

    if (-not $Data) { return 0 }

    $stats = $Data.NetworkStats
    $totalMessages = $stats.MessagesSent + $stats.MessagesReceived

    if ($totalMessages -eq 0) { return 100 }

    $successRate = ($totalMessages - $stats.MessagesFailed) / $totalMessages
    $agentHealth = ($Data.AgentHealth.Values | Where-Object { $_.Status -eq "Active" }).Count / $Data.AgentHealth.Count

    if ($Data.AgentHealth.Count -eq 0) { $agentHealth = 1 }

    $score = ($successRate * 0.6 + $agentHealth * 0.4) * 100
    return [math]::Round($score, 2)
}

function Generate-HTMLDashboard {
    param([psobject]$Data)

    $healthScore = Calculate-HealthScore -Data $Data
    $healthStatus = switch ($healthScore) {
        {$_ -ge 95} { "EXCELLENT" }
        {$_ -ge 85} { "GOOD" }
        {$_ -ge 70} { "FAIR" }
        default { "CRITICAL" }
    }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NCC Communication Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .header { background: linear-gradient(135deg, #1e3c72, #2a5298); color: white; padding: 20px; border-radius: 8px; }
        .metric-card { background: white; padding: 20px; margin: 10px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .status-excellent { color: #28a745; }
        .status-good { color: #17a2b8; }
        .status-fair { color: #ffc107; }
        .status-critical { color: #dc3545; }
        .chart { height: 200px; background: #f8f9fa; border-radius: 4px; display: flex; align-items: center; justify-content: center; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛰️ NCC Enterprise Communication Dashboard</h1>
        <p>Real-time monitoring of agent communication network</p>
        <div class="metric-card">
            <h2>Overall Health Score</h2>
            <div class="status-$($healthStatus.ToLower())" style="font-size: 2em; font-weight: bold;">
                $healthScore% - $healthStatus
            </div>
            <p>Last updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
    </div>

    <div class="grid">
        <div class="metric-card">
            <h3>📊 Message Statistics</h3>
            <p><strong>Total Messages:</strong> $($Data.NetworkStats.TotalMessages)</p>
            <p><strong>Sent:</strong> $($Data.NetworkStats.MessagesSent)</p>
            <p><strong>Received:</strong> $($Data.NetworkStats.MessagesReceived)</p>
            <p><strong>Failed:</strong> $($Data.NetworkStats.MessagesFailed)</p>
        </div>

        <div class="metric-card">
            <h3>🤖 Agent Status</h3>
            <p><strong>Active Agents:</strong> $($Data.NetworkStats.ActiveAgents)</p>
            <p><strong>Connectivity Checks:</strong> $($Data.NetworkStats.ConnectivityChecks)</p>
        </div>

        <div class="metric-card">
            <h3>⚡ Performance Metrics</h3>
            <div class="chart">Performance Chart Placeholder</div>
        </div>

        <div class="metric-card">
            <h3>🚨 Recent Alerts</h3>
            <div id="alerts">No recent alerts</div>
        </div>
    </div>

    <div class="metric-card">
        <h3>📋 Agent Health Details</h3>
        <table border="1" style="width: 100%; border-collapse: collapse;">
            <tr><th>Agent</th><th>Status</th><th>Last Update</th></tr>
"@

    if ($Data.AgentHealth) {
        foreach ($agent in $Data.AgentHealth.GetEnumerator()) {
            $html += "<tr><td>$($agent.Key)</td><td>$($agent.Value.Status)</td><td>$($agent.Value.LastUpdate)</td></tr>"
        }
    }

    $html += @"
        </table>
    </div>
</body>
</html>
"@

    return $html
}

function Start-DashboardMonitoring {
    Write-DashboardLog "Starting communication dashboard monitoring" -Level "INFO"

    while ($true) {
        try {
            $data = Get-MonitoringData
            if ($data) {
                $html = Generate-HTMLDashboard -Data $data
                $html | Out-File -FilePath $DashboardConfig.DashboardPath -Encoding UTF8

                $healthScore = Calculate-HealthScore -Data $data
                Write-DashboardLog "Dashboard updated - Health Score: $healthScore%" -Level "INFO"
            }
        }
        catch {
            Write-DashboardLog "Error updating dashboard: $($_.Exception.Message)" -Level "ERROR"
        }

        Start-Sleep -Seconds $RefreshInterval
    }
}

function Generate-HealthReport {
    $data = Get-MonitoringData
    if (-not $data) {
        Write-DashboardLog "No monitoring data available" -Level "WARNING"
        return
    }

    $reportPath = Join-Path $DashboardConfig.ReportPath "communication-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

    $report = @"
NCC Communication Health Report
Generated: $(Get-Date)

OVERALL HEALTH
==============
Health Score: $(Calculate-HealthScore -Data $data)%
Status: $(switch ($score) {
    {$_ -ge 95} { "EXCELLENT" }
    {$_ -ge 85} { "GOOD" }
    {$_ -ge 70} { "FAIR" }
    default { "CRITICAL" }
})

MESSAGE STATISTICS
==================
Total Messages: $($data.NetworkStats.TotalMessages)
Messages Sent: $($data.NetworkStats.MessagesSent)
Messages Received: $($data.NetworkStats.MessagesReceived)
Messages Failed: $($data.NetworkStats.MessagesFailed)
Success Rate: $(if ($data.NetworkStats.TotalMessages -gt 0) { [math]::Round((($data.NetworkStats.MessagesSent + $data.NetworkStats.MessagesReceived - $data.NetworkStats.MessagesFailed) / $data.NetworkStats.TotalMessages) * 100, 2) } else { 100 })%

AGENT STATUS
============
Active Agents: $($data.NetworkStats.ActiveAgents)
Connectivity Checks: $($data.NetworkStats.ConnectivityChecks)

AGENT DETAILS
=============
"@

    if ($data.AgentHealth) {
        foreach ($agent in $data.AgentHealth.GetEnumerator()) {
            $report += "$($agent.Key): $($agent.Value.Status) (Last seen: $($agent.Value.LastUpdate))`n"
        }
    }

    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-DashboardLog "Health report generated: $reportPath" -Level "SUCCESS"
}

# Main execution
if ($Start) {
    Start-DashboardMonitoring
}

if ($GenerateReport) {
    Generate-HealthReport
}

if ($CheckHealth) {
    $data = Get-MonitoringData
    $score = Calculate-HealthScore -Data $data
    Write-DashboardLog "Current health score: $score%" -Level "INFO"
    return @{ Score = $score; Data = $data }
}

if ($ViewMetrics) {
    $data = Get-MonitoringData
    Write-DashboardLog "Current Metrics:" -Level "INFO"
    if ($data) {
        Write-DashboardLog "Messages Sent: $($data.NetworkStats.MessagesSent)" -Level "INFO"
        Write-DashboardLog "Messages Received: $($data.NetworkStats.MessagesReceived)" -Level "INFO"
        Write-DashboardLog "Failed Messages: $($data.NetworkStats.MessagesFailed)" -Level "INFO"
        Write-DashboardLog "Active Agents: $($data.NetworkStats.ActiveAgents)" -Level "INFO"
    }
    return $data
}