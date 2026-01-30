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
#Requires -Version 5.1

<#
.SYNOPSIS
    NCC.DataQualityMonitor.ps1 - Data Quality Monitoring and Alerting System

.DESCRIPTION
    This script monitors data quality across the NCC enterprise data repository,
    performs automated quality checks, generates alerts, and maintains quality metrics.

.PARAMETER Mode
    Monitoring mode: Continuous, Batch, or Report

.PARAMETER IntervalMinutes
    Monitoring interval in minutes (default: 15)

.PARAMETER AlertThreshold
    Quality score threshold for alerts (default: 85)

.EXAMPLE
    .\NCC.DataQualityMonitor.ps1 -Mode Continuous

.EXAMPLE
    .\NCC.DataQualityMonitor.ps1 -Mode Report -AlertThreshold 90

.NOTES
    Author: NCC Data Quality Team
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Continuous", "Batch", "Report")]
    [string]$Mode = "Batch",

    [Parameter(Mandatory = $false)]
    [int]$IntervalMinutes = 15,

    [Parameter(Mandatory = $false)]
    [int]$AlertThreshold = 85,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Configuration
$Config = @{
    DataRoot = "_enterprise/data"
    QualityReportsPath = "_enterprise/reports/quality"
    AlertsPath = "_enterprise/alerts"
    LogPath = "_enterprise/logs"
    QualityThresholds = @{
        Critical = 70
        Warning = 85
        Good = 95
    }
    MaxRetries = 3
    AlertCooldownMinutes = 60
}

# Global variables
$QualityHistory = @{}
$LastAlerts = @{}

function Write-QualityLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"

    Write-Host $LogEntry

    $logFile = Join-Path $Config.LogPath "NCC_DataQualityMonitor_$(Get-Date -Format 'yyyy-MM-dd').log"
    Add-Content -Path $logFile -Value $LogEntry -ErrorAction SilentlyContinue
}

function Initialize-QualityMonitor {
    Write-QualityLog "Initializing NCC Data Quality Monitor..." "INFO"

    # Create required directories
    $directories = @(
        $Config.QualityReportsPath,
        $Config.AlertsPath,
        $Config.LogPath
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            Write-QualityLog "Created directory: $dir" "INFO"
        }
    }

    # Load quality history if exists
    $historyFile = Join-Path $Config.QualityReportsPath "quality_history.json"
    if (Test-Path $historyFile) {
        try {
            $script:QualityHistory = Get-Content $historyFile -Raw | ConvertFrom-Json
            Write-QualityLog "Loaded quality history with $($script:QualityHistory.PSObject.Properties.Count) entries" "INFO"
        }
        catch {
            Write-QualityLog "Failed to load quality history: $($_.Exception.Message)" "WARNING"
            $script:QualityHistory = @{}
        }
    }

    # Load last alerts
    $alertsFile = Join-Path $Config.AlertsPath "last_alerts.json"
    if (Test-Path $alertsFile) {
        try {
            $script:LastAlerts = Get-Content $alertsFile -Raw | ConvertFrom-Json
            Write-QualityLog "Loaded last alerts data" "INFO"
        }
        catch {
            Write-QualityLog "Failed to load alerts data: $($_.Exception.Message)" "WARNING"
            $script:LastAlerts = @{}
        }
    }

    Write-QualityLog "Quality monitor initialization completed" "INFO"
}

function Get-DataFiles {
    param([string]$DataType)

    $dataPath = switch ($DataType) {
        "agent" { Join-Path $Config.DataRoot "agent_data" }
        "division" { Join-Path $Config.DataRoot "division_data" }
        "enterprise" { Join-Path $Config.DataRoot "enterprise_data" }
        default { $Config.DataRoot }
    }

    if (-not (Test-Path $dataPath)) {
        Write-QualityLog "Data path not found: $dataPath" "WARNING"
        return @()
    }

    $files = Get-ChildItem -Path $dataPath -Filter "*.json" -ErrorAction SilentlyContinue
    Write-QualityLog "Found $($files.Count) $DataType data files" "INFO"
    return $files
}

