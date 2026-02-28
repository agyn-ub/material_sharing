const VALID_STATUSES = ['active', 'sold', 'reserved', 'expired'];

function validateListing(body) {
  const errors = [];

  if (!body.title || body.title.trim().length === 0) {
    errors.push('Title is required');
  } else if (body.title.length > 200) {
    errors.push('Title must be 200 characters or less');
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

  return errors;
}

function validateStatus(status) {
  return VALID_STATUSES.includes(status);
}

module.exports = { validateListing, validateStatus, VALID_STATUSES };
