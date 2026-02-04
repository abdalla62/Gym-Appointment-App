const express = require('express');
const router = express.Router();
const { registerUser, loginUser, getMe, getTrainers, getAllUsers, updateUser, deleteUser, getSystemStats, adminCreateUser } = require('../controllers/authController');
const { protect, admin } = require('../middleware/authMiddleware');

// Jidka diiwaangelinta (Register route)
router.post('/register', registerUser);

// Jidka soo gelitaanka (Login route)
router.post('/login', loginUser);

// Jidka helitaanka xogta user-ka (Get Me route)
router.get('/me', protect, getMe);
router.get('/trainers', protect, getTrainers);

// Admin User Management Routes
router.get('/users', protect, admin, getAllUsers);
router.put('/users/:id', protect, admin, updateUser);
router.delete('/users/:id', protect, admin, deleteUser);
router.get('/stats', protect, admin, getSystemStats);
router.post('/admin/create', protect, admin, adminCreateUser);

module.exports = router;
