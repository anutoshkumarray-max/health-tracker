#!/bin/bash
# Run this from inside your backend/ folder:
#   bash setup-auth.sh

set -e

echo "Creating auth module files..."

# ---------- validators/authValidator.js ----------
cat > src/validators/authValidator.js << 'EOF'
function validateRegister(req, res, next) {
    const { name, email, password } = req.body;

    if (!name || name.trim().length < 2) {
        return res.status(400).json({ success: false, message: 'Name must be at least 2 characters' });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
        return res.status(400).json({ success: false, message: 'Valid email is required' });
    }

    if (!password || password.length < 6) {
        return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    }

    next();
}

function validateLogin(req, res, next) {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    next();
}

module.exports = { validateRegister, validateLogin };
EOF

# ---------- services/authService.js ----------
cat > src/services/authService.js << 'EOF'
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');

const SALT_ROUNDS = 10;

async function registerUser(name, email, password) {
    const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
        const err = new Error('Email is already registered');
        err.statusCode = 409;
        throw err;
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const [result] = await pool.query(
        'INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)',
        [name, email, passwordHash]
    );

    await pool.query('INSERT INTO profiles (user_id) VALUES (?)', [result.insertId]);

    return { id: result.insertId, name, email };
}

async function loginUser(email, password) {
    const [rows] = await pool.query(
        'SELECT id, name, email, password_hash FROM users WHERE email = ?',
        [email]
    );

    if (rows.length === 0) {
        const err = new Error('Invalid email or password');
        err.statusCode = 401;
        throw err;
    }

    const user = rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);

    if (!isMatch) {
        const err = new Error('Invalid email or password');
        err.statusCode = 401;
        throw err;
    }

    const token = jwt.sign(
        { id: user.id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    return {
        token,
        user: { id: user.id, name: user.name, email: user.email }
    };
}

module.exports = { registerUser, loginUser };
EOF

# ---------- controllers/authController.js ----------
cat > src/controllers/authController.js << 'EOF'
const { registerUser, loginUser } = require('../services/authService');

async function register(req, res, next) {
    try {
        const { name, email, password } = req.body;
        const user = await registerUser(name, email, password);
        res.status(201).json({ success: true, data: user, message: 'Account created successfully' });
    } catch (err) {
        next(err);
    }
}

async function login(req, res, next) {
    try {
        const { email, password } = req.body;
        const result = await loginUser(email, password);
        res.status(200).json({ success: true, data: result, message: 'Login successful' });
    } catch (err) {
        next(err);
    }
}

module.exports = { register, login };
EOF

# ---------- middleware/authMiddleware.js ----------
cat > src/middleware/authMiddleware.js << 'EOF'
const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ success: false, message: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = { id: decoded.id, email: decoded.email };
        next();
    } catch (err) {
        return res.status(401).json({ success: false, message: 'Invalid or expired token' });
    }
}

module.exports = authMiddleware;
EOF

# ---------- routes/authRoutes.js ----------
cat > src/routes/authRoutes.js << 'EOF'
const express = require('express');
const rateLimit = require('express-rate-limit');
const { register, login } = require('../controllers/authController');
const { validateRegister, validateLogin } = require('../validators/authValidator');

const router = express.Router();

const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10,
    message: { success: false, message: 'Too many login attempts. Please try again later.' }
});

router.post('/register', validateRegister, register);
router.post('/login', loginLimiter, validateLogin, login);

module.exports = router;
EOF

# ---------- app.js (full replace) ----------
cat > src/app.js << 'EOF'
const express = require('express');
const cors = require('cors');
const errorHandler = require('./middleware/errorHandler');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (req, res) => {
    res.json({ success: true, message: 'Health Tracker API is running' });
});

app.use('/api/auth', require('./routes/authRoutes'));

app.use((req, res) => {
    res.status(404).json({ success: false, message: 'Route not found' });
});

app.use(errorHandler);

module.exports = app;
EOF

echo "Done. Files created:"
echo "  src/validators/authValidator.js"
echo "  src/services/authService.js"
echo "  src/controllers/authController.js"
echo "  src/middleware/authMiddleware.js"
echo "  src/routes/authRoutes.js"
echo "  src/app.js (replaced)"
echo ""
echo "Now run: npm run dev"
