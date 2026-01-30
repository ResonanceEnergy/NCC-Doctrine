# AAC HR Database Management System
# Comprehensive HR management for all 75 AAC agents
# Handles employee records, career progression, training, and compensation

param(
    [switch]$Initialize,
    [switch]$Update,
    [switch]$Report,
    [switch]$Training,
    [string]$AgentId,
    [string]$Action
)

$ScriptPath = $PSScriptRoot
$DataPath = Join-Path $ScriptPath "..\data"
$LogPath = Join-Path $ScriptPath "..\logs\AAC_HR_Database.log"

# Ensure directories exist
$LogDir = Split-Path $LogPath -Parent
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-AACLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [AAC-HR-$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(if($Level -eq "ERROR"){"Red"}elseif($Level -eq "SUCCESS"){"Green"}else{"Cyan"})
    Add-Content -Path $LogPath -Value $LogEntry
}

# AAC HR Database Structure
$AAC_HR_DATABASE = @{
    "AUG-001" = @{
        "employee_id" = "AUG-001"
        "name" = "Dr. Alexander Quantum"
        "class" = "A"
        "role" = "Chief Arbitrage Officer"
        "department" = "Executive"
        "hire_date" = "2026-01-01"
        "salary" = 750000
        "bonus_structure" = "20% of profits"
        "performance_rating" = 98.5
        "tenure_years" = 0.8
        "certifications" = @("CFA", "FRM", "PhD Finance")
        "training_completed" = @("Advanced Arbitrage Strategies", "Risk Management", "Leadership Development")
        "career_progression" = @("Senior Analyst", "Portfolio Manager", "Chief Arbitrage Officer")
        "performance_history" = @(
            @{ "date" = "2026-01-15"; "rating" = 97.2; "bonus" = 150000 },
            @{ "date" = "2026-01-29"; "rating" = 98.5; "bonus" = 180000 }
        )
        "development_plan" = "Focus on AI integration and emerging market arbitrage"
    }
    "AUG-002" = @{
        "employee_id" = "AUG-002"
        "name" = "Dr. Sarah Chen"
        "class" = "A"
        "role" = "Head of Quantitative Arbitrage"
        "department" = "Quantitative"
        "hire_date" = "2026-01-01"
        "salary" = 650000
        "bonus_structure" = "15% of quantitative profits"
        "performance_rating" = 97.2
        "tenure_years" = 0.8
        "certifications" = @("PhD Mathematics", "CQF", "FRM")
        "training_completed" = @("Machine Learning for Finance", "Stochastic Calculus", "Algorithm Development")
        "career_progression" = @("Quantitative Analyst", "Senior Quant", "Head of Quantitative Arbitrage")
        "performance_history" = @(
            @{ "date" = "2026-01-15"; "rating" = 96.8; "bonus" = 120000 },
            @{ "date" = "2026-01-29"; "rating" = 97.2; "bonus" = 135000 }
        )
        "development_plan" = "Develop next-generation arbitrage algorithms"
    }
    "AUG-003" = @{
        "employee_id" = "AUG-003"
        "name" = "Marcus Rodriguez"
        "class" = "A"
        "role" = "Head of Statistical Arbitrage"
        "department" = "Statistical"
        "hire_date" = "2026-01-01"
        "salary" = 620000
        "bonus_structure" = "15% of statistical profits"
        "performance_rating" = 96.8
        "tenure_years" = 0.8
        "certifications" = @("CFA", "MSc Statistics", "CQF")
        "training_completed" = @("Statistical Modeling", "Time Series Analysis", "Pairs Trading")
        "career_progression" = @("Statistical Analyst", "Senior Stat Arb Trader", "Head of Statistical Arbitrage")
        "performance_history" = @(
            @{ "date" = "2026-01-15"; "rating" = 96.1; "bonus" = 115000 },
            @{ "date" = "2026-01-29"; "rating" = 96.8; "bonus" = 125000 }
        )
        "development_plan" = "Expand statistical arbitrage across new asset classes"
    }
    "AUG-704" = @{
        "employee_id" = "AUG-704"
        "name" = "Jennifer Walsh"
        "class" = "A"
        "role" = "Department Head"
        "department" = "Executive"
        "hire_date" = "2026-01-01"
        "salary" = 500000
        "bonus_structure" = "10% of department profits"
        "performance_rating" = 95.5
        "tenure_years" = 0.8
        "certifications" = @("MBA", "CFA", "Leadership Certification")
        "training_completed" = @("Executive Leadership", "Strategic Management", "Team Development")
        "career_progression" = @("Senior Manager", "Director", "Department Head")
        "performance_history" = @(
            @{ "date" = "2026-01-15"; "rating" = 94.8; "bonus" = 75000 },
            @{ "date" = "2026-01-29"; "rating" = 95.5; "bonus" = 85000 }
        )
        "development_plan" = "Focus on team leadership and strategic planning"
    }
}

