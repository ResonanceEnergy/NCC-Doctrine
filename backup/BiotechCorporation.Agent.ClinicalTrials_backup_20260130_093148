# Biotech Corporation - Clinical Trials Agent
# Advanced clinical trial management and monitoring operations

param(
    [switch]$Initialize,
    [switch]$StartOperations,


# NCC Communication Integration
$AgentCommPath = Join-Path $PSScriptRoot "NCC.Agent.Communication.ps1"
if (Test-Path $AgentCommPath) {
    # Register agent with communication system
    & $AgentCommPath -AgentName "BiotechCorporation.Agent.ClinicalTrials" -Division "BiotechCorporation" -InitializeNetwork

    # Communication functions for agent use
    function Send-AgentMessage {
        param([string]$To, [string]$Type, [string]$Content, [string]$Priority = "Normal")
        & $AgentCommPath -AgentName "BiotechCorporation.Agent.ClinicalTrials" -TargetAgent $To -MessageType $Type -MessageContent $Content -Priority $Priority -SendMessage
    }

    function Receive-AgentMessages {
        return & $AgentCommPath -AgentName "BiotechCorporation.Agent.ClinicalTrials" -ReceiveMessages
    }

    function Broadcast-Message {
        param([string]$Type, [string]$Content, [string]$Priority = "Normal")
        & $AgentCommPath -AgentName "BiotechCorporation.Agent.ClinicalTrials" -MessageType $Type -MessageContent $Content -Priority $Priority -Broadcast
    }

    function Check-Connectivity {
        param([string]$TargetAgent)
        return & $AgentCommPath -TargetAgent $TargetAgent -CheckConnectivity
    }

    # Initialize communication on agent startup
    Write-Host "ðŸ”— Agent communication system initialized for BiotechCorporation.Agent.ClinicalTrials" -ForegroundColor Cyan
}
    [switch]$StopOperations,
    [switch]$Status,
    [switch]$MonitorTrials,
    [switch]$PatientRecruitment,
    [switch]$DataAnalysis,
    [switch]$RegulatoryCompliance,
    [switch]$GenerateReports
)

# Agent-specific configuration
$AgentConfig = @{
    Name = "BiotechCorporation.Agent.ClinicalTrials"
    Division = "BiotechCorporation"
    Role = "ClinicalTrials"
    Specialization = "Clinical Trial Management"
    Status = "Inactive"
    TrialPhases = @("Phase 1", "Phase 2", "Phase 3", "Phase 4")
    TherapeuticAreas = @("Oncology", "Neurology", "Cardiology", "Immunology", "Infectious Diseases")
    RegulatoryBodies = @("FDA", "EMA", "MHRA", "PMDA", "NMPA")
}

function Write-AgentLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$($AgentConfig.Name)] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(switch($Level){"ERROR"{"Red"}"WARNING"{"Yellow"}"SUCCESS"{"Green"}default{"Cyan"}})
}

function Initialize-Agent {
    Write-AgentLog "Initializing Biotech Corporation Clinical Trials Agent..." -Level "INFO"

    # Create clinical trials directories
    $dirs = @("data", "logs", "config", "trials", "patients", "regulatory", "reports", "protocols")
    foreach ($dir in $dirs) {
        $path = Join-Path $PSScriptRoot $dir
        if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
    }

    # Initialize trial databases
    $trialsPath = Join-Path $PSScriptRoot "data\active_trials.json"
    @{Trials = @(); LastUpdate = Get-Date} | ConvertTo-Json | Out-File $trialsPath -Encoding UTF8

    $patientsPath = Join-Path $PSScriptRoot "data\patient_database.json"
    @{Patients = @(); LastUpdate = Get-Date} | ConvertTo-Json | Out-File $patientsPath -Encoding UTF8

    $regulatoryPath = Join-Path $PSScriptRoot "data\regulatory_status.json"
    @{Submissions = @(); LastUpdate = Get-Date} | ConvertTo-Json | Out-File $regulatoryPath -Encoding UTF8

    $AgentConfig.Status = "Initialized"
    Write-AgentLog "Clinical trials agent initialization completed" -Level "SUCCESS"
}