function Test-DataCompleteness {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,

        [Parameter(Mandatory = $true)]
        [string]$DataType
    )

    if ($Data.Count -eq 0) {
        return @{ Score = 0; Details = "No data to evaluate" }
    }

    $completeRecords = 0
    $missingFields = @{}

    foreach ($record in $Data) {
        $isComplete = $true

        switch ($DataType) {
            "agent" {
                $requiredFields = @("agent_id", "agent_name", "division", "status")
                foreach ($field in $requiredFields) {
                    if (-not (Get-Member -InputObject $record -Name $field -MemberType Properties)) {
                        $isComplete = $false
                        if (-not $missingFields.ContainsKey($field)) {
                            $missingFields[$field] = 0
                        }
                        $missingFields[$field]++
                    }
                }
            }
            "division" {
                $requiredFields = @("division_id", "division_name", "metrics")
                foreach ($field in $requiredFields) {
                    if (-not (Get-Member -InputObject $record -Name $field -MemberType Properties)) {
                        $isComplete = $false
                        if (-not $missingFields.ContainsKey($field)) {
                            $missingFields[$field] = 0
                        }
                        $missingFields[$field]++
                    }
                }
            }
            "enterprise" {
                $requiredFields = @("timestamp", "enterprise_metrics")
                foreach ($field in $requiredFields) {
                    if (-not (Get-Member -InputObject $record -Name $field -MemberType Properties)) {
                        $isComplete = $false
                        if (-not $missingFields.ContainsKey($field)) {
                            $missingFields[$field] = 0
                        }
                        $missingFields[$field]++
                    }
                }
            }
        }

        if ($isComplete) {
            $completeRecords++
        }
    }

    $completenessScore = [math]::Round(($completeRecords / $Data.Count) * 100, 2)

    return @{
        Score = $completenessScore
        Details = "Complete records: $completeRecords/$($Data.Count)"
        MissingFields = $missingFields
    }
}

function Test-DataAccuracy {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,

        [Parameter(Mandatory = $true)]
        [string]$DataType
    )

    if ($Data.Count -eq 0) {
        return @{ Score = 0; Details = "No data to evaluate" }
    }

    $accurateRecords = 0
    $accuracyIssues = @()

    foreach ($record in $Data) {
        $isAccurate = $true

        switch ($DataType) {
            "agent" {
                # Check performance score range
                if ($record.performance_score -and ($record.performance_score -lt 0 -or $record.performance_score -gt 100)) {
                    $isAccurate = $false
                    $accuracyIssues += "Invalid performance score: $($record.performance_score)"
                }

                # Check email format
                if ($record.contact_info -and $record.contact_info.email) {
                    if ($record.contact_info.email -notmatch "^[^@\s]+@[^@\s]+\.[^@\s]+$") {
                        $isAccurate = $false
                        $accuracyIssues += "Invalid email format: $($record.contact_info.email)"
                    }
                }
            }
            "division" {
                # Check metric ranges
                if ($record.metrics) {
                    if ($record.metrics.success_rate -and ($record.metrics.success_rate -lt 0 -or $record.metrics.success_rate -gt 100)) {
                        $isAccurate = $false
                        $accuracyIssues += "Invalid success rate: $($record.metrics.success_rate)"
                    }
                    if ($record.metrics.resource_utilization -and ($record.metrics.resource_utilization -lt 0 -or $record.metrics.resource_utilization -gt 100)) {
                        $isAccurate = $false
                        $accuracyIssues += "Invalid resource utilization: $($record.metrics.resource_utilization)"
                    }
                }
            }
        }

        if ($isAccurate) {
            $accurateRecords++
        }
    }

    $accuracyScore = [math]::Round(($accurateRecords / $Data.Count) * 100, 2)

    return @{
        Score = $accuracyScore
        Details = "Accurate records: $accurateRecords/$($Data.Count)"
        Issues = $accuracyIssues
    }
}

