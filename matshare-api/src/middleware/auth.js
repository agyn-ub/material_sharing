const jwt = require('jsonwebtoken');
const jwksRsa = require('jwks-rsa');

const jwksClient = jwksRsa({
  jwksUri: `${process.env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`,
  cache: true,
  cacheMaxAge: 600000, // 10 minutes
});

function getSigningKey(header) {
  return new Promise((resolve, reject) => {
    jwksClient.getSigningKey(header.kid, (err, key) => {
      if (err) return reject(err);
      resolve(key.getPublicKey());
    });
  });
}

const auth = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid authorization header' });
  }

  const token = header.split(' ')[1];

  try {
    const decoded = jwt.decode(token, { complete: true });
    if (!decoded) {
      return res.status(401).json({ error: 'Invalid token' });
    }

    const publicKey = await getSigningKey(decoded.header);
    const payload = jwt.verify(token, publicKey, {
      algorithms: ['ES256'],
    });

    req.user = { id: payload.sub, email: payload.email };
    next();
  } catch (err) {
    console.error('Auth error:', err.message);
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};

module.exports = auth;
