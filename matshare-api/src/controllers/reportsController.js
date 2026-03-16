const pool = require('../config/db');

const VALID_REASONS = ['prohibited_content', 'fraud', 'offensive', 'spam', 'other'];

exports.createReport = async (req, res) => {
  try {
    const { listing_id, reason, comment } = req.body;
    const reporterId = req.user.id;

    if (!listing_id || !reason) {
      return res.status(400).json({ error: 'listing_id and reason are required' });
    }

    if (!VALID_REASONS.includes(reason)) {
      return res.status(400).json({ error: `Invalid reason. Must be one of: ${VALID_REASONS.join(', ')}` });
    }

    // Check listing exists and prevent self-reporting
    const listing = await pool.query(
      'SELECT user_id FROM listings WHERE id = $1',
      [listing_id]
    );

    if (listing.rows.length === 0) {
      return res.status(404).json({ error: 'Listing not found' });
    }

    if (listing.rows[0].user_id === reporterId) {
      return res.status(400).json({ error: 'Cannot report your own listing' });
    }

    const result = await pool.query(
      `INSERT INTO reports (reporter_id, listing_id, reason, comment)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (reporter_id, listing_id) DO NOTHING
       RETURNING *`,
      [reporterId, listing_id, reason, comment || null]
    );

    if (result.rows.length === 0) {
      // Already reported — return success silently (idempotent)
      return res.status(200).json({ message: 'Report already submitted' });
    }

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('createReport error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};
