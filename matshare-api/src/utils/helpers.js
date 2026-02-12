const VALID_CATEGORIES = ['materials', 'tools'];
const VALID_UNITS = ['kg', 'g', 'pieces', 'bags', 'liters', 'meters', 'sq_meters', 'boxes', 'sets', 'other'];
const VALID_STATUSES = ['active', 'sold', 'reserved', 'expired'];

function validateListing(body) {
  const errors = [];

  if (!body.title || body.title.trim().length === 0) {
    errors.push('Title is required');
  } else if (body.title.length > 200) {
    errors.push('Title must be 200 characters or less');
  }

  if (!body.category || !VALID_CATEGORIES.includes(body.category)) {
    errors.push(`Category must be one of: ${VALID_CATEGORIES.join(', ')}`);
  }

  if (body.unit && !VALID_UNITS.includes(body.unit)) {
    errors.push(`Unit must be one of: ${VALID_UNITS.join(', ')}`);
  }

  if (body.latitude == null || body.longitude == null) {
    errors.push('Latitude and longitude are required');
  } else {
    if (body.latitude < -90 || body.latitude > 90) errors.push('Invalid latitude');
    if (body.longitude < -180 || body.longitude > 180) errors.push('Invalid longitude');
  }

  if (body.price != null && body.price < 0) {
    errors.push('Price cannot be negative');
  }

  if (body.quantity != null && body.quantity < 0) {
    errors.push('Quantity cannot be negative');
  }

  return errors;
}

function validateStatus(status) {
  return VALID_STATUSES.includes(status);
}

module.exports = { validateListing, validateStatus, VALID_CATEGORIES, VALID_UNITS, VALID_STATUSES };
