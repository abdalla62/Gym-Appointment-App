const express = require('express');
const router = express.Router();
const { setAvailability, getTrainerAvailability } = require('../controllers/availabilityController');
const { protect } = require('../middleware/authMiddleware');

router.post('/', protect, setAvailability);
router.get('/:trainerId', protect, getTrainerAvailability);

module.exports = router;
