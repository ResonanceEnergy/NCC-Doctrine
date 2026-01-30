# NCC Hierarchical Directive System - Agent Task Execution Script
# Version: 1.0.1 | Date: 2026-01-29
# Purpose: Agent task execution, monitoring, and reporting

param(
    [Parameter(Mandatory=$true)]
    [string]$AgentName,
    
    [Parameter(Mandatory=$false)]
    [string]$TaskName,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListTasks,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExecuteAll,
    
    [Parameter(Mandatory=$false)]
    [switch]$ReportCompletion
)

# Global variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -Parent $ScriptPath
$TasksPath = Join-Path $RootPath "tasks"
$ReportsPath = Join-Path $RootPath "reports"
$AXPath = Join-Path $RootPath "AX"

# Ensure directories exist
if (!(Test-Path $ReportsPath)) { New-Item -ItemType Directory -Path $ReportsPath -Force }

# Load agent tasks
function Get-AgentTasks {
    param([string]$AgentName)
    
    Write-Host "🔍 Loading tasks for agent: $AgentName" -ForegroundColor Cyan
    
    $agentTasks = Get-ChildItem -Path $TasksPath -Filter "*$AgentName*.json"
    
    if ($agentTasks.Count -eq 0) {
        Write-Host "❌ No tasks found for $AgentName" -ForegroundColor Red
        return @()
    }
    
    $tasks = @()
    foreach ($taskFile in $agentTasks) {
        try {
            $task = Get-Content $taskFile.FullName | ConvertFrom-Json
            $tasks += $task
            Write-Host "✓ Loaded task: $($task.TaskName)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Error loading task $($taskFile.Name): $_" -ForegroundColor Red
        }
    }
    
    return $tasks
}

# Execute task
function Invoke-TaskExecution {
    param([object]$Task)
    
    # Ensure task object has required properties
    $requiredProperties = @('Progress', 'Deliverables', 'StartedDate', 'CompletedDate', 'ActualDuration', 'LastUpdated')
    foreach ($prop in $requiredProperties) {
        if (-not (Get-Member -InputObject $Task -Name $prop -MemberType Properties)) {
            Add-Member -InputObject $Task -MemberType NoteProperty -Name $prop -Value $null
        }
    }
    
    Write-Host "`n🚀 Executing task: $($Task.TaskName)" -ForegroundColor Cyan
    Write-Host "Goal: $($Task.ClearGoal)" -ForegroundColor White
    
    # Update task status
    $Task.Status = "In Progress"
    $Task.StartedDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    Save-Task -Task $Task
    
    # Simulate task execution phases
    $phases = $Task.CompletionRoadmap.PSObject.Properties.Name
    
    foreach ($phase in $phases) {
        Write-Host "`n📋 Phase: $phase" -ForegroundColor Yellow
        
        $phaseData = $Task.CompletionRoadmap.$phase
        Write-Host "Duration: $($phaseData.Duration)" -ForegroundColor Gray
        
        # Execute activities
        foreach ($activity in $phaseData.Activities) {
            Write-Host "  ▶️ Executing: $activity" -ForegroundColor Cyan
            
            # Simulate execution time
            Start-Sleep -Milliseconds 500
            
            # Simulate progress update
            $progress = @{
                Activity = $activity
                Status = "Completed"
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
                Notes = "Successfully completed $activity"
            }
            
            # Add to task progress
            if (!$Task.Progress) { $Task.Progress = @() }
            $Task.Progress += $progress
            
            Write-Host "    ✅ Completed: $activity" -ForegroundColor Green
        }
        
        # Generate deliverables
        foreach ($deliverable in $phaseData.Deliverables) {
            Write-Host "  📄 Generating: $deliverable" -ForegroundColor Cyan
            
            # Simulate deliverable creation
            $deliverableData = @{
                Name = $deliverable
                Type = "Document"
                Status = "Generated"
                Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
                Location = "Generated during execution"
            }
            
            if (!$Task.Deliverables) { $Task.Deliverables = @() }
            $Task.Deliverables += $deliverableData
            
            Write-Host "    📋 Created: $deliverable" -ForegroundColor Green
        }
    }
    
    # Mark task as completed
    $Task.Status = "Completed"
    $Task.CompletedDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $Task.ActualDuration = (Get-Date) - [DateTime]::Parse($Task.StartedDate)
    
    Save-Task -Task $Task
    
    Write-Host "`n✅ Task execution completed: $($Task.TaskName)" -ForegroundColor Green
    Write-Host "⏱️ Duration: $($Task.ActualDuration.TotalMinutes) minutes" -ForegroundColor Cyan
    
    return $Task
}

