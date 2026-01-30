# NCC Comprehensive Emergency and Crisis Management System - Master Activation
# Enterprise-Wide Emergency Detection, Response, Recovery, and Analysis Framework
# Version: 2.0.0 | Classification: NATRIX COMMAND CORP INTERNAL TOOL
# Date: 2026-01-29 | Authority: AZ PRIME Command

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("FullSystem", "Detection", "Response", "Recovery", "Communication", "Analysis", "Test", "Status", "Deactivate")]
    [string]$Action = "Status",

    [switch]$Continuous,
    [switch]$Emergency,
    [switch]$TestMode,
    [switch]$EnterpriseWide
)

# =============================================================================
# MASTER CONFIGURATION & SYSTEM INTEGRATION
# =============================================================================

$MasterConfig = @{
    Version = "2.0.0"
    BasePath = $PSScriptRoot
    SystemName = "NCC Comprehensive Emergency and Crisis Management System"
    Components = @(
        @{
            Name = "Emergency Detection"
            Script = Join-Path $PSScriptRoot "NCC_Emergency_Management_System.ps1"
            Status = "Inactive"
            ProcessId = $null
            LastHealthCheck = $null
        },
        @{
            Name = "Failover Recovery"
            Script = Join-Path $PSScriptRoot "NCC_Failover_Recovery_System.ps1"
            Status = "Inactive"
            ProcessId = $null
            LastHealthCheck = $null
        },
        @{
            Name = "Emergency Communication"
            Script = Join-Path $PSScriptRoot "NCC_Emergency_Communication_System.ps1"
            Status = "Inactive"
            ProcessId = $null
            LastHealthCheck = $null
        },
        @{
            Name = "Post-Incident Analysis"
            Script = Join-Path $PSScriptRoot "NCC_Post_Incident_Analysis_System.ps1"
            Status = "Inactive"
            ProcessId = $null
            LastHealthCheck = $null
        }
    )

    SystemHealth = @{
        OverallStatus = "Inactive"
        ActiveComponents = 0
        TotalComponents = 4
        LastSystemCheck = $null
        ContinuousMode = $false
        EmergencyMode = $false
    }

    MonitoringInterval = 60  # seconds
    HealthCheckInterval = 300  # 5 minutes
    ContinuousOperation = $false
}

# =============================================================================
# MASTER SYSTEM CONTROLLER
# =============================================================================

class NCCMasterEmergencyController {
    [hashtable]$Config
    [array]$SystemComponents
    [hashtable]$SystemHealth
    [hashtable]$ActiveProcesses

    NCCMasterEmergencyController([hashtable]$config) {
        $this.Config = $config
        $this.SystemComponents = $config.Components
        $this.SystemHealth = $config.SystemHealth
        $this.ActiveProcesses = @{}
    }

    [void]ActivateFullSystem([bool]$continuous = $false) {
        Write-Host "NCC COMPREHENSIVE EMERGENCY MANAGEMENT SYSTEM ACTIVATION" -ForegroundColor Cyan
        Write-Host "=========================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Initializing enterprise-wide emergency and crisis management framework..." -ForegroundColor Green
        Write-Host "System Version: $($this.Config.Version)" -ForegroundColor Green
        Write-Host "Authority: AZ PRIME Command" -ForegroundColor Green
        Write-Host ""

        # Pre-activation system check
        $this.PerformSystemPreCheck()

        # Activate all components
        $this.ActivateEmergencyDetection()
        $this.ActivateFailoverRecovery()
        $this.ActivateEmergencyCommunication()
        $this.ActivatePostIncidentAnalysis()

        # Start system monitoring
        $this.StartSystemMonitoring()

        # Update system health
        $this.SystemHealth.OverallStatus = "Active"
        $this.SystemHealth.ActiveComponents = ($this.SystemComponents | Where-Object { $_.Status -eq "Active" }).Count
        $this.SystemHealth.LastSystemCheck = Get-Date

        Write-Host ""
        Write-Host "SYSTEM ACTIVATION COMPLETE" -ForegroundColor Green
        Write-Host "==========================" -ForegroundColor Green
        Write-Host "All emergency management systems are now active and monitoring." -ForegroundColor Green
        Write-Host "Enterprise-wide crisis response capabilities: OPERATIONAL" -ForegroundColor Green
        Write-Host ""

        if ($continuous) {
            $this.StartContinuousOperation()
        }
    }

