const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const ctrl = require('../controllers/listingsController');

router.get('/nearby', auth, ctrl.getNearby);
router.get('/my', auth, ctrl.getMyListings);
router.get('/:id', auth, ctrl.getById);
router.post('/', auth, ctrl.create);
router.put('/:id', auth, ctrl.update);
router.patch('/:id/status', auth, ctrl.updateStatus);
router.delete('/:id', auth, ctrl.remove);

module.exports = router;