function Test-DataConsistency {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,

        [Parameter(Mandatory = $true)]
        [string]$DataType
    )

    if ($Data.Count -eq 0) {
        return @{ Score = 0; Details = "No data to evaluate" }
    }

    $consistencyScore = 100
    $consistencyIssues = @()

    switch ($DataType) {
        "agent" {
            # Check for duplicate agent IDs
            $agentIds = $Data | Where-Object { $_.agent_id } | Select-Object -ExpandProperty agent_id
            $uniqueIds = $agentIds | Select-Object -Unique
            if ($agentIds.Count -ne $uniqueIds.Count) {
                $duplicates = $agentIds.Count - $uniqueIds.Count
                $consistencyScore = [math]::Max(0, $consistencyScore - ($duplicates * 5))
                $consistencyIssues += "Found $duplicates duplicate agent IDs"
            }

            # Check division name consistency
            $divisions = $Data | Where-Object { $_.division } | Select-Object -ExpandProperty division | Select-Object -Unique
            # This would need a master division list for full validation
        }
        "division" {
            # Check for duplicate division IDs
            $divisionIds = $Data | Where-Object { $_.division_id } | Select-Object -ExpandProperty division_id
            $uniqueIds = $divisionIds | Select-Object -Unique
            if ($divisionIds.Count -ne $uniqueIds.Count) {
                $duplicates = $divisionIds.Count - $uniqueIds.Count
                $consistencyScore = [math]::Max(0, $consistencyScore - ($duplicates * 10))
                $consistencyIssues += "Found $duplicates duplicate division IDs"
            }
        }
    }

    return @{
        Score = [math]::Round($consistencyScore, 2)
        Details = "Consistency check completed"
        Issues = $consistencyIssues
    }
}

function Test-DataTimeliness {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,

        [Parameter(Mandatory = $true)]
        [string]$DataType
    )

    if ($Data.Count -eq 0) {
        return @{ Score = 0; Details = "No data to evaluate" }
    }

    $timelyRecords = 0
    $maxAgeHours = switch ($DataType) {
        "agent" { 24 }  # Agent data should be updated daily
        "division" { 12 }  # Division data should be updated twice daily
        "enterprise" { 6 }  # Enterprise data should be updated every 6 hours
        default { 24 }
    }

    $cutoffDate = (Get-Date).AddHours(-$maxAgeHours)

    foreach ($record in $Data) {
        $recordTimestamp = $record.timestamp
        if (-not $recordTimestamp) {
            $recordTimestamp = $record.metadata.updated_at
        }

        if ($recordTimestamp) {
            try {
                $recordDate = [DateTime]::Parse($recordTimestamp)
                if ($recordDate -gt $cutoffDate) {
                    $timelyRecords++
                }
            }
            catch {
                Write-QualityLog "Invalid timestamp format: $recordTimestamp" "WARNING"
            }
        }
    }

    $timelinessScore = [math]::Round(($timelyRecords / $Data.Count) * 100, 2)

    return @{
        Score = $timelinessScore
        Details = "Timely records: $timelyRecords/$($Data.Count) (within $maxAgeHours hours)"
    }
}

function Test-DataValidity {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,

        [Parameter(Mandatory = $true)]
        [string]$DataType
    )

    if ($Data.Count -eq 0) {
        return @{ Score = 0; Details = "No data to evaluate" }
    }

    $validRecords = 0
    $validityIssues = @()

    foreach ($record in $Data) {
        $isValid = $true

        # Check required metadata
        if (-not $record.metadata) {
            $isValid = $false
            $validityIssues += "Missing metadata"
        }
        elseif (-not $record.metadata.version) {
            $isValid = $false
            $validityIssues += "Missing version in metadata"
        }

        # Type-specific validity checks
        switch ($DataType) {
            "agent" {
                if ($record.agent_id -and $record.agent_id -notmatch "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$") {
                    $isValid = $false
                    $validityIssues += "Invalid agent ID format: $($record.agent_id)"
                }
            }
            "division" {
                if ($record.division_id -and $record.division_id -notmatch "^[A-Za-z_]+$") {
                    $isValid = $false
                    $validityIssues += "Invalid division ID format: $($record.division_id)"
                }
            }
        }

        if ($isValid) {
            $validRecords++
        }
    }

    $validityScore = [math]::Round(($validRecords / $Data.Count) * 100, 2)

    return @{
        Score = $validityScore
        Details = "Valid records: $validRecords/$($Data.Count)"
        Issues = $validityIssues
    }
}