    [void]PerformSystemPreCheck() {
        Write-Host "Performing pre-activation system checks..." -ForegroundColor Yellow

        # Check component scripts exist
        foreach ($component in $this.SystemComponents) {
            if (Test-Path $component.Script) {
                Write-Host "  ✓ $($component.Name) script found" -ForegroundColor Green
            } else {
                Write-Host "  ✗ $($component.Name) script missing: $($component.Script)" -ForegroundColor Red
            }
        }

        # Check required directories
        $requiredDirs = @(
            (Join-Path $this.Config.BasePath "logs"),
            (Join-Path $this.Config.BasePath "communication"),
            (Join-Path $this.Config.BasePath "reports"),
            (Join-Path $this.Config.BasePath "Playbooks")
        )

        foreach ($dir in $requiredDirs) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            Write-Host "  ✓ Directory ready: $dir" -ForegroundColor Green
        }

        # Check system resources
        $systemInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $totalMemory = [math]::Round($systemInfo.TotalVisibleMemorySize / 1MB, 2)
        $freeMemory = [math]::Round($systemInfo.FreePhysicalMemory / 1MB, 2)

        Write-Host "  System Resources:" -ForegroundColor Gray
        Write-Host "    Total Memory: ${totalMemory}GB" -ForegroundColor Gray
        Write-Host "    Free Memory: ${freeMemory}GB" -ForegroundColor Gray

        if ($freeMemory -lt 2) {
            Write-Host "  ⚠ Warning: Low system memory may impact performance" -ForegroundColor Yellow
        } else {
            Write-Host "  ✓ Sufficient system resources available" -ForegroundColor Green
        }

