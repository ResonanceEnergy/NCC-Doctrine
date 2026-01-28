param(
  [switch]$Initialize,      # seed data + settings + budgets + ledger
  [switch]$Build,           # generate Dashboard\NCC_Dashboard.html
  [switch]$Open,            # open the dashboard in default browser
  [switch]$Serve,           # run http://localhost:9080/
  [switch]$Watch,           # rebuild on data file changes
  [switch]$Export,          # zip bundle
  [switch]$UpdateProgress,  # prompt-driven from VS Code task inputs
  [string]$Project,
  [int]$Progress = -1,
  [switch]$SetupVSCode,     # write .vscode/tasks.json + launch.json
  [string]$Root = (Join-Path $PSScriptRoot "..")
)

# ─────────────────────────────────────────────────────────────────────────────
# Paths
# ─────────────────────────────────────────────────────────────────────────────
$DataDir       = Join-Path $Root "data"
$ScriptsDir    = Join-Path $Root "scripts"
$DashDir       = Join-Path $Root "Dashboard"
$VsDir         = Join-Path $Root ".vscode"

$PortfolioJson = Join-Path $DataDir "projects.json"
$SettingsJson  = Join-Path $DataDir "settings.json"
$BudgetsJson   = Join-Path $DataDir "budgets.json"
$LedgerJson    = Join-Path $DataDir "ledger.json"
$HtmlOut       = Join-Path $DashDir "NCC_Dashboard.html"

New-Item -ItemType Directory -Force -Path $DataDir, $ScriptsDir, $DashDir, $VsDir | Out-Null

# ─────────────────────────────────────────────────────────────────────────────
# Seeders (projects, settings, budgets, ledger)
# ─────────────────────────────────────────────────────────────────────────────
function Initialize-NccPortfolio {
  if (Test-Path $PortfolioJson) { return }
  $projectDir = Join-Path $Root "Projects"
  $portfolio = @(
    @{ProjectName='Resonance Energy'; Category='R&D';          Description=''; Path="$projectDir\Resonance Energy";             Status='Active'; Progress=0; LastUpdated='2026-01-27 10:34'; Parent='' }
    @{ProjectName='MicroHydro Project'; Category='R&D';         Description=''; Path="$projectDir\MicroHydro Project";           Status='Active'; Progress=0; LastUpdated='2026-01-27 10:34'; Parent='Resonance Energy' }
    @{ProjectName='Big Brain Intelligence'; Category='R&D';     Description=''; Path="$projectDir\Big Brain Intelligence";       Status='Active'; Progress=0; LastUpdated='2026-01-27 10:34'; Parent='' }
    @{ProjectName='Future Financial'; Category='Finance';       Description=''; Path="$projectDir\Future Financial";             Status='Active'; Progress=0; LastUpdated='2026-01-27 10:34'; Parent='' }
    @{ProjectName='Future Fibre Optics'; Category='Infrastructure'; Description=''; Path="$projectDir\Future Fibre Optics";    Status='Active'; Progress=0; LastUpdated='2026-01-27 10:34'; Parent='' }
    @{ProjectName='Mammoth Media'; Category='Media';            Description=''; Path="$projectDir\Mammoth Media";                Status='Active'; Progress=0; LastUpdated='2026-01-27 10:34'; Parent='' }
    @{ProjectName='Off Grid Technologies'; Category='R&D';      Description=''; Path="$projectDir\Off Grid Technologies";        Status='Active'; Progress=0; LastUpdated='2026-01-27 10:34'; Parent='' }
    @{ProjectName='Grip And Ripp HDD'; Category='Ops';          Description=''; Path="$projectDir\Grip And Ripp HDD";            Status='Active'; Progress=0; LastUpdated='2026-01-27 10:34'; Parent='' }
    @{ProjectName='Butterfield Acres'; Category='Ops';          Description=''; Path="$projectDir\Butterfield Acres";            Status='Active'; Progress=0; LastUpdated='2026-01-27 10:34'; Parent='' }
    @{ProjectName='Phone App Builder'; Category='Software';     Description=''; Path="$projectDir\Phone App Builder";            Status='Active'; Progress=0; LastUpdated='2026-01-27 10:34'; Parent='' }
    @{ProjectName='Uruguay and Paraguay Dream to Reality'; Category='Strategy'; Description=''; Path="$projectDir\Uruguay and Paraguay Dream to Reality"; Status='Active'; Progress=0; LastUpdated=''; Parent='' }
  )
  $portfolio | ConvertTo-Json -Depth 6 | Out-File -FilePath $PortfolioJson -Encoding UTF8
  Write-Host "Seeded → $PortfolioJson"
}

