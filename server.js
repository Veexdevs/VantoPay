const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'web')));

app.get('/{*path}', (req, res) => {
  res.sendFile(path.join(__dirname, 'web', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`VantoPay web preview running at http://0.0.0.0:${PORT}`);
});
