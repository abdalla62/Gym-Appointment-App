const Availability = require('../models/Availability');

// @desc    Deji waqtigaaga (Set trainer availability)
// @route   POST /api/availability
// @access  Private (Trainer only)
const setAvailability = async (req, res) => {
    const { date, slots } = req.body;

    if (!date || !slots || slots.length === 0) {
        return res.status(400).json({ message: 'Fadlan geli taariikhda iyo waqtiyada (Please add date and slots)' });
    }

    // Check if availability already exists for this date
    let availability = await Availability.findOne({ trainer: req.user.id, date });

    if (availability) {
        // Update existing slots
        availability.slots = slots;
        await availability.save();
    } else {
        // Create new
        availability = await Availability.create({
            trainer: req.user.id,
            date,
            slots
        });
    }

    res.status(200).json(availability);
};

// @desc    Hel waqtiyada banaan ee tababaraha (Get trainer availability)
// @route   GET /api/availability/:trainerId
// @access  Private
const getTrainerAvailability = async (req, res) => {
    const { date } = req.query;
    let query = { trainer: req.params.trainerId };

    if (date) {
        query.date = date;
    }

    const availability = await Availability.find(query);
    res.status(200).json(availability);
};

module.exports = {
    setAvailability,
    getTrainerAvailability
};
