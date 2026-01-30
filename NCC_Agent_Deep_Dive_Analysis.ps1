# NCC Agent Deep Dive Analysis Script
# Comprehensive identification and categorization of all NCC agents
# Date: 2026-01-30 | Authority: AZ PRIME Command

param(
    [switch]$Analyze,
    [switch]$Categorize,
    [switch]$Report
)

# Get all PowerShell files recursively
$rootPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$allPs1Files = Get-ChildItem -Path $rootPath -Filter "*.ps1" -Recurse -File

Write-Host "=== NCC AGENT DEEP DIVE ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Total PowerShell files found: $($allPs1Files.Count)" -ForegroundColor Yellow

# Categorize agents
$agentCategories = @{
    "Core Systems" = @()
    "Trading & Finance" = @()
    "Intelligence & Analytics" = @()
    "Communication & Coordination" = @()
    "Security & Compliance" = @()
    "Infrastructure & Operations" = @()
    "Emergency & Recovery" = @()
    "Performance & Optimization" = @()
    "Activation & Control" = @()
    "Utilities & Tools" = @()
    "Division Agents" = @()
    "Scripts" = @()
}

foreach ($file in $allPs1Files) {
    $fileName = $file.Name
    $filePath = $file.FullName

    # Categorize based on filename patterns
    if ($fileName -match "^(NCC\.|AZ\.|AX\.|LFG\.|MCC\.|FFC\.|CEO\.|EX\.|AAC\.|AZ_PRIME|Omega_Accountant|Supreme_Information_Auditor)") {
        $agentCategories["Core Systems"] += $file
    }
    elseif ($fileName -match "(Trading|Arbitrage|Finance|Portfolio|Quant|Risk|StatArb|StructArb|TechArb|PortMgmt|CompArb|QuantArb|RiskMgmt)") {
        $agentCategories["Trading & Finance"] += $file
    }
    elseif ($fileName -match "(Intelligence|Analytics|BigBrain|Quantum_Intelligence|DataBrokers|Pattern_Recognition|Master_Data_Analysis)") {
        $agentCategories["Intelligence & Analytics"] += $file
    }
    elseif ($fileName -match "(Communication|Coordination|MessageBroker|SwarmCoordination|Dashboard|Data\.Repository|DataPipeline)") {
        $agentCategories["Communication & Coordination"] += $file
    }
    elseif ($fileName -match "(Security|Compliance|Audit|Regulatory|Failover|Recovery|Emergency|Incident|Post_Incident|Crisis|Cybersecurity)") {
        $agentCategories["Security & Compliance"] += $file
    }
    elseif ($fileName -match "(Infrastructure|Operations|Automation|Robotics|QuantumComputing|SpaceOperations|GlobalLogistics|ResonanceEnergy|Biotech|MediaCorp|Ludwig_Law)") {
        $agentCategories["Infrastructure & Operations"] += $file
    }
    elseif ($fileName -match "(Emergency|Recovery|Failover|Crisis|Management|Response|Analysis)") {
        $agentCategories["Emergency & Recovery"] += $file
    }
    elseif ($fileName -match "(Performance|Optimization|Monitoring|Resource_Allocation|Automated_Performance|AX_Deployment|AX_Intelligence|AX_Performance)") {
        $agentCategories["Performance & Optimization"] += $file
    }
    elseif ($fileName -match "(Activate|Activation|Launcher|SuperLauncher|Master_Activation|FullSteam|Ultimate\.Activate|CEOs\.Activate|LFG\.Activate|MCC\.Activate|NCL\.Activate)") {
        $agentCategories["Activation & Control"] += $file
    }
    elseif ($fileName -match "(Agent\.|NCC\.Agent\.|Division.*Agent|.*\.Agent\.)") {
        $agentCategories["Division Agents"] += $file
    }
    elseif ($file.DirectoryName -match "Scripts|scripts") {
        $agentCategories["Scripts"] += $file
    }
    else {
        $agentCategories["Utilities & Tools"] += $file
    }
}

# Display results
Write-Host "`n=== AGENT CATEGORIZATION RESULTS ===" -ForegroundColor Green
$totalAgents = 0

foreach ($category in $agentCategories.Keys | Sort-Object) {
    $count = $agentCategories[$category].Count
    $totalAgents += $count
    Write-Host "$category : $count agents" -ForegroundColor White

    if ($Analyze) {
        foreach ($agent in $agentCategories[$category] | Sort-Object Name) {
            Write-Host "  - $($agent.Name)" -ForegroundColor Gray
        }
    }
}

Write-Host "`nTOTAL AGENTS IDENTIFIED: $totalAgents" -ForegroundColor Yellow

if ($Report) {
    # Generate detailed report
    $reportPath = Join-Path $rootPath "NCC_Agent_Deep_Dive_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    $reportContent = @"
NCC AGENT DEEP DIVE ANALYSIS REPORT
Generated: $(Get-Date)
Total Agents: $totalAgents

DETAILED BREAKDOWN BY CATEGORY:
"@

    foreach ($category in $agentCategories.Keys | Sort-Object) {
        $reportContent += "`n$category ($($agentCategories[$category].Count) agents):`n"
        foreach ($agent in $agentCategories[$category] | Sort-Object Name) {
            $reportContent += "  - $($agent.Name)`n"
        }
    }

    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "`nDetailed report saved to: $reportPath" -ForegroundColor Green
}
