# NCC Pizza Party Synchronization Protocol
# Version: 1.0.0 | Date: 2026-01-29
# Purpose: Synchronize insights across all agents and companies

$RootPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$AgentsPath = Join-Path $RootPath "agents"
$LogsPath = Join-Path $RootPath "logs"

function Write-PizzaLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [PIZZA] $Message" | Out-File -FilePath (Join-Path $LogsPath "Pizza_Party.log") -Append
}

Write-PizzaLog "🍕 Starting Pizza Party synchronization..."

# Gather insights from all agents
$allInsights = @()
$agentFolders = Get-ChildItem -Path $AgentsPath -Directory

foreach ($agentFolder in $agentFolders) {
    $insightsPath = Join-Path $agentFolder.FullName "insights"
    if (Test-Path $insightsPath) {
        $insightFiles = Get-ChildItem -Path $insightsPath -Filter "*.json"
        foreach ($file in $insightFiles) {
            $insight = Get-Content $file.FullName | ConvertFrom-Json
            $allInsights += $insight
        }
    }
}

# Share insights with all agents
foreach ($agentFolder in $agentFolders) {
    $sharedInsightsPath = Join-Path $agentFolder.FullName "shared_insights"
    if (!(Test-Path $sharedInsightsPath)) {
        New-Item -ItemType Directory -Path $sharedInsightsPath -Force
    }

    # Distribute insights
    for ($i = 0; $i -lt $allInsights.Count; $i++) {
        $insightFile = Join-Path $sharedInsightsPath "insight_$i.json"
        $allInsights[$i] | ConvertTo-Json | Set-Content -Path $insightFile
    }
}

Write-PizzaLog "✅ Pizza Party completed! $($allInsights.Count) insights shared across $($agentFolders.Count) agents"