function Invoke-QualityAssessment {
    param([string]$DataType)

    Write-QualityLog "Starting quality assessment for $DataType data..." "INFO"

    $dataFiles = Get-DataFiles -DataType $DataType
    if ($dataFiles.Count -eq 0) {
        Write-QualityLog "No $DataType data files found for assessment" "WARNING"
        return $null
    }

    # Load and combine data from all files
    $allData = @()
    foreach ($file in $dataFiles) {
        try {
            $fileData = Get-Content $file.FullName -Raw | ConvertFrom-Json
            if ($fileData -is [array]) {
                $allData += $fileData
            }
            else {
                $allData += $fileData
            }
        }
        catch {
            Write-QualityLog "Failed to load data from $($file.FullName): $($_.Exception.Message)" "ERROR"
        }
    }

    if ($allData.Count -eq 0) {
        Write-QualityLog "No valid $DataType data found" "WARNING"
        return $null
    }

    Write-QualityLog "Assessing quality of $($allData.Count) $DataType records" "INFO"

    # Perform quality checks
    $completeness = Test-DataCompleteness -Data $allData -DataType $DataType
    $accuracy = Test-DataAccuracy -Data $allData -DataType $DataType
    $consistency = Test-DataConsistency -Data $allData -DataType $DataType
    $timeliness = Test-DataTimeliness -Data $allData -DataType $DataType
    $validity = Test-DataValidity -Data $allData -DataType $DataType

    # Calculate overall quality score (weighted average)
    $overallScore = [math]::Round((
        ($completeness.Score * 0.25) +
        ($accuracy.Score * 0.25) +
        ($consistency.Score * 0.20) +
        ($timeliness.Score * 0.15) +
        ($validity.Score * 0.15)
    ), 2)

    $qualityReport = @{
        timestamp = (Get-Date).ToString("o")
        data_type = $DataType
        record_count = $allData.Count
        overall_quality_score = $overallScore
        quality_dimensions = @{
            completeness = $completeness
            accuracy = $accuracy
            consistency = $consistency
            timeliness = $timeliness
            validity = $validity
        }
        assessment_metadata = @{
            assessed_by = "NCC.DataQualityMonitor"
            assessment_version = "1.0.0"
            assessment_duration_seconds = 0
        }
    }

    Write-QualityLog "$DataType quality assessment completed. Overall score: $overallScore%" "INFO"
    return $qualityReport
}

function New-QualityAlert {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DataType,

        [Parameter(Mandatory = $true)]
        [hashtable]$QualityReport,

        [Parameter(Mandatory = $true)]
        [int]$Threshold
    )

    $alerts = @()

    # Check overall quality score
    if ($QualityReport.overall_quality_score -lt $Threshold) {
        $alerts += @{
            alert_id = [guid]::NewGuid().ToString()
            alert_type = "quality_threshold_breached"
            severity = if ($QualityReport.overall_quality_score -lt $Config.QualityThresholds.Critical) { "critical" }
                      elseif ($QualityReport.overall_quality_score -lt $Config.QualityThresholds.Warning) { "warning" }
                      else { "info" }
            message = "$DataType data quality below threshold: $($QualityReport.overall_quality_score)% (threshold: $Threshold%)"
            data_type = $DataType
            quality_score = $QualityReport.overall_quality_score
            threshold = $Threshold
            timestamp = (Get-Date).ToString("o")
            details = $QualityReport.quality_dimensions
        }
    }

    # Check individual dimension scores
    foreach ($dimension in $QualityReport.quality_dimensions.PSObject.Properties) {
        $dimensionScore = $dimension.Value.Score
        if ($dimensionScore -lt ($Threshold * 0.8)) {  # 80% of main threshold
            $alerts += @{
                alert_id = [guid]::NewGuid().ToString()
                alert_type = "dimension_quality_issue"
                severity = "warning"
                message = "$DataType $($dimension.Name) quality low: $dimensionScore%"
                data_type = $DataType
                dimension = $dimension.Name
                quality_score = $dimensionScore
                timestamp = (Get-Date).ToString("o")
                details = $dimension.Value
            }
        }
    }

    return $alerts
}

