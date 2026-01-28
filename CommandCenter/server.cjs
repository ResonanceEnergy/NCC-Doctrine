const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 8082;

console.log('Starting server...');

app.use(cors());
app.use(express.json());

// Placeholder data
let priorities = [
  'Maintain comms redundancy',
  'EMP readiness',
  'Critical project: Avatar Center'
];
let analytics = {
  activeProjects: 54,
  alerts: 0,
  opsPackets: 7
};
let timeline = [
  { event: 'System boot', time: '2026-01-27T08:00:00Z' },
  { event: 'EMP readiness check', time: '2026-01-27T09:00:00Z' }
];

// API endpoints
app.get('/api/priorities', (req, res) => res.json({ priorities }));
app.get('/api/analytics', (req, res) => res.json(analytics));
app.get('/api/timeline', (req, res) => res.json({ timeline }));

const server = app.listen(PORT, '127.0.0.1', () => {
  console.log(`Backend API running at http://localhost:${PORT}`);
});

server.on('error', (err) => {
  console.error('Server error:', err);
});

server.on('listening', () => {
  console.log('Server is listening');
});