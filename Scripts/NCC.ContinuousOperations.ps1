# NCC Hierarchical Directive System - Continuous Operations Script
# Version: 1.0.1 | Date: 2026-01-29
# Purpose: Continuous execution of the complete hierarchical directive system

param(
    [Parameter(Mandatory=$false)]
    [switch]$Continuous,

    [Parameter(Mandatory=$false)]
    [int]$IntervalMinutes = 60,

    [Parameter(Mandatory=$false)]
    [int]$IntervalSeconds,

    [Parameter(Mandatory=$false)]
    [switch]$SingleCycle,

    [Parameter(Mandatory=$false)]
    [switch]$StatusReport
)

# Global variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -Parent $ScriptPath
$LogsPath = Join-Path $RootPath "logs"
$AXPath = Join-Path $RootPath "AX"

# Ensure directories exist
if (!(Test-Path $LogsPath)) { New-Item -ItemType Directory -Path $LogsPath -Force }

# Logging function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    Write-Host $logMessage -ForegroundColor $(switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "Cyan" }
        default { "White" }
    })

    $logFile = Join-Path $LogsPath "NCC_Continuous_Operations.log"
    Add-Content -Path $logFile -Value $logMessage
}

# Get all NCC companies
function Get-NCCCompanies {
    Write-Log "🔍 Scanning for NCC companies..." "INFO"

    $companies = @()

    # Get all directories that look like companies
    $potentialCompanies = Get-ChildItem -Path $RootPath -Directory | Where-Object {
        $_.Name -notmatch "^(scripts|logs|AX|CEO_Messages|reports|goals|backups|archives|directives|companies)$" -and
        $_.Name -notmatch "^_.*" -and
        $_.Name -notmatch "\."
    }

    # Also check the companies folder
    $companiesDir = Join-Path $RootPath "companies"
    if (Test-Path $companiesDir) {
        $companyDirs = Get-ChildItem -Path $companiesDir -Directory
        $potentialCompanies += $companyDirs
    }

    foreach ($dir in $potentialCompanies) {
        # Check if it has a mission statement or directive files
        $missionFileMD = Join-Path $dir.FullName "Mission_Statement.md"
        $missionFileJSON = Join-Path $dir.FullName "mission_statement.json"
        $directiveFile = Join-Path $dir.FullName "company_directive.json"
        
        # Also check directives folder
        $directivesFolder = Join-Path $RootPath "directives"
        $directivePattern = "$($dir.Name)*.json"
        $directiveFiles = Get-ChildItem -Path $directivesFolder -Filter $directivePattern -File

        $hasMission = (Test-Path $missionFileMD) -or (Test-Path $missionFileJSON)
        $hasDirective = (Test-Path $directiveFile) -or ($directiveFiles.Count -gt 0)

        if ($hasMission -or $hasDirective) {
            $companies += @{
                Name = $dir.Name
                Path = $dir.FullName
                HasMission = $hasMission
                HasDirective = $hasDirective
            }
        }
    }

    Write-Log "Found $($companies.Count) NCC companies" "INFO"
    return $companies
}

# Execute directive creation phase
function Invoke-DirectiveCreationPhase {
    param([array]$Companies)

    Write-Log "🎯 Phase 1: Directive Creation (AZ/AX/C-Suite)" "INFO"

    $scriptPath = Join-Path $ScriptPath "NCC.DirectiveCreation.ps1"

    if (!(Test-Path $scriptPath)) {
        Write-Log "ERROR: Directive creation script not found: $scriptPath" "ERROR"
        return $false
    }

    try {
        # Create directives for all companies
        $argumentList = "-AllCompanies"
        $process = Start-Process -FilePath "pwsh" -ArgumentList "$scriptPath $argumentList" -NoNewWindow -Wait -PassThru

        if ($process.ExitCode -eq 0) {
            Write-Log "✓ Directive creation completed successfully" "SUCCESS"
            return $true
        } else {
            Write-Log "❌ Directive creation failed with exit code: $($process.ExitCode)" "ERROR"
            return $false
        }
    } catch {
        Write-Log "❌ Error executing directive creation: $_" "ERROR"
        return $false
    }
}

