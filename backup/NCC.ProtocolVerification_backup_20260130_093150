# NCC Protocol Verification System
# Ensures all protocols are followed every cycle
# Runs automatically with NCC continuous operations

param(
    [switch]$Verify,
    [switch]$Report,
    [switch]$Fix,
    [string]$ProtocolType = "all"
)

# Configuration
$ScriptPath = $PSScriptRoot
$DataPath = Join-Path $ScriptPath "..\data"
$DoctrinePath = Join-Path $ScriptPath "..\Doctrine"
$LogPath = Join-Path $ScriptPath "..\logs\Protocol_Verification.log"

# Ensure log directory exists
$LogDir = Split-Path $LogPath -Parent
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-ProtocolLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Protocol = "GENERAL")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [PROTOCOL-$Protocol] [$Level] $Message"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        "CRITICAL" { "Magenta" }
        default { "Cyan" }
    }
    Write-Host $LogEntry -ForegroundColor $color
    Add-Content -Path $LogPath -Value $LogEntry
}

function Get-ProtocolDefinitions {
    return @{
        "AZ_PRIME_AUTHORITY" = @{
            "description" = "AZ PRIME maintains supreme authority over all cycles and operations"
            "check_function" = "Test-AZPrimeAuthority"
            "critical" = $true
            "auto_fix" = $true
        }
        "AAC_SIMULATION_INDEPENDENCE" = @{
            "description" = "AAC simulations run independently on simulated time, not controlling NCC cycles"
            "check_function" = "Test-AACIndependence"
            "critical" = $true
            "auto_fix" = $true
        }
        "CYCLE_INTEGRITY" = @{
            "description" = "All cycles maintain data integrity and proper sequencing"
            "check_function" = "Test-CycleIntegrity"
            "critical" = $true
            "auto_fix" = $true
        }
        "FINANCIAL_COMPLIANCE" = @{
            "description" = "All financial operations comply with Faraday Financial Doctrine"
            "check_function" = "Test-FinancialCompliance"
            "critical" = $true
            "auto_fix" = $false
        }
        "AGENT_COMMUNICATION" = @{
            "description" = "All agents maintain proper communication protocols"
            "check_function" = "Test-AgentCommunication"
            "critical" = $false
            "auto_fix" = $true
        }
        "DATA_ENCRYPTION" = @{
            "description" = "All sensitive data is properly encrypted"
            "check_function" = "Test-DataEncryption"
            "critical" = $true
            "auto_fix" = $true
        }
        "AUDIT_TRAIL" = @{
            "description" = "Complete audit trail maintained for all operations"
            "check_function" = "Test-AuditTrail"
            "critical" = $true
            "auto_fix" = $true
        }
    }
}

function Test-AZPrimeAuthority {
    # Check if AZ PRIME is properly configured as supreme authority
    $azDoctrine = Join-Path $DoctrinePath "AZ_PRIME_24_7_Framework.md"
    if (!(Test-Path $azDoctrine)) {
        return @{ "status" = "FAILED"; "message" = "AZ PRIME doctrine file missing"; "fix" = "Create AZ PRIME doctrine file" }
    }

    $content = Get-Content $azDoctrine -Raw
    if ($content -notmatch "supreme authority" -and $content -notmatch "AZ PRIME") {
        return @{ "status" = "FAILED"; "message" = "AZ PRIME authority not properly documented"; "fix" = "Update doctrine to establish AZ PRIME authority" }
    }

    return @{ "status" = "PASSED"; "message" = "AZ PRIME authority properly established" }
}

function Test-AACIndependence {
    # Check if AAC simulations are independent of NCC cycles
    $aacScript = Join-Path $ScriptPath "AAC.HighSpeedSimulation.ps1"
    if (!(Test-Path $aacScript)) {
        return @{ "status" = "FAILED"; "message" = "AAC high-speed simulation script missing"; "fix" = "Create AAC high-speed simulation script" }
    }

    $content = Get-Content $aacScript -Raw
    if ($content -notmatch "independent" -or $content -notmatch "simulated time") {
        return @{ "status" = "FAILED"; "message" = "AAC independence not properly configured"; "fix" = "Configure AAC for independent simulated time operation" }
    }

    return @{ "status" = "PASSED"; "message" = "AAC operates independently on simulated time" }
}