# Add remaining agents (simplified for brevity - would include all 75 in production)
for ($i = 4; $i -le 75; $i++) {
    $agentId = "AUG-{0:D3}" -f $i
    $class = if ($i -le 22) { "A" } elseif ($i -le 60) { "B" } else { "C" }
    $baseSalary = switch ($class) {
        "A" { 400000 + (Get-Random -Maximum 200000) }
        "B" { 150000 + (Get-Random -Maximum 100000) }
        "C" { 80000 + (Get-Random -Maximum 40000) }
    }

    $AAC_HR_DATABASE[$agentId] = @{
        "employee_id" = $agentId
        "name" = "AAC Agent $i"
        "class" = $class
        "role" = "Arbitrage Specialist"
        "department" = "Operations"
        "hire_date" = "2026-01-01"
        "salary" = $baseSalary
        "bonus_structure" = "Performance-based"
        "performance_rating" = 85 + (Get-Random -Maximum 10)
        "tenure_years" = 0.8
        "certifications" = @("Basic Finance Certification")
        "training_completed" = @("Arbitrage Fundamentals")
        "career_progression" = @("Entry Level", "Specialist")
        "performance_history" = @(
            @{ "date" = "2026-01-15"; "rating" = 88; "bonus" = [math]::Round($baseSalary * 0.1) },
            @{ "date" = "2026-01-29"; "rating" = 90; "bonus" = [math]::Round($baseSalary * 0.12) }
        )
        "development_plan" = "Continue professional development in arbitrage strategies"
    }
}

function Initialize-AACHRDatabase {
    Write-AACLog "🔥 INITIALIZING AAC HR DATABASE 🔥" "INIT"

    $hrDbPath = Join-Path $DataPath "aac_hr_database.json"
    $AAC_HR_DATABASE | ConvertTo-Json -Depth 10 | Set-Content $hrDbPath

    # Initialize training database
    $trainingDbPath = Join-Path $DataPath "aac_training_database.json"
    $trainingData = @{
        "training_programs" = @(
            @{
                "id" = "ARB-101"
                "name" = "Arbitrage Fundamentals"
                "duration_hours" = 40
                "required_for" = @("All Agents")
                "certification" = "Basic Arbitrage Certification"
            },
            @{
                "id" = "QUANT-201"
                "name" = "Quantitative Methods"
                "duration_hours" = 60
                "required_for" = @("A-Agents", "B-Agents")
                "certification" = "Quantitative Certification"
            },
            @{
                "id" = "RISK-301"
                "name" = "Advanced Risk Management"
                "duration_hours" = 80
                "required_for" = @("A-Agents")
                "certification" = "Advanced Risk Certification"
            }
        )
        "training_records" = @()
        "last_updated" = (Get-Date).ToString("o")
    }
    $trainingData | ConvertTo-Json -Depth 10 | Set-Content $trainingDbPath

    Write-AACLog "AAC HR Database initialized with 75 employee records" "SUCCESS"
}

function Update-EmployeeRecord {
    param([string]$EmployeeId, [hashtable]$Updates)

    if ($AAC_HR_DATABASE.ContainsKey($EmployeeId)) {
        foreach ($key in $Updates.Keys) {
            $AAC_HR_DATABASE[$EmployeeId][$key] = $Updates[$key]
        }
        $AAC_HR_DATABASE[$EmployeeId]["last_updated"] = (Get-Date).ToString("o")

        $hrDbPath = Join-Path $DataPath "aac_hr_database.json"
        $AAC_HR_DATABASE | ConvertTo-Json -Depth 10 | Set-Content $hrDbPath

        Write-AACLog "Employee record updated for $EmployeeId" "UPDATE"
        return $true
    } else {
        Write-AACLog "Employee $EmployeeId not found" "ERROR"
        return $false
    }
}

