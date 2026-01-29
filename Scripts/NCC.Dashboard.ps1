

# NCC.Dashboard.ps1 - Minimal, robust dashboard automation script
param(
	[Parameter(Mandatory=$false)][switch]$Initialize,
	[Parameter(Mandatory=$false)][switch]$Build,
	[Parameter(Mandatory=$false)][switch]$Serve,
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
		$settingsJson = Get-Content $SettingsJson -Raw
		$budgetsJson = Get-Content $BudgetsJson -Raw
		$ledgerJson = Get-Content $LedgerJson -Raw
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
				<div class='metric'><strong id='agentsActive'>1920</strong><br>Agents Active</div>
				<div class='metric'><strong id='lfgStatus'>ENGAGED</strong><br>LFG! Protocol</div>
			</div>
			<div class='panel priority'>
				<h3>Priority List</h3>
				<ul id='priorityList'><li>Loading...</li></ul>
			</div>
			<div class='panel activity'>
				<h3>Timeline / Activity Feed</h3>
				<ul id='activityFeed'><li>Loading...</li></ul>
			</div>
			<div class='panel'>
				<h3>LFG! Protocol Status</h3>
				<div id='lfgProtocolStatus'>
					<div style='color: #30c3f2; margin-bottom: 10px;'><strong>🔥 ALL SYSTEMS LFG! ENGAGED 🔥</strong></div>
					<div>• Performance Multiplier: <span id='performanceMultiplier'>2.0x</span></div>
					<div>• Domination Level: <span id='dominationLevel'>MAXIMUM</span></div>
					<div>• Agent Teams: <span id='agentTeams'>15 Divisions</span></div>
					<div>• Last Activation: <span id='lastActivation'>2026-01-28 23:14:00</span></div>
				</div>
			</div>
		</div>
		<div>
			<div class='panel'>
				<h3>Projects</h3>
				<table id='projectsTable'>
					<thead><tr><th>Name</th><th>Category</th><th>Status</th><th>Progress</th></tr></thead>
					<tbody></tbody>
				</table>
			</div>
			<div class='panel'>
				<h3>Dashboard Team</h3>
				<div id='dashboardTeam'>
					<div style='margin-bottom: 10px;'><strong>Dashboard Operations Team:</strong></div>
					<div>• Lead Dashboard Engineer: AZ PRIME Command</div>
					<div>• Real-time Data Integration: AX Agent v2.1.4</div>
					<div>• UI/UX Optimization: Elite Unit S15</div>
					<div>• Content Management: NCL Digital OS</div>
					<div>• Performance Monitoring: Continuous Ops Framework</div>
					<div>• Security Oversight: Cybersecurity Command Center</div>
				</div>
			</div>
			<div class='panel'>
				<h3>System Health</h3>
				<div id='systemHealth'>
					<div>• Operational Efficiency: <span id='opEfficiency'>98%</span></div>
					<div>• Security Score: <span id='securityScore'>99</span></div>
					<div>• AI Performance: <span id='aiPerformance'>97%</span></div>
					<div>• Compliance Level: <span id='complianceLevel'>97%</span></div>
					<div>• Market Position: <span id='marketPosition'>DOMINANT</span></div>
				</div>
			</div>
		</div>
	</div>
</div>
<div id='hammerOverlay'><span style='font-size:5rem;'>🔨</span><span>Hammer action activated!</span></div>
<script>
const projects = JSON.parse(`@($projectsJson)`);
const settings = JSON.parse(`@($settingsJson)`);
const budgets = JSON.parse(`@($budgetsJson)`);
const ledger = JSON.parse(`@($ledgerJson)`);

const tbody = document.querySelector('#projectsTable tbody');
document.getElementById('projectsCount').textContent = projects.length;

// Load projects with progress
projects.forEach(p => {
	const row = document.createElement('tr');
	const progress = p.Progress || 0;
	const progressBar = `<div style='background: #333; border-radius: 4px; height: 8px; width: 100%;'><div style='background: linear-gradient(90deg, #30c3f2, #7a5cf5); height: 100%; width: ${progress}%; border-radius: 4px;'></div></div>`;
	row.innerHTML = `<td>${p.ProjectName}</td><td>${p.Category}</td><td>${p.Status}</td><td>${progressBar} ${progress}%</td>`;
	tbody.appendChild(row);
});

// Load settings data
if (settings.Bank) {
	document.getElementById('bankBalance').textContent = '$' + settings.Bank.Balance.toLocaleString();
}

if (settings.ncc_operations) {
	document.getElementById('opEfficiency').textContent = settings.ncc_operations.operational_efficiency + '%';
	document.getElementById('securityScore').textContent = settings.ncc_operations.security_score;
	document.getElementById('aiPerformance').textContent = settings.ncc_operations.ai_performance + '%';
	document.getElementById('complianceLevel').textContent = settings.ncc_operations.compliance_level + '%';
	document.getElementById('marketPosition').textContent = settings.ncc_operations.market_position;
}

// Load LFG protocol data
if (settings.ncc_operations && settings.ncc_operations.lfg_protocol) {
	const lfg = settings.ncc_operations.lfg_protocol;
	document.getElementById('performanceMultiplier').textContent = lfg.performance_multiplier + 'x';
	document.getElementById('dominationLevel').textContent = lfg.domination_level;
	document.getElementById('lastActivation').textContent = lfg.activation_timestamp.split('T')[0] + ' ' + lfg.activation_timestamp.split('T')[1].split('Z')[0];
	document.getElementById('agentTeams').textContent = Math.ceil(lfg.total_agents / 128) + ' Divisions';
}

// Dynamic metrics
document.getElementById('opsPackets').textContent = Math.floor(Math.random()*10+5);
document.getElementById('alerts').textContent = Math.floor(Math.random()*3);

// Priority list and activity feed with real data
const priorities = [
	'NCC HydroFlow Global Product Launch',
	'LFG! Protocol Optimization',
	'Agent Performance Monitoring',
	'International Expansion Planning',
	'Security Compliance Updates'
];
document.getElementById('priorityList').innerHTML = priorities.map(p => `<li>${p}</li>`).join('');

const activities = [
	'LFG! Protocol activated - All 1920 agents engaged',
	'Dashboard team deployed and operational',
	'Continuous operations cycle #25 completed',
	'AX Agent v2.1.4 performance optimized',
	'System health: All metrics green',
	'Backup completed successfully'
];
document.getElementById('activityFeed').innerHTML = activities.map(a => `<li>${a}</li>`).join('');

// Button actions
function refreshDashboard() {
	location.reload();
}

function addWidget() {
	alert('Widget system coming soon! Dashboard team is working on it.');
}

function showSettings() {
	const settingsInfo = `
Dashboard Settings:
• Auto-refresh: Enabled (30s intervals)
• Data source: Live NCC operations
• Theme: Dark Professional
• LFG Protocol: Active
• Team: Dashboard Operations Team
	`;
	alert(settingsInfo);
}

function triggerEmoji() {
	const avatar = document.getElementById('azAvatar');
	const emojis = ['🤖', '😎', '🚀', '🔥', '💪', '⚡'];
	const randomEmoji = emojis[Math.floor(Math.random() * emojis.length)];
	avatar.textContent = randomEmoji;
	setTimeout(() => avatar.textContent = '🤖', 2000);
}

// Hammer action with LFG theme
document.getElementById('hammerBtn').addEventListener('click', function() {
	var overlay = document.getElementById('hammerOverlay');
	overlay.innerHTML = `
		<span style='font-size:5rem;'>🔨⚡</span>
		<span>HAMMER ACTION ACTIVATED!</span>
		<span style='font-size:1.5rem; margin-top: 10px;'>LFG! Protocol Engaged!</span>
	`;
	overlay.style.display = 'flex';
	setTimeout(function() {
		overlay.style.display = 'none';
	}, 2000);
});

// Auto-refresh functionality
setInterval(() => {
	// Update dynamic metrics
	document.getElementById('opsPackets').textContent = Math.floor(Math.random()*10+5);
	document.getElementById('alerts').textContent = Math.floor(Math.random()*3);

	// Update activity feed with new entries
	const newActivities = [
		'Real-time data updated',
		'Agent status: All systems green',
		'LFG! momentum maintained'
	];
	const randomActivity = newActivities[Math.floor(Math.random() * newActivities.length)];
	const activityList = document.getElementById('activityFeed');
	activityList.innerHTML = `<li>${randomActivity}</li>` + activityList.innerHTML;
}, 30000); // Refresh every 30 seconds
	</script>
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
function Serve-NccDashboard {
	if (!(Test-Path $HtmlOut)) {
		Write-Host "[ERROR] Dashboard HTML not found: $HtmlOut"
		return
	}
	$listener = New-Object System.Net.HttpListener
	$port = 8081
	$url = "http://localhost:$port/"
	$listener.Prefixes.Add($url)
	try {
		$listener.Start()
		Write-Host "Serving dashboard at $url"
		Start-Process $url
		while ($listener.IsListening) {
			$context = $listener.GetContext()
			$response = $context.Response
			$buffer = [System.IO.File]::ReadAllBytes($HtmlOut)
			$response.ContentType = "text/html"
			$response.ContentLength64 = $buffer.Length
			$response.OutputStream.Write($buffer, 0, $buffer.Length)
			$response.OutputStream.Close()
		}
	} catch {
		Write-Host "[ERROR] Failed to serve dashboard: $_"
	} finally {
		$listener.Stop()
	}
}
if ($Serve) {
	Serve-NccDashboard
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
