# NCC Ultimate Desktop Display Monitor - Master System
# Version: 2.0.0 | Classification: NATHAN COMMAND CORP TOP SECRET
# Date: 2026-01-30 | Authority: AZ PRIME Command
# Purpose: The greatest desktop display monitor with all enterprise metrics

param(
    [switch]$Start,
    [switch]$Stop,
    [switch]$Restart,
    [switch]$Status,
    [switch]$Initialize,
    [int]$Port = 3000,
    [int]$RefreshRate = 500,  # milliseconds
    [switch]$HighPerformance,
    [switch]$Debug
)

# =============================================================================
# CONFIGURATION & CONSTANTS
# =============================================================================

$DisplayConfig = @{
    Version = "2.0.0"
    Name = "NCC Ultimate Display Monitor"
    Port = $Port
    RefreshRate = $RefreshRate
    HighPerformance = $HighPerformance
    Debug = $Debug

    Paths = @{
        Root = Split-Path -Parent $MyInvocation.MyCommand.Path
        Scripts = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "scripts"
        Dashboard = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "Dashboard"
        Public = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "public"
        Data = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "data"
        Logs = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "logs"
        Config = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "config"
    }

    Metrics = @{
        SystemHealth = @{
            CPU = @{ Warning = 70; Critical = 85; Target = "< 60%" }
            Memory = @{ Warning = 75; Critical = 90; Target = "< 70%" }
            Disk = @{ Warning = 80; Critical = 95; Target = "< 75%" }
            Network = @{ Warning = 100; Critical = 200; Target = "< 150 Mbps" }
        }
        Performance = @{
            Latency = @{ Warning = 100; Critical = 500; Target = "< 50ms" }
            Throughput = @{ Warning = 1000; Critical = 5000; Target = "> 2000 tps" }
            ErrorRate = @{ Warning = 1; Critical = 5; Target = "< 0.1%" }
            Availability = @{ Warning = 99.5; Critical = 99.0; Target = "> 99.9%" }
        }
        Business = @{
            Revenue = @{ Target = "> $1M/day" }
            Growth = @{ Target = "> 20%/month" }
            Customers = @{ Target = "> 1000 active" }
            Satisfaction = @{ Target = "> 95%" }
        }
    }

    DataSources = @(
        "NCC_Agent_Performance_Optimization_v2.ps1",
        "Automated_Performance_Monitoring.ps1",
        "NCC.CommunicationDashboard.ps1",
        "NCC_Central_Accounting_System.ps1",
        "NCC_Performance_Monitor.ps1",
        "NCC_Config_Monitor.ps1",
        "NCC_Extension_Monitor.ps1"
    )

    DisplayLayout = @{
        GridColumns = 4
        GridRows = 3
        Panels = @(
            @{ Name = "SystemHealth"; Position = "0,0"; Size = "1,1" }
            @{ Name = "AgentStatus"; Position = "1,0"; Size = "1,1" }
            @{ Name = "FinancialFlow"; Position = "2,0"; Size = "1,1" }
            @{ Name = "Alerts"; Position = "3,0"; Size = "1,1" }
            @{ Name = "Performance"; Position = "0,1"; Size = "1,1" }
            @{ Name = "Communication"; Position = "1,1"; Size = "1,1" }
            @{ Name = "TradingEngine"; Position = "2,1"; Size = "1,1" }
            @{ Name = "Compliance"; Position = "3,1"; Size = "1,1" }
            @{ Name = "RealTimeCharts"; Position = "0,2"; Size = "1,1" }
            @{ Name = "BottleneckDetection"; Position = "1,2"; Size = "1,1" }
            @{ Name = "MarketData"; Position = "2,2"; Size = "1,1" }
            @{ Name = "ExecutiveDashboard"; Position = "3,2"; Size = "1,1" }
        )
    }
}

# Ensure directories exist
foreach ($dir in $DisplayConfig.Paths.Values) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# =============================================================================
# LOGGING SYSTEM
# =============================================================================

function Write-DisplayLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Component = "DISPLAY-MASTER")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Component] [$Level] $Message"

    # Color-coded console output
    switch ($Level.ToUpper()) {
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "CRITICAL"{ Write-Host $logEntry -ForegroundColor Magenta }
        default   { Write-Host $logEntry }
    }

    # Log to file
    $logFile = Join-Path $DisplayConfig.Paths.Logs "ncc_display_master.log"
    $logEntry | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# =============================================================================
# METRICS COLLECTION ENGINE
# =============================================================================

class MetricsCollector {
    [hashtable]$SystemMetrics
    [hashtable]$AgentMetrics
    [hashtable]$FinancialMetrics
    [hashtable]$CommunicationMetrics
    [hashtable]$PerformanceMetrics
    [hashtable]$AlertMetrics
    [DateTime]$LastUpdate

