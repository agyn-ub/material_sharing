const pool = require('../config/db');

exports.upsertProfile = async (req, res) => {
  try {
    const { name, phone, avatar_url } = req.body;

    if (!name || name.trim().length === 0) {
      return res.status(400).json({ error: 'Name is required' });
    }

    const result = await pool.query(
      `INSERT INTO users (id, name, phone, avatar_url)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id) DO UPDATE SET
         name = COALESCE($2, users.name),
         phone = COALESCE($3, users.phone),
         avatar_url = COALESCE($4, users.avatar_url),
         updated_at = NOW()
       RETURNING *`,
      [req.user.id, name.trim(), phone || null, avatar_url || null]
    );

    console.log('upsertProfile response:', JSON.stringify(result.rows[0]));
    res.json(result.rows[0]);
  } catch (err) {
    console.error('upsertProfile error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('getProfile error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.getPublicProfile = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'SELECT id, name, phone, avatar_url, created_at FROM users WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('getPublicProfile error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};