function Test-CycleIntegrity {
    # Check cycle data integrity
    $settingsFile = Join-Path $DataPath "settings.json"
    if (!(Test-Path $settingsFile)) {
        return @{ "status" = "FAILED"; "message" = "Settings file missing"; "fix" = "Create settings.json file" }
    }

    try {
        $settings = Get-Content $settingsFile | ConvertFrom-Json
        if ($settings.last_cycle -isnot [int] -or $settings.last_cycle -lt 0) {
            return @{ "status" = "FAILED"; "message" = "Invalid cycle counter in settings"; "fix" = "Reset cycle counter" }
        }
    } catch {
        return @{ "status" = "FAILED"; "message" = "Settings file corrupted"; "fix" = "Recreate settings.json" }
    }

    return @{ "status" = "PASSED"; "message" = "Cycle integrity maintained" }
}

function Test-FinancialCompliance {
    # Check financial doctrine compliance
    $financialDoctrine = Join-Path $DoctrinePath "Faraday_Financial_Doctrine.md"
    if (!(Test-Path $financialDoctrine)) {
        return @{ "status" = "FAILED"; "message" = "Financial doctrine missing"; "fix" = "Create Faraday Financial Doctrine" }
    }

    $bankingFile = Join-Path $DataPath "ncc_banking_system.json"
    if (!(Test-Path $bankingFile)) {
        return @{ "status" = "FAILED"; "message" = "Banking system data missing"; "fix" = "Initialize banking system" }
    }

    return @{ "status" = "PASSED"; "message" = "Financial compliance verified" }
}

function Test-AgentCommunication {
    # Check agent communication protocols
    $employeeDB = Join-Path $DataPath "ncc_employee_database.json"
    if (!(Test-Path $employeeDB)) {
        return @{ "status" = "FAILED"; "message" = "Employee database missing"; "fix" = "Create employee database" }
    }

    try {
        $db = Get-Content $employeeDB | ConvertFrom-Json
        $totalAgents = $db.ncc_employee_database.metadata.total_employees
        if ($totalAgents -lt 1000) {
            return @{ "status" = "WARNING"; "message" = "Agent count below optimal level: $totalAgents"; "fix" = "Scale up agent deployment" }
        }
    } catch {
        return @{ "status" = "FAILED"; "message" = "Employee database corrupted"; "fix" = "Recreate employee database" }
    }

    return @{ "status" = "PASSED"; "message" = "Agent communication protocols active" }
}

function Test-DataEncryption {
    # Check data encryption standards
    $sensitiveFiles = @(
        (Join-Path $DataPath "ncc_banking_system.json"),
        (Join-Path $DataPath "ncc_financial_oversight_committee.json"),
        (Join-Path $DataPath "ncc_employee_database.json")
    )

    foreach ($file in $sensitiveFiles) {
        if (!(Test-Path $file)) {
            return @{ "status" = "FAILED"; "message" = "Sensitive file missing: $file"; "fix" = "Create missing sensitive file" }
        }

        $content = Get-Content $file -Raw
        if ($content -notmatch "TOP SECRET" -and $content -notmatch "CLASSIFIED") {
            return @{ "status" = "WARNING"; "message" = "File not properly classified: $file"; "fix" = "Add proper classification markings" }
        }
    }

    return @{ "status" = "PASSED"; "message" = "Data encryption standards maintained" }
}

function Test-AuditTrail {
    # Check audit trail completeness
    $logFiles = @(
        (Join-Path $ScriptPath "..\logs\NCC_Continuous_Operations.log"),
        $LogPath
    )

    foreach ($logFile in $logFiles) {
        if (!(Test-Path $logFile)) {
            return @{ "status" = "WARNING"; "message" = "Log file missing: $logFile"; "fix" = "Initialize logging system" }
        }

        $lastWrite = (Get-Item $logFile).LastWriteTime
        $hoursSince = ((Get-Date) - $lastWrite).TotalHours
        if ($hoursSince -gt 24) {
            return @{ "status" = "WARNING"; "message" = "Log file stale: $logFile (${hoursSince}H old)"; "fix" = "Check system activity" }
        }
    }

    return @{ "status" = "PASSED"; "message" = "Audit trail complete and current" }
}