function Start-AgentOperations {
    Write-AgentLog "Starting clinical trial operations..." -Level "INFO"
    $AgentConfig.Status = "Active"

    # Start trial monitoring systems
    Start-TrialMonitoring
    Start-PatientTracking
    Start-DataCollection
    Start-RegulatoryMonitoring

    Write-AgentLog "Clinical trial operations started" -Level "SUCCESS"
}

function Stop-AgentOperations {
    Write-AgentLog "Stopping clinical trial operations..." -Level "INFO"
    $AgentConfig.Status = "Inactive"

    Stop-TrialMonitoring
    Stop-PatientTracking
    Stop-DataCollection
    Stop-RegulatoryMonitoring

    Write-AgentLog "Clinical trial operations stopped" -Level "SUCCESS"
}

function Start-TrialMonitoring {
    Write-AgentLog "Starting trial monitoring..." -Level "INFO"
}

function Start-PatientTracking {
    Write-AgentLog "Starting patient tracking..." -Level "INFO"
}

function Start-DataCollection {
    Write-AgentLog "Starting clinical data collection..." -Level "INFO"
}

function Start-RegulatoryMonitoring {
    Write-AgentLog "Starting regulatory monitoring..." -Level "INFO"
}

function Stop-TrialMonitoring {
    Write-AgentLog "Stopping trial monitoring..." -Level "INFO"
}

function Stop-PatientTracking {
    Write-AgentLog "Stopping patient tracking..." -Level "INFO"
}

function Stop-DataCollection {
    Write-AgentLog "Stopping data collection..." -Level "INFO"
}

function Stop-RegulatoryMonitoring {
    Write-AgentLog "Stopping regulatory monitoring..." -Level "INFO"
}

function Monitor-ClinicalTrials {
    Write-AgentLog "Monitoring clinical trial progress and compliance..." -Level "INFO"

    $monitoring = @{
        Timestamp = Get-Date
        ActiveTrials = @()
        TrialMetrics = @{}
        ComplianceStatus = @()
        RiskIndicators = @()
        ActionItems = @()
    }

    # Simulate active trials
    for ($i = 1; $i -le (Get-Random -Minimum 5 -Maximum 12); $i++) {
        $trial = @{
            Id = [guid]::NewGuid().ToString()
            ProtocolNumber = "BTC-CT-$(Get-Random -Minimum 100 -Maximum 999)"
            Compound = "BTC-$(Get-Random -Minimum 100 -Maximum 999)"
            Phase = $AgentConfig.TrialPhases | Get-Random
            TherapeuticArea = $AgentConfig.TherapeuticAreas | Get-Random
            Status = @("Recruiting", "Active", "Follow-up", "Completed") | Get-Random
            TargetEnrollment = Get-Random -Minimum 50 -Maximum 1000
            CurrentEnrollment = 0
            Sites = Get-Random -Minimum 10 -Maximum 100
            Countries = @("US", "EU", "Japan", "China", "Canada") | Get-Random -Count (Get-Random -Minimum 1 -Maximum 5)
            StartDate = (Get-Date).AddMonths(-(Get-Random -Minimum 1 -Maximum 24))
            EstimatedCompletion = (Get-Date).AddMonths((Get-Random -Minimum -6 -Maximum 18))
            PrimaryEndpoint = "Overall Survival"
            SecondaryEndpoints = @("Progression Free Survival", "Objective Response Rate", "Quality of Life")
            DataQualityScore = [math]::Round((Get-Random -Minimum 70 -Maximum 100), 1)
            ComplianceScore = [math]::Round((Get-Random -Minimum 80 -Maximum 100), 1)
        }

        # Calculate current enrollment
        $trial.CurrentEnrollment = [math]::Min($trial.TargetEnrollment, [math]::Round($trial.TargetEnrollment * (Get-Random -Minimum 0.3 -Maximum 1.0)))

        $monitoring.ActiveTrials += $trial
    }

    # Calculate trial metrics
    $totalTrials = $monitoring.ActiveTrials.Count
    $recruitingTrials = ($monitoring.ActiveTrials | Where-Object { $_.Status -eq "Recruiting" }).Count
    $activeTrials = ($monitoring.ActiveTrials | Where-Object { $_.Status -eq "Active" }).Count
    $avgEnrollment = [math]::Round(($monitoring.ActiveTrials | Measure-Object -Property CurrentEnrollment -Average).Average, 1)
    $avgDataQuality = [math]::Round(($monitoring.ActiveTrials | Measure-Object -Property DataQualityScore -Average).Average, 1)
    $avgCompliance = [math]::Round(($monitoring.ActiveTrials | Measure-Object -Property ComplianceScore -Average).Average, 1)

    $monitoring.TrialMetrics = @{
        TotalTrials = $totalTrials
        RecruitingTrials = $recruitingTrials
        ActiveTrials = $activeTrials
        AverageEnrollment = $avgEnrollment
        AverageDataQuality = $avgDataQuality
        AverageCompliance = $avgCompliance
        OnTimeTrials = [math]::Round(($monitoring.ActiveTrials | Where-Object { $_.EstimatedCompletion -gt (Get-Date) }).Count / $totalTrials * 100, 1)
    }

    # Compliance status
    $monitoring.ComplianceStatus = @(
        @{Area = "Data Integrity"; Status = "Good"; Score = 95; Issues = 0},
        @{Area = "Patient Safety"; Status = "Excellent"; Score = 98; Issues = 0},
        @{Area = "Regulatory Reporting"; Status = "Good"; Score = 92; Issues = 2},
        @{Area = "Protocol Adherence"; Status = "Good"; Score = 94; Issues = 1}
    )

    # Risk indicators
    $monitoring.RiskIndicators = @(
        "Patient recruitment behind schedule in 2 trials",
        "Data quality concerns in 1 trial",
        "Regulatory inspection scheduled for Q2",
        "Supply chain disruption affecting drug delivery"
    )

    # Action items
    $monitoring.ActionItems = @(
        "Increase recruitment efforts in under-enrolled trials",
        "Implement additional data quality monitoring",
        "Prepare for regulatory inspection",
        "Develop contingency plans for supply chain issues"
    )

    # Save monitoring report
    $monitoringPath = Join-Path $PSScriptRoot "trials\trial_monitoring_$(Get-Date -Format 'yyyy-MM-dd').json"
    $trialsDir = Split-Path $monitoringPath -Parent
    if (-not (Test-Path $trialsDir)) { New-Item -ItemType Directory -Path $trialsDir -Force | Out-Null }
    $monitoring | ConvertTo-Json -Depth 10 | Out-File $monitoringPath -Encoding UTF8

    Write-AgentLog "Clinical trial monitoring completed - $totalTrials active trials, avg enrollment: $avgEnrollment" -Level "SUCCESS"
    return $monitoring
}

