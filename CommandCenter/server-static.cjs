const express = require('express');
const helmet = require('helmet');
const path = require('path');
const app = express();
const PORT = 8081;

console.log('Starting static server...');

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

app.use(express.static(path.join(__dirname, 'dist')));

const server = app.listen(PORT, () => {
  console.log(`Dashboard static server running at http://localhost:${PORT}`);
});

server.on('error', (err) => {
  console.error('Static server error:', err);
});

server.on('listening', () => {
  console.log('Static server is listening');
});