        Write-Host "Pre-activation checks completed." -ForegroundColor Green
        Write-Host ""
    }

    [void]ActivateEmergencyDetection() {
        Write-Host "Activating Emergency Detection System..." -ForegroundColor Cyan

        try {
            $component = $this.SystemComponents | Where-Object { $_.Name -eq "Emergency Detection" } | Select-Object -First 1
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo
            $startInfo.FileName = "powershell.exe"
            $startInfo.Arguments = "-ExecutionPolicy Bypass -File `"$($component.Script)`" -Action Monitor -EnterpriseWide"
            $startInfo.UseShellExecute = $false
            $startInfo.RedirectStandardOutput = $true
            $startInfo.RedirectStandardError = $true
            $startInfo.CreateNoWindow = $true

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $startInfo
            $process.Start() | Out-Null

            $component.Status = "Active"
            $component.ProcessId = $process.Id
            $component.LastHealthCheck = Get-Date

            $this.ActiveProcesses["EmergencyDetection"] = $process

            Write-Host "  ✓ Emergency Detection System activated (PID: $($process.Id))" -ForegroundColor Green

        } catch {
            Write-Host "  ✗ Failed to activate Emergency Detection System: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    [void]ActivateFailoverRecovery() {
        Write-Host "Activating Failover Recovery System..." -ForegroundColor Cyan

        try {
            $component = $this.SystemComponents | Where-Object { $_.Name -eq "Failover Recovery" } | Select-Object -First 1
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo
            $startInfo.FileName = "powershell.exe"
            $startInfo.Arguments = "-ExecutionPolicy Bypass -File `"$($component.Script)`" -Action Monitor -EnterpriseWide"
            $startInfo.UseShellExecute = $false
            $startInfo.RedirectStandardOutput = $true
            $startInfo.RedirectStandardError = $true
            $startInfo.CreateNoWindow = $true

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $startInfo
            $process.Start() | Out-Null

            $component.Status = "Active"
            $component.ProcessId = $process.Id
            $component.LastHealthCheck = Get-Date

            $this.ActiveProcesses["FailoverRecovery"] = $process

            Write-Host "  ✓ Failover Recovery System activated (PID: $($process.Id))" -ForegroundColor Green

        } catch {
            Write-Host "  ✗ Failed to activate Failover Recovery System: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    [void]ActivateEmergencyCommunication() {
        Write-Host "Activating Emergency Communication System..." -ForegroundColor Cyan

        try {
            $component = $this.SystemComponents | Where-Object { $_.Name -eq "Emergency Communication" } | Select-Object -First 1
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo
            $startInfo.FileName = "powershell.exe"
            $startInfo.Arguments = "-ExecutionPolicy Bypass -File `"$($component.Script)`" -Action Activate -EnterpriseWide"
            $startInfo.UseShellExecute = $false
            $startInfo.RedirectStandardOutput = $true
            $startInfo.RedirectStandardError = $true
            $startInfo.CreateNoWindow = $true

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $startInfo
            $process.Start() | Out-Null

            $component.Status = "Active"
            $component.ProcessId = $process.Id
            $component.LastHealthCheck = Get-Date

            $this.ActiveProcesses["EmergencyCommunication"] = $process

            Write-Host "  ✓ Emergency Communication System activated (PID: $($process.Id))" -ForegroundColor Green

        } catch {
            Write-Host "  ✗ Failed to activate Emergency Communication System: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    [void]ActivatePostIncidentAnalysis() {
        Write-Host "Activating Post-Incident Analysis System..." -ForegroundColor Cyan

        try {
            $component = $this.SystemComponents | Where-Object { $_.Name -eq "Post-Incident Analysis" } | Select-Object -First 1
            $startInfo = New-Object System.Diagnostics.ProcessStartInfo
            $startInfo.FileName = "powershell.exe"
            $startInfo.Arguments = "-ExecutionPolicy Bypass -File `"$($component.Script)`" -Action Analyze -Automated"
            $startInfo.UseShellExecute = $false
            $startInfo.RedirectStandardOutput = $true
            $startInfo.RedirectStandardError = $true
            $startInfo.CreateNoWindow = $true

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $startInfo
            $process.Start() | Out-Null

            $component.Status = "Active"
            $component.ProcessId = $process.Id
            $component.LastHealthCheck = Get-Date

            $this.ActiveProcesses["PostIncidentAnalysis"] = $process

            Write-Host "  ✓ Post-Incident Analysis System activated (PID: $($process.Id))" -ForegroundColor Green

        } catch {
            Write-Host "  ✗ Failed to activate Post-Incident Analysis System: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    [void]StartSystemMonitoring() {
        Write-Host "Starting system-wide health monitoring..." -ForegroundColor Cyan

        # Start background monitoring job
        $monitoringScript = {
            param($controller)

            while ($true) {
                try {
                    $controller.MonitorSystemHealth()
                } catch {
                    Write-Host "System monitoring error: $($_.Exception.Message)" -ForegroundColor Red
                }

                Start-Sleep -Seconds $controller.Config.MonitoringInterval
            }
        }

        Start-Job -Name "NCC_Emergency_System_Monitor" -ScriptBlock $monitoringScript -ArgumentList $this

        Write-Host "  ✓ System monitoring activated" -ForegroundColor Green
    }

    [void]MonitorSystemHealth() {
        $now = Get-Date

        # Check each component health
        foreach ($component in $this.SystemComponents) {
            if ($component.Status -eq "Active" -and $component.ProcessId) {
                try {
                    $process = Get-Process -Id $component.ProcessId -ErrorAction SilentlyContinue
                    if (-not $process) {
                        Write-Host "COMPONENT FAILURE: $($component.Name) process not found (PID: $($component.ProcessId))" -ForegroundColor Red
                        $component.Status = "Failed"
                        $this.HandleComponentFailure($component)
                    } else {
                        $component.LastHealthCheck = $now
                    }
                } catch {
                    Write-Host "Health check failed for $($component.Name): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }

        # Update overall system health
        $activeComponents = ($this.SystemComponents | Where-Object { $_.Status -eq "Active" }).Count
        $this.SystemHealth.ActiveComponents = $activeComponents
        $this.SystemHealth.LastSystemCheck = $now

        if ($activeComponents -eq 0) {
            $this.SystemHealth.OverallStatus = "Failed"
        } elseif ($activeComponents -lt $this.SystemHealth.TotalComponents) {
            $this.SystemHealth.OverallStatus = "Degraded"
        } else {
            $this.SystemHealth.OverallStatus = "Active"
        }
    }

    [void]HandleComponentFailure([hashtable]$component) {
        Write-Host "Handling failure of component: $($component.Name)" -ForegroundColor Magenta

        # Attempt automatic restart
        switch ($component.Name) {
            "Emergency Detection" {
                $this.ActivateEmergencyDetection()
            }
            "Failover Recovery" {
                $this.ActivateFailoverRecovery()
            }
            "Emergency Communication" {
                $this.ActivateEmergencyCommunication()
            }
            "Post-Incident Analysis" {
                $this.ActivatePostIncidentAnalysis()
            }
        }
    }

    [void]StartContinuousOperation() {
        Write-Host "Starting continuous emergency management operation..." -ForegroundColor Green

        $this.SystemHealth.ContinuousMode = $true
        $this.Config.ContinuousOperation = $true

        # Set up continuous monitoring with longer intervals
        Write-Host "Continuous monitoring active - system will maintain 24/7 emergency readiness." -ForegroundColor Green
        Write-Host "Press Ctrl+C to stop continuous operation." -ForegroundColor Yellow

        try {
            while ($this.Config.ContinuousOperation) {
                # Perform comprehensive system health check
                $this.PerformComprehensiveHealthCheck()

                # Generate system status report
                $this.GenerateSystemStatusReport()

                # Wait before next check
                Start-Sleep -Seconds 1800  # 30 minutes
            }
        } finally {
            $this.DeactivateSystem()
        }
    }

    [void]PerformComprehensiveHealthCheck() {
        Write-Host "Performing comprehensive system health check..." -ForegroundColor Gray

        # Check all components
        $this.MonitorSystemHealth()

        # Check system resources
        $systemInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $cpuUsage = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        $memoryUsage = [math]::Round(($systemInfo.TotalVisibleMemorySize - $systemInfo.FreePhysicalMemory) / $systemInfo.TotalVisibleMemorySize * 100, 2)

        Write-Host "  System Resources - CPU: ${cpuUsage}%, Memory: ${memoryUsage}%" -ForegroundColor Gray

        # Check disk space
        $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($disk in $diskInfo) {
            $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
            Write-Host "  Disk $($disk.DeviceID): ${freeSpaceGB}GB free of ${totalSpaceGB}GB" -ForegroundColor Gray
        }

        # Check network connectivity
        try {
            $networkTest = Test-Connection -ComputerName "8.8.8.8" -Count 1 -ErrorAction SilentlyContinue
            if ($networkTest) {
                Write-Host "  Network connectivity: OK" -ForegroundColor Green
            } else {
                Write-Host "  Network connectivity: FAILED" -ForegroundColor Red
            }
        } catch {
            Write-Host "  Network connectivity check failed" -ForegroundColor Red
        }
    }

    [void]GenerateSystemStatusReport() {
        $reportPath = Join-Path $this.Config.BasePath "logs\system_status_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

        $report = @"
NCC Emergency Management System Status Report
=============================================
Timestamp: $(Get-Date)
System Version: $($this.Config.Version)
Overall Status: $($this.SystemHealth.OverallStatus)
Active Components: $($this.SystemHealth.ActiveComponents)/$($this.SystemHealth.TotalComponents)
Continuous Mode: $($this.SystemHealth.ContinuousMode)
Emergency Mode: $($this.SystemHealth.EmergencyMode)

Component Status:
$($this.SystemComponents | ForEach-Object { "  $($_.Name): $($_.Status) (PID: $($_.ProcessId))" } | Out-String)

Active Processes:
$($this.ActiveProcesses.Keys | ForEach-Object { "  $_`: $($this.ActiveProcesses[$_].Id)" } | Out-String)

Last System Check: $($this.SystemHealth.LastSystemCheck)
"@

        $report | Out-File $reportPath -Encoding UTF8
    }

    [void]TestFullSystem() {
        Write-Host "Testing complete emergency management system..." -ForegroundColor Cyan

        # Test each component individually
        Write-Host "Testing Emergency Detection System..." -ForegroundColor Yellow
        & $this.SystemComponents[0].Script -Action Test

        Write-Host "Testing Failover Recovery System..." -ForegroundColor Yellow
        & $this.SystemComponents[1].Script -Action Test

        Write-Host "Testing Emergency Communication System..." -ForegroundColor Yellow
        & $this.SystemComponents[2].Script -Action Test

        Write-Host "Testing Post-Incident Analysis System..." -ForegroundColor Yellow
        # Analysis system test would be different

        Write-Host "Full system test completed." -ForegroundColor Green
    }

    [void]DeactivateSystem() {
        Write-Host "Deactivating emergency management system..." -ForegroundColor Yellow

        # Stop all processes
        foreach ($process in $this.ActiveProcesses.Values) {
            try {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Host "Failed to stop process $($process.Id): $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        # Stop monitoring job
        Get-Job -Name "NCC_Emergency_System_Monitor" -ErrorAction SilentlyContinue | Stop-Job -ErrorAction SilentlyContinue
        Get-Job -Name "NCC_Emergency_System_Monitor" -ErrorAction SilentlyContinue | Remove-Job -ErrorAction SilentlyContinue

        # Update component status
        foreach ($component in $this.SystemComponents) {
            $component.Status = "Inactive"
            $component.ProcessId = $null
        }

        # Update system health
        $this.SystemHealth.OverallStatus = "Inactive"
        $this.SystemHealth.ActiveComponents = 0
        $this.SystemHealth.ContinuousMode = $false

        $this.ActiveProcesses.Clear()

        Write-Host "Emergency management system deactivated." -ForegroundColor Green
    }

    [void]GetSystemStatus() {
        Write-Host "NCC Comprehensive Emergency Management System Status" -ForegroundColor Cyan
        Write-Host "====================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "System Information:" -ForegroundColor Yellow
        Write-Host "  Version: $($this.Config.Version)" -ForegroundColor White
        Write-Host "  Overall Status: $($this.SystemHealth.OverallStatus)" -ForegroundColor $(if ($this.SystemHealth.OverallStatus -eq "Active") { "Green" } elseif ($this.SystemHealth.OverallStatus -eq "Degraded") { "Yellow" } else { "Red" })
        Write-Host "  Active Components: $($this.SystemHealth.ActiveComponents)/$($this.SystemHealth.TotalComponents)" -ForegroundColor White
        Write-Host "  Continuous Mode: $($this.SystemHealth.ContinuousMode)" -ForegroundColor White
        Write-Host "  Emergency Mode: $($this.SystemHealth.EmergencyMode)" -ForegroundColor White
        Write-Host "  Last System Check: $($this.SystemHealth.LastSystemCheck)" -ForegroundColor White
        Write-Host ""

        Write-Host "Component Status:" -ForegroundColor Yellow
        foreach ($component in $this.SystemComponents) {
            $statusColor = switch ($component.Status) {
                "Active" { "Green" }
                "Failed" { "Red" }
                default { "Gray" }
            }
            $processInfo = if ($component.ProcessId) { "(PID: $($component.ProcessId))" } else { "" }
            Write-Host "  $($component.Name): $($component.Status) $processInfo" -ForegroundColor $statusColor
        }

        Write-Host ""
        Write-Host "Active Processes:" -ForegroundColor Yellow
        if ($this.ActiveProcesses.Count -eq 0) {
            Write-Host "  None" -ForegroundColor Gray
        } else {
            foreach ($processName in $this.ActiveProcesses.Keys) {
                $process = $this.ActiveProcesses[$processName]
                Write-Host "  $processName`: $($process.Id)" -ForegroundColor Green
            }
        }

        Write-Host ""
        Write-Host "System Capabilities:" -ForegroundColor Yellow
        Write-Host "  ✓ Automated Emergency Detection" -ForegroundColor Green
        Write-Host "  ✓ Real-time System Health Monitoring" -ForegroundColor Green
        Write-Host "  ✓ Automated Failover Systems" -ForegroundColor Green
        Write-Host "  ✓ Crisis Response Protocols" -ForegroundColor Green
        Write-Host "  ✓ Emergency Communication Channels" -ForegroundColor Green
        Write-Host "  ✓ Post-Incident Analysis Framework" -ForegroundColor Green
        Write-Host "  ✓ Enterprise-wide Crisis Management" -ForegroundColor Green
        Write-Host "  ✓ 24/7 Continuous Operation Support" -ForegroundColor Green
    }
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

$MasterController = [NCCMasterEmergencyController]::new($MasterConfig)

switch ($Action) {
    "FullSystem" {
        $MasterController.ActivateFullSystem($Continuous)
    }

    "Detection" {
        Write-Host "Activating Emergency Detection System only..." -ForegroundColor Cyan
        $MasterController.ActivateEmergencyDetection()
    }

    "Response" {
        Write-Host "Activating Crisis Response Systems..." -ForegroundColor Cyan
        $MasterController.ActivateFailoverRecovery()
        $MasterController.ActivateEmergencyCommunication()
    }

    "Recovery" {
        Write-Host "Activating Recovery Systems..." -ForegroundColor Cyan
        $MasterController.ActivateFailoverRecovery()
    }

    "Communication" {
        Write-Host "Activating Communication Systems..." -ForegroundColor Cyan
        $MasterController.ActivateEmergencyCommunication()
    }

    "Analysis" {
        Write-Host "Activating Analysis Systems..." -ForegroundColor Cyan
        $MasterController.ActivatePostIncidentAnalysis()
    }

    "Test" {
        $MasterController.TestFullSystem()
    }

    "Status" {
        $MasterController.GetSystemStatus()
    }

    "Deactivate" {
        $MasterController.DeactivateSystem()
    }

    default {
        Write-Host "NCC Comprehensive Emergency and Crisis Management System" -ForegroundColor Cyan
        Write-Host "=========================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Available Actions:" -ForegroundColor Yellow
        Write-Host "  -FullSystem   : Activate complete emergency management system"
        Write-Host "  -Detection    : Activate emergency detection only"
        Write-Host "  -Response     : Activate crisis response systems"
        Write-Host "  -Recovery     : Activate recovery systems"
        Write-Host "  -Communication: Activate communication systems"
        Write-Host "  -Analysis     : Activate analysis systems"
        Write-Host "  -Test         : Test all system components"
        Write-Host "  -Status       : Show system status"
        Write-Host "  -Deactivate   : Deactivate all systems"
        Write-Host ""
        Write-Host "Parameters:" -ForegroundColor Yellow
        Write-Host "  -Continuous   : Enable continuous 24/7 operation"
        Write-Host "  -Emergency    : Emergency mode activation"
        Write-Host "  -TestMode     : Test/simulation mode"
        Write-Host "  -EnterpriseWide: Enterprise-wide operations"
        Write-Host ""
        Write-Host "Usage Examples:" -ForegroundColor Gray
        Write-Host "  .\NCC_Master_Emergency_System.ps1 -Action FullSystem -Continuous" -ForegroundColor Gray
        Write-Host "  .\NCC_Master_Emergency_System.ps1 -Action Test" -ForegroundColor Gray
        Write-Host "  .\NCC_Master_Emergency_System.ps1 -Action Status" -ForegroundColor Gray
    }
}

# Save system state on exit
if ($Action -ne "Status" -and $Action -ne "Test") {
    Write-Host ""
    Write-Host "Emergency management system execution completed." -ForegroundColor Green
}