# Execute CEO directive breakdown phase
function Invoke-CEOBreakdownPhase {
    param([array]$Companies)

    Write-Log "👑 Phase 2: CEO Directive Breakdown" "INFO"

    $scriptPath = Join-Path $ScriptPath "NCC.CEO.DirectiveBreakdown.ps1"

    if (!(Test-Path $scriptPath)) {
        Write-Log "ERROR: CEO breakdown script not found: $scriptPath" "ERROR"
        return $false
    }

    $successCount = 0

    foreach ($company in $Companies) {
        try {
            Write-Log "Processing CEO breakdown for: $($company.Name)" "INFO"

            $argumentList = "-CompanyName '$($company.Name)'"
            $process = Start-Process -FilePath "pwsh" -ArgumentList "$scriptPath $argumentList" -NoNewWindow -Wait -PassThru

            if ($process.ExitCode -eq 0) {
                Write-Log "✓ CEO breakdown completed for $($company.Name)" "SUCCESS"
                $successCount++
            } else {
                Write-Log "❌ CEO breakdown failed for $($company.Name) (Exit code: $($process.ExitCode))" "ERROR"
            }
        } catch {
            Write-Log "❌ Error processing $($company.Name): $_" "ERROR"
        }
    }

    Write-Log "CEO breakdown phase: $successCount/$($Companies.Count) companies processed successfully" "INFO"
    return $successCount -gt 0
}

# Execute department head task creation phase
function Invoke-DeptHeadTaskCreationPhase {
    param([array]$Companies)

    Write-Log "🏢 Phase 3: Department Head Task Creation" "INFO"

    $scriptPath = Join-Path $ScriptPath "NCC.DeptHead.TaskCreation.ps1"

    if (!(Test-Path $scriptPath)) {
        Write-Log "ERROR: Department head task creation script not found: $scriptPath" "ERROR"
        return $false
    }

    # Get all departments that were created by CEO breakdown
    $departmentsPath = Join-Path $RootPath "departments"
    if (!(Test-Path $departmentsPath)) {
        Write-Log "ERROR: Departments directory not found: $departmentsPath" "ERROR"
        return $false
    }

    $departments = Get-ChildItem -Path $departmentsPath -Directory

    if ($departments.Count -eq 0) {
        Write-Log "ERROR: No departments found in $departmentsPath" "ERROR"
        return $false
    }

    $successCount = 0

    foreach ($department in $departments) {
        try {
            Write-Log "Processing department tasks for: $($department.Name)" "INFO"

            $argumentList = "-DepartmentName `"$($department.Name)`""
            $process = Start-Process -FilePath "pwsh" -ArgumentList "$scriptPath $argumentList" -NoNewWindow -Wait -PassThru

            if ($process.ExitCode -eq 0) {
                Write-Log "✓ Department tasks created for $($department.Name)" "SUCCESS"
                $successCount++
            } else {
                Write-Log "❌ Department task creation failed for $($department.Name) (Exit code: $($process.ExitCode))" "ERROR"
            }
        } catch {
            Write-Log "❌ Error processing $($department.Name): $_" "ERROR"
        }
    }

    Write-Log "Department task creation phase: $successCount/$($departments.Count) departments processed successfully" "INFO"
    return $successCount -gt 0
}

# Execute agent task execution phase
function Invoke-AgentExecutionPhase {
    param([array]$Companies)

    Write-Log "🤖 Phase 4: Agent Task Execution" "INFO"

    $scriptPath = Join-Path $ScriptPath "NCC.Agent.TaskExecution.ps1"

    if (!(Test-Path $scriptPath)) {
        Write-Log "ERROR: Agent execution script not found: $scriptPath" "ERROR"
        return $false
    }

    # Get all agents
    $agentsPath = Join-Path $RootPath "agents"
    if (!(Test-Path $agentsPath)) {
        Write-Log "ERROR: Agents directory not found: $agentsPath" "ERROR"
        return $false
    }

    $agentFiles = Get-ChildItem -Path $agentsPath -Filter "*.json"

    if ($agentFiles.Count -eq 0) {
        Write-Log "ERROR: No agent files found in $agentsPath" "ERROR"
        return $false
    }

    $successCount = 0

    foreach ($agentFile in $agentFiles) {
        try {
            $agentName = $agentFile.BaseName
            Write-Log "Processing agent execution for: ${agentName}" "INFO"

            $argumentList = "-AgentName `"${agentName}`" -ExecuteAll"
            $process = Start-Process -FilePath "pwsh" -ArgumentList "$scriptPath $argumentList" -NoNewWindow -Wait -PassThru

            if ($process.ExitCode -eq 0) {
                Write-Log "✓ Agent execution completed for ${agentName}" "SUCCESS"
                $successCount++
            } else {
                Write-Log "❌ Agent execution failed for ${agentName} (Exit code: $($process.ExitCode))" "ERROR"
            }
        } catch {
            Write-Log "❌ Error processing ${agentName}: $_" "ERROR"
        }
    }

    Write-Log "Agent execution phase: $successCount/$($agentFiles.Count) agents processed successfully" "INFO"
    return $successCount -gt 0
}

