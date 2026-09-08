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