function Manage-PatientRecruitment {
    Write-AgentLog "Managing patient recruitment and enrollment..." -Level "INFO"

    $recruitment = @{
        Timestamp = Get-Date
        RecruitmentMetrics = @{}
        ScreeningData = @()
        EnrollmentTrends = @()
        Challenges = @()
        Strategies = @()
    }

    # Recruitment metrics
    $recruitment.RecruitmentMetrics = @{
        TotalScreened = Get-Random -Minimum 500 -Maximum 2000
        EligiblePatients = Get-Random -Minimum 300 -Maximum 1500
        EnrolledPatients = Get-Random -Minimum 200 -Maximum 1200
        DropoutRate = [math]::Round((Get-Random -Minimum 5 -Maximum 25), 1)
        ScreeningSuccessRate = [math]::Round((Get-Random -Minimum 60 -Maximum 90), 1)
        EnrollmentTarget = 1000
        EnrollmentProgress = [math]::Round((Get-Random -Minimum 40 -Maximum 85), 1)
    }

    # Screening data by trial
    for ($i = 1; $i -le 5; $i++) {
        $screening = @{
            TrialId = "BTC-CT-$i"
            ScreenedThisMonth = Get-Random -Minimum 20 -Maximum 100
            EligibleThisMonth = Get-Random -Minimum 10 -Maximum 80
            EnrolledThisMonth = Get-Random -Minimum 5 -Maximum 60
            RejectionReasons = @(
                "Did not meet inclusion criteria",
                "Met exclusion criteria",
                "Patient declined participation",
                "Logistical issues"
            ) | Get-Random -Count (Get-Random -Minimum 1 -Maximum 4)
        }
        $recruitment.ScreeningData += $screening
    }

    # Enrollment trends
    for ($month = 1; $month -le 6; $month++) {
        $trend = @{
            Month = (Get-Date).AddMonths(-$month).ToString("MMM yyyy")
            Target = Get-Random -Minimum 150 -Maximum 200
            Actual = Get-Random -Minimum 120 -Maximum 180
            CumulativeTarget = 1000
            CumulativeActual = [math]::Min(1000, (Get-Random -Minimum 600 -Maximum 950))
        }
        $recruitment.EnrollmentTrends += $trend
    }

    # Recruitment challenges
    $recruitment.Challenges = @(
        "Competition from other clinical trials",
        "Stringent eligibility criteria",
        "Limited patient population for rare diseases",
        "Geographic limitations",
        "Patient travel and logistical issues"
    )

    # Recruitment strategies
    $recruitment.Strategies = @(
        "Expand to additional clinical sites",
        "Implement patient referral programs",
        "Use digital marketing and social media",
        "Partner with patient advocacy groups",
        "Offer telemedicine options for screening"
    )

    # Save recruitment report
    $recruitmentPath = Join-Path $PSScriptRoot "patients\recruitment_status_$(Get-Date -Format 'yyyy-MM-dd').json"
    $patientsDir = Split-Path $recruitmentPath -Parent
    if (-not (Test-Path $patientsDir)) { New-Item -ItemType Directory -Path $patientsDir -Force | Out-Null }
    $recruitment | ConvertTo-Json -Depth 10 | Out-File $recruitmentPath -Encoding UTF8

    Write-AgentLog "Patient recruitment management completed - $($recruitment.RecruitmentMetrics.EnrolledPatients) patients enrolled" -Level "SUCCESS"
    return $recruitment
}

