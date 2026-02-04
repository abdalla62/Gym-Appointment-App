const mongoose = require('mongoose');

const availabilitySchema = mongoose.Schema({
    trainer: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: 'User'
    },
    date: {
        type: String, // Format: YYYY-MM-DD
        required: [true, 'Fadlan dooro taariikh (Please select a date)']
    },
    slots: [{
        time: {
            type: String, // e.g., "10:00 AM"
            required: true
        },
        isBooked: {
            type: Boolean,
            default: false
        }
    }]
}, {
    timestamps: true
});

module.exports = mongoose.model('Availability', availabilitySchema);
