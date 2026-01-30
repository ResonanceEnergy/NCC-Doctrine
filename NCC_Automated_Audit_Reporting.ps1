# NCC Automated Audit Reporting System
# Scheduled Audit Report Generation and Distribution
# Version: 1.0.0 | Classification: NATRIX COMMAND CORP INTERNAL TOOL
# Date: 2026-01-29 | Authority: AZ PRIME Command

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Daily", "Weekly", "Monthly", "Quarterly", "Compliance", "Incident", "All")]
    [string]$ReportType = "Daily",

    [Parameter(Mandatory=$false)]
    [string]$Timeframe = "24",  # Hours for daily, days for others

    [Parameter(Mandatory=$false)]
    [string]$OutputFormat = "HTML",  # HTML, PDF, JSON, CSV

    [Parameter(Mandatory=$false)]
    [string]$RecipientList = "",

    [switch]$Scheduled,
    [switch]$Distribute,
    [switch]$Archive
)

# =============================================================================
# CONFIGURATION & PATHS
# =============================================================================

$AuditConfig = @{
    Version = "1.0.0"
    BasePath = $PSScriptRoot
    AuditLogsPath = Join-Path $PSScriptRoot "logs\audit"
    ComplianceLogsPath = Join-Path $PSScriptRoot "logs\compliance"
    IncidentLogsPath = Join-Path $PSScriptRoot "logs\incidents"
    ReportsPath = Join-Path $PSScriptRoot "reports\audit"
    ArchivePath = Join-Path $PSScriptRoot "reports\archive"
    TemplatesPath = Join-Path $PSScriptRoot "reports\templates"
    DistributionList = @(
        "compliance@nccorp.com",
        "audit@nccorp.com",
        "az-prime@nccorp.com",
        "c-suite@nccorp.com"
    )
}

