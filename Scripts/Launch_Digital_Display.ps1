# NCC Digital Display Launcher
# Opens the real-time digital display in the default browser

param(
    [switch]$Fullscreen
)

$displayPath = Join-Path $PSScriptRoot "NCC_Digital_Display.html"

if (Test-Path $displayPath) {
    Write-Host "🚀 Launching NCC Digital Display..." -ForegroundColor Green
    Write-Host "📊 Real-time metrics display activated" -ForegroundColor Cyan

    if ($Fullscreen) {
        # Open in fullscreen mode (requires additional setup)
        Start-Process "msedge.exe" -ArgumentList "--kiosk $displayPath"
    } else {
        Start-Process $displayPath
    }

    Write-Host "✅ Digital display opened successfully" -ForegroundColor Green
    Write-Host "🔥 LFG! Real-time monitoring active" -ForegroundColor Yellow
} else {
    Write-Error "❌ Digital display file not found: $displayPath"
}