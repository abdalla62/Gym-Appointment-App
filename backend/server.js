const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const morgan = require('morgan');
const connectDB = require('./config/db');

// Xumbada deegaanka (Load env vars)
dotenv.config();

// Ku xirri xog-keydka (Connect to Database)
connectDB();

const app = express();

// Middleware-yada (Middlewares)
app.use(express.json()); // U ogolow JSON data
app.use(cors()); // Oggolow Cross-Origin requests
if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev')); // Log-garee codsiyada (Log requests)
}

// Wadooyinka (Routes)
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/appointments', require('./routes/appointmentRoutes'));
app.use('/api/availability', require('./routes/availabilityRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));

// Tijaabada server-ka (Test route)
app.get('/', (req, res) => {
    res.send('Server-ku wuu shaqeynayaa...');
});

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
    // Server-ku wuxuu ka shaqeynayaa port-ka ...
    console.log(`Server is running in ${process.env.NODE_ENV} mode on port ${PORT}`);
});

// Qalad baafinta (Error handling for server)
server.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
        console.error(`Port ${PORT} is already in use. Please stop the other process or use a different port.`);
        process.exit(1);
    } else {
        console.error('An unexpected error occurred:', error);
    }
});
