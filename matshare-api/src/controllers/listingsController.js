const pool = require('../config/db');
const { validateListing, validateStatus } = require('../utils/helpers');

function formatListing(row) {
  return {
    ...row,
    price: row.price != null ? parseFloat(row.price) : null,
    quantity: row.quantity != null ? parseFloat(row.quantity) : null,
    distance_meters: row.distance_meters != null ? parseFloat(row.distance_meters) : null,
    latitude: row.latitude != null ? parseFloat(row.latitude) : null,
    longitude: row.longitude != null ? parseFloat(row.longitude) : null,
  };
}

exports.getNearby = async (req, res) => {
  try {
    const { lat, lng, radius = 10000, category, search, limit = 50, offset = 0 } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ error: 'lat and lng are required' });
    }

    const result = await pool.query(
      'SELECT * FROM search_listings_nearby($1, $2, $3, $4, $5, $6, $7)',
      [
        parseFloat(lat),
        parseFloat(lng),
        parseInt(radius),
        category || null,
        search || null,
        parseInt(limit),
        parseInt(offset),
      ]
    );

    res.json({ listings: result.rows.map(formatListing), total: result.rows.length });
  } catch (err) {
    console.error('getNearby error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.getById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `SELECT l.*, u.name AS seller_name, u.phone AS seller_phone,
              ST_Y(l.location::geometry) AS latitude,
              ST_X(l.location::geometry) AS longitude
       FROM listings l
       JOIN users u ON l.user_id = u.id
       WHERE l.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Listing not found' });
    }

    res.json(formatListing(result.rows[0]));
  } catch (err) {
    console.error('getById error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.create = async (req, res) => {
  try {
    const errors = validateListing(req.body);
    if (errors.length > 0) {
      return res.status(400).json({ errors });
    }

    const {
      title, description, category, subcategory,
      quantity, unit, price, is_free,
      photo_urls, latitude, longitude, address_text,
      residential_complex,
    } = req.body;

    const result = await pool.query(
      `INSERT INTO listings
        (user_id, title, description, category, subcategory,
         quantity, unit, price, is_free, photo_urls,
         location, address_text, residential_complex)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
               ST_MakePoint($11, $12)::geography, $13, $14)
       RETURNING *`,
      [
        req.user.id, title, description || null, category, subcategory || null,
        quantity || null, unit || null, price || 0, is_free || false,
        photo_urls || [],
        longitude, latitude, address_text || null,
        residential_complex || null,
      ]
    );

    res.status(201).json(formatListing(result.rows[0]));
  } catch (err) {
    console.error('create error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.update = async (req, res) => {
  try {
    const { id } = req.params;

    const ownership = await pool.query(
      'SELECT user_id FROM listings WHERE id = $1', [id]
    );
    if (ownership.rows.length === 0) {
      return res.status(404).json({ error: 'Listing not found' });
    }
    if (ownership.rows[0].user_id !== req.user.id) {
      return res.status(403).json({ error: 'Not authorized to edit this listing' });
    }

    const {
      title, description, category, subcategory,
      quantity, unit, price, is_free,
      photo_urls, latitude, longitude, address_text,
      residential_complex,
    } = req.body;

    const result = await pool.query(
      `UPDATE listings SET
        title = COALESCE($1, title),
        description = COALESCE($2, description),
        category = COALESCE($3, category),
        subcategory = COALESCE($4, subcategory),
        quantity = COALESCE($5, quantity),
        unit = COALESCE($6, unit),
        price = $7,
        is_free = $8,
        photo_urls = $9,
        location = CASE WHEN $10::double precision IS NOT NULL AND $11::double precision IS NOT NULL
                        THEN ST_MakePoint($10, $11)::geography
                        ELSE location END,
        address_text = COALESCE($12, address_text),
        residential_complex = COALESCE($13, residential_complex),
        updated_at = NOW()
       WHERE id = $14
       RETURNING *, ST_Y(location::geometry) AS latitude, ST_X(location::geometry) AS longitude`,
      [
        title || null,
        description != null ? description : null,
        category || null,
        subcategory != null ? subcategory : null,
        quantity != null ? quantity : null,
        unit || null,
        price != null ? price : 0,
        is_free != null ? is_free : false,
        photo_urls || [],
        longitude != null ? longitude : null,
        latitude != null ? latitude : null,
        address_text != null ? address_text : null,
        residential_complex != null ? residential_complex : null,
        id,
      ]
    );

    res.json(formatListing(result.rows[0]));
  } catch (err) {
    console.error('update error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.updateStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!validateStatus(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const ownership = await pool.query(
      'SELECT user_id FROM listings WHERE id = $1', [id]
    );
    if (ownership.rows.length === 0) {
      return res.status(404).json({ error: 'Listing not found' });
    }
    if (ownership.rows[0].user_id !== req.user.id) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const result = await pool.query(
      `UPDATE listings SET status = $1, updated_at = NOW()
       WHERE id = $2 RETURNING *`,
      [status, id]
    );

    res.json(formatListing(result.rows[0]));
  } catch (err) {
    console.error('updateStatus error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.remove = async (req, res) => {
  try {
    const { id } = req.params;

    const listing = await pool.query(
      'SELECT user_id, photo_urls FROM listings WHERE id = $1', [id]
    );
    if (listing.rows.length === 0) {
      return res.status(404).json({ error: 'Listing not found' });
    }
    if (listing.rows[0].user_id !== req.user.id) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    // Delete photos from Supabase Storage
    const photoUrls = listing.rows[0].photo_urls || [];
    if (photoUrls.length > 0) {
      const bucket = 'listing-photos';
      const storagePaths = photoUrls.flatMap((url) => {
        const path = url.split(`/${bucket}/`)[1];
        if (!path) return [];
        // Delete both full-size and thumbnail
        return [path, path.replace('.jpg', '_thumb.jpg')];
      });

      if (storagePaths.length > 0) {
        try {
          await fetch(`${process.env.SUPABASE_URL}/storage/v1/object/${bucket}`, {
            method: 'DELETE',
            headers: {
              'Authorization': `Bearer ${process.env.SUPABASE_SERVICE_KEY}`,
              'apikey': process.env.SUPABASE_SERVICE_KEY,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ prefixes: storagePaths }),
          });
        } catch (storageErr) {
          console.error('Storage cleanup error:', storageErr.message);
        }
      }
    }

    await pool.query('DELETE FROM listings WHERE id = $1', [id]);
    res.json({ message: 'Listing deleted' });
  } catch (err) {
    console.error('remove error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.getMyListings = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT *, ST_Y(location::geometry) AS latitude,
              ST_X(location::geometry) AS longitude
       FROM listings
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [req.user.id]
    );

    res.json({ listings: result.rows.map(formatListing), total: result.rows.length });
  } catch (err) {
    console.error('getMyListings error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};