function Analyze-ClinicalData {
    Write-AgentLog "Analyzing clinical trial data..." -Level "INFO"

    $analysis = @{
        Timestamp = Get-Date
        DataQualityMetrics = @{}
        EfficacyData = @()
        SafetyData = @()
        StatisticalAnalysis = @{}
        InterimResults = @()
        DataGaps = @()
    }

    # Data quality metrics
    $analysis.DataQualityMetrics = @{
        Completeness = [math]::Round((Get-Random -Minimum 85 -Maximum 98), 1)
        Accuracy = [math]::Round((Get-Random -Minimum 90 -Maximum 99), 1)
        Consistency = [math]::Round((Get-Random -Minimum 88 -Maximum 97), 1)
        Timeliness = [math]::Round((Get-Random -Minimum 80 -Maximum 95), 1)
        OverallScore = [math]::Round((Get-Random -Minimum 85 -Maximum 97), 1)
    }

    # Efficacy data
    $analysis.EfficacyData = @(
        @{Endpoint = "Primary Endpoint"; Value = [math]::Round((Get-Random -Minimum 40 -Maximum 75), 1); Unit = "%"; Status = "Positive"},
        @{Endpoint = "Secondary Endpoint 1"; Value = [math]::Round((Get-Random -Minimum 30 -Maximum 65), 1); Unit = "%"; Status = "Positive"},
        @{Endpoint = "Secondary Endpoint 2"; Value = [math]::Round((Get-Random -Minimum 25 -Maximum 55), 1); Unit = "%"; Status = "Neutral"}
    )

    # Safety data
    $analysis.SafetyData = @(
        @{Event = "Adverse Events"; Rate = [math]::Round((Get-Random -Minimum 60 -Maximum 85), 1); Severity = "Mostly Mild-Moderate"},
        @{Event = "Serious Adverse Events"; Rate = [math]::Round((Get-Random -Minimum 5 -Maximum 20), 1); Severity = "Manageable"},
        @{Event = "Treatment Discontinuation"; Rate = [math]::Round((Get-Random -Minimum 10 -Maximum 25), 1); Severity = "Within Expectations"}
    )

    # Statistical analysis
    $analysis.StatisticalAnalysis = @{
        SampleSize = Get-Random -Minimum 200 -Maximum 800
        Power = [math]::Round((Get-Random -Minimum 80 -Maximum 95), 1)
        PValue = [math]::Round((Get-Random -Minimum 0.001 -Maximum 0.05), 4)
        ConfidenceInterval = "95%"
        EffectSize = [math]::Round((Get-Random -Minimum 0.3 -Maximum 0.8), 2)
    }

    # Interim results
    $analysis.InterimResults = @(
        "Primary endpoint met with statistical significance",
        "Favorable safety profile observed",
        "Patient-reported outcomes show quality of life improvement",
        "Biomarker data supports mechanism of action"
    )

    # Data gaps
    $analysis.DataGaps = @(
        "Long-term follow-up data limited",
        "Subgroup analysis incomplete",
        "Health economics data pending",
        "Real-world evidence collection ongoing"
    )

    # Save data analysis
    $analysisPath = Join-Path $PSScriptRoot "trials\data_analysis_$(Get-Date -Format 'yyyy-MM-dd').json"
    $trialsDir = Split-Path $analysisPath -Parent
    if (-not (Test-Path $trialsDir)) { New-Item -ItemType Directory -Path $trialsDir -Force | Out-Null }
    $analysis | ConvertTo-Json -Depth 10 | Out-File $analysisPath -Encoding UTF8

    Write-AgentLog "Clinical data analysis completed - Data quality score: $($analysis.DataQualityMetrics.OverallScore)%" -Level "SUCCESS"
    return $analysis
}