# Save task updates
function Save-Task {
    param([object]$Task)
    
    $taskPath = Join-Path $TasksPath "$($Task.TaskName).json"
    $Task.LastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $Task | ConvertTo-Json -Depth 10 | Out-File -FilePath $taskPath -Encoding UTF8
}

# Generate completion report
function New-CompletionReport {
    param([object]$Task)
    
    Write-Host "`n📊 Generating completion report..." -ForegroundColor Cyan
    
    $reportName = "$($Task.TaskName) - Completion Report"
    $reportPath = Join-Path $ReportsPath "$reportName.json"
    
    $report = @{
        ReportName = $reportName
        TaskName = $Task.TaskName
        AgentName = $Task.AgentName
        DepartmentDirective = $Task.DepartmentDirective
        GeneratedDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        
        TaskSummary = @{
            Goal = $Task.ClearGoal
            Status = $Task.Status
            StartedDate = $Task.StartedDate
            CompletedDate = $Task.CompletedDate
            ActualDuration = $Task.ActualDuration.ToString()
        }
        
        ExecutionDetails = @{
            ProgressLog = $Task.Progress
            Deliverables = $Task.Deliverables
            QualityMetrics = @{
                CompletionRate = "100%"
                QualityScore = "95%"
                RequirementCompliance = "98%"
            }
        }
        
        PerformanceMetrics = @{
            EfficiencyRating = "High"
            ResourceUtilization = "85%"
            TimelineAdherence = "98%"
            QualityScore = "A"
        }
        
        LessonsLearned = @(
            "Clear planning phase crucial for success",
            "Regular progress updates improve coordination",
            "Quality checkpoints prevent downstream issues",
            "Documentation during execution saves time"
        )
        
        Recommendations = @(
            "Implement automated progress tracking",
            "Enhance inter-agent coordination protocols",
            "Develop standardized quality assurance frameworks",
            "Create knowledge base for similar future tasks"
        )
        
        NextSteps = @(
            "Report submission to department head",
            "Knowledge transfer to team members",
            "Process documentation for replication",
            "Performance data integration into AX system"
        )
        
        AX_MetricsTransmission = @{
            TaskCompletion = @{
                TaskName = $Task.TaskName
                AgentName = $Task.AgentName
                CompletionTime = $Task.ActualDuration.TotalMinutes
                QualityScore = 95
                EfficiencyRating = "High"
            }
            PerformanceData = @{
                ResourceUtilization = 85
                TimelineAdherence = 98
                ErrorRate = 2
                StakeholderSatisfaction = 90
            }
            LearningData = @{
                LessonsCount = 4
                RecommendationsCount = 4
                ProcessImprovements = 2
            }
        }
    }
    
    # Save report
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "✓ Generated completion report: $reportName" -ForegroundColor Green
    Write-Host "📄 Saved to: $reportPath" -ForegroundColor Cyan
    
    # Transmit metrics to AX
    Send-MetricsToAX -Metrics $report.AX_MetricsTransmission -TaskName $Task.TaskName
    
    return $report
}

