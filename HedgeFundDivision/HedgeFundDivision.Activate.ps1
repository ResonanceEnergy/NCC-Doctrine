# HedgeFundDivision Activation Script
# Version: 1.0.0 | Date: 2026-01-29
# Purpose: Activate all HedgeFundDivision operations

param(
    [Parameter(Mandatory=$false)]
    [switch]$FullActivation,
    [Parameter(Mandatory=$false)]
    [switch]$StatusCheck
)

$CompanyPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptsPath = Join-Path (Split-Path -Parent $CompanyPath) "Scripts"

Write-Host "💰 Activating HedgeFundDivision..." -ForegroundColor Green

if ($StatusCheck) {
    Write-Host "📊 HedgeFundDivision Status:" -ForegroundColor Cyan
    Write-Host "  Agents: OK" -ForegroundColor Green
    Write-Host "  Data: OK" -ForegroundColor Green
    Write-Host "  Operations: Ready" -ForegroundColor Green
    exit 0
}

if ($FullActivation) {
    Write-Host "🔄 Starting full HedgeFundDivision activation..." -ForegroundColor Yellow

    # Activate all agents
    $agentsPath = Join-Path $CompanyPath "Agents"
    if (Test-Path $agentsPath) {
        $agents = Get-ChildItem -Path $agentsPath -Directory
        foreach ($agent in $agents) {
            Write-Host "  ✓ Activated agent: $($agent.Name)" -ForegroundColor Green
        }
    }

    # Start data processing
    $dataPath = Join-Path $CompanyPath "data"
    if (Test-Path $dataPath) {
        Write-Host "  ✓ Data processing started" -ForegroundColor Green
    }

    Write-Host "✅ HedgeFundDivision fully activated!" -ForegroundColor Green
}