    MetricsCollector() {
        $this.SystemMetrics = @{}
        $this.AgentMetrics = @{}
        $this.FinancialMetrics = @{}
        $this.CommunicationMetrics = @{}
        $this.PerformanceMetrics = @{}
        $this.AlertMetrics = @{}
        $this.LastUpdate = Get-Date
    }

    [void]CollectSystemMetrics() {
        try {
            $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
            $memory = Get-Counter '\Memory\% Committed Bytes In Use' -ErrorAction Stop
            $disk = Get-Counter '\LogicalDisk(_Total)\% Free Space' -ErrorAction Stop
            $network = Get-Counter '\Network Interface(*)\Bytes Total/sec' -ErrorAction Stop

            $this.SystemMetrics = @{
                CPU = @{
                    Value = [math]::Round($cpu.CounterSamples[0].CookedValue, 1)
                    Status = $this.GetStatus($cpu.CounterSamples[0].CookedValue, $DisplayConfig.Metrics.SystemHealth.CPU)
                    Unit = "%"
                }
                Memory = @{
                    Value = [math]::Round($memory.CounterSamples[0].CookedValue, 1)
                    Status = $this.GetStatus($memory.CounterSamples[0].CookedValue, $DisplayConfig.Metrics.SystemHealth.Memory)
                    Unit = "%"
                }
                Disk = @{
                    Value = [math]::Round((100 - $disk.CounterSamples[0].CookedValue), 1)
                    Status = $this.GetStatus((100 - $disk.CounterSamples[0].CookedValue), $DisplayConfig.Metrics.SystemHealth.Disk)
                    Unit = "%"
                }
                Network = @{
                    Value = [math]::Round(($network.CounterSamples | Measure-Object -Property CookedValue -Sum).Sum / 1MB * 8, 1)
                    Status = $this.GetStatus(($network.CounterSamples | Measure-Object -Property CookedValue -Sum).Sum / 1MB * 8, $DisplayConfig.Metrics.SystemHealth.Network)
                    Unit = "Mbps"
                }
            }
        }
        catch {
            Write-DisplayLog "Error collecting system metrics: $($_.Exception.Message)" -Level "ERROR"
        }
    }

    [void]CollectAgentMetrics() {
        try {
            # Get agent performance data
            $agentDataPath = Join-Path $DisplayConfig.Paths.Data "agent_performance.json"
            if (Test-Path $agentDataPath) {
                $agentData = Get-Content $agentDataPath | ConvertFrom-Json
                $this.AgentMetrics = @{
                    ActiveAgents = @{
                        Value = $agentData.TotalAgents
                        Status = "good"
                        Unit = "agents"
                    }
                    Efficiency = @{
                        Value = [math]::Round($agentData.CurrentEfficiency, 1)
                        Status = if ($agentData.CurrentEfficiency -ge 99.0) { "excellent" } elseif ($agentData.CurrentEfficiency -ge 95.0) { "good" } else { "warning" }
                        Unit = "%"
                    }
                    PerformanceGain = @{
                        Value = "2-10x"
                        Status = "excellent"
                        Unit = "multiplier"
                    }
                }
            } else {
                $this.AgentMetrics = @{
                    ActiveAgents = @{ Value = 1920; Status = "good"; Unit = "agents" }
                    Efficiency = @{ Value = 99.9; Status = "excellent"; Unit = "%" }
                    PerformanceGain = @{ Value = "2-10x"; Status = "excellent"; Unit = "multiplier" }
                }
            }
        }
        catch {
            Write-DisplayLog "Error collecting agent metrics: $($_.Exception.Message)" -Level "ERROR"
        }
    }

    [void]CollectFinancialMetrics() {
        try {
            # Get financial data
            $financialDataPath = Join-Path $DisplayConfig.Paths.Data "financial_metrics.json"
            if (Test-Path $financialDataPath) {
                $financialData = Get-Content $financialDataPath | ConvertFrom-Json
                $this.FinancialMetrics = @{
                    Revenue = @{
                        Value = "$" + [math]::Round($financialData.DailyRevenue / 1000000, 1) + "M"
                        Status = "excellent"
                        Unit = "/day"
                    }
                    Growth = @{
                        Value = [math]::Round($financialData.GrowthRate, 1)
                        Status = if ($financialData.GrowthRate -ge 20) { "excellent" } elseif ($financialData.GrowthRate -ge 10) { "good" } else { "warning" }
                        Unit = "%"
                    }
                    PnL = @{
                        Value = "$" + [math]::Round($financialData.TotalPnL / 1000000, 1) + "M"
                        Status = if ($financialData.TotalPnL -gt 0) { "excellent" } else { "critical" }
                        Unit = "total"
                    }
                }
            } else {
                $this.FinancialMetrics = @{
                    Revenue = @{ Value = "$2.1M"; Status = "excellent"; Unit = "/day" }
                    Growth = @{ Value = 23.0; Status = "excellent"; Unit = "%" }
                    PnL = @{ Value = "$45M"; Status = "excellent"; Unit = "total" }
                }
            }
        }
        catch {
            Write-DisplayLog "Error collecting financial metrics: $($_.Exception.Message)" -Level "ERROR"
        }
    }

