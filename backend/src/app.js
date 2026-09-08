const express = require('express');
const cors = require('cors');
const errorHandler = require('./middleware/errorHandler');

const app = express();

app.use(cors());
app.use(express.json());

// Health check route — confirms server is up
app.get('/api/health', (req, res) => {
    res.json({ success: true, message: 'Health Tracker API is running' });
});

// Route mounting will go here as each module is built:
// app.use('/api/auth', require('./routes/authRoutes'));
// app.use('/api/profile', require('./routes/profileRoutes'));
// app.use('/api/weight', require('./routes/weightRoutes'));
// ...

// 404 handler for unmatched routes
app.use((req, res) => {
    res.status(404).json({ success: false, message: 'Route not found' });
});

// Centralized error handler — must be last
app.use(errorHandler);

module.exports = app;