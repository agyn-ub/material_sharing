require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const listingsRoutes = require('./routes/listings');
const usersRoutes = require('./routes/users');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'public')));

app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});


// Temporary debug endpoint - remove after testing
app.get('/api/debug/nearby', async (req, res) => {
  try {
    const pool = require('./config/db');
    const result = await pool.query(
      'SELECT title, ST_Distance(location, ST_MakePoint(71.399, 51.100)::geography) as dist FROM listings WHERE status = $1 ORDER BY dist',
      ['active']
    );
    const fn = await pool.query(
      'SELECT * FROM search_listings_nearby($1, $2, $3, $4, $5, $6, $7)',
      [51.100, 71.399, 10000, null, null, 6, 0]
    );
    res.json({
      all_active: result.rows.map(r => ({ title: r.title, dist: Math.round(r.dist) })),
      search_fn_results: fn.rows.length,
      search_fn_titles: fn.rows.map(r => r.title),
    });
  } catch (e) {
    res.json({ error: e.message });
  }
});

app.use('/api/listings', listingsRoutes);
app.use('/api/users', usersRoutes);

app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.use((err, req, res, _next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`MatShare API running on port ${PORT}`);
});