function Send-QualityAlerts {
    param([array]$Alerts)

    if ($Alerts.Count -eq 0) {
        return
    }

    Write-QualityLog "Sending $($Alerts.Count) quality alerts..." "INFO"

    foreach ($alert in $Alerts) {
        # Check if alert was sent recently (cooldown period)
        $alertKey = "$($alert.data_type)_$($alert.alert_type)"
        $lastSent = $script:LastAlerts[$alertKey]

        if ($lastSent) {
            $lastSentTime = [DateTime]::Parse($lastSent)
            $cooldownEnd = $lastSentTime.AddMinutes($Config.AlertCooldownMinutes)
            if ((Get-Date) -lt $cooldownEnd) {
                Write-QualityLog "Alert '$alertKey' still in cooldown period, skipping" "INFO"
                continue
            }
        }

        # Send alert (in a real system, this would integrate with notification systems)
        Write-QualityLog "ALERT [$($alert.severity.ToUpper())]: $($alert.message)" "WARNING"

        # Log alert to file
        $alertFile = Join-Path $Config.AlertsPath "quality_alert_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
        if (-not $DryRun) {
            $alert | ConvertTo-Json -Depth 10 | Set-Content -Path $alertFile -Encoding UTF8
        }

        # Update last sent time
        $script:LastAlerts[$alertKey] = (Get-Date).ToString("o")
    }

    # Save updated alert tracking
    $alertsTrackingFile = Join-Path $Config.AlertsPath "last_alerts.json"
    if (-not $DryRun) {
        $script:LastAlerts | ConvertTo-Json | Set-Content -Path $alertsTrackingFile -Encoding UTF8
    }
}

function Save-QualityReport {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$QualityReport,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $reportFile = Join-Path $Config.QualityReportsPath "quality_report_$($QualityReport.data_type)_$timestamp.json"

    if (-not $DryRun) {
        $QualityReport | ConvertTo-Json -Depth 10 | Set-Content -Path $reportFile -Encoding UTF8
    }

    Write-QualityLog "Quality report saved: $reportFile" "INFO"

    # Update quality history
    $historyKey = "$($QualityReport.data_type)_$(Get-Date -Format 'yyyy-MM-dd')"
    $script:QualityHistory[$historyKey] = @{
        date = Get-Date -Format "yyyy-MM-dd"
        data_type = $QualityReport.data_type
        quality_score = $QualityReport.overall_quality_score
        record_count = $QualityReport.record_count
        report_file = $reportFile
    }

    # Save quality history
    $historyFile = Join-Path $Config.QualityReportsPath "quality_history.json"
    if (-not $DryRun) {
        $script:QualityHistory | ConvertTo-Json | Set-Content -Path $historyFile -Encoding UTF8
    }
}

function Invoke-BatchQualityMonitoring {
    Write-QualityLog "Starting batch quality monitoring..." "INFO"

    $dataTypes = @("agent", "division", "enterprise")
    $allQualityReports = @()

    foreach ($dataType in $dataTypes) {
        $qualityReport = Invoke-QualityAssessment -DataType $dataType
        if ($qualityReport) {
            $allQualityReports += $qualityReport
            Save-QualityReport -QualityReport $qualityReport -DryRun:$DryRun

            # Generate alerts
            $alerts = New-QualityAlert -DataType $dataType -QualityReport $qualityReport -Threshold $AlertThreshold
            Send-QualityAlerts -Alerts $alerts
        }
    }

    # Generate summary report
    if ($allQualityReports.Count -gt 0) {
        $summaryReport = @{
            timestamp = (Get-Date).ToString("o")
            report_type = "batch_quality_summary"
            data_types_assessed = $dataTypes.Count
            total_records = ($allQualityReports | Measure-Object -Property record_count -Sum).Sum
            average_quality_score = [math]::Round(($allQualityReports | Measure-Object -Property overall_quality_score -Average).Average, 2)
            quality_breakdown = $allQualityReports | ForEach-Object {
                @{
                    data_type = $_.data_type
                    quality_score = $_.overall_quality_score
                    record_count = $_.record_count
                }
            }
            alerts_generated = $allQualityReports | ForEach-Object {
                $alerts = New-QualityAlert -DataType $_.data_type -QualityReport $_ -Threshold $AlertThreshold
                $alerts.Count
            } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        }

        $summaryFile = Join-Path $Config.QualityReportsPath "quality_summary_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
        if (-not $DryRun) {
            $summaryReport | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryFile -Encoding UTF8
        }

        Write-QualityLog "Batch quality monitoring completed. Summary saved: $summaryFile" "INFO"
    }

    Write-QualityLog "Batch quality monitoring completed" "INFO"
}

function Invoke-ContinuousQualityMonitoring {
    Write-QualityLog "Starting continuous quality monitoring with $IntervalMinutes minute intervals..." "INFO"
    Write-QualityLog "Press Ctrl+C to stop" "INFO"

    while ($true) {
        try {
            Invoke-BatchQualityMonitoring
        }
        catch {
            Write-QualityLog "Error in continuous monitoring cycle: $($_.Exception.Message)" "ERROR"
        }

        Write-QualityLog "Waiting $IntervalMinutes minutes until next monitoring cycle..." "INFO"
        Start-Sleep -Seconds ($IntervalMinutes * 60)
    }
}

