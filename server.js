const express = require('express');
const path = require('path');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'ncc-secret-key-2026';

console.log('Starting NCC Dashboard server...');

// Middleware
app.use(express.json());

// Serve avatar images from database/avatars
try {
  app.use('/avatars', express.static(path.join(__dirname, 'database/avatars')));
  console.log('Static avatars directory set up.');
} catch (err) {
  console.error('[Startup Error] Setting up avatars directory:', err);
}

// Serve static files from public
try {
  // Serve static files from the 'public' directory with no-cache headers
  app.use(express.static(path.join(__dirname, 'public'), {
    setHeaders: (res, filePath) => {
      res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');
      res.setHeader('Surrogate-Control', 'no-store');
    }
  }));
  console.log('Static public directory set up.');
} catch (err) {
  console.error('[Startup Error] Setting up static public directory:', err);
}

// Simple user store (in production, use database)
const users = [
  { id: 1, username: 'azprime', password: bcrypt.hashSync('ncc2026', 10), role: 'admin' },
  { id: 2, username: 'safety', password: bcrypt.hashSync('ncc2026', 10), role: 'security' }
];

// Middleware to verify JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Access token required' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    req.user = user;
    next();
  });
};
let priorities = [
  "Maintain comms redundancy",
  "EMP readiness",
  "Critical project: Avatar Center"
];
let auditLog = [];

// Login endpoint
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  const user = users.find(u => u.username === username);
  if (!user || !await bcrypt.compare(password, user.password)) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '24h' });
  res.json({ token, user: { id: user.id, username: user.username, role: user.role } });
});

// Get projects
const fs = require('fs');
app.get('/api/projects', authenticateToken, (req, res) => {
  try {
    const projectsData = JSON.parse(fs.readFileSync(path.join(__dirname, 'NCC_ProjectSchema.json'), 'utf8'));
    res.json(projectsData);
  } catch (err) {
    res.status(500).json({ error: 'Failed to load projects' });
  }
});

// Get priorities
app.get('/api/priorities', authenticateToken, (req, res) => {
  res.json({ priorities });
});

// Add a new priority (requires CDR approval on frontend)
app.post('/api/priorities', authenticateToken, express.json(), (req, res) => {
  const { priority, user } = req.body;
  if (!priority) return res.status(400).json({ error: 'Missing priority' });
  priorities.unshift(priority);
  auditLog.unshift({
    type: 'priority',
    action: 'add',
    priority,
    user: user || 'unknown',
    timestamp: new Date().toISOString()
  });
  res.json({ success: true, priorities });
});

// Get audit log
app.get('/api/audit', authenticateToken, (req, res) => {
  res.json({ auditLog });
});
app.get('/api/:action', authenticateToken, (req, res) => {
  const action = req.params.action;
  res.json({ output: `Action '${action}' received.` });
});

// IT Department consultation endpoint
app.get('/api/it-consult', authenticateToken, (req, res) => {
  const q = req.query.q || '';
  res.json({
    'IT Team Captain': `Strategic assessment: ${q} - Comprehensive security analysis and mitigation strategy implemented.`,
    'Ethical Hacker Alpha': `Offensive analysis: ${q} - Vulnerability exploitation simulated, zero-day threats neutralized.`,
    'Ethical Hacker Beta': `Defensive posture: ${q} - Advanced persistent threat detection enhanced, intrusion prevention optimized.`
  });
});

