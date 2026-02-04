const Notification = require('../models/Notification');

// @desc    Hel ogeysiisyada (Get notifications)
// @route   GET /api/notifications
// @access  Private
const getNotifications = async (req, res) => {
    const notifications = await Notification.find({ user: req.user.id }).sort({ createdAt: -1 });
    res.status(200).json(notifications);
};

// @desc    Calaamadee in la akhriyay (Mark as read)
// @route   PUT /api/notifications/:id
// @access  Private
const markAsRead = async (req, res) => {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
        return res.status(404).json({ message: 'Lama helin' });
    }

    if (notification.user.toString() !== req.user.id) {
        return res.status(401).json({ message: 'Not authorized' });
    }

    notification.read = true;
    await notification.save();

    res.status(200).json(notification);
};

module.exports = {
    getNotifications,
    markAsRead
};
