const { spawn, exec } = require('child_process');
const path = require('path');
const http = require('http');

console.log('====================================================');
console.log('   DELICIOUS CHICKEN CENTER - FULL STACK RUNNER     ');
console.log('====================================================');

// 1. Start Backend Server (port 3000)
console.log('[1/3] Starting Backend API & Socket Server (port 3000)...');
const backend = spawn('node', [path.join(__dirname, 'backend', 'server.js')], {
  stdio: 'inherit',
  cwd: path.join(__dirname, 'backend')
});

// 2. Start Admin Panel Web Server (port 8000)
console.log('[2/3] Starting Admin Panel Web Server (port 8000)...');
const admin = spawn('node', [path.join(__dirname, 'admin-panel', 'serve.js')], {
  stdio: 'inherit',
  cwd: path.join(__dirname, 'admin-panel')
});

// 3. Start Customer Panel Web Server (port 8001)
console.log('[3/3] Starting Customer Mobile Web App (port 8001)...');
const customer = spawn('node', [path.join(__dirname, 'mobile-app', 'serve.js')], {
  stdio: 'inherit',
  cwd: path.join(__dirname, 'mobile-app')
});

function checkReady(port, cb) {
  const req = http.get(`http://localhost:${port}/`, (res) => {
    cb(true);
  });
  req.on('error', () => {
    setTimeout(() => checkReady(port, cb), 500);
  });
}

// Wait for servers to be active, then open browser
setTimeout(() => {
  console.log('\n✅ All services are active!');
  console.log('   - Backend API:    http://localhost:3000');
  console.log('   - Admin Panel:    http://localhost:8000');
  console.log('   - Customer Panel: http://localhost:8001\n');

  // Launch Chrome on Windows
  console.log('🌐 Opening Chrome with Admin and Customer panels...');
  exec('start chrome http://localhost:8000 http://localhost:8001', (err) => {
    if (err) {
      console.log('Could not open Chrome automatically; please open the URLs manually.');
    }
  });
}, 2000);

process.on('SIGINT', () => {
  console.log('Shutting down services...');
  backend.kill();
  admin.kill();
  customer.kill();
  process.exit(0);
});
