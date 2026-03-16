const pool = require('../config/db');

exports.deleteAccount = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get all user's listings to clean up photos
    const listings = await pool.query(
      'SELECT photo_urls FROM listings WHERE user_id = $1',
      [userId]
    );

    // Delete photos from Supabase Storage
    const allPhotoPaths = listings.rows.flatMap((row) => {
      const urls = row.photo_urls || [];
      return urls.flatMap((url) => {
        const path = url.split('/listing-photos/')[1];
        if (!path) return [];
        return [path, path.replace('.jpg', '_thumb.jpg')];
      });
    });

    if (allPhotoPaths.length > 0) {
      try {
        await fetch(`${process.env.SUPABASE_URL}/storage/v1/object/listing-photos`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${process.env.SUPABASE_SERVICE_KEY}`,
            'apikey': process.env.SUPABASE_SERVICE_KEY,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ prefixes: allPhotoPaths }),
        });
      } catch (storageErr) {
        console.error('Storage cleanup error:', storageErr.message);
      }
    }

    // Delete user from Supabase Auth (CASCADE will clean up users + listings tables)
    const authResponse = await fetch(
      `${process.env.SUPABASE_URL}/auth/v1/admin/users/${userId}`,
      {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${process.env.SUPABASE_SERVICE_KEY}`,
          'apikey': process.env.SUPABASE_SERVICE_KEY,
        },
      }
    );

    if (!authResponse.ok) {
      const errBody = await authResponse.text();
      console.error('Supabase auth delete error:', errBody);
      return res.status(500).json({ error: 'Failed to delete account' });
    }

    res.json({ message: 'Account deleted' });
  } catch (err) {
    console.error('deleteAccount error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.upsertProfile = async (req, res) => {
  try {
    const { name, phone, avatar_url, eula_accepted_at } = req.body;

    if (!name || name.trim().length === 0) {
      return res.status(400).json({ error: 'Name is required' });
    }

    const result = await pool.query(
      `INSERT INTO users (id, name, phone, avatar_url, eula_accepted_at)
       VALUES ($1, $2, $3, $4, CASE WHEN $5::boolean THEN NOW() ELSE NULL END)
       ON CONFLICT (id) DO UPDATE SET
         name = COALESCE($2, users.name),
         phone = COALESCE($3, users.phone),
         avatar_url = COALESCE($4, users.avatar_url),
         eula_accepted_at = COALESCE(users.eula_accepted_at, CASE WHEN $5::boolean THEN NOW() ELSE NULL END),
         updated_at = NOW()
       RETURNING *`,
      [req.user.id, name.trim(), phone || null, avatar_url || null, eula_accepted_at ? true : false]
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
