const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

console.log('Starting NCC Dashboard server...');

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

// API endpoints for all actions (mocked)
app.get('/api/:action', (req, res) => {
  const action = req.params.action;
  res.json({ output: `Action '${action}' received.` });
});

// Chat bots endpoint (mocked)
app.get('/api/chat', (req, res) => {
  const q = req.query.q || '';
  res.json({
    copilot: `Copilot says: ${q}`,
    chatgpt: `ChatGPT says: ${q}`,
    gemini: `Gemini says: ${q}`,
    claude: `Claude says: ${q}`,
    llama: `Llama says: ${q}`,
    bing: `Bing says: ${q}`,
    perplexity: `Perplexity says: ${q}`
  });
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
