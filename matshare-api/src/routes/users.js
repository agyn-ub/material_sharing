const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const ctrl = require('../controllers/usersController');

router.post('/profile', auth, ctrl.upsertProfile);
router.get('/profile', auth, ctrl.getProfile);
router.get('/:id/public', auth, ctrl.getPublicProfile);

module.exports = router;
