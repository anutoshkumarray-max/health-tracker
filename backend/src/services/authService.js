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
