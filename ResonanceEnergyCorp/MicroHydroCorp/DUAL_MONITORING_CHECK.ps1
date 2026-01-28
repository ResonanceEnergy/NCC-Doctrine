#!/usr/bin/env pwsh
# DUAL_MONITORING_CHECK.ps1
# Monitor both Tier 1 and Tier 2 simultaneously
# Run daily Jan 25 - Feb 7

param(
    [string]$LogFile = "c:\MircoHydro\DUAL_MONITORING_LOG.txt"
)

$t1arch = "c:\MircoHydro\TIER1_CLEANUP_ARCHIVED_20260124"
$t2arch = "c:\MircoHydro\TIER2_CLEANUP_ARCHIVED_20260124"
$sotPath = "c:\MircoHydro\MicroHydroV1 — SoT"
$backupPath = "c:\MircoHydro_CONSOLIDATION_BACKUP_20260124"
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

# Initialize log
if (-not (Test-Path $LogFile)) {
    Add-Content -Path $LogFile -Value "DUAL MONITORING LOG - Tier 1 & 2"
    Add-Content -Path $LogFile -Value "Started: $timestamp"
    Add-Content -Path $LogFile -Value "═════════════════════════════════════════════════════════════════"
    Add-Content -Path $LogFile -Value ""
}

Write-Host ""
Write-Host "[$timestamp] DUAL TIER MONITORING" -ForegroundColor Green
Write-Host ""

# TIER 1 CHECKS
Write-Host "TIER 1 CHECKS:" -ForegroundColor Cyan
$t1files = @(Get-ChildItem -Path $t1arch -Recurse -File -ErrorAction SilentlyContinue)
$t1size = ($t1files | Measure-Object -Property Length -Sum).Sum / 1MB
$t1pass = if ($t1files.Count -eq 28) { "✅" } else { "⚠️" }
Write-Host "  $t1pass Files: $($t1files.Count) / 28"
Write-Host "  $t1pass Size: $([math]::Round($t1size, 1)) / 5.7 MB"
Add-Content -Path $LogFile -Value "[$timestamp] T1: $($t1files.Count) files, $([math]::Round($t1size, 1)) MB - $t1pass"

# TIER 2 CHECKS
Write-Host ""
Write-Host "TIER 2 CHECKS:" -ForegroundColor Cyan
$t2files = @(Get-ChildItem -Path $t2arch -Recurse -File -ErrorAction SilentlyContinue)
$t2size = ($t2files | Measure-Object -Property Length -Sum).Sum / 1MB
$t2pass = if ($t2files.Count -eq 39) { "✅" } else { "⚠️" }
Write-Host "  $t2pass Files: $($t2files.Count) / 39"
Write-Host "  $t2pass Size: $([math]::Round($t2size, 2)) / 0.2 MB"
Add-Content -Path $LogFile -Value "[$timestamp] T2: $($t2files.Count) files, $([math]::Round($t2size, 2)) MB - $t2pass"

# SYSTEM CHECKS
Write-Host ""
Write-Host "SYSTEM CHECKS:" -ForegroundColor Cyan
$sotOK = Test-Path $sotPath
$backupOK = Test-Path $backupPath
Write-Host "  $(if ($sotOK) { '✅' } else { '❌' }) SoT operational: $sotOK"
Write-Host "  $(if ($backupOK) { '✅' } else { '❌' }) Backup accessible: $backupOK"
Add-Content -Path $LogFile -Value "[$timestamp] SoT: $sotOK, Backup: $backupOK"

Write-Host ""
$allPass = if ($t1files.Count -eq 28 -and $t2files.Count -eq 39 -and $sotOK -and $backupOK) { "✅ PASS" } else { "⚠️ CHECK" }
Write-Host "$allPass OVERALL STATUS" -ForegroundColor $(if ($allPass -like "*PASS*") { 'Green' } else { 'Yellow' })
Add-Content -Path $LogFile -Value "$allPass"
Add-Content -Path $LogFile -Value ""

Write-Host ""
exit 0