function Initialize-NccSettings {
  if (Test-Path $SettingsJson) { return }
  $rnd = [System.Random]::new()
  $settings = [ordered]@{
    Bank = @{
      Balance       = [math]::Round(($rnd.NextDouble()*250000), 2)   # placeholder
      DeltaPct      = [math]::Round((($rnd.Next(-300, 300))/10.0),1) # -30..+30%
      RunwayDays    = $rnd.Next(30, 180)
      Currency      = "USD"
      Source        = "random"
      LastRefreshed = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    }
    Posture = "NORMAL"
  }
  $settings | ConvertTo-Json -Depth 6 | Out-File -FilePath $SettingsJson -Encoding UTF8
  Write-Host "Seeded → $SettingsJson"
}

function Initialize-NccBudgets {
  if (Test-Path $BudgetsJson) { return }
  $seed = @(
    @{ProjectName='Resonance Energy';    Cap=550000; Allocated=210000},
    @{ProjectName='MicroHydro Project';  Cap=180000; Allocated= 65000},
    @{ProjectName='Future Financial';    Cap= 90000; Allocated= 12000},
    @{ProjectName='Future Fibre Optics'; Cap=140000; Allocated= 18000}
  )
  $seed | ConvertTo-Json -Depth 6 | Out-File $BudgetsJson -Encoding UTF8
  Write-Host "Seeded → $BudgetsJson"
}

function Initialize-NccLedger {
  if (Test-Path $LedgerJson) { return }
  $rnd = [System.Random]::new()
  $rows = @()
  1..30 | ForEach-Object {
    $amt  = [math]::Round(($rnd.Next(-8000, 6000)),2)
    $proj = (Get-Content $PortfolioJson -Raw | ConvertFrom-Json | Get-Random).ProjectName
    $rows += @{
      ts=(Get-Date).AddDays(-$rnd.Next(0,30)).ToString("yyyy-MM-dd HH:mm")
      project=$proj; type=($amt -lt 0 ? 'expense' : 'revenue'); amount=$amt; memo='sim'
    }
  }
  $rows | Sort-Object ts | ConvertTo-Json -Depth 6 | Out-File $LedgerJson -Encoding UTF8
  Write-Host "Seeded → $LedgerJson"
}

function Refresh-NccSettingsRandom {
  if (!(Test-Path $SettingsJson)) { Initialize-NccSettings }
  $settings = Get-Content $SettingsJson -Raw | ConvertFrom-Json
  if ($settings.Bank.Source -eq "random") {
    $rnd = [System.Random]::new()
    $settings.Bank.Balance       = [math]::Round(($rnd.NextDouble()*250000), 2)
    $settings.Bank.DeltaPct      = [math]::Round((($rnd.Next(-300, 300))/10.0),1)
    $settings.Bank.RunwayDays    = $rnd.Next(30, 180)
    $settings.Bank.LastRefreshed = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    $settings | ConvertTo-Json -Depth 6 | Out-File -FilePath $SettingsJson -Encoding UTF8
  }
}

