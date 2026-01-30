const express = require('express');
const WebSocket = require('ws');
const path = require('path');
const fs = require('fs');
const os = require('os');

class NCCDisplayServer {
    constructor(port = 3000, refreshRate = 100) {  // Enhanced refresh rate
        this.port = port;
        this.refreshRate = refreshRate;
        this.app = express();
        this.metrics = {};
        this.clients = new Set();
        this.lastMetricsUpdate = Date.now();
        this.messageQueue = [];
        this.isProcessingQueue = false;
        this.binaryMode = true;  // Enable binary WebSocket payloads
        this.compressionEnabled = true;  // Enable payload compression

        this.setupMiddleware();
        this.setupRoutes();
        this.setupWebSocketServer();
        this.startMetricsCollection();
        this.startPerformanceMonitoring();
    }

    setupMiddleware() {
        // CORS middleware
        this.app.use((req, res, next) => {
            res.header('Access-Control-Allow-Origin', '*');
            res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
            res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
            res.header('Cache-Control', 'no-cache, no-store, must-revalidate');
            res.header('Pragma', 'no-cache');
            res.header('Expires', '0');
            next();
        });

        // Static file serving
        this.app.use(express.static(path.join(__dirname, 'Dashboard')));
        this.app.use(express.static(path.join(__dirname, 'public')));
        this.app.use(express.static(path.join(__dirname, 'assets')));

        // JSON parsing
        this.app.use(express.json());
    }

    setupRoutes() {
        // Main dashboard route
        this.app.get('/', (req, res) => {
            res.sendFile(path.join(__dirname, 'Dashboard', 'NCC_Ultimate_Display.html'));
        });

        // Metrics API endpoint
        this.app.get('/metrics', (req, res) => {
            res.json(this.getMetrics());
        });

        // Health check endpoint
        this.app.get('/health', (req, res) => {
            res.json({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                uptime: process.uptime(),
                memory: process.memoryUsage(),
                clients: this.clients.size
            });
        });

        // System info endpoint
        this.app.get('/system', (req, res) => {
            res.json({
                platform: os.platform(),
                arch: os.arch(),
                cpus: os.cpus().length,
                totalMemory: os.totalmem(),
                freeMemory: os.freemem(),
                uptime: os.uptime(),
                loadAverage: os.loadavg(),
                networkInterfaces: os.networkInterfaces()
            });
        });

        // WebSocket upgrade handling
        this.app.get('/ws', (req, res) => {
            // WebSocket handshake
            if (req.headers.upgrade && req.headers.upgrade.toLowerCase() === 'websocket') {
                // This would be handled by the WebSocket server
                res.status(400).send('WebSocket connection required');
            } else {
                res.status(400).send('WebSocket upgrade required');
            }
        });
    }

    setupWebSocketServer() {
        // Create WebSocket server with enhanced performance settings
        this.wss = new WebSocket.Server({
            server: this.server,
            perMessageDeflate: this.compressionEnabled,
            maxPayload: 1024 * 1024, // 1MB max payload
            backlog: 1000 // Connection backlog
        });

        this.wss.on('connection', (ws, req) => {
            console.log(`New WebSocket connection from ${req.socket.remoteAddress}`);
            this.clients.add(ws);

            // Send initial metrics immediately
            this.sendMetricsToClient(ws);

            ws.on('message', (message) => {
                try {
                    const data = JSON.parse(message.toString());
                    this.handleClientMessage(ws, data);
                } catch (error) {
                    console.error('Invalid WebSocket message:', error);
                }
            });

            ws.on('close', () => {
                console.log('WebSocket connection closed');
                this.clients.delete(ws);
            });

            ws.on('error', (error) => {
                console.error('WebSocket error:', error);
                this.clients.delete(ws);
            });

            // Implement ping/pong for connection health
            ws.isAlive = true;
            ws.on('pong', () => {
                ws.isAlive = true;
            });
        });

        // Connection health check every 30 seconds
        setInterval(() => {
            this.wss.clients.forEach((ws) => {
                if (!ws.isAlive) {
                    console.log('Terminating dead WebSocket connection');
                    return ws.terminate();
                }
                ws.isAlive = false;
                ws.ping();
            });
        }, 30000);
    }

