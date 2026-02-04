const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI);
        // Xiriirka database-ka wuu guuleystay (Database connection successful)
        console.log(`MongoDB Connected Successfully : ${conn.connection.host}`);
    } catch (error) {
        // Khalad ayaa dhacay (Error occurred)
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

module.exports = connectDB;
