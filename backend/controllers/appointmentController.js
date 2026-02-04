const Appointment = require('../models/Appointment');
const Availability = require('../models/Availability');
const Notification = require('../models/Notification');
const mongoose = require('mongoose');

// @desc    Buug ballan cusub (Book a new appointment)
// @route   POST /api/appointments
// @access  Private
const createAppointment = async (req, res) => {
    try {
        console.log('Booking Request Body:', req.body);
        const { trainer, date, time, notes, scolor } = req.body;

        if (!trainer || !date || !time) {
            return res.status(400).json({ message: 'Fadlan buuxi dhammaan meelaha muhiimka ah' });
        }

        // 1. Check if trainer has availability (Optionalized for manual booking)
        /*
        const trainerAvailability = await Availability.findOne({ trainer, date });

        if (!trainerAvailability) {
            return res.status(400).json({ message: 'Tababaruhu ma shaqeynayo maalintan' });
        }

        const slot = trainerAvailability.slots.find(s => s.time === time);
        if (!slot) {
            return res.status(400).json({ message: 'Waqtigaan ma jiro jadwal' });
        }

        if (slot.isBooked) {
            return res.status(400).json({ message: 'Waqtigaan horay ayaa loo qabsaday' });
        }
        */

        // 2. Check double booking
        const existingAppointment = await Appointment.findOne({ user: req.user.id, date, time });
        if (existingAppointment) {
            return res.status(400).json({ message: 'Horay ayaad ballan u qabsatay waqtigaan' });
        }

        // 3. Create Appointment
        const appointment = await Appointment.create({
            user: req.user.id,
            trainer,
            date,
            time,
            notes,
            status: 'pending',
            scolor: scolor || '#FF7F27'
        });

        // 4. Mark slot (Disabled for manual booking)
        /*
        slot.isBooked = true;
        await trainerAvailability.save();
        */

        // 5. Notification
        await Notification.create({
            user: trainer,
            message: `Ballan cusub ayaa laguu qabsaday: ${date} @ ${time}`,
            type: 'appointment_booked'
        });

        res.status(201).json(appointment);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Hel ballamada user-ka (Get user appointments)
// @route   GET /api/appointments
// @access  Private
const getAppointments = async (req, res) => {
    try {
        const appointments = await Appointment.find({ user: req.user.id }).populate('trainer', 'name email');
        res.status(200).json(appointments);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Hel ballamada Tababaraha (Get trainer appointments)
// @route   GET /api/appointments/trainer
// @access  Private (Trainer)
const getTrainerAppointments = async (req, res) => {
    try {
        const appointments = await Appointment.find({ trainer: req.user.id }).populate('user', 'name email');
        res.status(200).json(appointments);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Update status (Accept/Reject/Complete)
// @route   PUT /api/appointments/:id/status
// @access  Private (Trainer/Admin)
const updateAppointmentStatus = async (req, res) => {
    try {
        const { status } = req.body;

        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(404).json({ message: 'Ballan lama helin (Invalid ID)' });
        }

        const appointment = await Appointment.findById(req.params.id);

        if (!appointment) {
            return res.status(404).json({ message: 'Ballan lama helin' });
        }

        // Verify trainer owns this appointment
        if (appointment.trainer.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(401).json({ message: 'Not authorized' });
        }

        appointment.status = status;
        await appointment.save();

        // Notify User
        await Notification.create({
            user: appointment.user,
            message: `Ballankii ${appointment.date} waa la bedelay: ${status}`,
            type: status === 'confirmed' ? 'appointment_confirmed' : 'appointment_cancelled'
        });

        res.status(200).json(appointment);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Jooji ballan (Cancel appointment by user)
// @route   PUT /api/appointments/:id/cancel
// @access  Private
const cancelAppointment = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(404).json({ message: 'Ballan lama helin (Invalid ID)' });
        }

        const appointment = await Appointment.findById(req.params.id);

        if (!appointment) {
            return res.status(404).json({ message: 'Ballan lama helin' });
        }

        if (appointment.user.toString() !== req.user.id) {
            return res.status(401).json({ message: 'Not authorized' });
        }

        appointment.status = 'cancelled';
        await appointment.save();

        res.status(200).json(appointment);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Hel dhammaan ballamada (Admin Only) (Get all appointments)
// @route   GET /api/appointments/all
// @access  Private/Admin
const getAllAppointments = async (req, res) => {
    try {
        const appointments = await Appointment.find({})
            .populate('user', 'name email')
            .populate('trainer', 'name email');
        res.status(200).json(appointments);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Tirtir ballan (Admin Only) (Delete appointment)
// @route   DELETE /api/appointments/:id
// @access  Private/Admin
const deleteAppointment = async (req, res) => {
    try {
        if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
            return res.status(404).json({ message: 'Ballan lama helin (Invalid ID)' });
        }

        const appointment = await Appointment.findById(req.params.id);

        if (!appointment) {
            return res.status(404).json({ message: 'Ballan lama helin' });
        }

        await Appointment.deleteOne({ _id: appointment._id });
        res.json({ message: 'Ballankii waa la tirtiray (Appointment removed)' });
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Admin create appointment (Admin Only)
// @route   POST /api/appointments/admin/create
// @access  Private/Admin
const adminCreateAppointment = async (req, res) => {
    try {
        const { user, trainer, date, time, notes, status, scolor } = req.body;

        if (!user || !trainer || !date || !time) {
            return res.status(400).json({ message: 'Missing fields' });
        }

        const appointment = await Appointment.create({
            user,
            trainer,
            date,
            time,
            notes,
            status: status || 'confirmed',
            scolor: scolor || '#FF7F27'
        });

        res.status(201).json(appointment);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Admin update appointment (Admin Only)
// @route   PUT /api/appointments/admin/:id
// @access  Private/Admin
const adminUpdateAppointment = async (req, res) => {
    try {
        const appointment = await Appointment.findById(req.params.id);
        if (!appointment) {
            return res.status(404).json({ message: 'Appointment not found' });
        }

        appointment.user = req.body.user || appointment.user;
        appointment.trainer = req.body.trainer || appointment.trainer;
        appointment.date = req.body.date || appointment.date;
        appointment.time = req.body.time || appointment.time;
        appointment.notes = req.body.notes || appointment.notes;
        appointment.scolor = req.body.scolor || appointment.scolor;

        const updatedAppointment = await appointment.save();
        res.json(updatedAppointment);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

module.exports = {
    createAppointment,
    getAppointments,
    getTrainerAppointments,
    updateAppointmentStatus,
    cancelAppointment,
    getAllAppointments,
    deleteAppointment,
    adminCreateAppointment,
    adminUpdateAppointment
};