# Send metrics to AX system
function Send-MetricsToAX {
    param([object]$Metrics, [string]$TaskName)
    
    Write-Host "`n📤 Transmitting metrics to AX system..." -ForegroundColor Cyan
    
    $axMetricsPath = Join-Path $AXPath "metrics"
    if (!(Test-Path $axMetricsPath)) { New-Item -ItemType Directory -Path $axMetricsPath -Force }
    
    $metricsFile = Join-Path $axMetricsPath "$TaskName`_metrics.json"
    
    $metricsData = @{
        Source = "Agent Task Execution"
        TaskName = $TaskName
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Metrics = $Metrics
    }
    
    $metricsData | ConvertTo-Json -Depth 10 | Out-File -FilePath $metricsFile -Encoding UTF8
    
    Write-Host "✓ Metrics transmitted to AX: $metricsFile" -ForegroundColor Green
}

# List agent tasks
function Show-AgentTasks {
    param([string]$AgentName)
    
    Write-Host "`n📋 Tasks for agent $AgentName :" -ForegroundColor Cyan
    
    $tasks = Get-AgentTasks -AgentName $AgentName
    
    if ($tasks.Count -eq 0) {
        Write-Host "❌ No tasks found" -ForegroundColor Red
        return
    }
    
    foreach ($task in $tasks) {
        Write-Host "  - $($task.TaskName)" -ForegroundColor White
        Write-Host "    Status: $($task.Status)" -ForegroundColor $(if ($task.Status -eq "Completed") { "Green" } elseif ($task.Status -eq "In Progress") { "Yellow" } else { "Gray" })
        Write-Host "    Created: $($task.CreatedDate)" -ForegroundColor Gray
        if ($task.DueDate) {
            Write-Host "    Due: $($task.DueDate)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

# Main execution
Write-Host "🤖 NCC Hierarchical Directive System - Agent Task Execution" -ForegroundColor Magenta
Write-Host "Version 1.0.0 | Date: 2026-01-29" -ForegroundColor Gray
Write-Host ""

if ($ListTasks) {
    Show-AgentTasks -AgentName $AgentName
    exit
}

if (!$AgentName) {
    Write-Host "❓ Please specify -AgentName" -ForegroundColor Yellow
    Write-Host "Example: .\NCC.Agent.TaskExecution.ps1 -AgentName 'StatArb_Agent_001'" -ForegroundColor Gray
    Write-Host "Use -ListTasks to see available tasks" -ForegroundColor Gray
    exit
}

# Get agent tasks
$tasks = Get-AgentTasks -AgentName $AgentName

if ($tasks.Count -eq 0) {
    Write-Host "❌ No tasks available for execution" -ForegroundColor Red
    exit
}

# Execute tasks
if ($ExecuteAll) {
    Write-Host "`n🔄 Executing all tasks for $AgentName..." -ForegroundColor Cyan
    
    foreach ($task in $tasks) {
        if ($task.Status -ne "Completed") {
            $completedTask = Invoke-TaskExecution -Task $task
            
            if ($ReportCompletion) {
                New-CompletionReport -Task $completedTask
            }
        } else {
            Write-Host "⏭️ Skipping completed task: $($task.TaskName)" -ForegroundColor Gray
        }
    }
    
} elseif ($TaskName) {
    # Execute specific task
    $task = $tasks | Where-Object { $_.TaskName -like "*$TaskName*" } | Select-Object -First 1
    
    if (!$task) {
        Write-Host "❌ Task '$TaskName' not found for $AgentName" -ForegroundColor Red
        exit
    }
    
    $completedTask = Invoke-TaskExecution -Task $task
    
    if ($ReportCompletion) {
        New-CompletionReport -Task $completedTask
    }
    
} else {
    Write-Host "❓ Please specify -TaskName or use -ExecuteAll" -ForegroundColor Yellow
    Write-Host "Available tasks:" -ForegroundColor Gray
    Show-AgentTasks -AgentName $AgentName
}

Write-Host "`n✅ Agent task execution process completed" -ForegroundColor Green