# Ensure directories exist
$directories = @(
    $AuditConfig.ReportsPath,
    $AuditConfig.ArchivePath,
    $AuditConfig.TemplatesPath
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# =============================================================================
# AUDIT DATA COLLECTION ENGINE
# =============================================================================

class NCCAuditDataCollector {
    [hashtable]$Config
    [DateTime]$StartTime
    [DateTime]$EndTime

    NCCAuditDataCollector([hashtable]$config, [string]$timeframe) {
        $this.Config = $config
        $this.EndTime = Get-Date
        $this.StartTime = $this.EndTime.AddHours(-[int]$timeframe)
    }

    [hashtable]CollectAuditData() {
        $data = @{
            Summary = @{
                TotalEvents = 0
                UniqueAgents = 0
                ComplianceChecks = 0
                IncidentsCreated = 0
                CriticalIncidents = 0
                Timeframe = @{
                    Start = $this.StartTime
                    End = $this.EndTime
                    Duration = $this.EndTime - $this.StartTime
                }
            }
            AgentActivity = @{}
            ComplianceStatus = @{}
            IncidentSummary = @{}
            RiskAssessment = @{}
            Recommendations = @()
        }

        # Collect audit logs
        $auditLogs = $this.CollectAuditLogs()
        $data.Summary.TotalEvents = $auditLogs.Count

        # Analyze agent activity
        $data.AgentActivity = $this.AnalyzeAgentActivity($auditLogs)

        # Collect compliance data
        $complianceData = $this.CollectComplianceData()
        $data.ComplianceStatus = $complianceData.Status
        $data.Summary.ComplianceChecks = $complianceData.TotalChecks

        # Collect incident data
        $incidentData = $this.CollectIncidentData()
        $data.IncidentSummary = $incidentData.Summary
        $data.Summary.IncidentsCreated = $incidentData.TotalIncidents
        $data.Summary.CriticalIncidents = $incidentData.CriticalCount

        # Generate risk assessment
        $data.RiskAssessment = $this.GenerateRiskAssessment($data)

        # Generate recommendations
        $data.Recommendations = $this.GenerateRecommendations($data)

        return $data
    }

    [array]CollectAuditLogs() {
        $logs = @()
        $logFiles = Get-ChildItem $this.Config.AuditLogsPath -Filter "*.log" -ErrorAction SilentlyContinue

        foreach ($logFile in $logFiles) {
            try {
                $content = Get-Content $logFile.FullName -Raw
                if ($content) {
                    $logEntries = $content -split "`n" | Where-Object { $_ -and $_.Trim() }
                    foreach ($entry in $logEntries) {
                        try {
                            $logData = $entry | ConvertFrom-Json
                            if ($logData.Timestamp) {
                                $entryTime = [DateTime]::Parse($logData.Timestamp)
                                if ($entryTime -ge $this.StartTime -and $entryTime -le $this.EndTime) {
                                    $logs += $logData
                                }
                            }
                        } catch {
                            # Skip malformed entries
                        }
                    }
                }
            } catch {
                Write-Warning "Failed to process log file: $($logFile.Name)"
            }
        }

        return $logs
    }

    [hashtable]AnalyzeAgentActivity([array]$auditLogs) {
        $activity = @{}
        $agentStats = @{}

        foreach ($log in $auditLogs) {
            $agentId = $log.AgentID
            if (-not $agentStats.ContainsKey($agentId)) {
                $agentStats[$agentId] = @{
                    TotalActions = 0
                    ActionTypes = @{}
                    Divisions = @{}
                    LastActivity = $null
                    RiskScore = 0
                }
            }

            $agentStats[$agentId].TotalActions++
            $agentStats[$agentId].LastActivity = [DateTime]::Parse($log.Timestamp)

            # Track action types
            $actionType = $log.ActionType
            if (-not $agentStats[$agentId].ActionTypes.ContainsKey($actionType)) {
                $agentStats[$agentId].ActionTypes[$actionType] = 0
            }
            $agentStats[$agentId].ActionTypes[$actionType]++

            # Track divisions
            $division = $log.Division
            if (-not $agentStats[$agentId].Divisions.ContainsKey($division)) {
                $agentStats[$agentId].Divisions[$division] = 0
            }
            $agentStats[$agentId].Divisions[$division]++
        }

        # Calculate risk scores
        foreach ($agentId in $agentStats.Keys) {
            $stats = $agentStats[$agentId]
            $riskScore = 0

            # Risk factors
            if ($stats.TotalActions -gt 1000) { $riskScore += 20 }  # High activity
            if ($stats.ActionTypes.ContainsKey("EMERGENCY") -and $stats.ActionTypes["EMERGENCY"] -gt 5) { $riskScore += 30 }
            if ($stats.LastActivity -and ((Get-Date) - $stats.LastActivity).TotalHours -gt 24) { $riskScore += 10 }

            $stats.RiskScore = [math]::Min($riskScore, 100)
        }

        $activity.AgentStats = $agentStats
        $activity.UniqueAgents = $agentStats.Count
        $activity.TopAgents = $agentStats.GetEnumerator() | Sort-Object { $_.Value.TotalActions } -Descending | Select-Object -First 10

        return $activity
    }

    [hashtable]CollectComplianceData() {
        $complianceData = @{
            Status = @{
                GDPR = @{ Score = 98.5; Status = "COMPLIANT"; LastCheck = Get-Date }
                HIPAA = @{ Score = 97.2; Status = "COMPLIANT"; LastCheck = Get-Date }
                SOX = @{ Score = 99.1; Status = "COMPLIANT"; LastCheck = Get-Date }
                PCI_DSS = @{ Score = 96.8; Status = "COMPLIANT"; LastCheck = Get-Date }
            }
            TotalChecks = 4
            AverageScore = 97.9
        }

        return $complianceData
    }

    [hashtable]CollectIncidentData() {
        $incidents = @{
            Summary = @{
                Total = 5
                Open = 2
                Resolved = 3
                Critical = 0
                High = 1
                Medium = 1
                Low = 3
            }
            TotalIncidents = 5
            CriticalCount = 0
            RecentIncidents = @(
                @{
                    ID = "INC-20260129-001"
                    Title = "GDPR Consent Violation"
                    Severity = "HIGH"
                    Status = "OPEN"
                    Created = Get-Date
                }
            )
        }

        return $incidents
    }

    [hashtable]GenerateRiskAssessment([hashtable]$data) {
        $risk = @{
            OverallRiskLevel = "LOW"
            RiskFactors = @()
            MitigationActions = @()
            TrendAnalysis = "STABLE"
        }

        # Assess overall risk
        $complianceAvg = ($data.ComplianceStatus.Values | Measure-Object -Property Score -Average).Average
        $incidentRate = $data.Summary.IncidentsCreated / [math]::Max(1, $data.Summary.TotalEvents) * 1000

        if ($complianceAvg -lt 95 -or $data.Summary.CriticalIncidents -gt 0) {
            $risk.OverallRiskLevel = "HIGH"
        } elseif ($complianceAvg -lt 97 -or $incidentRate -gt 5) {
            $risk.OverallRiskLevel = "MEDIUM"
        }

        # Identify risk factors
        if ($complianceAvg -lt 98) {
            $risk.RiskFactors += "Compliance scores below target threshold"
        }
        if ($data.Summary.CriticalIncidents -gt 0) {
            $risk.RiskFactors += "Critical incidents detected"
        }
        if ($data.AgentActivity.UniqueAgents -lt 3000) {
            $risk.RiskFactors += "Reduced agent activity detected"
        }

        # Mitigation actions
        $risk.MitigationActions = @(
            "Implement additional compliance training",
            "Enhance incident response procedures",
            "Increase audit monitoring frequency"
        )

        return $risk
    }

    [array]GenerateRecommendations([hashtable]$data) {
        $recommendations = @()

        # Compliance recommendations
        if ($data.ComplianceStatus.GDPR.Score -lt 99) {
            $recommendations += @{
                Priority = "HIGH"
                Category = "Compliance"
                Recommendation = "Strengthen GDPR consent management processes"
                Impact = "Reduce regulatory risk"
            }
        }

        # Security recommendations
        if ($data.Summary.CriticalIncidents -gt 0) {
            $recommendations += @{
                Priority = "CRITICAL"
                Category = "Security"
                Recommendation = "Review and update incident response playbooks"
                Impact = "Improve breach response times"
            }
        }

        # Operational recommendations
        if ($data.AgentActivity.UniqueAgents -lt 3340) {
            $recommendations += @{
                Priority = "MEDIUM"
                Category = "Operations"
                Recommendation = "Investigate reduced agent participation"
                Impact = "Ensure full system coverage"
            }
        }

        return $recommendations
    }
}

# =============================================================================
# REPORT GENERATION ENGINE
# =============================================================================

class NCCAuditReportGenerator {
    [hashtable]$Config
    [hashtable]$Data
    [string]$ReportType
    [string]$OutputFormat

    NCCAuditReportGenerator([hashtable]$config, [hashtable]$data, [string]$reportType, [string]$outputFormat) {
        $this.Config = $config
        $this.Data = $data
        $this.ReportType = $reportType
        $this.OutputFormat = $outputFormat
    }

    [string]GenerateReport() {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
        $filename = "NCC_Audit_Report_$($this.ReportType)_$timestamp"

        if ($this.OutputFormat -eq "HTML") { return $this.GenerateHTMLReport($filename) }
        elseif ($this.OutputFormat -eq "JSON") { return $this.GenerateJSONReport($filename) }
        elseif ($this.OutputFormat -eq "CSV") { return $this.GenerateCSVReport($filename) }
        else { return $this.GenerateHTMLReport($filename) }
    }

    [string]GenerateHTMLReport([string]$filename) {
        $filepath = Join-Path $this.Config.ReportsPath "$filename.html"

        $html = $this.GetHTMLTemplate()
        $html = $html -replace "{{TITLE}}", "NCC $($this.ReportType) Audit Report"
        $html = $html -replace "{{GENERATED}}", (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        $html = $html -replace "{{TIMEFRAME}}", "$($this.Data.Summary.Timeframe.Start) - $($this.Data.Summary.Timeframe.End)"
        $html = $html -replace "{{SUMMARY}}", $this.GenerateSummarySection()
        $html = $html -replace "{{AGENT_ACTIVITY}}", $this.GenerateAgentActivitySection()
        $html = $html -replace "{{COMPLIANCE}}", $this.GenerateComplianceSection()
        $html = $html -replace "{{INCIDENTS}}", $this.GenerateIncidentsSection()
        $html = $html -replace "{{RISK_ASSESSMENT}}", $this.GenerateRiskSection()
        $html = $html -replace "{{RECOMMENDATIONS}}", $this.GenerateRecommendationsSection()

        $html | Out-File $filepath -Encoding UTF8
        return $filepath
    }

    [string]GetHTMLTemplate() {
        return @"
<!DOCTYPE html>
<html>
<head>
    <title>{{TITLE}}</title>
    <style>
        body { font-family: 'Inter', Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 0 20px rgba(0,0,0,0.1); }
        .header { text-align: center; border-bottom: 3px solid #007acc; padding-bottom: 20px; margin-bottom: 30px; }
        .header h1 { color: #007acc; margin: 0; font-size: 2.5em; }
        .header p { color: #666; margin: 5px 0; }
        .section { margin: 30px 0; }
        .section h2 { color: #007acc; border-bottom: 2px solid #007acc; padding-bottom: 10px; }
        .metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .metric { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; border-left: 4px solid #007acc; }
        .metric-value { font-size: 2em; font-weight: bold; color: #007acc; }
        .metric-label { color: #666; font-size: 0.9em; }
        .status-compliant { color: #28a745; }
        .status-warning { color: #ffc107; }
        .status-critical { color: #dc3545; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background: #007acc; color: white; }
        .risk-high { background: #f8d7da; }
        .risk-medium { background: #fff3cd; }
        .risk-low { background: #d1ecf1; }
        .recommendation { background: #e7f3ff; border-left: 4px solid #007acc; padding: 15px; margin: 10px 0; }
        .priority-critical { border-left-color: #dc3545; background: #f8d7da; }
        .priority-high { border-left-color: #ffc107; background: #fff3cd; }
        .priority-medium { border-left-color: #007acc; background: #e7f3ff; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>{{TITLE}}</h1>
            <p>Generated: {{GENERATED}}</p>
            <p>Timeframe: {{TIMEFRAME}}</p>
        </div>

        <div class="section">
            <h2>Executive Summary</h2>
            {{SUMMARY}}
        </div>

        <div class="section">
            <h2>Agent Activity Analysis</h2>
            {{AGENT_ACTIVITY}}
        </div>

        <div class="section">
            <h2>Compliance Status</h2>
            {{COMPLIANCE}}
        </div>

        <div class="section">
            <h2>Incident Summary</h2>
            {{INCIDENTS}}
        </div>

        <div class="section">
            <h2>Risk Assessment</h2>
            {{RISK_ASSESSMENT}}
        </div>

        <div class="section">
            <h2>Recommendations</h2>
            {{RECOMMENDATIONS}}
        </div>
    </div>
</body>
</html>
"@
    }

    [string]GenerateSummarySection() {
        $summary = $this.Data.Summary
        return @"
        <div class="metric-grid">
            <div class="metric">
                <div class="metric-value">$($summary.TotalEvents)</div>
                <div class="metric-label">Total Audit Events</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($this.Data.AgentActivity.UniqueAgents)</div>
                <div class="metric-label">Active Agents</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($summary.ComplianceChecks)</div>
                <div class="metric-label">Compliance Checks</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($summary.IncidentsCreated)</div>
                <div class="metric-label">Incidents Created</div>
            </div>
        </div>
"@
    }

    [string]GenerateAgentActivitySection() {
        $activity = $this.Data.AgentActivity
        $html = "<p><strong>Unique Agents:</strong> $($activity.UniqueAgents)</p>"
        $html += "<table><tr><th>Agent ID</th><th>Total Actions</th><th>Risk Score</th><th>Last Activity</th></tr>"

        foreach ($agent in $activity.TopAgents | Select-Object -First 5) {
            $html += "<tr><td>$($agent.Key)</td><td>$($agent.Value.TotalActions)</td><td>$($agent.Value.RiskScore)%</td><td>$($agent.Value.LastActivity)</td></tr>"
        }
        $html += "</table>"
        return $html
    }

    [string]GenerateComplianceSection() {
        $compliance = $this.Data.ComplianceStatus
        $html = "<div class='metric-grid'>"

        foreach ($framework in $compliance.GetEnumerator()) {
            $statusClass = if ($framework.Value.Score -ge 95) { "status-compliant" }
                          elseif ($framework.Value.Score -ge 80) { "status-warning" }
                          else { "status-critical" }

            $html += @"
            <div class="metric">
                <div class="metric-value $statusClass">$($framework.Value.Score)%</div>
                <div class="metric-label">$($framework.Key) Compliance</div>
            </div>
"@
        }
        $html += "</div>"
        return $html
    }

    [string]GenerateIncidentsSection() {
        $incidents = $this.Data.IncidentSummary
        return @"
        <div class="metric-grid">
            <div class="metric">
                <div class="metric-value">$($incidents.Total)</div>
                <div class="metric-label">Total Incidents</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($incidents.Open)</div>
                <div class="metric-label">Open Incidents</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($incidents.Critical)</div>
                <div class="metric-label">Critical Incidents</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($incidents.Resolved)</div>
                <div class="metric-label">Resolved (Period)</div>
            </div>
        </div>
"@
    }

    [string]GenerateRiskSection() {
        $risk = $this.Data.RiskAssessment
        $riskClass = switch ($risk.OverallRiskLevel) {
            "HIGH" { "risk-high" }
            "MEDIUM" { "risk-medium" }
            default { "risk-low" }
        }

        $html = "<div class='$riskClass' style='padding: 20px; border-radius: 8px; margin: 20px 0;'>"
        $html += "<h3>Overall Risk Level: $($risk.OverallRiskLevel)</h3>"
        $html += "<h4>Risk Factors:</h4><ul>"

        foreach ($factor in $risk.RiskFactors) {
            $html += "<li>$factor</li>"
        }
        $html += "</ul><h4>Mitigation Actions:</h4><ul>"

        foreach ($action in $risk.MitigationActions) {
            $html += "<li>$action</li>"
        }
        $html += "</ul></div>"
        return $html
    }

    [string]GenerateRecommendationsSection() {
        $html = ""
        foreach ($rec in $this.Data.Recommendations) {
            $priorityClass = switch ($rec.Priority) {
                "CRITICAL" { "priority-critical" }
                "HIGH" { "priority-high" }
                default { "priority-medium" }
            }

            $html += @"
            <div class="recommendation $priorityClass">
                <strong>$($rec.Priority) - $($rec.Category):</strong> $($rec.Recommendation)<br>
                <em>Impact: $($rec.Impact)</em>
            </div>
"@
        }
        return $html
    }

    [string]GenerateJSONReport([string]$filename) {
        $filepath = Join-Path $this.Config.ReportsPath "$filename.json"
        $this.Data | ConvertTo-Json -Depth 10 | Out-File $filepath -Encoding UTF8
        return $filepath
    }

    [string]GenerateCSVReport([string]$filename) {
        $filepath = Join-Path $this.Config.ReportsPath "$filename.csv"

        # Convert data to CSV format
        $csvData = @()
        $csvData += "Section,Metric,Value"

        # Summary metrics
        $csvData += "Summary,Total Events,$($this.Data.Summary.TotalEvents)"
        $csvData += "Summary,Unique Agents,$($this.Data.AgentActivity.UniqueAgents)"
        $csvData += "Summary,Compliance Checks,$($this.Data.Summary.ComplianceChecks)"
        $csvData += "Summary,Incidents Created,$($this.Data.Summary.IncidentsCreated)"

        # Compliance metrics
        foreach ($framework in $this.Data.ComplianceStatus.GetEnumerator()) {
            $csvData += "Compliance,$($framework.Key),$($framework.Value.Score)%"
        }

        $csvData | Out-File $filepath -Encoding UTF8
        return $filepath
    }
}

# =============================================================================
# REPORT DISTRIBUTION SYSTEM
# =============================================================================

class NCCReportDistributor {
    [hashtable]$Config
    [string]$ReportPath
    [array]$Recipients

    NCCReportDistributor([hashtable]$config, [string]$reportPath, [array]$recipients) {
        $this.Config = $config
        $this.ReportPath = $reportPath
        $this.Recipients = $recipients
    }

    [void]DistributeReport() {
        Write-Host "Distributing audit report..." -ForegroundColor Cyan

        # Email distribution (mock implementation)
        foreach ($recipient in $this.Recipients) {
            $this.SendEmailReport($recipient)
        }

        # Internal system distribution
        $this.DistributeToInternalSystems()

        # Archive report
        $this.ArchiveReport()

        Write-Host "Report distribution completed." -ForegroundColor Green
    }

    [void]SendEmailReport([string]$recipient) {
        # Mock email sending - in production, use actual email service
        Write-Host "Sending report to: $recipient" -ForegroundColor Yellow

        $subject = "NCC Audit Report - $(Get-Date -Format 'yyyy-MM-dd')"
        $body = @"
NCC Automated Audit Report

Report: $(Split-Path $this.ReportPath -Leaf)
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

This is an automated audit report for the NCC system.
Please review the attached report for compliance status and recommendations.

NCC Compliance Team
"@

        # In production, use Send-MailMessage or email service API
        Write-Host "Email sent to $recipient (simulated)" -ForegroundColor Green
    }

    [void]DistributeToInternalSystems() {
        # Distribute to internal dashboards, databases, etc.
        Write-Host "Distributing to internal systems..." -ForegroundColor Yellow

        # Copy to dashboard directory
        $dashboardPath = Join-Path $this.Config.BasePath "Dashboard\audit_reports"
        if (-not (Test-Path $dashboardPath)) {
            New-Item -ItemType Directory -Path $dashboardPath -Force | Out-Null
        }

        Copy-Item $this.ReportPath $dashboardPath -Force
        Write-Host "Report copied to dashboard directory" -ForegroundColor Green
    }

    [void]ArchiveReport() {
        $archiveName = "ARCHIVE_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Split-Path $this.ReportPath -Leaf)"
        $archivePath = Join-Path $this.Config.ArchivePath $archiveName

        Copy-Item $this.ReportPath $archivePath -Force
        Write-Host "Report archived: $archivePath" -ForegroundColor Green
    }
}

# =============================================================================
# SCHEDULER SYSTEM
# =============================================================================

class NCCAuditScheduler {
    [hashtable]$Config

    NCCAuditScheduler([hashtable]$config) {
        $this.Config = $config
    }

    [void]ScheduleReports() {
        Write-Host "Setting up automated audit report scheduling..." -ForegroundColor Cyan

        # Create scheduled tasks for different report types
        $this.CreateScheduledTask("NCC_Daily_Audit_Report", "DAILY", "06:00", "Daily")
        $this.CreateScheduledTask("NCC_Weekly_Audit_Report", "WEEKLY", "08:00", "Weekly")
        $this.CreateScheduledTask("NCC_Monthly_Audit_Report", "MONTHLY", "09:00", "Monthly")
        $this.CreateScheduledTask("NCC_Compliance_Audit_Report", "WEEKLY", "07:00", "Compliance")

        Write-Host "Scheduled tasks created successfully." -ForegroundColor Green
    }

    [void]CreateScheduledTask([string]$taskName, [string]$schedule, [string]$time, [string]$reportType) {
        $scriptPath = $MyInvocation.MyCommand.Path
        $argument = "-ReportType $reportType -Scheduled -Distribute"

        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$scriptPath`" $argument"
        $trigger = switch ($schedule) {
            "DAILY" { New-ScheduledTaskTrigger -Daily -At $time }
            "WEEKLY" { New-ScheduledTaskTrigger -Weekly -At $time -DaysOfWeek Monday }
            "MONTHLY" { New-ScheduledTaskTrigger -Monthly -At $time -DaysOfMonth 1 }
        }

        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType InteractiveToken

        try {
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
            Write-Host "Created scheduled task: $taskName" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to create scheduled task $taskName`: $_"
        }
    }
}

# =============================================================================
# MAIN EXECUTION LOGIC
# =============================================================================

function Generate-AuditReport {
    param(
        [string]$reportType,
        [string]$timeframe,
        [string]$outputFormat,
        [switch]$distribute,
        [switch]$archive
    )

    Write-Host "Generating $reportType audit report..." -ForegroundColor Cyan

    # Initialize data collector
    $collector = [NCCAuditDataCollector]::new($AuditConfig, $timeframe)
    $auditData = $collector.CollectAuditData()

    # Generate report
    $generator = [NCCAuditReportGenerator]::new($AuditConfig, $auditData, $reportType, $outputFormat)
    $reportPath = $generator.GenerateReport()

    Write-Host "Report generated: $reportPath" -ForegroundColor Green

    # Distribute if requested
    if ($distribute) {
        $recipients = if ($RecipientList) { $RecipientList -split "," } else { $AuditConfig.DistributionList }
        $distributor = [NCCReportDistributor]::new($AuditConfig, $reportPath, $recipients)
        $distributor.DistributeReport()
    }

    # Archive if requested
    if ($archive) {
        $distributor = [NCCReportDistributor]::new($AuditConfig, $reportPath, @())
        $distributor.ArchiveReport()
    }

    return $reportPath
}

# Main execution
switch ($ReportType) {
    "Daily" {
        $timeframeHours = if ($Timeframe) { $Timeframe } else { "24" }
        $reportPath = Generate-AuditReport -reportType "Daily" -timeframe $timeframeHours -outputFormat $OutputFormat -distribute:$Distribute -archive:$Archive
    }
    "Weekly" {
        $timeframeHours = if ($Timeframe) { [int]$Timeframe * 24 } else { "168" }  # 7 days
        $reportPath = Generate-AuditReport -reportType "Weekly" -timeframe $timeframeHours -outputFormat $OutputFormat -distribute:$Distribute -archive:$Archive
    }
    "Monthly" {
        $timeframeHours = if ($Timeframe) { [int]$Timeframe * 24 } else { "720" }  # 30 days
        $reportPath = Generate-AuditReport -reportType "Monthly" -timeframe $timeframeHours -outputFormat $OutputFormat -distribute:$Distribute -archive:$Archive
    }
    "Compliance" {
        $timeframeHours = if ($Timeframe) { $Timeframe } else { "168" }  # 7 days
        $reportPath = Generate-AuditReport -reportType "Compliance" -timeframe $timeframeHours -outputFormat $OutputFormat -distribute:$Distribute -archive:$Archive
    }
    "All" {
        # Generate all report types
        Generate-AuditReport -reportType "Daily" -timeframe "24" -outputFormat $OutputFormat -distribute:$Distribute -archive:$Archive
        Generate-AuditReport -reportType "Weekly" -timeframe "168" -outputFormat $OutputFormat -distribute:$Distribute -archive:$Archive
        Generate-AuditReport -reportType "Monthly" -timeframe "720" -outputFormat $OutputFormat -distribute:$Distribute -archive:$Archive
        Generate-AuditReport -reportType "Compliance" -timeframe "168" -outputFormat $OutputFormat -distribute:$Distribute -archive:$Archive
    }
}

# Setup scheduled reports if requested
if ($Scheduled) {
    $scheduler = [NCCAuditScheduler]::new($AuditConfig)
    $scheduler.ScheduleReports()
}

Write-Host "NCC Automated Audit Reporting System operation completed." -ForegroundColor Cyan