function Calculate-Compensation {
    param([string]$EmployeeId)

    if (-not $AAC_HR_DATABASE.ContainsKey($EmployeeId)) {
        return $null
    }

    $employee = $AAC_HR_DATABASE[$EmployeeId]
    $baseSalary = $employee.salary
    $performanceRating = $employee.performance_rating
    $class = $employee.class

    # Calculate bonus multiplier based on class and performance
    $bonusMultiplier = switch ($class) {
        "A" { 0.25 + ($performanceRating - 90) / 100 }  # 25% base + performance adjustment
        "B" { 0.15 + ($performanceRating - 85) / 100 }  # 15% base + performance adjustment
        "C" { 0.10 + ($performanceRating - 80) / 100 }  # 10% base + performance adjustment
    }

    $annualBonus = [math]::Round($baseSalary * $bonusMultiplier)
    $totalCompensation = $baseSalary + $annualBonus

    return @{
        "employee_id" = $EmployeeId
        "base_salary" = $baseSalary
        "annual_bonus" = $annualBonus
        "total_compensation" = $totalCompensation
        "bonus_percentage" = [math]::Round($bonusMultiplier * 100, 2)
        "performance_rating" = $performanceRating
    }
}

function Generate-HRReport {
    Write-AACLog "📊 GENERATING AAC HR COMPENSATION REPORT 📊" "REPORT"

    $report = @{
        "timestamp" = (Get-Date).ToString("o")
        "total_employees" = $AAC_HR_DATABASE.Count
        "compensation_summary" = @{
            "total_base_salary" = 0
            "total_annual_bonus" = 0
            "total_compensation" = 0
            "average_base_salary" = 0
            "average_bonus_percentage" = 0
        }
        "class_breakdown" = @{
            "A_Agents" = @{ "count" = 0; "total_compensation" = 0; "average_salary" = 0 }
            "B_Agents" = @{ "count" = 0; "total_compensation" = 0; "average_salary" = 0 }
            "C_Agents" = @{ "count" = 0; "total_compensation" = 0; "average_salary" = 0 }
        }
        "top_performers" = @()
        "high_earners" = @()
    }

    $compensationData = @()

    foreach ($employeeId in $AAC_HR_DATABASE.Keys) {
        $comp = Calculate-Compensation -EmployeeId $employeeId
        if ($comp) {
            $compensationData += $comp

            $report.compensation_summary.total_base_salary += $comp.base_salary
            $report.compensation_summary.total_annual_bonus += $comp.annual_bonus
            $report.compensation_summary.total_compensation += $comp.total_compensation

            $class = $AAC_HR_DATABASE[$employeeId].class
            $report.class_breakdown."${class}_Agents".count++
            $report.class_breakdown."${class}_Agents".total_compensation += $comp.total_compensation
        }
    }

    # Calculate averages
    $totalEmployees = $compensationData.Count
    $report.compensation_summary.average_base_salary = [math]::Round($report.compensation_summary.total_base_salary / $totalEmployees)
    $report.compensation_summary.average_bonus_percentage = [math]::Round(($compensationData | Measure-Object -Property bonus_percentage -Average).Average, 2)

    # Calculate class averages
    foreach ($class in @("A", "B", "C")) {
        $classKey = "${class}_Agents"
        if ($report.class_breakdown.$classKey.count -gt 0) {
            $report.class_breakdown.$classKey.average_salary = [math]::Round($report.class_breakdown.$classKey.total_compensation / $report.class_breakdown.$classKey.count)
        }
    }

    # Top performers and high earners
    $report.top_performers = $AAC_HR_DATABASE.GetEnumerator() |
        Sort-Object { $_.Value.performance_rating } -Descending |
        Select-Object -First 5 |
        ForEach-Object {
            @{
                "employee_id" = $_.Key
                "name" = $_.Value.name
                "performance_rating" = $_.Value.performance_rating
                "role" = $_.Value.role
            }
        }

    $report.high_earners = $compensationData |
        Sort-Object -Property total_compensation -Descending |
        Select-Object -First 5

    $reportPath = Join-Path $DataPath "aac_hr_compensation_report.json"
    $report | ConvertTo-Json -Depth 10 | Set-Content $reportPath

    Write-AACLog "HR compensation report generated and saved" "SUCCESS"
    return $report
}

function Add-TrainingRecord {
    param(
        [string]$EmployeeId,
        [string]$TrainingProgram,
        [string]$CompletionDate = (Get-Date).ToString("yyyy-MM-dd"),
        [string]$Certification
    )

    $trainingDbPath = Join-Path $DataPath "aac_training_database.json"
    $trainingData = Get-Content $trainingDbPath | ConvertFrom-Json

    $newRecord = @{
        "employee_id" = $EmployeeId
        "training_program" = $TrainingProgram
        "completion_date" = $CompletionDate
        "certification" = $Certification
        "recorded_date" = (Get-Date).ToString("o")
    }

    $trainingData.training_records += $newRecord
    $trainingData.last_updated = (Get-Date).ToString("o")

    $trainingData | ConvertTo-Json -Depth 10 | Set-Content $trainingDbPath

    # Update employee record
    if ($AAC_HR_DATABASE.ContainsKey($EmployeeId)) {
        $AAC_HR_DATABASE[$EmployeeId].training_completed += $TrainingProgram
        if ($Certification) {
            $AAC_HR_DATABASE[$EmployeeId].certifications += $Certification
        }
    }

    Write-AACLog "Training record added for $EmployeeId - $TrainingProgram" "TRAINING"
}

