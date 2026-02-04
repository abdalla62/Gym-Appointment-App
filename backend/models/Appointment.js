const mongoose = require('mongoose');

const appointmentSchema = mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: 'User'
    },
    trainer: {
        type: mongoose.Schema.Types.ObjectId,
        required: [true, 'Fadlan dooro tababare (Please select a trainer)'],
        ref: 'User'
    },
    date: {
        type: String, // Waxaan isticmaali karnaa Date object, laakiin String ayaa ka fudud hadda.
        required: [true, 'Fadlan dooro taariikh (Please select a date)']
    },
    time: {
        type: String,
        required: [true, 'Fadlan dooro waqti (Please select a time)']
    },
    status: {
        type: String,
        enum: ['pending', 'confirmed', 'cancelled', 'completed'],
        default: 'pending'
    },
    notes: {
        type: String,
        required: false
    },
    price: {
        type: Number,
        default: 50 // Default price per session
    },
    scolor: {
        type: String,
        default: '#FF7F27' // Default to AppColors.primary (Orange)
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('Appointment', appointmentSchema);

//this appinment model