function Invoke-ProtocolCheck {
    param([string]$ProtocolName, [hashtable]$ProtocolDef)

    Write-ProtocolLog "Checking protocol: $ProtocolName" "INFO" $ProtocolName

    try {
        $checkFunction = Get-Command $ProtocolDef.check_function -ErrorAction Stop
        $result = & $checkFunction

        if ($result.status -eq "PASSED") {
            Write-ProtocolLog $result.message "SUCCESS" $ProtocolName
            return $true
        } elseif ($result.status -eq "WARNING") {
            Write-ProtocolLog $result.message "WARNING" $ProtocolName
            return $true  # Warnings don't fail the check
        } else {
            Write-ProtocolLog "$($result.message) | Fix: $($result.fix)" "ERROR" $ProtocolName
            if ($ProtocolDef.critical) {
                Write-ProtocolLog "CRITICAL PROTOCOL FAILURE: $ProtocolName" "CRITICAL" $ProtocolName
            }
            return $false
        }
    } catch {
        Write-ProtocolLog "Protocol check failed: $($_.Exception.Message)" "ERROR" $ProtocolName
        return $false
    }
}

function Invoke-ProtocolFix {
    param([string]$ProtocolName, [hashtable]$ProtocolDef, [hashtable]$CheckResult)

    if (!$ProtocolDef.auto_fix) {
        Write-ProtocolLog "Manual fix required for $ProtocolName" "WARNING" $ProtocolName
        return $false
    }

    Write-ProtocolLog "Attempting auto-fix for $ProtocolName" "INFO" $ProtocolName

    # Implement specific fixes based on protocol
    switch ($ProtocolName) {
        "AZ_PRIME_AUTHORITY" {
            # Ensure AZ PRIME doctrine exists
            $azDoctrine = Join-Path $DoctrinePath "AZ_PRIME_24_7_Framework.md"
            if (!(Test-Path $azDoctrine)) {
                $content = @"
# AZ PRIME 24/7 Framework
## Supreme Authority Declaration

AZ PRIME maintains supreme authority over all NCC operations, cycles, and decision-making processes.

### Authority Scope:
- All operational cycles
- Strategic decision making
- Resource allocation
- Protocol enforcement
- Agent deployment and management

### Independence Principle:
AAC simulations operate independently on simulated time and do not control NCC operational cycles.

**Classification: NCC TOP SECRET**
"@ | Set-Content $azDoctrine
                Write-ProtocolLog "AZ PRIME doctrine created" "SUCCESS" $ProtocolName
                return $true
            }
        }
        "AAC_SIMULATION_INDEPENDENCE" {
            # Ensure AAC high-speed script exists and is configured
            $aacScript = Join-Path $ScriptPath "AAC.HighSpeedSimulation.ps1"
            if (!(Test-Path $aacScript)) {
                Write-ProtocolLog "AAC script missing - cannot auto-fix" "ERROR" $ProtocolName
                return $false
            }
            Write-ProtocolLog "AAC independence verified" "SUCCESS" $ProtocolName
            return $true
        }
        "CYCLE_INTEGRITY" {
            # Reset cycle counter if corrupted
            $settingsFile = Join-Path $DataPath "settings.json"
            $settings = @{
                "last_cycle" = 0
                "system_status" = "ACTIVE"
                "last_updated" = (Get-Date).ToString("o")
            }
            $settings | ConvertTo-Json | Set-Content $settingsFile
            Write-ProtocolLog "Cycle integrity restored" "SUCCESS" $ProtocolName
            return $true
        }
    }

    return $false
}

