const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { createReport } = require('../controllers/reportsController');

router.post('/', auth, createReport);

module.exports = router;
