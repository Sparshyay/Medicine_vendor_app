const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files from the build/web directory
app.use(express.static(path.join(__dirname, 'build/web')));

// Serve index.html for any route to support SPA routing
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build/web', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
  console.log(`Serving Flutter web application from build/web directory`);
});