function Monitor-RegulatoryCompliance {
    Write-AgentLog "Monitoring regulatory compliance and submissions..." -Level "INFO"

    $compliance = @{
        Timestamp = Get-Date
        RegulatoryStatus = @()
        SubmissionTracking = @()
        InspectionReadiness = @{}
        ComplianceIssues = @()
        UpcomingDeadlines = @()
    }

    # Regulatory status by region
    foreach ($body in $AgentConfig.RegulatoryBodies) {
        $status = @{
            RegulatoryBody = $body
            Status = @("Approved", "Under Review", "Submitted", "Planning") | Get-Random
            LastUpdate = (Get-Date).AddDays(-(Get-Random -Minimum 1 -Maximum 90))
            NextMilestone = (Get-Date).AddDays((Get-Random -Minimum 30 -Maximum 180))
            ComplianceScore = [math]::Round((Get-Random -Minimum 85 -Maximum 100), 1)
        }
        $compliance.RegulatoryStatus += $status
    }

    # Submission tracking
    $compliance.SubmissionTracking = @(
        @{Type = "IND"; Status = "Approved"; Submitted = (Get-Date).AddMonths(-6); Approved = (Get-Date).AddMonths(-4)},
        @{Type = "CTA"; Status = "Under Review"; Submitted = (Get-Date).AddMonths(-2); Expected = (Get-Date).AddMonths(1)},
        @{Type = "NDA"; Status = "Planning"; TargetSubmission = (Get-Date).AddMonths(6)}
    )

    # Inspection readiness
    $compliance.InspectionReadiness = @{
        DocumentationComplete = [math]::Round((Get-Random -Minimum 85 -Maximum 98), 1)
        SystemsValidated = [math]::Round((Get-Random -Minimum 90 -Maximum 100), 1)
        TrainingComplete = [math]::Round((Get-Random -Minimum 80 -Maximum 95), 1)
        OverallReadiness = [math]::Round((Get-Random -Minimum 85 -Maximum 97), 1)
    }

    # Compliance issues
    $compliance.ComplianceIssues = @(
        "Minor deviation in data recording procedure",
        "Training record update required",
        "Documentation formatting standardization needed"
    )

    # Upcoming deadlines
    $compliance.UpcomingDeadlines = @(
        @{Deadline = (Get-Date).AddDays(30); Description = "Annual safety report submission"},
        @{Deadline = (Get-Date).AddDays(60); Description = "Regulatory meeting preparation"},
        @{Deadline = (Get-Date).AddDays(90); Description = "DSUR submission"}
    )

    # Save compliance report
    $compliancePath = Join-Path $PSScriptRoot "regulatory\compliance_status_$(Get-Date -Format 'yyyy-MM-dd').json"
    $regulatoryDir = Split-Path $compliancePath -Parent
    if (-not (Test-Path $regulatoryDir)) { New-Item -ItemType Directory -Path $regulatoryDir -Force | Out-Null }
    $compliance | ConvertTo-Json -Depth 10 | Out-File $compliancePath -Encoding UTF8

    Write-AgentLog "Regulatory compliance monitoring completed" -Level "SUCCESS"
    return $compliance
}

