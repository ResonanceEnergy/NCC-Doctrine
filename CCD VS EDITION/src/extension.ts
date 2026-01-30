// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {

	// Use the console to output diagnostic information (console.log) and errors (console.error)
	// This line of code will only be executed once when your extension is activated
	console.log('Congratulations, your extension "ncc-command-center-dashboard" is now active!');

	// Track the current panel
	let currentPanel: vscode.WebviewPanel | undefined = undefined;

	// The command has been defined in the package.json file
	// Now provide the implementation of the command with registerCommand
	// The commandId parameter must match the command field in package.json
	const disposable = vscode.commands.registerCommand('ncc-command-center-dashboard.openDashboard', () => {
		const columnToShowIn = vscode.window.activeTextEditor
			? vscode.window.activeTextEditor.viewColumn
			: undefined;

		if (currentPanel) {
			currentPanel.reveal(columnToShowIn);
		} else {
			currentPanel = vscode.window.createWebviewPanel(
				'nccCommandCenter',
				'NCC Command Center Dashboard',
				columnToShowIn || vscode.ViewColumn.One,
				{
					enableScripts: true
				}
			);

			currentPanel.webview.html = getWebviewContent();

			currentPanel.onDidDispose(
				() => {
					currentPanel = undefined;
				},
				null,
				context.subscriptions
			);
		}
	});

	context.subscriptions.push(disposable);
}

// This method is called when your extension is deactivated
export function deactivate() {}

function getWebviewContent() {
	return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NCC Command Center Dashboard</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
        }
        .summary {
            display: flex;
            justify-content: space-around;
            margin-bottom: 20px;
        }
        .summary-item {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            text-align: center;
        }
        .departments {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        .department-card {
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        .department-card:hover {
            transform: translateY(-2px);
        }
        .status {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            margin-right: 10px;
        }
        .status.normal { background-color: #4CAF50; }
        .status.warning { background-color: #FF9800; }
        .status.critical { background-color: #F44336; }
        .tasks {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .task-list {
            list-style: none;
            padding: 0;
        }
        .task-item {
            padding: 10px;
            border-bottom: 1px solid #eee;
            display: flex;
            justify-content: space-between;
        }
        .task-item:last-child {
            border-bottom: none;
        }
        .task-status {
            font-weight: bold;
        }
        .pending { color: #FF9800; }
        .completed { color: #4CAF50; }
        .in-progress { color: #2196F3; }
    </style>
</head>
<body>
    <div class="header">
        <h1>NCC Command Center Dashboard</h1>
        <p>Real-time monitoring of corporate departments</p>
    </div>
    
    <div class="summary">
        <div class="summary-item">
            <h3>Total Departments</h3>
            <p id="total-depts">24</p>
        </div>
        <div class="summary-item">
            <h3>Active Tasks</h3>
            <p id="active-tasks">0</p>
        </div>
        <div class="summary-item">
            <h3>Alerts</h3>
            <p id="alerts">0</p>
        </div>
    </div>
    
    <h2>Department Monitoring</h2>
    <div class="departments" id="departments-container">
        <!-- Departments will be populated by JS -->
    </div>
    
    <h2>Task Management</h2>
    <div class="tasks">
        <ul class="task-list" id="task-list">
            <!-- Tasks will be populated by JS -->
        </ul>
    </div>

    <script>
        // Department data
        const departments = [
            'Human Resources', 'Information Technology', 'Finance', 'Marketing', 'Sales',
            'Operations', 'Legal', 'Research & Development', 'Customer Service', 'Supply Chain',
            'Quality Assurance', 'Public Relations', 'Executive', 'Security', 'Facilities',
            'Procurement', 'Compliance', 'Training', 'Analytics', 'Strategy', 'Innovation',
            'Sustainability', 'Risk Management', 'Corporate Communications'
        ];

        let tasks = [
            { id: 1, title: 'Review Q4 Budget', department: 'Finance', status: 'pending' },
            { id: 2, title: 'Update Security Policies', department: 'Security', status: 'in-progress' },
            { id: 3, title: 'Launch Marketing Campaign', department: 'Marketing', status: 'completed' },
            { id: 4, title: 'Conduct Employee Training', department: 'Training', status: 'pending' },
            { id: 5, title: 'Audit Compliance Reports', department: 'Compliance', status: 'in-progress' }
        ];

        function getRandomStatus() {
            const statuses = ['normal', 'warning', 'critical'];
            return statuses[Math.floor(Math.random() * statuses.length)];
        }

        function updateDashboard() {
            // Update departments
            const container = document.getElementById('departments-container');
            container.innerHTML = '';
            
            let alerts = 0;
            departments.forEach(dept => {
                const status = getRandomStatus();
                if (status === 'critical' || status === 'warning') alerts++;
                
                const card = document.createElement('div');
                card.className = 'department-card';
                card.innerHTML = \`
                    <h4><span class="status \${status}"></span>\${dept}</h4>
                    <p>Tasks: \${Math.floor(Math.random() * 10)}</p>
                    <p>Alerts: \${status === 'normal' ? 0 : Math.floor(Math.random() * 3) + 1}</p>
                \`;
                container.appendChild(card);
            });
            
            // Update tasks
            const taskList = document.getElementById('task-list');
            taskList.innerHTML = '';
            
            let activeTasks = 0;
            tasks.forEach(task => {
                if (task.status !== 'completed') activeTasks++;
                
                const item = document.createElement('li');
                item.className = 'task-item';
                item.innerHTML = \`
                    <div>
                        <strong>\${task.title}</strong> - \${task.department}
                    </div>
                    <span class="task-status \${task.status.replace(' ', '-')}">\${task.status}</span>
                \`;
                taskList.appendChild(item);
            });
            
            // Update summary
            document.getElementById('active-tasks').textContent = activeTasks;
            document.getElementById('alerts').textContent = alerts;
        }

        // Initial load
        updateDashboard();
        
        // Update every 5 seconds
        setInterval(updateDashboard, 5000);
    </script>
</body>
</html>`;
}