    handleClientMessage(ws, data) {
        // Handle client requests for specific metrics or actions
        switch (data.type) {
            case 'subscribe':
                // Handle metric subscriptions
                console.log(`Client subscribed to: ${data.metrics}`);
                break;
            case 'unsubscribe':
                // Handle unsubscriptions
                console.log(`Client unsubscribed from: ${data.metrics}`);
                break;
            case 'ping':
                // Respond to ping
                ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
                break;
            default:
                console.log('Unknown message type:', data.type);
        }
    }

    sendMetricsToClient(ws) {
        if (ws.readyState === WebSocket.OPEN) {
            const metrics = this.getMetrics();
            const payload = this.binaryMode ?
                Buffer.from(JSON.stringify(metrics)) :
                JSON.stringify(metrics);

            ws.send(payload, { binary: this.binaryMode });
        }
    }

    broadcastMetrics() {
        const metrics = this.getMetrics();
        const payload = this.binaryMode ?
            Buffer.from(JSON.stringify(metrics)) :
            JSON.stringify(metrics);

        this.clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(payload, { binary: this.binaryMode });
            }
        });
    }

    startPerformanceMonitoring() {
        // Monitor server performance
        setInterval(() => {
            const memUsage = process.memoryUsage();
            const cpuUsage = this.getCPUUsage();

            if (memUsage.heapUsed > 500 * 1024 * 1024) { // 500MB
                console.warn('High memory usage detected:', memUsage.heapUsed);
            }

            if (cpuUsage > 80) {
                console.warn('High CPU usage detected:', cpuUsage);
            }
        }, 5000); // Check every 5 seconds
    }

    getMetrics() {
        // Collect real-time system metrics
        const systemMetrics = {
            CPU: {
                Value: this.getCPUUsage(),
                Status: this.getStatus(this.getCPUUsage(), { warning: 70, critical: 85 }),
                Unit: '%'
            },
            Memory: {
                Value: Math.round((1 - os.freemem() / os.totalmem()) * 100),
                Status: this.getStatus(Math.round((1 - os.freemem() / os.totalmem()) * 100), { warning: 75, critical: 90 }),
                Unit: '%'
            },
            Disk: {
                Value: 78, // Placeholder - would need disk monitoring
                Status: 'good',
                Unit: '%'
            },
            Network: {
                Value: Math.round(os.loadavg()[0] * 10), // Simplified network load
                Status: 'good',
                Unit: 'Mbps'
            }
        };

        // Agent metrics (would integrate with actual agent system)
        const agentMetrics = {
            ActiveAgents: {
                Value: 1920,
                Status: 'excellent',
                Unit: 'agents'
            },
            Efficiency: {
                Value: 99.9,
                Status: 'excellent',
                Unit: '%'
            },
            PerformanceGain: {
                Value: '2-10x',
                Status: 'excellent',
                Unit: 'multiplier'
            }
        };

        // Financial metrics (would integrate with financial systems)
        const financialMetrics = {
            Revenue: {
                Value: '$2.1M',
                Status: 'excellent',
                Unit: '/day'
            },
            Growth: {
                Value: 23.0,
                Status: 'excellent',
                Unit: '%'
            },
            PnL: {
                Value: '$45M',
                Status: 'excellent',
                Unit: 'total'
            }
        };

        // Communication metrics
        const communicationMetrics = {
            MessagesPerHour: {
                Value: 1.2,
                Status: 'good',
                Unit: 'K/hr'
            },
            SuccessRate: {
                Value: 99.0,
                Status: 'excellent',
                Unit: '%'
            },
            ActiveConnections: {
                Value: 3340,
                Status: 'good',
                Unit: 'connections'
            }
        };

        // Performance metrics
        const performanceMetrics = {
            Latency: {
                Value: '< 50ms',
                Status: 'excellent',
                Unit: 'response'
            },
            Throughput: {
                Value: 5000,
                Status: 'excellent',
                Unit: 'tps'
            },
            ErrorRate: {
                Value: 0.01,
                Status: 'excellent',
                Unit: '%'
            },
            Availability: {
                Value: 99.99,
                Status: 'excellent',
                Unit: '%'
            }
        };

        // Alert metrics
        const alertMetrics = {
            Critical: {
                Value: 3,
                Status: 'critical',
                Unit: 'alerts'
            },
            Warning: {
                Value: 12,
                Status: 'warning',
                Unit: 'alerts'
            },
            Info: {
                Value: 25,
                Status: 'good',
                Unit: 'alerts'
            }
        };

        return {
            System: systemMetrics,
            Agents: agentMetrics,
            Financial: financialMetrics,
            Communication: communicationMetrics,
            Performance: performanceMetrics,
            Alerts: alertMetrics,
            Timestamp: new Date().toISOString(),
            RefreshRate: this.refreshRate,
            ServerUptime: process.uptime(),
            ConnectedClients: this.clients.size
        };
    }

    getCPUUsage() {
        // Simplified CPU usage calculation
        const loadAvg = os.loadavg()[0];
        const numCPUs = os.cpus().length;
        return Math.min(Math.round((loadAvg / numCPUs) * 100), 100);
    }

    getStatus(value, thresholds) {
        if (typeof value === 'string') return 'good';
        if (value >= (thresholds.critical || 90)) return 'critical';
        if (value >= (thresholds.warning || 70)) return 'warning';
        return 'good';
    }

    startMetricsCollection() {
        // Update metrics at specified refresh rate
        setInterval(() => {
            this.lastMetricsUpdate = Date.now();
            this.broadcastMetrics();
        }, this.refreshRate);

        console.log(`📊 NCC Display Server: Metrics collection started (${this.refreshRate}ms intervals)`);
    }

    broadcastMetrics() {
        const metrics = this.getMetrics();

        // Broadcast to all connected WebSocket clients
        this.clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                try {
                    client.send(JSON.stringify(metrics));
                } catch (error) {
                    console.error('Error sending metrics to client:', error);
                    this.clients.delete(client);
                }
            } else {
                this.clients.delete(client);
            }
        });
    }

    start() {
        // Start HTTP server
        this.server = this.app.listen(this.port, () => {
            console.log(`🚀 NCC Ultimate Display Monitor Server v2.0.0 started on port ${this.port}`);
            console.log(`📱 Dashboard: http://localhost:${this.port}`);
            console.log(`🔄 Refresh Rate: ${this.refreshRate}ms`);
            console.log(`💻 System: ${os.platform()} ${os.arch()}`);
            console.log(`⚡ CPUs: ${os.cpus().length}, Memory: ${Math.round(os.totalmem() / 1024 / 1024 / 1024)}GB`);
        });

        // Start WebSocket server
        this.wss = new WebSocket.Server({ server: this.server });

        this.wss.on('connection', (ws, req) => {
            console.log(`🔗 New WebSocket client connected from ${req.socket.remoteAddress}`);
            this.clients.add(ws);

            // Send initial metrics
            ws.send(JSON.stringify(this.getMetrics()));

            ws.on('message', (message) => {
                try {
                    const data = JSON.parse(message.toString());
                    console.log('Received message from client:', data);
                } catch (error) {
                    console.error('Error parsing client message:', error);
                }
            });

            ws.on('close', () => {
                console.log('WebSocket client disconnected');
                this.clients.delete(ws);
            });

            ws.on('error', (error) => {
                console.error('WebSocket client error:', error);
                this.clients.delete(ws);
            });
        });

        // Graceful shutdown
        process.on('SIGINT', () => {
            console.log('\n🛑 Shutting down NCC Display Server...');
            this.wss.close();
            this.server.close(() => {
                console.log('✅ Server shutdown complete');
                process.exit(0);
            });
        });

        process.on('SIGTERM', () => {
            console.log('\n🛑 Shutting down NCC Display Server...');
            this.wss.close();
            this.server.close(() => {
                console.log('✅ Server shutdown complete');
                process.exit(0);
            });
        });
    }
}

// Start the server if this file is run directly
if (require.main === module) {
    const port = process.env.PORT || 3000;
    const refreshRate = process.env.REFRESH_RATE || 500;

    console.log('🎯 Starting NCC Ultimate Display Monitor Server...');
    console.log('📊 Real-time enterprise performance monitoring');
    console.log('⚡ Sub-second refresh rates for maximum performance');
    console.log('🌟 The greatest desktop display monitor ever created');

    const server = new NCCDisplayServer(port, refreshRate);
    server.start();
}

module.exports = NCCDisplayServer;
