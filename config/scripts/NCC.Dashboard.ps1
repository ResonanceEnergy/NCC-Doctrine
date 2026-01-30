
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

# NCC.Dashboard.ps1 - Minimal, robust dashboard automation script
param(
	[Parameter(Mandatory=$false)][switch]$Initialize,
	[Parameter(Mandatory=$false)][switch]$Build,
	[Parameter(Mandatory=$false)][switch]$Open
)


# --- Path Setup (portable from anywhere) ---
$ScriptRoot = $PSScriptRoot
if (-not $ScriptRoot) { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$WorkspaceRoot = Resolve-Path (Join-Path $ScriptRoot "..") | ForEach-Object { $_.Path }
$DataDir = Join-Path $WorkspaceRoot 'data'
if (-not (Test-Path $DataDir)) { New-Item -ItemType Directory -Force -Path $DataDir | Out-Null }
$DashDir = Join-Path $WorkspaceRoot 'Dashboard'
if (-not (Test-Path $DashDir)) { New-Item -ItemType Directory -Force -Path $DashDir | Out-Null }
$PortfolioJson = Join-Path $DataDir 'projects.json'
$SettingsJson  = Join-Path $DataDir 'settings.json'
$BudgetsJson   = Join-Path $DataDir 'budgets.json'
$LedgerJson    = Join-Path $DataDir 'ledger.json'
$HtmlOut       = Join-Path $DashDir 'NCC_Dashboard.html'

# --- Data Seeders ---
function Initialize-NccPortfolio {
	if (Test-Path $PortfolioJson) { return }
	$projects = @(
		@{ ProjectName = 'Resonance Energy'; Category = 'R&D'; Status = 'Active' },
		@{ ProjectName = 'MicroHydro Project'; Category = 'R&D'; Status = 'Active' }
	)
	$projects | ConvertTo-Json -Depth 6 | Out-File -FilePath $PortfolioJson -Encoding UTF8
}
function Initialize-NccSettings {
	if (Test-Path $SettingsJson) { return }
	$rnd = [System.Random]::new()
	$settings = @{ Bank = @{ Balance = [math]::Round($rnd.NextDouble()*100000,2); DeltaPct = [math]::Round($rnd.Next(-200,200)/10,1); RunwayDays = $rnd.Next(30,180); Currency = 'USD'; Source = 'random'; LastRefreshed = (Get-Date).ToString('yyyy-MM-dd HH:mm') }; Posture = 'NORMAL' }
	$settings | ConvertTo-Json -Depth 6 | Out-File -FilePath $SettingsJson -Encoding UTF8
}
function Initialize-NccBudgets {
	if (Test-Path $BudgetsJson) { return }
	$budgets = @(@{ ProjectName = 'Resonance Energy'; Cap = 50000; Allocated = 20000 })
	$budgets | ConvertTo-Json -Depth 6 | Out-File $BudgetsJson -Encoding UTF8
}
function Initialize-NccLedger {
	if (Test-Path $LedgerJson) { return }
	$rnd = [System.Random]::new()
	$rows = @()
	1..10 | ForEach-Object {
		$amt = [math]::Round($rnd.Next(-5000,5000),2)
		$rows += @{ ts = (Get-Date).AddDays(-$rnd.Next(0,30)).ToString('yyyy-MM-dd HH:mm'); project = 'Resonance Energy'; type = ($amt -lt 0 ? 'expense' : 'revenue'); amount = $amt; memo = 'sim' }
	}
	$rows | Sort-Object ts | ConvertTo-Json -Depth 6 | Out-File $LedgerJson -Encoding UTF8
}

# --- Dashboard HTML Builder ---
function New-NccDashboardHtml {
		if (!(Test-Path $PortfolioJson)) { throw "Missing $PortfolioJson (run -Initialize)" }
		$projectsJson = Get-Content $PortfolioJson -Raw
			   $html = @"
<!doctype html><html lang='en'><head>
<meta charset='utf-8'/><meta name='viewport' content='width=device-width,initial-scale=1'/>
<title>NCC Dashboard</title>
<style>
body { background: linear-gradient(135deg, #0a0f14 0%, #1a2a3a 100%); color: #e6f7ff; font-family: 'Inter', system-ui, sans-serif; margin: 0; }
.container { max-width: 1200px; margin: 0 auto; padding: 24px; }
.header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; }
.avatar { width: 80px; height: 80px; border-radius: 50%; background: radial-gradient(circle at 50% 50%, #19384b 0%, #30c3f2 100%); animation: breath 3s infinite alternate; display: flex; align-items: center; justify-content: center; font-size: 48px; }
@keyframes breath { 0% { box-shadow: 0 0 0 0 #30c3f2; } 100% { box-shadow: 0 0 30px 10px #7a5cf5; } }
.buttons { display: flex; gap: 12px; }
.btn { background: #14202a; color: #9bdfff; border: 1px solid #30c3f2; border-radius: 8px; padding: 8px 16px; cursor: pointer; font-size: 16px; transition: background 0.2s; }
.btn:hover { background: #30c3f2; color: #fff; }
.main { display: grid; grid-template-columns: 2fr 1fr; gap: 24px; }
.panel { background: #0e151d; border-radius: 12px; padding: 18px; box-shadow: 0 2px 16px #06101644; margin-bottom: 18px; }
.metrics { display: flex; gap: 24px; margin-bottom: 18px; }
.metric { background: #19384b; color: #fff; border-radius: 8px; padding: 12px 18px; min-width: 120px; text-align: center; }
.activity, .priority { margin-bottom: 18px; }
table { width: 100%; border-collapse: collapse; margin-top: 1em; }
th, td { border: 1px solid #444; padding: 8px; text-align: left; }
th { background: #222; color: #7af; }
.hammer-btn { background: linear-gradient(90deg, #ffb347, #ffcc33); color: #222; border: none; border-radius: 12px; padding: 8px 20px; font-size: 1.2rem; font-weight: bold; box-shadow: 0 4px 16px rgba(0,0,0,0.15); cursor: pointer; transition: transform 0.1s, box-shadow 0.2s; margin-left: 12px; }
.hammer-btn:active { transform: scale(0.97); box-shadow: 0 2px 8px rgba(0,0,0,0.25); }
#hammerOverlay { display:none; position:fixed; top:0; left:0; width:100vw; height:100vh; background:rgba(255,220,100,0.85); z-index:2000; justify-content:center; align-items:center; flex-direction:column; font-size:2.5rem; font-weight:bold; }
</style>
</head><body>
<div class='container'>
	<div class='header'>
		<div class='avatar' id='azAvatar'>🤖</div>
		<div class='buttons'>
			<button class='btn' onclick='refreshDashboard()'>Refresh</button>
			<button class='btn' onclick='addWidget()'>Add Widget</button>
			<button class='btn' onclick='showSettings()'>Settings</button>
			<button class='btn' onclick='triggerEmoji()'>AZ Emoji</button>
			<button class='hammer-btn' id='hammerBtn'>🔨 Hammer</button>
		</div>
	</div>
	<div class='main'>
		<div>
			<div class='panel metrics'>
				<div class='metric'><strong id='projectsCount'>0</strong><br>Projects</div>
				<div class='metric'><strong id='opsPackets'>0</strong><br>Ops Packets</div>
				<div class='metric'><strong id='alerts'>0</strong><br>Alerts</div>
				<div class='metric'><strong id='bankBalance'>$0</strong><br>Bank Account</div>
			</div>
			<div class='panel priority'>
				<h3>Priority List</h3>
				<ul id='priorityList'><li>Loading...</li></ul>
			</div>
			<div class='panel activity'>
				<h3>Timeline / Activity Feed</h3>
				<ul id='activityFeed'><li>Loading...</li></ul>
			</div>
		</div>
		<div>
			<div class='panel'>
				<h3>Projects</h3>
				<table id='projectsTable'>
					<thead><tr><th>Name</th><th>Category</th><th>Status</th></tr></thead>
					<tbody></tbody>
				</table>
			</div>
		</div>
	</div>
</div>
<div id='hammerOverlay'><span style='font-size:5rem;'>🔨</span><span>Hammer action activated!</span></div>
<script>
const projects = JSON.parse(`@($projectsJson)`);
const tbody = document.querySelector('#projectsTable tbody');
document.getElementById('projectsCount').textContent = projects.length;
projects.forEach(p => {
	const row = document.createElement('tr');
	row.innerHTML = `<td>${p.ProjectName}</td><td>${p.Category}</td><td>${p.Status}</td>`;
	tbody.appendChild(row);
});
// Placeholder for live metrics
document.getElementById('opsPackets').textContent = Math.floor(Math.random()*10+1);
document.getElementById('alerts').textContent = Math.floor(Math.random()*5);
document.getElementById('bankBalance').textContent = '$' + (Math.floor(Math.random()*100000)+1000);
// Priority list and activity feed
document.getElementById('priorityList').innerHTML = '<li>Project Alpha</li><li>Project Beta</li><li>Urgent: Ops Packet</li>';
document.getElementById('activityFeed').innerHTML = '<li>Bank account updated</li><li>New alert received</li><li>Widget added</li>';
// Button actions
function refreshDashboard() { location.reload(); }
function addWidget() { alert('Widget added!'); }
function showSettings() { alert('Settings dialog (not implemented)'); }
function triggerEmoji() { const avatar = document.getElementById('azAvatar'); avatar.textContent = '😎'; setTimeout(()=>avatar.textContent='🤖', 1200); }
document.getElementById('hammerBtn').addEventListener('click', function() {
	var overlay = document.getElementById('hammerOverlay');
	overlay.style.display = 'flex';
	setTimeout(function() {
		 overlay.style.display = 'none';
	}, 1200);
});
	</script>
	</body></html>
"@
	Initialize-NccLedger
	Write-Host 'All data files initialized.'
	return $html
}
if ($Build) {
	$html = New-NccDashboardHtml
	$html | Out-File -FilePath $HtmlOut -Encoding UTF8
	Write-Host "Built → $HtmlOut"
}
if ($Open) {
	if (!(Test-Path $HtmlOut)) {
		$null = New-NccDashboardHtml | Out-File -FilePath $HtmlOut -Encoding UTF8
	}
}
	if (Test-Path $HtmlOut) {
		Start-Process $HtmlOut
	} else {
		Write-Host "[ERROR] Dashboard HTML not found: $HtmlOut"
	}
<<<<<<< HEAD

=======
>>>>>>> c6b295e0d92d0143018dcdcb5ba8fd1affca0fae
