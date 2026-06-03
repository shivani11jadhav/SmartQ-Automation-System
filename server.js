const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const FILE_PATH = path.join(__dirname, 'web_prototype.html');

const server = http.createServer((req, res) => {
  fs.readFile(FILE_PATH, (err, data) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Error loading prototype file: ' + err.message);
      return;
    }
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(data);
  });
});

server.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});