if ($Initialize) {
  Initialize-NccPortfolio
  Initialize-NccSettings
  Initialize-NccBudgets
  Initialize-NccLedger
  Write-Host "All data files initialized."
}
# ─────────────────────────────────────────────────────────────────────────────
# Build the single-file dashboard
# ─────────────────────────────────────────────────────────────────────────────
function New-NccDashboardHtml {
  if (!(Test-Path $PortfolioJson)) { throw "Missing $PortfolioJson (run -Initialize)" }
  Refresh-NccSettingsRandom

  $projectsJson = Get-Content $PortfolioJson -Raw
  $settingsJson = Get-Content $SettingsJson -Raw
  $budgetsJson  = (Test-Path $BudgetsJson) ? (Get-Content $BudgetsJson -Raw) : "[]"
  $ledgerJson   = (Test-Path $LedgerJson)  ? (Get-Content $LedgerJson -Raw)  : "[]"

  $htmlTemplate = @'
<!doctype html><html lang="en"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>NCC COPR. — AZ PRIME Command UI</title>
https://cdn.jsdelivr.net
<style>
:root{--bg:#0a0f14;--fg:#e6f7ff;--muted:#9bdfff;--teal:#30c3f2;--vio:#7a5cf5;--amber:#ffb100;--red:#ff3b3b;--panel:#0e151d;--br:#14202a}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:14px/1.5 Inter,system-ui,-apple-system,Segoe UI,Roboto}
.header{height:25vh;display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px;padding:16px}
.card{background:var(--panel);border:1px solid var(--br);border-radius:14px;padding:16px;box-shadow:0 0 30px #061016 inset}
.kpi{display:flex;gap:16px;align-items:center;flex-wrap:wrap}
.main{height:60vh;display:grid;grid-template-columns:1.2fr 1.2fr 1fr;gap:16px;padding:16px}
.footer{height:15vh;padding:16px}
.tile{display:flex;flex-direction:column;gap:6px}
.row{display:flex;gap:12px;flex-wrap:wrap}
.pill{padding:4px 10px;border-radius:999px;background:#0f1b24;color:var(--muted);border:1px solid #123040}
.list{display:grid;grid-template-columns:repeat(5,1fr);gap:12px}
.proj{padding:10px;border:1px solid #13202c;border-radius:10px;background:#0d151d}
.bar{height:6px;background:#10202a;border-radius:4px;overflow:hidden}
.bar>i{display:block;height:100%;background:linear-gradient(90deg, var(--teal), var(--vio))}
h1,h2,h3{margin:0 0 8px 0;letter-spacing:.04em}
#avatar{height:88px;margin-top:12px;border-radius:12px;background:
 radial-gradient(closest-side at 50% 50%, #19384b 0%, transparent 65%),
 radial-gradient(closest-side at 50% 50%, rgba(48,195,242,.25) 0%, transparent 60%);
 animation:breath 4s infinite}
@keyframes breath{0%{box-shadow:0 0 0 0 rgba(48,195,242,.25)}50%{box-shadow:0 0 25px 6px rgba(122,92,245,.25)}100%{box-shadow:0 0 0 0 rgba(48,195,242,.25)}}
a.btn,button.btn{background:transparent;border:1px solid #123040;color:var(--muted);padding:8px 12px;border-radius:10px;cursor:pointer}
a.btn:hover,button.btn:hover{border-color:var(--teal);color:#fff}
</style></head><body>

<div class="header">
  <div class="card">
    <h2>Bank Account</h2>
    <div class="kpi">
      <div class="tile"><strong id="bal">$—</strong><small>Balance</small></div>
      <div class="tile"><span id="delta" class="pill">Δ 0%</span><small>vs Target</small></div>
      <div class="tile"><span id="runway" class="pill">— d</span><small>Runway</small></div>
    </div>
  </div>
  <div class="card">
    <h1 style="text-align:center">NCC COPR.</h1>
    <div class="kpi" style="justify-content:center">
      <span class="pill" id="posture">NORMAL</span>
      <span class="pill" id="clock"></span>
      <span class="pill">All Sites ▾</span>
      <span class="pill">Mic</span><span class="pill">＋</span><span class="pill">≡</span><span class="pill">⚙</span>
    </div>
  </div>
  <div class="card">
    <h2>Projects</h2>
    <div class="kpi">
      <span class="pill">Portfolio Loaded</span>
    </div>
  </div>
</div>
<div class="main">
  <div class="card">
    <h3>Dashboard Main Area</h3>
    <p>This is a minimal working dashboard. Customize as needed.</p>
  </div>
<div class="footer">
  <span>&copy; NCC Corp. 2026</span>
</div>
</body>
</html>
'@
}

if ($Build) {
  $html = New-NccDashboardHtml
  $html | Out-File -FilePath $HtmlOut -Encoding UTF8
  Write-Host "Built → $HtmlOut"
}
# ─────────────────────────────────────────────────────────────────────────────
# Check for admin rights (required for HttpListener on Windows)
# ─────────────────────────────────────────────────────────────────────────────
function Test-IsAdmin {
  $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
  return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ─────────────────────────────────────────────────────────────────────────────
# Simple static file server for -Serve (with error handling)
# ─────────────────────────────────────────────────────────────────────────────
if ($Serve) {
  if (-not (Test-IsAdmin)) {
    Write-Host "[FATAL] You must run PowerShell as Administrator to use -Serve (HttpListener requires admin rights on Windows)."
    exit 1
  }

  # NCC.Dashboard.ps1 — All-in-one automation for dashboard build, serve, and data seeding
  param(
    [switch]$Initialize,      # Seed all required data files
    [switch]$Build,           # Generate Dashboard/NCC_Dashboard.html
    [switch]$Serve,           # Serve dashboard on http://localhost:9081/
    [switch]$Open,            # Open dashboard in default browser
    [string]$Root
  )

  # Always resolve $Root to the script's parent directory, regardless of invocation location
  if (-not $Root -or $Root -eq "") {
    $ScriptPath = $MyInvocation.MyCommand.Path
    $ScriptDir = Split-Path -Parent $ScriptPath
    $Root = Join-Path $ScriptDir ".." | Resolve-Path -ErrorAction Stop | ForEach-Object { $_.Path }
  }
        $file = Join-Path $DashDir $path
  # Paths
  $DataDir    = Join-Path $Root "data"
  $DashDir    = Join-Path $Root "Dashboard"
  $VsDir      = Join-Path $Root ".vscode"
  $PortfolioJson = Join-Path $DataDir "projects.json"
  $SettingsJson  = Join-Path $DataDir "settings.json"
  $BudgetsJson   = Join-Path $DataDir "budgets.json"
  $LedgerJson    = Join-Path $DataDir "ledger.json"
  $HtmlOut       = Join-Path $DashDir "NCC_Dashboard.html"

  New-Item -ItemType Directory -Force -Path $DataDir, $DashDir, $VsDir | Out-Null

  # Data Seeders
  function Initialize-NccPortfolio {
    if (Test-Path $PortfolioJson) { return }
    $projectDir = Join-Path $Root "Projects"
    $portfolio = @(
      @{ProjectName='Resonance Energy'; Category='R&D'; Path=(Join-Path $projectDir 'Resonance Energy'); Status='Active'; Progress=0; LastUpdated=(Get-Date -Format 'yyyy-MM-dd HH:mm'); Parent='' }
      @{ProjectName='MicroHydro Project'; Category='R&D'; Path=(Join-Path $projectDir 'MicroHydro Project'); Status='Active'; Progress=0; LastUpdated=(Get-Date -Format 'yyyy-MM-dd HH:mm'); Parent='Resonance Energy' }
      @{ProjectName='Big Brain Intelligence'; Category='R&D'; Path=(Join-Path $projectDir 'Big Brain Intelligence'); Status='Active'; Progress=0; LastUpdated=(Get-Date -Format 'yyyy-MM-dd HH:mm'); Parent='' }
      @{ProjectName='Future Financial'; Category='Finance'; Path=(Join-Path $projectDir 'Future Financial'); Status='Active'; Progress=0; LastUpdated=(Get-Date -Format 'yyyy-MM-dd HH:mm'); Parent='' }
      @{ProjectName='Future Fibre Optics'; Category='Infrastructure'; Path=(Join-Path $projectDir 'Future Fibre Optics'); Status='Active'; Progress=0; LastUpdated=(Get-Date -Format 'yyyy-MM-dd HH:mm'); Parent='' }
      @{ProjectName='Mammoth Media'; Category='Media'; Path=(Join-Path $projectDir 'Mammoth Media'); Status='Active'; Progress=0; LastUpdated=(Get-Date -Format 'yyyy-MM-dd HH:mm'); Parent='' }
      @{ProjectName='Off Grid Technologies'; Category='R&D'; Path=(Join-Path $projectDir 'Off Grid Technologies'); Status='Active'; Progress=0; LastUpdated=(Get-Date -Format 'yyyy-MM-dd HH:mm'); Parent='' }
      @{ProjectName='Grip And Ripp HDD'; Category='Ops'; Path=(Join-Path $projectDir 'Grip And Ripp HDD'); Status='Active'; Progress=0; LastUpdated=(Get-Date -Format 'yyyy-MM-dd HH:mm'); Parent='' }
      @{ProjectName='Butterfield Acres'; Category='Ops'; Path=(Join-Path $projectDir 'Butterfield Acres'); Status='Active'; Progress=0; LastUpdated=(Get-Date -Format 'yyyy-MM-dd HH:mm'); Parent='' }
      @{ProjectName='Phone App Builder'; Category='Software'; Path=(Join-Path $projectDir 'Phone App Builder'); Status='Active'; Progress=0; LastUpdated=(Get-Date -Format 'yyyy-MM-dd HH:mm'); Parent='' }
      @{ProjectName='Uruguay and Paraguay Dream to Reality'; Category='Strategy'; Path=(Join-Path $projectDir 'Uruguay and Paraguay Dream to Reality'); Status='Active'; Progress=0; LastUpdated=''; Parent='' }
    )
    $portfolio | ConvertTo-Json -Depth 6 | Out-File -FilePath $PortfolioJson -Encoding UTF8
    Write-Host "Seeded → $PortfolioJson"
  }
  function Initialize-NccSettings {
    if (Test-Path $SettingsJson) { return }
    $rnd = [System.Random]::new()
    $settings = [ordered]@{
      Bank = @{
        Balance       = [math]::Round(($rnd.NextDouble()*250000), 2)
        DeltaPct      = [math]::Round((($rnd.Next(-300, 300))/10.0),1)
        RunwayDays    = $rnd.Next(30, 180)
        Currency      = "USD"
        Source        = "random"
        LastRefreshed = (Get-Date).ToString("yyyy-MM-dd HH:mm")
      }
      Posture = "NORMAL"
    }
    $settings | ConvertTo-Json -Depth 6 | Out-File -FilePath $SettingsJson -Encoding UTF8
    Write-Host "Seeded → $SettingsJson"
  }
  function Initialize-NccBudgets {
    if (Test-Path $BudgetsJson) { return }
    $seed = @(
      @{ProjectName='Resonance Energy';    Cap=550000; Allocated=210000},
      @{ProjectName='MicroHydro Project';  Cap=180000; Allocated= 65000},
      @{ProjectName='Future Financial';    Cap= 90000; Allocated= 12000},
      @{ProjectName='Future Fibre Optics'; Cap=140000; Allocated= 18000}
    )
    $seed | ConvertTo-Json -Depth 6 | Out-File $BudgetsJson -Encoding UTF8
    Write-Host "Seeded → $BudgetsJson"
  }
  function Initialize-NccLedger {
    if (Test-Path $LedgerJson) { return }
    $rnd = [System.Random]::new()
    $rows = @()
    1..30 | ForEach-Object {
      $amt  = [math]::Round(($rnd.Next(-8000, 6000)),2)
      $proj = (Get-Content $PortfolioJson -Raw | ConvertFrom-Json | Get-Random).ProjectName
      $rows += @{
        ts=(Get-Date).AddDays(-$rnd.Next(0,30)).ToString("yyyy-MM-dd HH:mm")
        project=$proj; type=($amt -lt 0 ? 'expense' : 'revenue'); amount=$amt; memo='sim'
      }
    }
    $rows | Sort-Object ts | ConvertTo-Json -Depth 6 | Out-File $LedgerJson -Encoding UTF8
    Write-Host "Seeded → $LedgerJson"
  }
  function Refresh-NccSettingsRandom {
    if (!(Test-Path $SettingsJson)) { Initialize-NccSettings }
    $settings = Get-Content $SettingsJson -Raw | ConvertFrom-Json
    if ($settings.Bank.Source -eq "random") {
      $rnd = [System.Random]::new()
      $settings.Bank.Balance       = [math]::Round(($rnd.NextDouble()*250000), 2)
      $settings.Bank.DeltaPct      = [math]::Round((($rnd.Next(-300, 300))/10.0),1)
      $settings.Bank.RunwayDays    = $rnd.Next(30, 180)
      $settings.Bank.LastRefreshed = (Get-Date).ToString("yyyy-MM-dd HH:mm")
      $settings | ConvertTo-Json -Depth 6 | Out-File -FilePath $SettingsJson -Encoding UTF8
    }
  }

  # Seed all data files
  if ($Initialize) {
    Initialize-NccPortfolio
    Initialize-NccSettings
    Initialize-NccBudgets
    Initialize-NccLedger
    Write-Host "All data files initialized."
  }

  # Build dashboard HTML
  function New-NccDashboardHtml {
    if (!(Test-Path $PortfolioJson)) { throw "Missing $PortfolioJson (run -Initialize)" }
    Refresh-NccSettingsRandom
    $projectsJson = Get-Content $PortfolioJson -Raw
    $settingsJson = Get-Content $SettingsJson -Raw
    $budgetsJson  = (Test-Path $BudgetsJson) ? (Get-Content $BudgetsJson -Raw) : "[]"
    $ledgerJson   = (Test-Path $LedgerJson)  ? (Get-Content $LedgerJson -Raw)  : "[]"
    $htmlTemplate = @'
  <!doctype html><html lang="en"><head>
  <meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>NCC COPR. — AZ PRIME Command UI</title>
  <style>
  :root{--bg:#0a0f14;--fg:#e6f7ff;--muted:#9bdfff;--teal:#30c3f2;--vio:#7a5cf5;--amber:#ffb100;--red:#ff3b3b;--panel:#0e151d;--br:#14202a}
  *{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--fg);font:14px/1.5 Inter,system-ui,-apple-system,Segoe UI,Roboto}
  .header{height:25vh;display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px;padding:16px}
  .card{background:var(--panel);border:1px solid var(--br);border-radius:14px;padding:16px;box-shadow:0 0 30px #061016 inset}
  .kpi{display:flex;gap:16px;align-items:center;flex-wrap:wrap}
  .main{height:60vh;display:grid;grid-template-columns:1.2fr 1.2fr 1fr;gap:16px;padding:16px}
  .footer{height:15vh;padding:16px}
  .tile{display:flex;flex-direction:column;gap:6px}
  .row{display:flex;gap:12px;flex-wrap:wrap}
  .pill{padding:4px 10px;border-radius:999px;background:#0f1b24;color:var(--muted);border:1px solid #123040}
  .list{display:grid;grid-template-columns:repeat(5,1fr);gap:12px}
  .proj{padding:10px;border:1px solid #13202c;border-radius:10px;background:#0d151d}
  .bar{height:6px;background:#10202a;border-radius:4px;overflow:hidden}
  .bar>i{display:block;height:100%;background:linear-gradient(90deg, var(--teal), var(--vio))}
  h1,h2,h3{margin:0 0 8px 0;letter-spacing:.04em}
  #avatar{height:88px;margin-top:12px;border-radius:12px;background:
   radial-gradient(closest-side at 50% 50%, #19384b 0%, transparent 65%),
   radial-gradient(closest-side at 50% 50%, rgba(48,195,242,.25) 0%, transparent 60%);
   animation:breath 4s infinite}
  @keyframes breath{0%{box-shadow:0 0 0 0 rgba(48,195,242,.25)}50%{box-shadow:0 0 25px 6px rgba(122,92,245,.25)}100%{box-shadow:0 0 0 0 rgba(48,195,242,.25)}}
  a.btn,button.btn{background:transparent;border:1px solid #123040;color:var(--muted);padding:8px 12px;border-radius:10px;cursor:pointer}
        Write-Host "Request: $($request.Url) → $file"
  </style></head><body>

  <div class="header">
    <div class="card">
      <h2>Bank Account</h2>
      <div class="kpi">
        <div class="tile"><strong id="bal">$—</strong><small>Balance</small></div>
        <div class="tile"><span id="delta" class="pill">Δ 0%</span><small>vs Target</small></div>
        <div class="tile"><span id="runway" class="pill">— d</span><small>Runway</small></div>
      </div>
    </div>
    <div class="card">
      <h1 style="text-align:center">NCC COPR.</h1>
      <div class="kpi" style="justify-content:center">
        <span class="pill" id="posture">NORMAL</span>
        <span class="pill" id="clock"></span>
        <span class="pill">All Sites ▾</span>
        <span class="pill">Mic</span><span class="pill">＋</span><span class="pill">≡</span><span class="pill">⚙</span>
      </div>
    </div>
    <div class="card">
      <h2>Projects</h2>
      <div class="kpi">
        <span class="pill">Portfolio Loaded</span>
      </div>
    </div>
  </div>
  <div class="main">
    <div class="card">
      <h3>Dashboard Main Area</h3>
      <p>This is a minimal working dashboard. Customize as needed.</p>
    </div>
  </div>
  <div class="footer">
    <span>&copy; NCC Corp. 2026</span>
  </div>
  </body>
  </html>
  '@
    return $htmlTemplate
  }
  if ($Build) {
    $html = New-NccDashboardHtml
    $html | Out-File -FilePath $HtmlOut -Encoding UTF8
    Write-Host "Built → $HtmlOut"
  }

  # Serve dashboard
  function Test-IsAdmin {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
  }
  if ($Serve) {
    if (-not (Test-IsAdmin)) {
      Write-Host "[FATAL] You must run PowerShell as Administrator to use -Serve (HttpListener requires admin rights on Windows)."
      exit 1
    }
    try {
      $listener = New-Object System.Net.HttpListener
      $url = "http://localhost:9081/"
      $listener.Prefixes.Add($url)
      $listener.Start()
      Write-Host "Serving $DashDir on $url (Ctrl+C to stop)"
      while ($listener.IsListening) {
        try {
          $context = $listener.GetContext()
          $request = $context.Request
          $response = $context.Response
          $path = $request.Url.AbsolutePath.TrimStart('/').Replace('/', '\')
          if ([string]::IsNullOrWhiteSpace($path)) { $path = "NCC_Dashboard.html" }
          $file = Join-Path $DashDir $path
          Write-Host "Request: $($request.Url) → $file"
          if (Test-Path $file) {
            $bytes = [System.IO.File]::ReadAllBytes($file)
            $response.ContentType = if ($file -like '*.html') { 'text/html' } elseif ($file -like '*.css') { 'text/css' } elseif ($file -like '*.js') { 'application/javascript' } else { 'application/octet-stream' }
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
          } else {
            $response.StatusCode = 404
            $errorBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.OutputStream.Write($errorBytes, 0, $errorBytes.Length)
          }
          $response.OutputStream.Close()
        } catch {
          Write-Host "[ERROR] $($_.Exception.Message)"
        }
      }
      $listener.Stop()
    } catch {
      Write-Host "[FATAL] $($_.Exception.Message)"
      Write-Host "Try running PowerShell as Administrator if you see 'Access is denied' or 'Failed to listen'."
      exit 1
    }
    return
  }
        if (Test-Path $file) {
          $bytes = [System.IO.File]::ReadAllBytes($file)
          $response.ContentType = if ($file -like '*.html') { 'text/html' } elseif ($file -like '*.css') { 'text/css' } elseif ($file -like '*.js') { 'application/javascript' } else { 'application/octet-stream' }
          $response.ContentLength64 = $bytes.Length
          $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
          $response.StatusCode = 404
          $errorBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
          $response.OutputStream.Write($errorBytes, 0, $errorBytes.Length)
        }
        $response.OutputStream.Close()
      } catch {
        Write-Host "[ERROR] $($_.Exception.Message)"
      }
    }
    $listener.Stop()
  } catch {
    Write-Host "[FATAL] $($_.Exception.Message)"
    Write-Host "Try running PowerShell as Administrator if you see 'Access is denied' or 'Failed to listen'."
    exit 1
  }
  return
}
