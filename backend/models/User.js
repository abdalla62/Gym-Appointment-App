const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Fadlan geli magacaaga (Please add a name)']
    },
    email: {
        type: String,
        required: [true, 'Fadlan geli email-kaaga (Please add an email)'],
        unique: true
    },
    password: {
        type: String,
        required: [true, 'Fadlan geli lambarka sirta ah (Please add a password)']
    },
    role: {
        type: String,
        enum: ['user', 'admin', 'trainer', 'coach'],
        default: 'user'
    }
}, {
    timestamps: true
});

// Kaydinta ka hor, sirta (password) hash-garee (Encrypt password before saving)
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) {
        next();
    }
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

// Isbarbardhig sirta la soo geliyay iyo midda kaydsan (Match user entered password to hashed password in database)
userSchema.methods.matchPassword = async function (enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
