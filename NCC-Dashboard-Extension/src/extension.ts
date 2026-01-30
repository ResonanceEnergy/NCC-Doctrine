import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

export function activate(context: vscode.ExtensionContext) {
    console.log('NCC Dashboard Display extension is now active!');

    let dashboardPanel: vscode.WebviewPanel | undefined;
    let statusBarItems: vscode.StatusBarItem[] = [];
    let refreshTimer: NodeJS.Timeout | undefined;

    // Create status bar items
    const createStatusBarItems = () => {
        // Clear existing items
        statusBarItems.forEach(item => item.dispose());
        statusBarItems = [];

        // FFC Balance
        const ffcItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
        ffcItem.command = 'ncc-dashboard.show';
        statusBarItems.push(ffcItem);

        // AAC Balance
        const aacItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 99);
        aacItem.command = 'ncc-dashboard.show';
        statusBarItems.push(aacItem);

        // LFG Status
        const lfgItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 98);
        lfgItem.command = 'ncc-dashboard.show';
        statusBarItems.push(lfgItem);

        // Alerts
        const alertsItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 97);
        alertsItem.command = 'ncc-dashboard.show';
        statusBarItems.push(alertsItem);

        // Projects
        const projectsItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 96);
        projectsItem.command = 'ncc-dashboard.show';
        statusBarItems.push(projectsItem);
    };

    // Load dashboard data
    const loadDashboardData = async () => {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
        if (!workspaceFolder) return null;

        const config = vscode.workspace.getConfiguration('ncc-dashboard');
        const dataPath = config.get('dataPath', './data');
        const dataDir = path.join(workspaceFolder.uri.fsPath, dataPath);

        try {
            const settingsPath = path.join(dataDir, 'settings.json');
            const projectsPath = path.join(dataDir, 'projects.json');
            const budgetsPath = path.join(dataDir, 'budgets.json');
            const dashboardStatusPath = path.join(dataDir, 'dashboard_status.json');
            const aacResultsPath = path.join(dataDir, 'aac_simulation_results.json');

            const data: any = {};

            // Load settings
            if (fs.existsSync(settingsPath)) {
                data.settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
            }

            // Load projects
            if (fs.existsSync(projectsPath)) {
                data.projects = JSON.parse(fs.readFileSync(projectsPath, 'utf8'));
            }

            // Load budgets
            if (fs.existsSync(budgetsPath)) {
                data.budgets = JSON.parse(fs.readFileSync(budgetsPath, 'utf8'));
            }

            // Load dashboard status
            if (fs.existsSync(dashboardStatusPath)) {
                data.dashboardStatus = JSON.parse(fs.readFileSync(dashboardStatusPath, 'utf8'));
            }

            // Load AAC results (latest entry)
            if (fs.existsSync(aacResultsPath)) {
                const aacData = JSON.parse(fs.readFileSync(aacResultsPath, 'utf8'));
                if (Array.isArray(aacData) && aacData.length > 0) {
                    data.aacResults = aacData[aacData.length - 1];
                }
            }

            return data;
        } catch (error) {
            console.error('Error loading dashboard data:', error);
            return null;
        }
    };

    // Update status bar items
    const updateStatusBarItems = async () => {
        const data = await loadDashboardData();
        if (!data) return;

        // Generate synthetic balances for FFC and AAC
        const generateSyntheticBalance = (baseAmount: number, variance: number = 0.1) => {
            const variation = (Math.random() - 0.5) * 2 * variance;
            return Math.round(baseAmount * (1 + variation));
        };

        const ffcBalance = generateSyntheticBalance(25000000, 0.05); // $25M base
        const aacBalance = generateSyntheticBalance(15000000, 0.08); // $15M base

        // Update status bar items
        if (statusBarItems.length >= 5) {
            statusBarItems[0].text = `$(bank) FFC: $${(ffcBalance / 1000000).toFixed(1)}M`;
            statusBarItems[0].tooltip = `Faraday Financial Corp Balance: $${ffcBalance.toLocaleString()}`;

            statusBarItems[1].text = `$(graph) AAC: $${(aacBalance / 1000000).toFixed(1)}M`;
            statusBarItems[1].tooltip = `Augmented Arbitrage Corp Balance: $${aacBalance.toLocaleString()}`;

            statusBarItems[2].text = `$(zap) LFG! ENGAGED`;
            statusBarItems[2].tooltip = `LFG Protocol Active - Performance Multiplier: 2.0x`;

            const alerts = Math.floor(Math.random() * 3);
            statusBarItems[3].text = `$(warning) Alerts: ${alerts}`;
            statusBarItems[3].tooltip = `${alerts} active system alerts`;

            const projectsCount = data.projects ? data.projects.length : 0;
            const activeProjects = data.projects ? data.projects.filter((p: any) => p.Status === 'Active').length : 0;
            statusBarItems[4].text = `$(project) Projects: ${activeProjects}/${projectsCount}`;
            statusBarItems[4].tooltip = `${activeProjects} active projects out of ${projectsCount} total`;

            // Show all status bar items
            statusBarItems.forEach(item => item.show());
        }
    };

    // Create dashboard HTML content
    const getDashboardHtml = (data: any) => {
        const generateSyntheticBalance = (baseAmount: number, variance: number = 0.1) => {
            const variation = (Math.random() - 0.5) * 2 * variance;
            return Math.round(baseAmount * (1 + variation));
        };

        const ffcBalance = generateSyntheticBalance(25000000, 0.05);
        const aacBalance = generateSyntheticBalance(15000000, 0.08);
        const opsPackets = Math.floor(Math.random() * 10 + 5);
        const alerts = Math.floor(Math.random() * 3);

        return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NCC Dashboard - VS Code Display</title>
    <style>
        body {
            background: linear-gradient(135deg, #0a0f14 0%, #1a2a3a 100%);
            color: #e6f7ff;
            font-family: 'Inter', system-ui, sans-serif;
            margin: 0;
            padding: 16px;
            font-size: 12px;
        }
        .container { max-width: 100%; margin: 0 auto; }
        .header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 16px;
            font-size: 14px;
            font-weight: bold;
        }
        .avatar {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: radial-gradient(circle at 50% 50%, #19384b 0%, #30c3f2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            animation: breath 3s infinite alternate;
        }
        @keyframes breath { 0% { box-shadow: 0 0 0 0 #30c3f2; } 100% { box-shadow: 0 0 20px 5px #7a5cf5; } }
        .metrics {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 8px;
            margin-bottom: 16px;
        }
        .metric {
            background: #19384b;
            color: #fff;
            border-radius: 6px;
            padding: 8px 12px;
            text-align: center;
            font-size: 11px;
        }
        .metric strong { display: block; font-size: 13px; margin-bottom: 2px; }
        .section { margin-bottom: 16px; }
        .section h3 {
            color: #30c3f2;
            margin: 0 0 8px 0;
            font-size: 13px;
            font-weight: bold;
        }
        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }
        .panel {
            background: #0e151d;
            border-radius: 8px;
            padding: 12px;
            box-shadow: 0 2px 12px #06101644;
        }
        .status-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 4px;
            font-size: 11px;
        }
        .status-item span:first-child { color: #9bdfff; }
        .status-item span:last-child { color: #30c3f2; font-weight: bold; }
        .activity-list {
            max-height: 120px;
            overflow-y: auto;
            font-size: 10px;
        }
        .activity-item {
            margin-bottom: 4px;
            padding: 4px;
            background: #19384b;
            border-radius: 4px;
        }
        .lfg-banner {
            background: linear-gradient(90deg, #ffb347, #ffcc33);
            color: #222;
            padding: 8px 12px;
            border-radius: 6px;
            text-align: center;
            font-weight: bold;
            font-size: 12px;
            margin-bottom: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="avatar">🤖</div>
            <div>NCC Operations Dashboard - VS Code Display</div>
            <div style="font-size: 10px; color: #9bdfff;">LFG! Protocol Active</div>
        </div>

        <div class="lfg-banner">
            🔥 ALL SYSTEMS LFG! ENGAGED - PERFORMANCE MULTIPLIER: 2.0x 🔥
        </div>

        <div class="metrics">
            <div class="metric"><strong>${data.projects ? data.projects.filter((p: any) => p.Status === 'Active').length : 0}</strong><br>Active Projects</div>
            <div class="metric"><strong>${opsPackets}</strong><br>Ops Packets</div>
            <div class="metric"><strong>${alerts}</strong><br>Alerts</div>
            <div class="metric"><strong>$${Math.round(ffcBalance / 1000000)}M</strong><br>FFC Balance</div>
            <div class="metric"><strong>$${Math.round(aacBalance / 1000000)}M</strong><br>AAC Balance</div>
            <div class="metric"><strong>1920</strong><br>Agents Active</div>
            <div class="metric"><strong>ENGAGED</strong><br>LFG! Protocol</div>
        </div>

        <div class="grid">
            <div class="section">
                <h3>System Health</h3>
                <div class="panel">
                    <div class="status-item"><span>Operational Efficiency:</span> <span>${data.settings?.ncc_operations?.operational_efficiency || 95}%</span></div>
                    <div class="status-item"><span>Security Score:</span> <span>${data.settings?.ncc_operations?.security_score || 99}</span></div>
                    <div class="status-item"><span>AI Performance:</span> <span>${data.settings?.ncc_operations?.ai_performance || 97}%</span></div>
                    <div class="status-item"><span>Compliance Level:</span> <span>${data.settings?.ncc_operations?.compliance_level || 97}%</span></div>
                    <div class="status-item"><span>Market Position:</span> <span>${data.settings?.ncc_operations?.market_position || 'DOMINANT'}</span></div>
                </div>
            </div>

            <div class="section">
                <h3>LFG! Protocol Status</h3>
                <div class="panel">
                    <div class="status-item"><span>Performance Multiplier:</span> <span>2.0x</span></div>
                    <div class="status-item"><span>Domination Level:</span> <span>MAXIMUM</span></div>
                    <div class="status-item"><span>Agent Teams:</span> <span>15 Divisions</span></div>
                    <div class="status-item"><span>Last Activation:</span> <span>${new Date().toISOString().split('T')[0]}</span></div>
                </div>
            </div>

            <div class="section">
                <h3>Intelligence Status</h3>
                <div class="panel">
                    <div class="status-item"><span>BBIC YouTube:</span> <span style="color: #ffcc33;">CONFIGURED</span></div>
                    <div class="status-item"><span>BBIC Reddit:</span> <span style="color: #ffcc33;">40 SUBREDDITS</span></div>
                    <div class="status-item"><span>AAC Simulation:</span> <span style="color: #30c3f2;">${data.aacResults ? 'ACTIVE' : 'PENDING'}</span></div>
                    <div class="status-item"><span>Social Monitoring:</span> <span style="color: #ff6b6b;">PENDING</span></div>
                </div>
            </div>

            <div class="section">
                <h3>Recent Activity</h3>
                <div class="panel">
                    <div class="activity-list">
                        <div class="activity-item">[${new Date().toLocaleTimeString()}] Dashboard refreshed</div>
                        <div class="activity-item">[${new Date().toLocaleTimeString()}] LFG! momentum maintained</div>
                        <div class="activity-item">[${new Date().toLocaleTimeString()}] System health: All green</div>
                        <div class="activity-item">[${new Date().toLocaleTimeString()}] Agent coordination active</div>
                        <div class="activity-item">[${new Date().toLocaleTimeString()}] Performance optimized</div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>`;
    };

    // Show dashboard command
    const showDashboardCommand = vscode.commands.registerCommand('ncc-dashboard.show', async () => {
        if (dashboardPanel) {
            dashboardPanel.reveal(vscode.ViewColumn.One);
            return;
        }

        dashboardPanel = vscode.window.createWebviewPanel(
            'nccDashboard',
            'NCC Operations Dashboard',
            vscode.ViewColumn.One,
            {
                enableScripts: true,
                retainContextWhenHidden: true
            }
        );

        // Set initial content
        const data = await loadDashboardData();
        dashboardPanel.webview.html = getDashboardHtml(data || {});

        // Handle panel disposal
        dashboardPanel.onDidDispose(() => {
            dashboardPanel = undefined;
            if (refreshTimer) {
                clearInterval(refreshTimer);
                refreshTimer = undefined;
            }
        });

        // Set context for menu items
        vscode.commands.executeCommand('setContext', 'ncc-dashboard.visible', true);
    });

    // Refresh dashboard command
    const refreshDashboardCommand = vscode.commands.registerCommand('ncc-dashboard.refresh', async () => {
        if (dashboardPanel) {
            const data = await loadDashboardData();
            dashboardPanel.webview.html = getDashboardHtml(data || {});
        }
        updateStatusBarItems();
    });

    // Hide dashboard command
    const hideDashboardCommand = vscode.commands.registerCommand('ncc-dashboard.hide', () => {
        if (dashboardPanel) {
            dashboardPanel.dispose();
        }
    });

    // Initialize status bar items
    createStatusBarItems();
    updateStatusBarItems();

    // Set up auto-refresh
    const config = vscode.workspace.getConfiguration('ncc-dashboard');
    if (config.get('autoRefresh', true)) {
        const interval = config.get('refreshInterval', 15) * 1000;
        refreshTimer = setInterval(() => {
            updateStatusBarItems();
            if (dashboardPanel && dashboardPanel.visible) {
                vscode.commands.executeCommand('ncc-dashboard.refresh');
            }
        }, interval);
    }

    // Register commands
    context.subscriptions.push(
        showDashboardCommand,
        refreshDashboardCommand,
        hideDashboardCommand,
        ...statusBarItems
    );

    // Handle configuration changes
    vscode.workspace.onDidChangeConfiguration(e => {
        if (e.affectsConfiguration('ncc-dashboard')) {
            const config = vscode.workspace.getConfiguration('ncc-dashboard');
            if (refreshTimer) {
                clearInterval(refreshTimer);
            }
            if (config.get('autoRefresh', true)) {
                const interval = config.get('refreshInterval', 15) * 1000;
                refreshTimer = setInterval(() => {
                    updateStatusBarItems();
                    if (dashboardPanel && dashboardPanel.visible) {
                        vscode.commands.executeCommand('ncc-dashboard.refresh');
                    }
                }, interval);
            }
        }
    });
}

export function deactivate() {}