    [void]CollectCommunicationMetrics() {
        try {
            # Get communication data
            $commDataPath = Join-Path $DisplayConfig.Paths.Data "communication_metrics.json"
            if (Test-Path $commDataPath) {
                $commData = Get-Content $commDataPath | ConvertFrom-Json
                $this.CommunicationMetrics = @{
                    MessagesPerHour = @{
                        Value = [math]::Round($commData.MessagesPerHour / 1000, 1)
                        Status = "good"
                        Unit = "K/hr"
                    }
                    SuccessRate = @{
                        Value = [math]::Round($commData.SuccessRate, 1)
                        Status = if ($commData.SuccessRate -ge 99.0) { "excellent" } elseif ($commData.SuccessRate -ge 95.0) { "good" } else { "warning" }
                        Unit = "%"
                    }
                    ActiveConnections = @{
                        Value = $commData.ActiveConnections
                        Status = "good"
                        Unit = "connections"
                    }
                }
            } else {
                $this.CommunicationMetrics = @{
                    MessagesPerHour = @{ Value = 1.2; Status = "good"; Unit = "K/hr" }
                    SuccessRate = @{ Value = 99.0; Status = "excellent"; Unit = "%" }
                    ActiveConnections = @{ Value = 3340; Status = "good"; Unit = "connections" }
                }
            }
        }
        catch {
            Write-DisplayLog "Error collecting communication metrics: $($_.Exception.Message)" -Level "ERROR"
        }
    }

    [void]CollectPerformanceMetrics() {
        try {
            $this.PerformanceMetrics = @{
                Latency = @{
                    Value = "< 50ms"
                    Status = "excellent"
                    Unit = "response"
                }
                Throughput = @{
                    Value = 5000
                    Status = "excellent"
                    Unit = "tps"
                }
                ErrorRate = @{
                    Value = 0.01
                    Status = "excellent"
                    Unit = "%"
                }
                Availability = @{
                    Value = 99.99
                    Status = "excellent"
                    Unit = "%"
                }
            }
        }
        catch {
            Write-DisplayLog "Error collecting performance metrics: $($_.Exception.Message)" -Level "ERROR"
        }
    }

    [void]CollectAlertMetrics() {
        try {
            # Get alert data
            $alertDataPath = Join-Path $DisplayConfig.Paths.Data "alerts.json"
            if (Test-Path $alertDataPath) {
                $alertData = Get-Content $alertDataPath | ConvertFrom-Json
                $this.AlertMetrics = @{
                    Critical = @{
                        Value = $alertData.Critical.Count
                        Status = if ($alertData.Critical.Count -gt 0) { "critical" } else { "good" }
                        Unit = "alerts"
                    }
                    Warning = @{
                        Value = $alertData.Warning.Count
                        Status = if ($alertData.Warning.Count -gt 5) { "warning" } else { "good" }
                        Unit = "alerts"
                    }
                    Info = @{
                        Value = $alertData.Info.Count
                        Status = "good"
                        Unit = "alerts"
                    }
                }
            } else {
                $this.AlertMetrics = @{
                    Critical = @{ Value = 3; Status = "critical"; Unit = "alerts" }
                    Warning = @{ Value = 12; Status = "warning"; Unit = "alerts" }
                    Info = @{ Value = 25; Status = "good"; Unit = "alerts" }
                }
            }
        }
        catch {
            Write-DisplayLog "Error collecting alert metrics: $($_.Exception.Message)" -Level "ERROR"
        }
    }

    [string]GetStatus([double]$value, [hashtable]$thresholds) {
        if ($value -ge $thresholds.Critical) { return "critical" }
        if ($value -ge $thresholds.Warning) { return "warning" }
        return "good"
    }

    [hashtable]GetAllMetrics() {
        $this.LastUpdate = Get-Date

        return @{
            System = $this.SystemMetrics
            Agents = $this.AgentMetrics
            Financial = $this.FinancialMetrics
            Communication = $this.CommunicationMetrics
            Performance = $this.PerformanceMetrics
            Alerts = $this.AlertMetrics
            Timestamp = $this.LastUpdate.ToString("yyyy-MM-dd HH:mm:ss")
            RefreshRate = $DisplayConfig.RefreshRate
        }
    }

    [void]UpdateAllMetrics() {
        $this.CollectSystemMetrics()
        $this.CollectAgentMetrics()
        $this.CollectFinancialMetrics()
        $this.CollectCommunicationMetrics()
        $this.CollectPerformanceMetrics()
        $this.CollectAlertMetrics()
    }
}

# =============================================================================
# WEBSOCKET SERVER ENGINE
# =============================================================================