function Generate-ClinicalReports {
    Write-AgentLog "Generating clinical trial reports..." -Level "INFO"

    $reports = @{
        Timestamp = Get-Date
        ExecutiveSummary = @{}
        TrialProgressReports = @()
        SafetyReports = @()
        RegulatoryReports = @()
        FinancialReports = @()
    }

    # Executive summary
    $reports.ExecutiveSummary = @{
        TotalActiveTrials = Get-Random -Minimum 8 -Maximum 15
        PatientsEnrolled = Get-Random -Minimum 1500 -Maximum 3500
        TrialsOnTrack = [math]::Round((Get-Random -Minimum 70 -Maximum 90), 1)
        KeyMilestones = @(
            "Phase 3 trial completed enrollment",
            "Positive interim analysis results",
            "Regulatory approval in EU achieved"
        )
        MajorChallenges = @(
            "Patient recruitment delays",
            "Supply chain disruptions"
        )
        NextSteps = @(
            "Initiate Phase 3 trial",
            "File NDA with FDA",
            "Expand to additional markets"
        )
    }

    # Trial progress reports
    for ($i = 1; $i -le 3; $i++) {
        $progress = @{
            TrialId = "BTC-CT-$i"
            Title = "Phase $($i+1) Study of BTC-Compound in $($AgentConfig.TherapeuticAreas | Get-Random)"
            Progress = [math]::Round((Get-Random -Minimum 60 -Maximum 95), 1)
            Enrollment = Get-Random -Minimum 200 -Maximum 600
            DataQuality = [math]::Round((Get-Random -Minimum 85 -Maximum 98), 1)
            Timeline = "On Track"
            KeyFindings = @(
                "Primary endpoint trending positive",
                "Safety profile acceptable",
                "Patient compliance high"
            )
        }
        $reports.TrialProgressReports += $progress
    }

    # Safety reports
    $reports.SafetyReports = @(
        @{Type = "Monthly Safety Report"; Status = "Completed"; Date = (Get-Date).AddMonths(-1)},
        @{Type = "DSUR"; Status = "In Progress"; DueDate = (Get-Date).AddMonths(2)},
        @{Type = "Development Safety Update"; Status = "Planned"; DueDate = (Get-Date).AddMonths(6)}
    )

    # Regulatory reports
    $reports.RegulatoryReports = @(
        @{Type = "IND Annual Report"; Status = "Submitted"; Date = (Get-Date).AddMonths(-1)},
        @{Type = "CTA Response"; Status = "Received"; Date = (Get-Date).AddDays(-15)},
        @{Type = "Meeting Request"; Status = "Planned"; Date = (Get-Date).AddDays(45)}
    )

    # Financial reports
    $reports.FinancialReports = @(
        @{Type = "Trial Budget vs Actual"; Variance = [math]::Round((Get-Random -Minimum -10 -Maximum 5), 1)},
        @{Type = "Cost per Patient"; Amount = Get-Random -Minimum 50000 -Maximum 150000},
        @{Type = "Regulatory Filing Costs"; Amount = Get-Random -Minimum 2000000 -Maximum 5000000}
    )

    # Save reports
    $reportsPath = Join-Path $PSScriptRoot "reports\clinical_reports_$(Get-Date -Format 'yyyy-MM-dd').json"
    $reportsDir = Split-Path $reportsPath -Parent
    if (-not (Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null }
    $reports | ConvertTo-Json -Depth 10 | Out-File $reportsPath -Encoding UTF8

    Write-AgentLog "Clinical reports generated successfully" -Level "SUCCESS"
    return $reports
}

# Main execution logic
if ($Initialize) { Initialize-Agent }
if ($StartOperations) { Start-AgentOperations }
if ($StopOperations) { Stop-AgentOperations }
if ($Status) { Write-AgentLog "Status: $($AgentConfig.Status)" -Level "INFO" }
if ($MonitorTrials) { Monitor-ClinicalTrials }
if ($PatientRecruitment) { Manage-PatientRecruitment }
if ($DataAnalysis) { Analyze-ClinicalData }
if ($RegulatoryCompliance) { Monitor-RegulatoryCompliance }
if ($GenerateReports) { Generate-ClinicalReports }

# Default status display
if (-not ($Initialize -or $StartOperations -or $StopOperations -or $Status -or $MonitorTrials -or $PatientRecruitment -or $DataAnalysis -or $RegulatoryCompliance -or $GenerateReports)) {
    Write-AgentLog "$($AgentConfig.Name) - Status: $($AgentConfig.Status) - Trial Phases: $($AgentConfig.TrialPhases.Count)" -Level "INFO"
}