function Invoke-QualityReportGeneration {
    Write-QualityLog "Generating comprehensive quality report..." "INFO"

    # Load quality history
    $historyFile = Join-Path $Config.QualityReportsPath "quality_history.json"
    $qualityHistory = @{}
    if (Test-Path $historyFile) {
        try {
            $qualityHistory = Get-Content $historyFile -Raw | ConvertFrom-Json
        }
        catch {
            Write-QualityLog "Failed to load quality history: $($_.Exception.Message)" "WARNING"
        }
    }

    # Generate trend analysis
    $trends = @{}
    foreach ($entry in $qualityHistory.PSObject.Properties) {
        $dataType = $entry.Value.data_type
        if (-not $trends.ContainsKey($dataType)) {
            $trends[$dataType] = @()
        }
        $trends[$dataType] += @{
            date = $entry.Value.date
            quality_score = $entry.Value.quality_score
            record_count = $entry.Value.record_count
        }
    }

    # Calculate trend metrics
    $trendAnalysis = @{}
    foreach ($dataType in $trends.Keys) {
        $scores = $trends[$dataType] | Sort-Object date | Select-Object -Last 7  # Last 7 days
        if ($scores.Count -ge 2) {
            $firstScore = $scores[0].quality_score
            $lastScore = $scores[-1].quality_score
            $trend = if ($lastScore -gt $firstScore) { "improving" }
                    elseif ($lastScore -lt $firstScore) { "declining" }
                    else { "stable" }

            $trendAnalysis[$dataType] = @{
                current_score = $lastScore
                trend = $trend
                change = [math]::Round($lastScore - $firstScore, 2)
                data_points = $scores.Count
            }
        }
    }

    # Generate comprehensive report
    $comprehensiveReport = @{
        timestamp = (Get-Date).ToString("o")
        report_type = "comprehensive_quality_report"
        report_period = "Last 7 days"
        trend_analysis = $trendAnalysis
        quality_history_summary = @{
            total_assessments = $qualityHistory.PSObject.Properties.Count
            data_types_tracked = ($qualityHistory.PSObject.Properties | Select-Object -ExpandProperty Value | Select-Object -ExpandProperty data_type -Unique).Count
            average_quality_score = if ($qualityHistory.PSObject.Properties.Count -gt 0) {
                [math]::Round(($qualityHistory.PSObject.Properties | Select-Object -ExpandProperty Value | Measure-Object -Property quality_score -Average).Average, 2)
            } else { 0 }
        }
        recommendations = @(
            "Maintain data quality monitoring frequency",
            "Address any declining quality trends promptly",
            "Review and update data validation rules regularly",
            "Implement automated data cleansing for low-quality data"
        )
        metadata = @{
            generated_by = "NCC.DataQualityMonitor"
            report_version = "1.0.0"
        }
    }

    $reportFile = Join-Path $Config.QualityReportsPath "comprehensive_quality_report_$(Get-Date -Format 'yyyy-MM-dd').json"
    if (-not $DryRun) {
        $comprehensiveReport | ConvertTo-Json -Depth 10 | Set-Content -Path $reportFile -Encoding UTF8
    }

    Write-QualityLog "Comprehensive quality report generated: $reportFile" "INFO"
}

# Main execution logic
Write-QualityLog "=== NCC Data Quality Monitor Started ===" "INFO"
Write-QualityLog "Mode: $Mode, Interval: $IntervalMinutes minutes, Alert Threshold: $AlertThreshold%, DryRun: $DryRun" "INFO"

try {
    Initialize-QualityMonitor

    switch ($Mode) {
        "Batch" {
            Invoke-BatchQualityMonitoring
        }
        "Continuous" {
            Invoke-ContinuousQualityMonitoring
        }
        "Report" {
            Invoke-QualityReportGeneration
        }
    }

    Write-QualityLog "=== NCC Data Quality Monitor Completed Successfully ===" "INFO"
    exit 0
}
catch {
    Write-QualityLog "Data Quality Monitor failed: $($_.Exception.Message)" "ERROR"
    Write-QualityLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
<<<<<<< HEAD
}
=======
}
>>>>>>> c6b295e0d92d0143018dcdcb5ba8fd1affca0fae
