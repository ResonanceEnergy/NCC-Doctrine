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
# NCC Desktop Display Integration System v1.0.0
# Author: NCC Command Center
# Purpose: Unified console, dashboard, and desktop display system

param(
    [switch]$StartServer,
    [switch]$OpenDashboard,
    [switch]$AuditSystem,
    [switch]$FullSystem
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Get script directory and root path
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath = Split-Path -Parent $ScriptDir

# Import required functions
. "$ScriptDir\NCC.Utilities.ps1"

# Configuration
$Config = @{
    ServerPort = 3000
    DashboardUrl = "http://localhost:3000"
    DigitalDisplayPath = Join-Path $RootPath "Dashboard\NCC_Digital_Display.html"
    DashboardPath = Join-Path $RootPath "Dashboard\NCC_Dashboard.html"
    ConsolePath = Join-Path $RootPath "public\index.html"
    ServerPath = Join-Path $RootPath "server.js"
}

function Test-ServerRunning {
    param([int]$Port = 3000)

    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port" -TimeoutSec 5 -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Start-NCCServer {
    Write-Log "Starting NCC Dashboard Server..." -Level "INFO"

    if (Test-ServerRunning -Port $Config.ServerPort) {
        Write-Log "OK Server is already running on port $($Config.ServerPort)" -Level "SUCCESS"
        return $true
    }

    # Check if server.js exists
    if (-not (Test-FileExists -Path $Config.ServerPath)) {
        Write-Log "ERROR Server file not found: $($Config.ServerPath)" -Level "ERROR"
        return $false
    }

    # Check if node_modules exists
    if (-not (Test-DirectoryExists -Path (Join-Path $RootPath "node_modules"))) {
        Write-Log "Installing Node.js dependencies..." -Level "INFO"
        Push-Location $RootPath
        try {
            npm install
        }
        finally {
            Pop-Location
        }
    }

    # Start server in background
    Write-Log "Web Starting server on port $($Config.ServerPort)..." -Level "INFO"
    $serverProcess = Start-Process -FilePath "node" -ArgumentList $Config.ServerPath -WorkingDirectory $RootPath -NoNewWindow -PassThru

    # Wait for server to start
    $maxWait = 30
    $waitCount = 0
    while (-not (Test-ServerRunning -Port $Config.ServerPort) -and $waitCount -lt $maxWait) {
        Start-Sleep -Seconds 1
        $waitCount++
    }

    if (Test-ServerRunning -Port $Config.ServerPort) {
        Write-Log "OK Server started successfully on port $($Config.ServerPort)" -Level "SUCCESS"
        return $true
    } else {
        Write-Log "ERROR Server failed to start within $($maxWait) seconds" -Level "ERROR"
        return $false
    }
}

function Invoke-SystemAudit {
    Write-Log "Auditing NCC Desktop Display System..." -Level "INFO"

    $auditResults = @{
        ServerStatus = $false
        DashboardExists = $false
        DigitalDisplayExists = $false
        ConsoleExists = $false
        DependenciesInstalled = $false
        Issues = @()
    }

    # Check server status
    $auditResults.ServerStatus = Test-ServerRunning -Port $Config.ServerPort

    # Check file existence
    $auditResults.DashboardExists = Test-FileExists -Path $Config.DashboardPath
    $auditResults.DigitalDisplayExists = Test-FileExists -Path $Config.DigitalDisplayPath
    $auditResults.ConsoleExists = Test-FileExists -Path $Config.ConsolePath

    # Check dependencies
    $packageJson = Join-Path $RootPath "package.json"
    $nodeModules = Join-Path $RootPath "node_modules"
    $auditResults.DependenciesInstalled = (Test-FileExists -Path $packageJson) -and (Test-DirectoryExists -Path $nodeModules)

    # Identify issues
    if (-not $auditResults.ServerStatus) {
        $auditResults.Issues += "Server not running on port $($Config.ServerPort)"
    }
    if (-not $auditResults.DashboardExists) {
        $auditResults.Issues += "Dashboard file missing: $($Config.DashboardPath)"
    }
    if (-not $auditResults.DigitalDisplayExists) {
        $auditResults.Issues += "Digital display file missing: $($Config.DigitalDisplayPath)"
    }
    if (-not $auditResults.ConsoleExists) {
        $auditResults.Issues += "Console file missing: $($Config.ConsolePath)"
    }
    if (-not $auditResults.DependenciesInstalled) {
        $auditResults.Issues += "Node.js dependencies not installed"
    }

    # Report results
    Write-Log "Status Audit Results:" -Level "INFO"
    Write-Log "  • Server Running: $($auditResults.ServerStatus)" -Level "INFO"
    Write-Log "  • Dashboard File: $($auditResults.DashboardExists)" -Level "INFO"
    Write-Log "  • Digital Display: $($auditResults.DigitalDisplayExists)" -Level "INFO"
    Write-Log "  • Console File: $($auditResults.ConsoleExists)" -Level "INFO"
    Write-Log "  • Dependencies: $($auditResults.DependenciesInstalled)" -Level "INFO"

    if ($auditResults.Issues.Count -gt 0) {
        Write-Log "WARNING Issues Found: $($auditResults.Issues.Count)" -Level "WARNING"
        foreach ($issue in $auditResults.Issues) {
            Write-Log "  • $issue" -Level "WARNING"
        }
    } else {
        Write-Log "OK No issues found - system is healthy!" -Level "SUCCESS"
    }

    return $auditResults
}

# Main execution logic
if ($FullSystem -or $AuditSystem) {
    Invoke-SystemAudit
}

if ($FullSystem -or $StartServer) {
    Start-NCCServer
}

if ($OpenDashboard) {
    if (-not (Test-ServerRunning -Port $Config.ServerPort)) {
        Write-Log "WARNING Server not running, starting server first..." -Level "WARNING"
        if (-not (Start-NCCServer)) {
            Write-Log "ERROR Cannot open dashboard - server failed to start" -Level "ERROR"
            exit 1
        }
    }

    try {
        Start-Process $Config.DashboardUrl
        Write-Log "OK Dashboard opened in default browser" -Level "SUCCESS"
    }
    catch {
        Write-Log "ERROR Failed to open dashboard: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Show usage if no parameters
if (-not ($StartServer -or $OpenDashboard -or $AuditSystem -or $FullSystem)) {
    Write-Log "NCC Desktop Display Integration System" -Level "INFO"
    Write-Log "Usage:" -Level "INFO"
    Write-Log "  .\NCC.DesktopDisplay.ps1 -FullSystem        # Audit, fix, and start everything" -Level "INFO"
    Write-Log "  .\NCC.DesktopDisplay.ps1 -StartServer       # Start the dashboard server" -Level "INFO"
    Write-Log "  .\NCC.DesktopDisplay.ps1 -OpenDashboard     # Open dashboard in browser" -Level "INFO"
    Write-Log "  .\NCC.DesktopDisplay.ps1 -AuditSystem        # Audit system for issues" -Level "INFO"
<<<<<<< HEAD
}
=======
}
>>>>>>> c6b295e0d92d0143018dcdcb5ba8fd1affca0fae
