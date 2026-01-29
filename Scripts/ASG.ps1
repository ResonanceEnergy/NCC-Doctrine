# NCC ASG Activation Protocol
# Autonomous System Generator - Emergency Activation Command

param(
    [switch]$Activate,
    [switch]$Status,
    [switch]$Deactivate
)

# Configuration
$ScriptPath = $PSScriptRoot
$ContinuousOpsScript = Join-Path $ScriptPath "NCC.ContinuousOperations.ps1"
$LogPath = Join-Path $ScriptPath "..\logs\ASG_Activation.log"

# Ensure log directory exists
$LogDir = Split-Path $LogPath -Parent
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-ASGLog {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [ASG] [$Level] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogPath -Value $LogEntry
}

function Get-ProcessStatus {
    $processName = "powershell"
    $continuousOps = Get-Process -Name $processName -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*NCC.ContinuousOperations.ps1*" -and $_.CommandLine -like "*Continuous*" }

    return $continuousOps
}

function Show-Status {
    Write-ASGLog "Checking NCC system status" "STATUS"

    $processes = Get-ProcessStatus
    if ($processes) {
        Write-ASGLog "NCC Continuous Operations: ACTIVE" "STATUS"
        Write-ASGLog "Running processes: $($processes.Count)" "STATUS"
        foreach ($proc in $processes) {
            Write-ASGLog "PID: $($proc.Id) - Started: $($proc.StartTime)" "STATUS"
        }
    } else {
        Write-ASGLog "NCC Continuous Operations: INACTIVE" "STATUS"
    }

    # Check data integrity
    $dataPath = Join-Path $ScriptPath "..\data"
    $dataFiles = @("budgets.json", "ledger.json", "projects.json", "settings.json")
    $dataStatus = "HEALTHY"
    foreach ($file in $dataFiles) {
        $filePath = Join-Path $dataPath $file
        if (!(Test-Path $filePath)) {
            $dataStatus = "INCOMPLETE"
            break
        }
    }
    Write-ASGLog "Data integrity: $dataStatus" "STATUS"
}

function Activate-Systems {
    Write-ASGLog "Initiating NCC ASG Activation Protocol" "ACTIVATE"

    # Check if already running
    $existingProcesses = Get-ProcessStatus
    if ($existingProcesses) {
        Write-ASGLog "NCC Continuous Operations already active - $($existingProcesses.Count) processes running" "WARNING"
        return
    }

    # Initialize data if needed
    Write-ASGLog "Initializing system data" "ACTIVATE"
    & $ContinuousOpsScript -Initialize

    # Launch continuous operations with 30-second intervals
    Write-ASGLog "Launching continuous operations with 30-second cycle intervals" "ACTIVATE"
    $job = Start-Job -ScriptBlock {
        param($scriptPath, $continuousOpsScript)
        Set-Location $scriptPath
        & $continuousOpsScript -Continuous -IntervalMinutes 0.5
    } -ArgumentList $ScriptPath, $ContinuousOpsScript

    Start-Sleep -Seconds 2

    # Verify activation
    $newProcesses = Get-ProcessStatus
    if ($newProcesses) {
        Write-ASGLog "ASG Activation successful - Continuous operations running with 30-second cycles" "SUCCESS"
        Write-ASGLog "Process ID: $($newProcesses.Id)" "SUCCESS"
    } else {
        Write-ASGLog "ASG Activation failed - No processes detected" "ERROR"
    }
}

function Deactivate-Systems {
    Write-ASGLog "Initiating NCC system deactivation" "DEACTIVATE"

    $processes = Get-ProcessStatus
    if ($processes) {
        Write-ASGLog "Terminating $($processes.Count) continuous operation processes" "DEACTIVATE"
        foreach ($proc in $processes) {
            try {
                Stop-Process -Id $proc.Id -Force
                Write-ASGLog "Terminated process ID: $($proc.Id)" "DEACTIVATE"
            } catch {
                Write-ASGLog "Failed to terminate process ID: $($proc.Id) - $($_.Exception.Message)" "ERROR"
            }
        }
        Write-ASGLog "NCC system deactivation completed" "DEACTIVATE"
    } else {
        Write-ASGLog "No active NCC processes found to deactivate" "DEACTIVATE"
    }
}

# Main execution
if ($Activate) {
    Activate-Systems
} elseif ($Status) {
    Show-Status
} elseif ($Deactivate) {
    Deactivate-Systems
} else {
    Write-ASGLog "NCC ASG Activation Protocol" "INFO"
    Write-ASGLog "Usage: ASG.ps1 -Activate | -Status | -Deactivate" "INFO"
    Write-ASGLog "  -Activate  : Launch continuous operations with 30-second cycles" "INFO"
    Write-ASGLog "  -Status    : Check current system status" "INFO"
    Write-ASGLog "  -Deactivate: Stop all continuous operations" "INFO"
}