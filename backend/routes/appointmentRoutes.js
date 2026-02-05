const express = require('express');
const router = express.Router();
const {
    createAppointment,
    getAppointments,
    cancelAppointment,
    getTrainerAppointments,
    updateAppointmentStatus,
    getAllAppointments,
    deleteAppointment,
    adminCreateAppointment,
    adminUpdateAppointment
} = require('../controllers/appointmentController');
const { protect } = require('../middleware/authMiddleware');

router.route('/')
    .post(protect, createAppointment)
    .get(protect, getAppointments);

router.post('/book', protect, createAppointment);

router.get('/trainer', protect, getTrainerAppointments);

router.put('/:id/cancel', protect, cancelAppointment);
router.put('/:id/status', protect, updateAppointmentStatus);

const { admin } = require('../middleware/authMiddleware');

// Admin Routes
// to reade all appointments for admin to manage and view
router.get('/all', protect, admin, getAllAppointments);
router.post('/admin/create', protect, admin, adminCreateAppointment);
router.put('/admin/:id', protect, admin, adminUpdateAppointment);
router.delete('/:id', protect, admin, deleteAppointment);

module.exports = router;