# Execute department head report compilation phase
function Invoke-DeptHeadReportCompilationPhase {
    param([array]$Companies)

    Write-Log "📊 Phase 5: Department Head Report Compilation" "INFO"

    $scriptPath = Join-Path $ScriptPath "NCC.DeptHead.ReportCompilation.ps1"

    if (!(Test-Path $scriptPath)) {
        Write-Log "ERROR: Report compilation script not found: $scriptPath" "ERROR"
        return $false
    }

    # Get all departments
    $departmentsPath = Join-Path $RootPath "departments"
    if (!(Test-Path $departmentsPath)) {
        Write-Log "ERROR: Departments directory not found: $departmentsPath" "ERROR"
        return $false
    }

    $departments = Get-ChildItem -Path $departmentsPath -Directory

    if ($departments.Count -eq 0) {
        Write-Log "ERROR: No departments found in $departmentsPath" "ERROR"
        return $false
    }

    $successCount = 0

    foreach ($department in $departments) {
        try {
            Write-Log "Processing report compilation for: $($department.Name)" "INFO"

            $argumentList = "-DepartmentName `"$($department.Name)`""
            $process = Start-Process -FilePath "pwsh" -ArgumentList "$scriptPath $argumentList" -NoNewWindow -Wait -PassThru

            if ($process.ExitCode -eq 0) {
                Write-Log "✓ Report compilation completed for $($department.Name)" "SUCCESS"
                $successCount++
            } else {
                Write-Log "❌ Report compilation failed for $($department.Name) (Exit code: $($process.ExitCode))" "ERROR"
            }
        } catch {
            Write-Log "❌ Error processing $($department.Name): $_" "ERROR"
        }
    }

    Write-Log "Report compilation phase: $successCount/$($departments.Count) departments processed successfully" "INFO"
    return $successCount -gt 0
}

# Execute CEO feedback integration phase
function Invoke-CEOFeedbackIntegrationPhase {
    param([array]$Companies)

    Write-Log "🔄 Phase 6: CEO Feedback Integration" "INFO"

    $scriptPath = Join-Path $ScriptPath "NCC.CEO.FeedbackIntegration.ps1"

    if (!(Test-Path $scriptPath)) {
        Write-Log "ERROR: CEO feedback integration script not found: $scriptPath" "ERROR"
        return $false
    }

    $successCount = 0

    foreach ($company in $Companies) {
        try {
            Write-Log "Processing CEO feedback for: $($company.Name)" "INFO"

            $argumentList = "-CompanyName '$($company.Name)'"
            $process = Start-Process -FilePath "pwsh" -ArgumentList "$scriptPath $argumentList" -NoNewWindow -Wait -PassThru

            if ($process.ExitCode -eq 0) {
                Write-Log "✓ CEO feedback integrated for $($company.Name)" "SUCCESS"
                $successCount++
            } else {
                Write-Log "❌ CEO feedback integration failed for $($company.Name) (Exit code: $($process.ExitCode))" "ERROR"
            }
        } catch {
            Write-Log "❌ Error processing $($company.Name): $_" "ERROR"
        }
    }

    Write-Log "CEO feedback integration phase: $successCount/$($Companies.Count) companies processed successfully" "INFO"
    return $successCount -gt 0
}

# Generate status report
function New-StatusReport {
    Write-Log "📋 Generating NCC Operations Status Report" "INFO"

    $reportPath = Join-Path $LogsPath "NCC_Status_Report.json"

    $companies = Get-NCCCompanies

    $statusReport = @{
        ReportName = "NCC Hierarchical Directive System Status Report"
        GeneratedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        SystemVersion = "1.0.0"

        SystemOverview = @{
            TotalCompanies = $companies.Count
            CompaniesWithMissions = ($companies | Where-Object { $_.HasMission }).Count
            CompaniesWithDirectives = ($companies | Where-Object { $_.HasDirective }).Count
            OperationalReadiness = if ($companies.Count -gt 0) {
                [math]::Round((($companies | Where-Object { $_.HasMission -and $_.HasDirective }).Count / $companies.Count) * 100, 2)
            } else { 0 }
        }

        CompanyDetails = $companies | ForEach-Object {
            @{
                CompanyName = $_.Name
                HasMissionStatement = $_.HasMission
                HasActiveDirective = $_.HasDirective
                OperationalStatus = if ($_.HasMission -and $_.HasDirective) { "Fully Operational" } elseif ($_.HasMission) { "Mission Ready" } else { "Setup Required" }
            }
        }

        RecentActivity = @{
            LogFile = Join-Path $LogsPath "NCC_Continuous_Operations.log"
            LastLogEntries = if (Test-Path (Join-Path $LogsPath "NCC_Continuous_Operations.log")) {
                Get-Content (Join-Path $LogsPath "NCC_Continuous_Operations.log") -Tail 10
            } else { @("No log entries found") }
        }

        SystemHealth = @{
            AllScriptsPresent = (Test-Path (Join-Path $ScriptPath "NCC.DirectiveCreation.ps1")) -and
                                (Test-Path (Join-Path $ScriptPath "NCC.CEO.DirectiveBreakdown.ps1")) -and
                                (Test-Path (Join-Path $ScriptPath "NCC.DeptHead.TaskCreation.ps1")) -and
                                (Test-Path (Join-Path $ScriptPath "NCC.Agent.TaskExecution.ps1")) -and
                                (Test-Path (Join-Path $ScriptPath "NCC.DeptHead.ReportCompilation.ps1")) -and
                                (Test-Path (Join-Path $ScriptPath "NCC.CEO.FeedbackIntegration.ps1"))

            RequiredDirectories = (Test-Path (Join-Path $RootPath "CEO_Messages")) -and
                                (Test-Path (Join-Path $RootPath "reports")) -and
                                (Test-Path (Join-Path $RootPath "goals")) -and
                                (Test-Path (Join-Path $RootPath "AX"))
        }
    }

    $statusReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8

    Write-Log "✓ Status report generated: $reportPath" "SUCCESS"

    # Display summary
    Write-Host "`n📊 NCC System Status Summary:" -ForegroundColor Cyan
    Write-Host "  Companies: $($statusReport.SystemOverview.TotalCompanies)" -ForegroundColor White
    Write-Host "  With Missions: $($statusReport.SystemOverview.CompaniesWithMissions)" -ForegroundColor White
    Write-Host "  With Directives: $($statusReport.SystemOverview.CompaniesWithDirectives)" -ForegroundColor White
    Write-Host "  Operational Readiness: $($statusReport.SystemOverview.OperationalReadiness)%" -ForegroundColor $(if ($statusReport.SystemOverview.OperationalReadiness -gt 80) { "Green" } elseif ($statusReport.SystemOverview.OperationalReadiness -gt 50) { "Yellow" } else { "Red" })
    Write-Host "  System Health: $(if ($statusReport.SystemHealth.AllScriptsPresent -and $statusReport.SystemHealth.RequiredDirectories) { 'Good' } else { 'Issues Detected' })" -ForegroundColor $(if ($statusReport.SystemHealth.AllScriptsPresent -and $statusReport.SystemHealth.RequiredDirectories) { "Green" } else { "Red" })
}

# Execute single cycle
function Invoke-SingleCycle {
    Write-Log "🔄 Executing single cycle of NCC Hierarchical Directive System" "INFO"

    $companies = Get-NCCCompanies

    if ($companies.Count -eq 0) {
        Write-Log "❌ No NCC companies found. Please ensure companies have mission statements or directives." "ERROR"
        return $false
    }

    $cycleStart = Get-Date

    # Phase 1: Directive Creation
    $phase1Success = Invoke-DirectiveCreationPhase -Companies $companies

    # Phase 2: CEO Breakdown
    $phase2Success = Invoke-CEOBreakdownPhase -Companies $companies

    # Phase 3: Department Head Task Creation
    $phase3Success = Invoke-DeptHeadTaskCreationPhase -Companies $companies

    # Phase 4: Agent Execution
    $phase4Success = Invoke-AgentExecutionPhase -Companies $companies

    # Phase 5: Report Compilation
    $phase5Success = Invoke-DeptHeadReportCompilationPhase -Companies $companies

    # Phase 6: CEO Feedback Integration
    $phase6Success = Invoke-CEOFeedbackIntegrationPhase -Companies $companies

    $cycleEnd = Get-Date
    $cycleDuration = $cycleEnd - $cycleStart

    $cycleResults = @{
        CycleStart = $cycleStart
        CycleEnd = $cycleEnd
        Duration = $cycleDuration.TotalMinutes
        Phases = @{
            DirectiveCreation = $phase1Success
            CEOBreakdown = $phase2Success
            DeptHeadTaskCreation = $phase3Success
            AgentExecution = $phase4Success
            ReportCompilation = $phase5Success
            CEOFeedbackIntegration = $phase6Success
        }
        OverallSuccess = $phase1Success -and $phase2Success -and $phase3Success -and $phase4Success -and $phase5Success -and $phase6Success
    }

    Write-Log "Cycle completed in $([math]::Round($cycleDuration.TotalMinutes, 2)) minutes" "INFO"
    Write-Log "Overall success: $($cycleResults.OverallSuccess)" $(if ($cycleResults.OverallSuccess) { "SUCCESS" } else { "WARN" })

    return $cycleResults
}

# Continuous operations loop
function Start-ContinuousOperations {
    param([int]$IntervalMinutes, [int]$IntervalSeconds)

    $intervalText = if ($IntervalSeconds) { "$IntervalSeconds seconds" } else { "$IntervalMinutes minutes" }
    Write-Log "🚀 Starting NCC Continuous Operations (Interval: $intervalText)" "INFO"
    Write-Log "Press Ctrl+C to stop continuous operations" "WARN"

    $cycleCount = 0

    while ($true) {
        $cycleCount++
        Write-Log "=== Starting Cycle #$cycleCount ===" "INFO"

        try {
            $cycleResult = Invoke-SingleCycle

            if ($cycleResult.OverallSuccess) {
                Write-Log "✅ Cycle #$cycleCount completed successfully" "SUCCESS"
            } else {
                Write-Log "⚠️ Cycle #$cycleCount completed with issues" "WARN"
            }

            # Generate status report every 5 cycles
            if ($cycleCount % 5 -eq 0) {
                New-StatusReport
            }

        } catch {
            Write-Log "❌ Error in cycle #$cycleCount : $_" "ERROR"
        }

        Write-Log "⏱️ Waiting $intervalText until next cycle..." "INFO"
        if ($IntervalSeconds) {
            Start-Sleep -Seconds $IntervalSeconds
        } else {
            Start-Sleep -Seconds ($IntervalMinutes * 60)
        }
    }
}

# Main execution
Write-Host "🚀 NCC Hierarchical Directive System - Continuous Operations" -ForegroundColor Magenta
Write-Host "Version 1.0.0 | Date: 2026-01-29" -ForegroundColor Gray
Write-Host ""

if ($StatusReport) {
    New-StatusReport
    exit
}

if ($SingleCycle) {
    Invoke-SingleCycle
    exit
}

if ($Continuous) {
    if ($IntervalSeconds) {
        Start-ContinuousOperations -IntervalMinutes $IntervalMinutes -IntervalSeconds $IntervalSeconds
    } else {
        Start-ContinuousOperations -IntervalMinutes $IntervalMinutes
    }
} else {
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\NCC.ContinuousOperations.ps1 -SingleCycle              # Run one complete cycle" -ForegroundColor White
    Write-Host "  .\NCC.ContinuousOperations.ps1 -Continuous              # Run continuous operations (default 60min intervals)" -ForegroundColor White
    Write-Host "  .\NCC.ContinuousOperations.ps1 -Continuous -IntervalMinutes 30  # Run with 30min intervals" -ForegroundColor White
    Write-Host "  .\NCC.ContinuousOperations.ps1 -Continuous -IntervalSeconds 1   # Run with 1 second intervals" -ForegroundColor White
    Write-Host "  .\NCC.ContinuousOperations.ps1 -StatusReport            # Generate system status report" -ForegroundColor White
    Write-Host ""
    Write-Host "The hierarchical directive system includes:" -ForegroundColor Gray
    Write-Host "  1. AZ/AX/C-Suite Directive Creation" -ForegroundColor Gray
    Write-Host "  2. CEO Directive Breakdown" -ForegroundColor Gray
    Write-Host "  3. Department Head Task Creation" -ForegroundColor Gray
    Write-Host "  4. Agent Task Execution" -ForegroundColor Gray
    Write-Host "  5. Department Head Report Compilation" -ForegroundColor Gray
    Write-Host "  6. CEO Feedback Integration" -ForegroundColor Gray
}