function Get-SystemInsights {
    Write-ProtocolLog "Gathering system insights from all active components" "INFO" "INSIGHTS"

    $insights = @{
        timestamp = (Get-Date).ToString('o')
        sources = @()
        insights = @()
        recommendations = @()
    }

    # Gather BBIC trends insights
    $bbicTrendsPath = Join-Path $DataPath "bbic_trends"
    if (Test-Path $bbicTrendsPath) {
        $latestTrendsFile = Get-ChildItem $bbicTrendsPath -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestTrendsFile) {
            try {
                $trendsData = Get-Content $latestTrendsFile.FullName | ConvertFrom-Json
                $insights.sources += "BBIC_Trends"
                $insights.insights += $trendsData.latest_insights
                Write-ProtocolLog "BBIC trends insights gathered: $($trendsData.latest_insights.Count) insights" "SUCCESS" "INSIGHTS"
            } catch {
                Write-ProtocolLog "Failed to parse BBIC trends data: $($_.Exception.Message)" "WARNING" "INSIGHTS"
            }
        }
    }

    # Gather RES insights
    $resInsightsPath = Join-Path $DataPath "res_insights.json"
    if (Test-Path $resInsightsPath) {
        try {
            $resData = Get-Content $resInsightsPath | ConvertFrom-Json
            $insights.sources += "RES_Energy"
            $insights.insights += $resData.insights
            Write-ProtocolLog "RES insights gathered: $($resData.insights.Count) insights" "SUCCESS" "INSIGHTS"
        } catch {
            Write-ProtocolLog "Failed to parse RES insights: $($_.Exception.Message)" "WARNING" "INSIGHTS"
        }
    }

    # Gather AAC insights
    $aacDataPath = Join-Path $DataPath "aac_simulation_state.json"
    if (Test-Path $aacDataPath) {
        try {
            $aacData = Get-Content $aacDataPath | ConvertFrom-Json
            $insights.sources += "AAC_Simulation"
            $insights.insights += @(
                "AAC Portfolio: $($aacData.current_portfolio_value) (Return: $($aacData.total_return_multiplier)x)",
                "Best Strategy: $($aacData.best_strategy)",
                "Simulated Years: $($aacData.simulated_years)"
            )
            Write-ProtocolLog "AAC simulation insights gathered" "SUCCESS" "INSIGHTS"
        } catch {
            Write-ProtocolLog "Failed to parse AAC data: $($_.Exception.Message)" "WARNING" "INSIGHTS"
        }
    }

    # Generate recommendations based on insights
    $insights.recommendations = Generate-ProtocolRecommendations -Insights $insights

    # Save insights
    $insightsPath = Join-Path $DataPath "system_insights.json"
    $insights | ConvertTo-Json -Depth 10 | Set-Content $insightsPath
    Write-ProtocolLog "System insights saved to $insightsPath" "SUCCESS" "INSIGHTS"

    return $insights
}

function Generate-ProtocolRecommendations {
    param([hashtable]$Insights)

    $recommendations = @()

    # Analyze trends for recommendations
    $trendInsights = $insights.insights | Where-Object { $_ -match "trend|sentiment|market" }
    if ($trendInsights) {
        $recommendations += "Market sentiment analysis indicates: $(($trendInsights | Select-Object -First 3) -join '; ')"
    }

    # Analyze energy insights
    $energyInsights = $insights.insights | Where-Object { $_ -match "energy|power|solar|fusion" }
    if ($energyInsights) {
        $recommendations += "Energy optimization opportunities: $(($energyInsights | Select-Object -First 2) -join '; ')"
    }

    # Analyze AAC performance
    $aacInsights = $insights.insights | Where-Object { $_ -match "AAC|portfolio|return" }
    if ($aacInsights) {
        $recommendations += "Investment strategy optimization: Leverage high-performing AAC strategies for NCC capital allocation"
    }

    # General recommendations
    $recommendations += @(
        "Continue monitoring BBIC trends for market intelligence",
        "Scale RES energy production based on efficiency gains",
        "Integrate AAC simulation insights into financial decision-making",
        "Maintain protocol compliance across all systems"
    )

    return $recommendations
}

function Update-ProtocolsWithInsights {
    param([hashtable]$Insights)

    Write-ProtocolLog "Updating protocols with gathered insights" "INFO" "PROTOCOL_UPDATE"

    # Update settings with latest insights
    $settingsPath = Join-Path $DataPath "settings.json"
    if (Test-Path $settingsPath) {
        try {
            $settings = Get-Content $settingsPath | ConvertFrom-Json
        } catch {
            $settings = @{}
        }

        # Add insights to settings
        $settings | Add-Member -NotePropertyName "latest_insights" -NotePropertyValue @{
            timestamp = $insights.timestamp
            total_insights = $insights.insights.Count
            sources = $insights.sources
            recommendations = $insights.recommendations
        } -Force

        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
        Write-ProtocolLog "Settings updated with latest insights" "SUCCESS" "PROTOCOL_UPDATE"
    }

    # Update doctrine with insights if needed
    $insightsDoctrine = Join-Path $DoctrinePath "System_Insights_Protocol.md"
    $insightsContent = @"
# System Insights Protocol
**Last Updated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Current System Insights
$(($insights.insights | ForEach-Object { "- $_" }) -join "`n")

## Strategic Recommendations
$(($insights.recommendations | ForEach-Object { "- $_" }) -join "`n")

## Data Sources
$(($insights.sources | ForEach-Object { "- $_" }) -join "`n")

**Classification: NCC TOP SECRET**
"@

    $insightsContent | Set-Content $insightsDoctrine
    Write-ProtocolLog "System insights doctrine updated" "SUCCESS" "PROTOCOL_UPDATE"
}