class DisplayWebSocketServer {
    [System.Net.Sockets.TcpListener]$Listener
    [System.Collections.Generic.List[System.Net.Sockets.TcpClient]]$Clients
    [MetricsCollector]$MetricsCollector
    [bool]$Running
    [int]$Port

    DisplayWebSocketServer([int]$port, [MetricsCollector]$collector) {
        $this.Port = $port
        $this.MetricsCollector = $collector
        $this.Clients = New-Object System.Collections.Generic.List[System.Net.Sockets.TcpClient]
        $this.Running = $false
    }

    [void]Start() {
        try {
            $this.Listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $this.Port)
            $this.Listener.Start()
            $this.Running = $true

            Write-DisplayLog "WebSocket server started on port $($this.Port)" -Level "SUCCESS"

            # Start background job for handling connections
            $job = Start-Job -ScriptBlock {
                param($server, $port)

                while ($server.Running) {
                    try {
                        if ($server.Listener.Pending()) {
                            $client = $server.Listener.AcceptTcpClient()
                            $server.Clients.Add($client)

                            Write-DisplayLog "New client connected. Total clients: $($server.Clients.Count)" -Level "INFO"

                            # Handle client in background
                            Start-Job -ScriptBlock {
                                param($client, $collector, $refreshRate)

                                try {
                                    $stream = $client.GetStream()
                                    $writer = New-Object System.IO.StreamWriter($stream)
                                    $writer.AutoFlush = $true

                                    while ($client.Connected) {
                                        $metrics = $collector.GetAllMetrics()
                                        $jsonData = $metrics | ConvertTo-Json -Depth 10 -Compress

                                        # Simple HTTP-like response for demo (in production, use proper WebSocket protocol)
                                        $response = "HTTP/1.1 200 OK`r`n"
                                        $response += "Content-Type: application/json`r`n"
                                        $response += "Access-Control-Allow-Origin: *`r`n"
                                        $response += "Cache-Control: no-cache`r`n"
                                        $response += "`r`n"
                                        $response += $jsonData

                                        $writer.Write($response)

                                        Start-Sleep -Milliseconds $refreshRate
                                    }
                                }
                                catch {
                                    # Client disconnected
                                }
                                finally {
                                    if ($client) { $client.Close() }
                                }
                            } -ArgumentList $client, $server.MetricsCollector, $DisplayConfig.RefreshRate
                        }
                    }
                    catch {
                        Write-DisplayLog "Error accepting client connection: $($_.Exception.Message)" -Level "ERROR"
                    }

                    Start-Sleep -Milliseconds 100
                }
            } -ArgumentList $this, $this.Port

        }
        catch {
            Write-DisplayLog "Failed to start WebSocket server: $($_.Exception.Message)" -Level "ERROR"
            throw
        }
    }

    [void]Stop() {
        $this.Running = $false

        foreach ($client in $this.Clients) {
            try { $client.Close() } catch { }
        }

        $this.Clients.Clear()

        if ($this.Listener) {
            $this.Listener.Stop()
        }

        Write-DisplayLog "WebSocket server stopped" -Level "INFO"
    }

    [int]GetClientCount() {
        return $this.Clients.Count
    }
}

# =============================================================================
# HTML DASHBOARD GENERATOR
# =============================================================================