# Main execution logic
if ($Initialize) {
    Initialize-AACHRDatabase
    Write-AACLog "AAC HR Database Management System initialized successfully" "SUCCESS"
    exit 0
}

if ($Update -and $AgentId) {
    Write-Host "Updating employee record for $AgentId..." -ForegroundColor Yellow
    # Example update - in production this would take parameters
    $updates = @{
        "performance_rating" = 95.0
        "last_review" = (Get-Date).ToString("yyyy-MM-dd")
    }
    Update-EmployeeRecord -EmployeeId $AgentId -Updates $updates
    exit 0
}

if ($Report) {
    $hrReport = Generate-HRReport
    Write-Host "AAC HR Compensation Report:" -ForegroundColor Yellow
    Write-Host "Total Employees: $($hrReport.total_employees)" -ForegroundColor Cyan
    Write-Host ("Total Compensation: ${0:N0}" -f $hrReport.compensation_summary.total_compensation) -ForegroundColor Green
    Write-Host ("Average Base Salary: ${0:N0}" -f $hrReport.compensation_summary.average_base_salary) -ForegroundColor Magenta
    Write-Host "Average Bonus Percentage: $($hrReport.compensation_summary.average_bonus_percentage)%" -ForegroundColor Blue
    Write-Host "" -ForegroundColor White
    Write-Host "Class Breakdown:" -ForegroundColor Yellow
    Write-Host "A-Agents: $($hrReport.class_breakdown.A_Agents.count) employees, Avg Salary: ${0:N0}" -f $hrReport.class_breakdown.A_Agents.average_salary -ForegroundColor Red
    Write-Host "B-Agents: $($hrReport.class_breakdown.B_Agents.count) employees, Avg Salary: ${0:N0}" -f $hrReport.class_breakdown.B_Agents.average_salary -ForegroundColor Blue
    Write-Host "C-Agents: $($hrReport.class_breakdown.C_Agents.count) employees, Avg Salary: ${0:N0}" -f $hrReport.class_breakdown.C_Agents.average_salary -ForegroundColor Green
    exit 0
}

if ($Training -and $AgentId) {
    Write-Host "Adding training record for $AgentId..." -ForegroundColor Yellow
    Add-TrainingRecord -EmployeeId $AgentId -TrainingProgram "Advanced Arbitrage Strategies" -Certification "Advanced Arbitrage Certification"
    exit 0
}

if ($AgentId -and $Action -eq "compensation") {
    $comp = Calculate-Compensation -EmployeeId $AgentId
    if ($comp) {
        Write-Host "Compensation Details for $($comp.employee_id):" -ForegroundColor Yellow
        Write-Host ("Base Salary: ${0:N0}" -f $comp.base_salary) -ForegroundColor Cyan
        Write-Host ("Annual Bonus: ${0:N0}" -f $comp.annual_bonus) -ForegroundColor Green
        Write-Host ("Total Compensation: ${0:N0}" -f $comp.total_compensation) -ForegroundColor Magenta
        Write-Host "Bonus Percentage: $($comp.bonus_percentage)%" -ForegroundColor Blue
        Write-Host "Performance Rating: $($comp.performance_rating)%" -ForegroundColor White
    } else {
        Write-Host "Employee $AgentId not found" -ForegroundColor Red
    }
    exit 0
}

# Default: Show help
Write-Host "AAC HR Database Management System" -ForegroundColor Yellow
Write-Host "Usage:" -ForegroundColor Cyan
Write-Host "  .\AAC.HRDatabase.ps1 -Initialize              # Initialize HR databases" -ForegroundColor White
Write-Host "  .\AAC.HRDatabase.ps1 -Report                  # Generate compensation report" -ForegroundColor White
Write-Host "  .\AAC.HRDatabase.ps1 -AgentId AUG-001 -Action compensation  # Show agent compensation" -ForegroundColor White
Write-Host "  .\AAC.HRDatabase.ps1 -Training -AgentId AUG-001  # Add training record" -ForegroundColor White
Write-Host "  .\AAC.HRDatabase.ps1 -Update -AgentId AUG-001   # Update employee record" -ForegroundColor White