const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Appointment = require('../models/Appointment');

// @desc    Diiwaangeli user cusub (Register new user)
// @route   POST /api/auth/register
// @access  Public
const registerUser = async (req, res) => {
    const { name, email, password } = req.body;
    console.log('Register Request:', { name, email, password: password ? '********' : 'missing' });

    if (!name || !email || !password) {
        console.log('Registration failed: Missing fields');
        return res.status(400).json({ message: 'Fadlan buuxi dhammaan meelaha banaan (Please add all fields)' });
    }

    // Hubi haddii user-ku jiro (Check if user exists)
    const userExists = await User.findOne({ email });

    if (userExists) {
        console.log('Registration failed: User already exists -', email);
        return res.status(400).json({ message: 'User-kan horay ayuu u jiray (User already exists)' });
    }

    // Abuur user-ka (Create user)
    const user = await User.create({
        name,
        email,
        password,
        role: 'user' // Force 'user' role for public registration for security
    });

    if (user) {
        res.status(201).json({
            _id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            token: generateToken(user._id)
        });
    } else {
        res.status(400).json({ message: 'Xogta user-ka waa khalad (Invalid user data)' });
    }
};

// @desc    Soo galitaanka user-ka & qaadashada token-ka (Authenticate a user)
// @route   POST /api/auth/login
// @access  Public
const loginUser = async (req, res) => {
    const { email, password } = req.body;
    console.log('Login Request:', { email, password: password ? '********' : 'missing' });

    // Hubi email-ka (Check for user email)
    const user = await User.findOne({ email });

    if (!user) {
        console.log('Login failed: User not found -', email);
    }

    if (user && (await user.matchPassword(password))) {
        console.log('Login success:', email);
        res.json({
            _id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            token: generateToken(user._id)
        });
    } else {
        if (user) console.log('Login failed: Invalid password for -', email);
        res.status(400).json({ message: 'Email ama Password waa khalad (Invalid credentials)' });
    }
};

// @desc    Hel xogta user-ka hadda jira (Get user data)
// @route   GET /api/auth/me
// @access  Private
const getMe = async (req, res) => {
    res.status(200).json(req.user);
};

// Samee JWT Token (Generate JWT)
const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

// @desc    Hel dhammaan tababarayaasha (Get all trainers)
// @route   GET /api/auth/trainers
// @access  Private
const getTrainers = async (req, res) => {
    const trainers = await User.find({ role: { $in: ['trainer', 'coach'] } }).select('-password');
    res.status(200).json(trainers);
};

// @desc    Hel dhammaan user-ada (Admin Only) (Get all users)
// @route   GET /api/auth/users
// @access  Private/Admin
const getAllUsers = async (req, res) => {
    const users = await User.find({}).select('-password');
    res.status(200).json(users);
};

// @desc    Update user (Admin Only)
// @route   PUT /api/auth/users/:id
// @access  Private/Admin
const updateUser = async (req, res) => {
    const user = await User.findById(req.params.id);

    if (user) {
        user.name = req.body.name || user.name;
        user.email = req.body.email || user.email;
        user.role = req.body.role || user.role;

        if (req.body.password) {
            user.password = req.body.password;
        }

        const updatedUser = await user.save();
        res.json({
            _id: updatedUser._id,
            name: updatedUser.name,
            email: updatedUser.email,
            role: updatedUser.role,
        });
    } else {
        res.status(404).json({ message: 'User lam helin (User not found)' });
    }
};

// @desc    Delete user (Admin Only)
// @route   DELETE /api/auth/users/:id
// @access  Private/Admin
const deleteUser = async (req, res) => {
    const user = await User.findById(req.params.id);

    if (user) {
        if (user.role === 'admin') {
            return res.status(400).json({ message: 'Ma tirtiri kartid Admin (Cannot delete admin user)' });
        }
        await User.deleteOne({ _id: user._id });
        res.json({ message: 'User waa la tirtiray (User removed)' });
    } else {
        res.status(404).json({ message: 'User lam helin (User not found)' });
    }
};

// @desc    Hel xogta guud ee nidaamka (Admin Only) (Get system stats)
// @route   GET /api/auth/stats
// @access  Private/Admin
const getSystemStats = async (req, res) => {
    try {
        const totalUsers = await User.countDocuments();
        const totalTrainers = await User.countDocuments({ role: { $in: ['trainer', 'coach'] } });
        const totalAppointments = await Appointment.countDocuments();
        const activeAppointments = await Appointment.countDocuments({ status: { $in: ['pending', 'confirmed'] } });

        res.status(200).json({
            totalUsers,
            totalTrainers,
            totalAppointments,
            activeAppointments
        });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Abuur user cusub (Admin Only) (Create user)
// @route   POST /api/auth/admin/create
// @access  Private/Admin
const adminCreateUser = async (req, res) => {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ message: 'Fadlan buuxi dhammaan meelaha banaan' });
    }

    const userExists = await User.findOne({ email });
    if (userExists) {
        return res.status(400).json({ message: 'User-kan horay ayuu u jiray' });
    }

    const user = await User.create({
        name,
        email,
        password,
        role: role || 'user'
    });

    if (user) {
        res.status(201).json({
            _id: user.id,
            name: user.name,
            email: user.email,
            role: user.role
        });
    } else {
        res.status(400).json({ message: 'Xogta user-ka waa khalad' });
    }
};

module.exports = {
    registerUser,
    loginUser,
    getMe,
    getTrainers,
    getAllUsers,
    updateUser,
    deleteUser,
    getSystemStats,
    adminCreateUser
};