// C33 Executive Agents consultation endpoint
app.get('/api/chat', authenticateToken, (req, res) => {
  const q = req.query.q || '';
  const responses = {
    // Command (CDR) - CEO Council (10 CEOs)
    'CEO - Vision & Strategy (CDR)': `Strategic command: ${q} - Vision established, strategic intent communicated, commander's guidance issued.`,
    'CEO - Financial Operations': `Financial command: ${q} - Capital allocation directed, ROI objectives set, fiscal discipline enforced.`,
    'CEO - Technology Innovation': `Technology command: ${q} - Innovation priorities defined, R&D directives issued, technology roadmap approved.`,
    'CEO - Operational Excellence': `Operations command: ${q} - Process standards established, efficiency targets set, operational tempo directed.`,
    'CEO - Market Leadership': `Market command: ${q} - Competitive strategy approved, market positioning directed, brand authority established.`,
    'CEO - Global Expansion': `Expansion command: ${q} - International objectives set, market entry strategies approved, global footprint directed.`,
    'CEO - Product Development': `Product command: ${q} - Development pipeline prioritized, innovation cycles directed, product strategy approved.`,
    'CEO - Customer Experience': `Customer command: ${q} - Experience standards set, loyalty objectives defined, customer-centric directives issued.`,
    'CEO - Sustainability': `Sustainability command: ${q} - ESG objectives established, environmental targets set, sustainable practices directed.`,
    'CEO - Risk Management': `Risk command: ${q} - Risk tolerance defined, mitigation strategies approved, enterprise resilience directed.`,
    
    // Control (XO) - Executive Coordination (8 Roles)
    'XO - Chief of Staff': `Executive coordination: ${q} - Battle rhythm synchronized, decision cycles managed, command tempo maintained.`,
    'COO - Operations Control': `Operations control: ${q} - Execution synchronized, resource allocation coordinated, operational readiness maintained.`,
    'CFO - Financial Control': `Financial control: ${q} - Budget execution monitored, financial risks controlled, capital efficiency optimized.`,
    'CHRO - Human Resources Control': `HR control: ${q} - Talent strategy coordinated, organizational development managed, workforce readiness ensured.`,
    'CLO - Legal Control': `Legal control: ${q} - Compliance monitored, legal risks managed, regulatory coordination maintained.`,
    'CCO - Communications Control': `Communications control: ${q} - Messaging coordinated, stakeholder engagement managed, information flow controlled.`,
    'CGO - Growth Control': `Growth control: ${q} - Expansion initiatives coordinated, market opportunities managed, growth trajectory controlled.`,
    'CEO - Strategic Control': `Strategic control: ${q} - Long-term objectives coordinated, strategic initiatives synchronized, vision execution controlled.`,
    
    // Communications (S6) - Digital & IT (7 Roles)
    'CTO - Technology Communications': `Tech communications: ${q} - Digital infrastructure maintained, technology integration coordinated, IT systems synchronized.`,
    'CIO - IT Infrastructure': `IT communications: ${q} - Network operations managed, system reliability ensured, digital connectivity maintained.`,
    'CDO - Data Communications': `Data communications: ${q} - Information flow managed, data integrity ensured, analytics coordination maintained.`,
    'CMO - Digital Marketing': `Digital communications: ${q} - Online presence coordinated, digital campaigns managed, brand messaging synchronized.`,
    'CPO - Procurement Systems': `Procurement communications: ${q} - Supply systems integrated, vendor coordination managed, procurement networks maintained.`,
    'CQO - Quality Communications': `Quality communications: ${q} - Standards coordination managed, quality assurance synchronized, compliance monitoring maintained.`,
    'CEO - Innovation Labs': `Innovation communications: ${q} - R&D coordination managed, technology transfer facilitated, innovation pipeline maintained.`,
    
    // Operations (S3) - Execution (6 Roles)
    'COO - Supply Chain Operations': `Supply operations: ${q} - Logistics execution managed, supply chain coordination maintained, operational flow ensured.`,
    'CRO - Revenue Operations': `Revenue operations: ${q} - Sales execution coordinated, revenue targets managed, customer acquisition optimized.`,
    'CEO - Customer Success': `Customer operations: ${q} - Success metrics managed, retention strategies executed, customer satisfaction optimized.`,
    'CEO - Corporate Development': `Development operations: ${q} - M&A execution managed, partnership coordination maintained, growth initiatives deployed.`,
    'CEO - Public Affairs': `Public operations: ${q} - Stakeholder engagement managed, reputation coordination maintained, public relations executed.`,
    'CEO - Strategic Alliances': `Alliance operations: ${q} - Partnership execution managed, alliance coordination maintained, collaborative initiatives deployed.`,
    
    // Intelligence/Security (S2) - Threat & Risk (4 Roles)
    'CSO - Corporate Security': `Security intelligence: ${q} - Threat assessment conducted, security measures coordinated, protective operations maintained.`,
    'CEO - Risk Analytics': `Risk intelligence: ${q} - Risk analysis performed, threat assessment coordinated, mitigation strategies developed.`,
    'CEO - Crisis Management': `Crisis intelligence: ${q} - Emergency assessment conducted, response coordination managed, crisis management maintained.`,
    'CEO - Diversity & Inclusion': `Inclusion intelligence: ${q} - Diversity metrics monitored, inclusion strategies coordinated, cultural intelligence maintained.`,
    
    // Logistics (S4) - Sustainment (3 Roles)
    'CEO - Sustainability Operations': `Sustainability logistics: ${q} - Resource sustainment managed, environmental coordination maintained, sustainable operations ensured.`,
    'CPO - Procurement Logistics': `Procurement logistics: ${q} - Supply sustainment managed, resource coordination maintained, procurement operations ensured.`,
    'CQO - Quality Assurance': `Quality logistics: ${q} - Standards sustainment managed, quality coordination maintained, assurance operations ensured.`,
    
    // Security Command (NCC Doctrine)
    'Security Captain': `Security command: ${q} - Threat evaluation conducted, protective measures implemented per NCC doctrine hierarchy.`,
    'Security 10 Division Lead': `Division command: ${q} - Coordinated security response executed, asset protection maintained, division operations directed.`,
    'Security IT Specialist': `IT security command: ${q} - Cyber defense coordinated, digital assets protected, IT security operations maintained.`,
    'EMP Response Coordinator': `EMP command: ${q} - Electromagnetic protection coordinated, resilience protocols activated, ALPHA-LOCK posture maintained.`
  };
  res.json(responses);
});

// Start the server
try {
  app.listen(PORT, () => {
    console.log(`NCC Dashboard running at http://localhost:${PORT}`);
  });
} catch (err) {
  console.error('[Startup Error] During app.listen:', err);
}

// Global error handlers
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  process.exit(1);
});
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection:', reason);
  process.exit(1);
});
