# Launch all 10 NCC Data Intelligence Campaigns simultaneously

$venvPython = Join-Path $PSScriptRoot ".." ".venv" "Scripts" "python.exe"
$scriptsDir = Join-Path $PSScriptRoot

$campaigns = @(
    "ncc_academic_research.py",
    "ncc_crypto_blockchain.py", 
    "ncc_data_correlation.py",
    "ncc_ecommerce_pricing.py",
    "ncc_financial_sentiment.py",
    "ncc_health_wellness.py",
    "ncc_job_market.py",
    "ncc_real_estate.py",
    "ncc_social_media_trends.py",
    "ncc_tech_innovation.py"
)

Write-Host "🚀 AZ PRIME: Launching all 10 data intelligence campaigns simultaneously..." -ForegroundColor Green

$jobs = @()

foreach ($campaign in $campaigns) {
    $scriptPath = Join-Path $scriptsDir $campaign
    Write-Host "Launching $campaign..." -ForegroundColor Yellow
    $job = Start-Job -ScriptBlock {
        param($python, $script)
        & $python $script
    } -ArgumentList $venvPython, $scriptPath
    $jobs += $job
}

Write-Host "All campaigns launched. Monitoring..." -ForegroundColor Green

# Wait for all jobs to complete or timeout
$jobs | Wait-Job -Timeout 300  # 5 minutes timeout

# Get results
foreach ($job in $jobs) {
    $result = Receive-Job $job
    Write-Host "Campaign $($job.Name) output:" -ForegroundColor Cyan
    Write-Host $result
    Remove-Job $job
}

Write-Host "✅ All data intelligence campaigns completed." -ForegroundColor Green