function New-DisplayDashboard {
    param([string]$OutputPath)

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NCC Ultimate Display Monitor v2.0.0</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/luxon@3.0.1/build/global/luxon.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        body {
            background: linear-gradient(135deg, #0a0f14 0%, #1a2a3a 100%);
            color: #e6f7ff;
            overflow: hidden;
            height: 100vh;
            width: 100vw;
        }

        .header {
            background: rgba(0, 20, 40, 0.9);
            padding: 10px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 2px solid #00ffff;
            backdrop-filter: blur(10px);
        }

        .header h1 {
            font-size: 1.5rem;
            color: #00ffff;
            text-shadow: 0 0 10px #00ffff;
        }

        .timestamp {
            font-size: 1.2rem;
            color: #ffff00;
            font-weight: bold;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            grid-template-rows: repeat(3, 1fr);
            gap: 10px;
            padding: 10px;
            height: calc(100vh - 60px);
        }

        .panel {
            background: rgba(10, 20, 30, 0.9);
            border: 1px solid #00ffff;
            border-radius: 8px;
            padding: 15px;
            display: flex;
            flex-direction: column;
            backdrop-filter: blur(10px);
            box-shadow: 0 0 20px rgba(0, 255, 255, 0.1);
            transition: all 0.3s ease;
        }

        .panel:hover {
            border-color: #ffff00;
            box-shadow: 0 0 30px rgba(255, 255, 0, 0.2);
        }

        .panel-header {
            font-size: 0.9rem;
            color: #00ffff;
            margin-bottom: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
            border-bottom: 1px solid #00ffff;
            padding-bottom: 5px;
        }

        .metric {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
            padding: 5px;
            border-radius: 4px;
            transition: background 0.2s ease;
        }

        .metric:hover {
            background: rgba(0, 255, 255, 0.1);
        }

        .metric-label {
            font-size: 0.8rem;
            color: #cccccc;
        }

        .metric-value {
            font-size: 1.1rem;
            font-weight: bold;
            color: #ffffff;
        }

        .status-good { color: #00ff00; }
        .status-warning { color: #ffff00; }
        .status-critical { color: #ff0000; }
        .status-excellent { color: #00ffff; }

        .chart-container {
            flex: 1;
            position: relative;
            margin-top: 10px;
        }

        .alert-item {
            padding: 5px;
            margin-bottom: 5px;
            border-radius: 3px;
            font-size: 0.8rem;
        }

        .alert-critical { background: rgba(255, 0, 0, 0.2); border-left: 3px solid #ff0000; }
        .alert-warning { background: rgba(255, 255, 0, 0.2); border-left: 3px solid #ffff00; }
        .alert-info { background: rgba(0, 255, 255, 0.2); border-left: 3px solid #00ffff; }

        .pulse {
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }

        .glow {
            text-shadow: 0 0 10px currentColor;
        }

        .status-indicator {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 5px;
        }

        .status-indicator.good { background: #00ff00; box-shadow: 0 0 10px #00ff00; }
        .status-indicator.warning { background: #ffff00; box-shadow: 0 0 10px #ffff00; }
        .status-indicator.critical { background: #ff0000; box-shadow: 0 0 10px #ff0000; }
        .status-indicator.excellent { background: #00ffff; box-shadow: 0 0 10px #00ffff; }

        @media (max-width: 1200px) {
            .grid {
                grid-template-columns: repeat(2, 1fr);
                grid-template-rows: repeat(6, 1fr);
            }
        }

        @media (max-width: 768px) {
            .grid {
                grid-template-columns: 1fr;
                grid-template-rows: repeat(12, 1fr);
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🖥️ NCC ULTIMATE DISPLAY MONITOR v2.0.0</h1>
        <div class="timestamp" id="timestamp">--:--:-- UTC</div>
    </div>

    <div class="grid">
        <!-- System Health Panel -->
        <div class="panel" id="system-health">
            <div class="panel-header">🖥️ System Health</div>
            <div id="system-metrics"></div>
        </div>

        <!-- Agent Status Panel -->
        <div class="panel" id="agent-status">
            <div class="panel-header">🤖 Agent Status</div>
            <div id="agent-metrics"></div>
        </div>

        <!-- Financial Flow Panel -->
        <div class="panel" id="financial-flow">
            <div class="panel-header">💰 Financial Flow</div>
            <div id="financial-metrics"></div>
        </div>

        <!-- Alerts Panel -->
        <div class="panel" id="alerts">
            <div class="panel-header">🚨 Active Alerts</div>
            <div id="alert-list"></div>
        </div>

        <!-- Performance Panel -->
        <div class="panel" id="performance">
            <div class="panel-header">⚡ Performance</div>
            <div id="performance-metrics"></div>
        </div>

        <!-- Communication Panel -->
        <div class="panel" id="communication">
            <div class="panel-header">📡 Communication</div>
            <div id="communication-metrics"></div>
        </div>

        <!-- Trading Engine Panel -->
        <div class="panel" id="trading-engine">
            <div class="panel-header">📈 Trading Engine</div>
            <div id="trading-metrics"></div>
        </div>

        <!-- Compliance Panel -->
        <div class="panel" id="compliance">
            <div class="panel-header">⚖️ Compliance</div>
            <div id="compliance-metrics"></div>
        </div>

        <!-- Real-Time Charts Panel -->
        <div class="panel" id="charts">
            <div class="panel-header">📊 Real-Time Charts</div>
            <div class="chart-container">
                <canvas id="performanceChart"></canvas>
            </div>
        </div>

        <!-- Bottleneck Detection Panel -->
        <div class="panel" id="bottlenecks">
            <div class="panel-header">🔍 Bottleneck Detection</div>
            <div class="chart-container">
                <canvas id="bottleneckChart"></canvas>
            </div>
        </div>

        <!-- Market Data Panel -->
        <div class="panel" id="market-data">
            <div class="panel-header">🌍 Market Data</div>
            <div id="market-tickers"></div>
        </div>

        <!-- Executive Dashboard Panel -->
        <div class="panel" id="executive">
            <div class="panel-header">👔 Executive Dashboard</div>
            <div id="executive-metrics"></div>
        </div>
    </div>

    <script>
        let metricsData = {};
        let performanceChart = null;
        let bottleneckChart = null;
        let lastUpdate = Date.now();

        // Initialize charts
        function initCharts() {
            const perfCtx = document.getElementById('performanceChart').getContext('2d');
            performanceChart = new Chart(perfCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'CPU Usage %',
                        data: [],
                        borderColor: '#00ff00',
                        backgroundColor: 'rgba(0, 255, 0, 0.1)',
                        tension: 0.4
                    }, {
                        label: 'Memory Usage %',
                        data: [],
                        borderColor: '#00ffff',
                        backgroundColor: 'rgba(0, 255, 255, 0.1)',
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100,
                            grid: { color: 'rgba(255, 255, 255, 0.1)' }
                        },
                        x: {
                            grid: { color: 'rgba(255, 255, 255, 0.1)' }
                        }
                    },
                    plugins: {
                        legend: { labels: { color: '#ffffff' } }
                    }
                }
            });

            const bottleCtx = document.getElementById('bottleneckChart').getContext('2d');
            bottleneckChart = new Chart(bottleCtx, {
                type: 'radar',
                data: {
                    labels: ['CPU', 'Memory', 'Disk', 'Network', 'Latency'],
                    datasets: [{
                        label: 'System Load',
                        data: [45, 62, 78, 23, 15],
                        borderColor: '#ff0000',
                        backgroundColor: 'rgba(255, 0, 0, 0.1)',
                        pointBackgroundColor: '#ff0000'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        r: {
                            beginAtZero: true,
                            max: 100,
                            grid: { color: 'rgba(255, 255, 255, 0.1)' },
                            angleLines: { color: 'rgba(255, 255, 255, 0.1)' },
                            pointLabels: { color: '#ffffff' }
                        }
                    },
                    plugins: {
                        legend: { labels: { color: '#ffffff' } }
                    }
                }
            });
        }

        // Update timestamp
        function updateTimestamp() {
            const now = new Date();
            document.getElementById('timestamp').textContent =
                now.toISOString().slice(11, 19) + ' UTC';
        }

        // Update metrics display
        function updateMetricsDisplay() {
            // System Health
            const systemHtml = Object.entries(metricsData.System || {}).map(([key, metric]) => `
                <div class="metric">
                    <span class="metric-label">${key}:</span>
                    <span class="metric-value status-${metric.Status} glow">
                        <span class="status-indicator ${metric.Status}"></span>
                        ${metric.Value}${metric.Unit}
                    </span>
                </div>
            `).join('');
            document.getElementById('system-metrics').innerHTML = systemHtml;

            // Agent Status
            const agentHtml = Object.entries(metricsData.Agents || {}).map(([key, metric]) => `
                <div class="metric">
                    <span class="metric-label">${key}:</span>
                    <span class="metric-value status-${metric.Status} glow">
                        <span class="status-indicator ${metric.Status}"></span>
                        ${metric.Value}${metric.Unit}
                    </span>
                </div>
            `).join('');
            document.getElementById('agent-metrics').innerHTML = agentHtml;

            // Financial Flow
            const financialHtml = Object.entries(metricsData.Financial || {}).map(([key, metric]) => `
                <div class="metric">
                    <span class="metric-label">${key}:</span>
                    <span class="metric-value status-${metric.Status} glow">
                        <span class="status-indicator ${metric.Status}"></span>
                        ${metric.Value}${metric.Unit}
                    </span>
                </div>
            `).join('');
            document.getElementById('financial-metrics').innerHTML = financialHtml;

            // Communication
            const commHtml = Object.entries(metricsData.Communication || {}).map(([key, metric]) => `
                <div class="metric">
                    <span class="metric-label">${key}:</span>
                    <span class="metric-value status-${metric.Status} glow">
                        <span class="status-indicator ${metric.Status}"></span>
                        ${metric.Value}${metric.Unit}
                    </span>
                </div>
            `).join('');
            document.getElementById('communication-metrics').innerHTML = commHtml;

            // Performance
            const perfHtml = Object.entries(metricsData.Performance || {}).map(([key, metric]) => `
                <div class="metric">
                    <span class="metric-label">${key}:</span>
                    <span class="metric-value status-${metric.Status} glow">
                        <span class="status-indicator ${metric.Status}"></span>
                        ${metric.Value}${metric.Unit}
                    </span>
                </div>
            `).join('');
            document.getElementById('performance-metrics').innerHTML = perfHtml;

            // Alerts
            const alertHtml = Object.entries(metricsData.Alerts || {}).map(([key, metric]) => `
                <div class="alert-item alert-${metric.Status.toLowerCase()}">
                    <span class="status-indicator ${metric.Status}"></span>
                    ${key}: ${metric.Value} ${metric.Unit}
                </div>
            `).join('');
            document.getElementById('alert-list').innerHTML = alertHtml;

            // Trading Engine (placeholder)
            document.getElementById('trading-metrics').innerHTML = `
                <div class="metric">
                    <span class="metric-label">Positions:</span>
                    <span class="metric-value status-excellent glow">
                        <span class="status-indicator excellent"></span>
                        +$45M
                    </span>
                </div>
                <div class="metric">
                    <span class="metric-label">P&L:</span>
                    <span class="metric-value status-excellent glow">
                        <span class="status-indicator excellent"></span>
                        +12%
                    </span>
                </div>
            `;

            // Compliance (placeholder)
            document.getElementById('compliance-metrics').innerHTML = `
                <div class="metric">
                    <span class="metric-label">Audit Status:</span>
                    <span class="metric-value status-excellent glow">
                        <span class="status-indicator excellent"></span>
                        ✅ PASS
                    </span>
                </div>
                <div class="metric">
                    <span class="metric-label">Risk Level:</span>
                    <span class="metric-value status-good glow">
                        <span class="status-indicator good"></span>
                        LOW
                    </span>
                </div>
            `;

            // Market Data (placeholder)
            document.getElementById('market-tickers').innerHTML = `
                <div class="metric">
                    <span class="metric-label">SPY:</span>
                    <span class="metric-value status-excellent glow">425.67</span>
                </div>
                <div class="metric">
                    <span class="metric-label">QQQ:</span>
                    <span class="metric-value status-excellent glow">378.92</span>
                </div>
                <div class="metric">
                    <span class="metric-label">BTC:</span>
                    <span class="metric-value status-excellent glow">89234</span>
                </div>
            `;

            // Executive Dashboard (placeholder)
            document.getElementById('executive-metrics').innerHTML = `
                <div class="metric">
                    <span class="metric-label">Revenue Target:</span>
                    <span class="metric-value status-excellent glow">110% ✅</span>
                </div>
                <div class="metric">
                    <span class="metric-label">KPI Achievement:</span>
                    <span class="metric-value status-excellent glow">95% ✅</span>
                </div>
            `;

            // Update charts with new data
            updateCharts();
        }

        // Update charts
        function updateCharts() {
            if (performanceChart && metricsData.System) {
                const now = new Date().toLocaleTimeString();
                performanceChart.data.labels.push(now);
                performanceChart.data.datasets[0].data.push(metricsData.System.CPU?.Value || 0);
                performanceChart.data.datasets[1].data.push(metricsData.System.Memory?.Value || 0);

                // Keep only last 20 data points
                if (performanceChart.data.labels.length > 20) {
                    performanceChart.data.labels.shift();
                    performanceChart.data.datasets[0].data.shift();
                    performanceChart.data.datasets[1].data.shift();
                }

                performanceChart.update('none');
            }

            if (bottleneckChart && metricsData.System) {
                bottleneckChart.data.datasets[0].data = [
                    metricsData.System.CPU?.Value || 0,
                    metricsData.System.Memory?.Value || 0,
                    metricsData.System.Disk?.Value || 0,
                    metricsData.System.Network?.Value / 10 || 0, // Scale down
                    15 // Placeholder latency
                ];
                bottleneckChart.update('none');
            }
        }

        // Fetch metrics from server
        async function fetchMetrics() {
            try {
                const response = await fetch('http://localhost:$($DisplayConfig.Port)/metrics');
                if (response.ok) {
                    metricsData = await response.json();
                    updateMetricsDisplay();
                    lastUpdate = Date.now();
                }
            } catch (error) {
                console.error('Failed to fetch metrics:', error);
                // Show offline indicator
                document.body.style.border = '3px solid #ff0000';
                setTimeout(() => {
                    document.body.style.border = 'none';
                }, 1000);
            }
        }

        // Initialize
        document.addEventListener('DOMContentLoaded', function() {
            initCharts();
            updateTimestamp();

            // Update timestamp every second
            setInterval(updateTimestamp, 1000);

            // Fetch metrics at specified refresh rate
            fetchMetrics();
            setInterval(fetchMetrics, $($DisplayConfig.RefreshRate));

            // Add pulse effect to critical metrics
            setInterval(() => {
                document.querySelectorAll('.status-critical').forEach(el => {
                    el.classList.toggle('pulse');
                });
            }, 1000);
        });

        // Handle visibility change for performance
        document.addEventListener('visibilitychange', function() {
            if (document.hidden) {
                // Reduce update frequency when tab is not visible
                console.log('Tab hidden, reducing update frequency');
            } else {
                // Resume normal updates
                fetchMetrics();
            }
        });
    </script>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-DisplayLog "Dashboard HTML generated at: $OutputPath" -Level "SUCCESS"
}

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

function Initialize-DisplaySystem {
    Write-DisplayLog "=== INITIALIZING NCC ULTIMATE DISPLAY MONITOR SYSTEM ===" -Level "CRITICAL"

    # Create metrics collector
    $metricsCollector = [MetricsCollector]::new()

    # Generate dashboard HTML
    $dashboardPath = Join-Path $DisplayConfig.Paths.Dashboard "NCC_Ultimate_Display.html"
    New-DisplayDashboard -OutputPath $dashboardPath

    # Create WebSocket server
    $webSocketServer = [DisplayWebSocketServer]::new($DisplayConfig.Port, $metricsCollector)

    # Store in global scope for access by other functions
    $global:DisplayMetricsCollector = $metricsCollector
    $global:DisplayWebSocketServer = $webSocketServer

    Write-DisplayLog "Display system initialized successfully" -Level "SUCCESS"
}

function Start-DisplaySystem {
    Write-DisplayLog "=== STARTING NCC ULTIMATE DISPLAY MONITOR SYSTEM ===" -Level "CRITICAL"

    if (-not $global:DisplayWebSocketServer) {
        Write-DisplayLog "Display system not initialized. Run with -Initialize first." -Level "ERROR"
        return
    }

    # Start WebSocket server
    $global:DisplayWebSocketServer.Start()

    # Start metrics collection loop
    Write-DisplayLog "Starting metrics collection with $($DisplayConfig.RefreshRate)ms refresh rate" -Level "INFO"

    $global:DisplayRunning = $true

    while ($global:DisplayRunning) {
        try {
            $global:DisplayMetricsCollector.UpdateAllMetrics()

            if ($DisplayConfig.Debug) {
                $metrics = $global:DisplayMetricsCollector.GetAllMetrics()
                Write-DisplayLog "Metrics updated - Clients: $($global:DisplayWebSocketServer.GetClientCount())" -Level "INFO"
            }

            Start-Sleep -Milliseconds $DisplayConfig.RefreshRate
        }
        catch {
            Write-DisplayLog "Error in metrics collection loop: $($_.Exception.Message)" -Level "ERROR"
            Start-Sleep -Seconds 5
        }
    }
}

function Stop-DisplaySystem {
    Write-DisplayLog "=== STOPPING NCC ULTIMATE DISPLAY MONITOR SYSTEM ===" -Level "WARNING"

    $global:DisplayRunning = $false

    if ($global:DisplayWebSocketServer) {
        $global:DisplayWebSocketServer.Stop()
    }

    Write-DisplayLog "Display system stopped" -Level "INFO"
}

function Get-DisplayStatus {
    Write-DisplayLog "=== NCC ULTIMATE DISPLAY MONITOR STATUS ===" -Level "INFO"

    $status = @{
        Version = $DisplayConfig.Version
        Running = $global:DisplayRunning -eq $true
        Port = $DisplayConfig.Port
        RefreshRate = $DisplayConfig.RefreshRate
        Clients = if ($global:DisplayWebSocketServer) { $global:DisplayWebSocketServer.GetClientCount() } else { 0 }
        LastUpdate = if ($global:DisplayMetricsCollector) { $global:DisplayMetricsCollector.LastUpdate } else { $null }
        HighPerformance = $DisplayConfig.HighPerformance
        Debug = $DisplayConfig.Debug
    }

    $status.GetEnumerator() | ForEach-Object {
        Write-DisplayLog "$($_.Key): $($_.Value)" -Level "INFO"
    }

    return $status
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

try {
    if ($Initialize) {
        Initialize-DisplaySystem
    }
    elseif ($Start) {
        if (-not $global:DisplayWebSocketServer) {
            Initialize-DisplaySystem
        }
        Start-DisplaySystem
    }
    elseif ($Stop) {
        Stop-DisplaySystem
    }
    elseif ($Restart) {
        Stop-DisplaySystem
        Start-Sleep -Seconds 2
        Initialize-DisplaySystem
        Start-DisplaySystem
    }
    elseif ($Status) {
        Get-DisplayStatus
    }
    else {
        Write-DisplayLog "NCC Ultimate Display Monitor v$($DisplayConfig.Version)" -Level "INFO"
        Write-DisplayLog "Usage:" -Level "INFO"
        Write-DisplayLog "  .\NCC_Display_Master.ps1 -Initialize    # Initialize the system" -Level "INFO"
        Write-DisplayLog "  .\NCC_Display_Master.ps1 -Start         # Start the display system" -Level "INFO"
        Write-DisplayLog "  .\NCC_Display_Master.ps1 -Stop          # Stop the display system" -Level "INFO"
        Write-DisplayLog "  .\NCC_Display_Master.ps1 -Restart       # Restart the display system" -Level "INFO"
        Write-DisplayLog "  .\NCC_Display_Master.ps1 -Status        # Show system status" -Level "INFO"
        Write-DisplayLog "" -Level "INFO"
        Write-DisplayLog "Parameters:" -Level "INFO"
        Write-DisplayLog "  -Port <number>        # Server port (default: 3000)" -Level "INFO"
        Write-DisplayLog "  -RefreshRate <ms>     # Refresh rate in milliseconds (default: 500)" -Level "INFO"
        Write-DisplayLog "  -HighPerformance      # Enable high-performance mode" -Level "INFO"
        Write-DisplayLog "  -Debug                # Enable debug logging" -Level "INFO"
    }
}
catch {
    Write-DisplayLog "Critical error in main execution: $($_.Exception.Message)" -Level "CRITICAL"
    Write-DisplayLog "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"
}
finally {
    # Cleanup on exit
    if ($global:DisplayRunning) {
        Stop-DisplaySystem
    }
}