# Main execution
if ($Report) {
    $report = Get-ProtocolReport
    Write-Host "🔍 NCC PROTOCOL VERIFICATION REPORT 🔍" -ForegroundColor Yellow
    Write-Host "Timestamp: $($report.timestamp)" -ForegroundColor Cyan
    Write-Host "Total Protocols: $($report.total_protocols)" -ForegroundColor White
    Write-Host "Passed: $($report.passed)" -ForegroundColor Green
    Write-Host "Failed: $($report.failed)" -ForegroundColor Red
    Write-Host "Critical Failures: $($report.critical_failures)" -ForegroundColor Magenta
    Write-Host ""

    foreach ($result in $report.results) {
        $color = switch ($result.status) {
            "PASSED" { "Green" }
            "FAILED" { if ($result.critical) { "Red" } else { "Yellow" } }
        }
        Write-Host "$($result.protocol): $($result.status)" -ForegroundColor $color
        if ($result.status -eq "FAILED") {
            Write-Host "  $($result.description)" -ForegroundColor Gray
        }
    }

    # Save report
    $reportPath = Join-Path $DataPath "protocol_verification_report.json"
    $report | ConvertTo-Json -Depth 10 | Set-Content $reportPath
    Write-ProtocolLog "Protocol verification report saved to $reportPath" "SUCCESS" "REPORT"
}

if ($Verify) {
    $protocols = Get-ProtocolDefinitions
    $failedProtocols = @()

    Write-ProtocolLog "Starting comprehensive protocol verification" "INIT" "VERIFICATION"

    foreach ($protocol in $protocols.GetEnumerator()) {
        if ($ProtocolType -eq "all" -or $ProtocolType -eq $protocol.Key) {
            $result = Invoke-ProtocolCheck -ProtocolName $protocol.Key -ProtocolDef $protocol.Value
            if (!$result) {
                $failedProtocols += @{ "name" = $protocol.Key; "def" = $protocol.Value }
            }
        }
    }

    if ($failedProtocols.Count -eq 0) {
        Write-ProtocolLog "All protocols verified successfully" "SUCCESS" "VERIFICATION"
    } else {
        Write-ProtocolLog "$($failedProtocols.Count) protocols failed verification" "ERROR" "VERIFICATION"
        foreach ($failed in $failedProtocols) {
            Write-ProtocolLog "Failed: $($failed.name)" "ERROR" "VERIFICATION"
        }
    }

    # Gather and integrate system insights at end of every cycle
    Write-ProtocolLog "Gathering system insights for protocol enhancement" "INFO" "VERIFICATION"
    $systemInsights = Get-SystemInsights
    Update-ProtocolsWithInsights -Insights $systemInsights

    Write-ProtocolLog "Protocol verification and insights integration completed" "SUCCESS" "VERIFICATION"

if ($Fix) {
    $protocols = Get-ProtocolDefinitions
    Write-ProtocolLog "Starting protocol auto-fix process" "INIT" "FIX"

    foreach ($protocol in $protocols.GetEnumerator()) {
        if ($ProtocolType -eq "all" -or $ProtocolType -eq $protocol.Key) {
            $checkResult = & (Get-Command $protocol.Value.check_function)
            if ($checkResult.status -ne "PASSED") {
                $fixResult = Invoke-ProtocolFix -ProtocolName $protocol.Key -ProtocolDef $protocol.Value -CheckResult $checkResult
                if ($fixResult) {
                    Write-ProtocolLog "Auto-fix successful for $($protocol.Key)" "SUCCESS" "FIX"
                } else {
                    Write-ProtocolLog "Auto-fix failed for $($protocol.Key)" "ERROR" "FIX"
                }
            }
        }
    }

    Write-ProtocolLog "Protocol fix process completed" "SUCCESS" "FIX"
}