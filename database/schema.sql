-- Health Tracker — MySQL Schema
-- Run this against a fresh database: mysql -u root -p health_tracker < schema.sql

CREATE DATABASE IF NOT EXISTS health_tracker;
USE health_tracker;

-- ============================
-- USERS
-- ============================
CREATE TABLE users (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================
-- PROFILES (1:1 with users)
-- ============================
CREATE TABLE profiles (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    user_id           INT NOT NULL UNIQUE,
    age               INT,
    height_cm         DECIMAL(5,2),
    current_weight_kg DECIMAL(5,2),
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================
-- WEIGHT RECORDS
-- ============================
CREATE TABLE weight_records (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT NOT NULL,
    weight_kg   DECIMAL(5,2) NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at  TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_weight_user (user_id),
    INDEX idx_weight_date (recorded_at)
);

-- ============================
-- WATER RECORDS
-- ============================
CREATE TABLE water_records (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT NOT NULL,
    amount_ml   INT NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at  TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_water_user (user_id),
    INDEX idx_water_date (recorded_at)
);

-- ============================
-- STEP RECORDS
-- ============================
CREATE TABLE step_records (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    steps          INT NOT NULL,
    recorded_date  DATE NOT NULL,
    deleted_at     TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_steps_user (user_id),
    INDEX idx_steps_date (recorded_date),
    UNIQUE KEY uq_steps_user_date (user_id, recorded_date)
);

-- ============================
-- SLEEP RECORDS
-- ============================
CREATE TABLE sleep_records (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    sleep_hours  DECIMAL(4,2) NOT NULL,
    sleep_date   DATE NOT NULL,
    deleted_at   TIMESTAMP NULL DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_sleep_user (user_id),
    INDEX idx_sleep_date (sleep_date),
    UNIQUE KEY uq_sleep_user_date (user_id, sleep_date)
);

-- ============================
-- GOALS
-- ============================
CREATE TABLE goals (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    type         VARCHAR(50) NOT NULL,       -- e.g. 'weight', 'steps', 'water', 'sleep'
    target_value DECIMAL(8,2) NOT NULL,
    unit         VARCHAR(20) NOT NULL,       -- e.g. 'kg', 'steps', 'ml', 'hours'
    start_date   DATE NOT NULL,
    end_date     DATE,
    status       ENUM('active', 'completed', 'abandoned') DEFAULT 'active',
    streak_count        INT DEFAULT 0,
    last_completed_date DATE NULL DEFAULT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_goals_user (user_id),
    INDEX idx_goals_status (status)
);

-- ============================
-- REMINDERS
-- ============================
CREATE TABLE reminders (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    user_id       INT NOT NULL,
    type          VARCHAR(50) NOT NULL,      -- e.g. 'water', 'sleep', 'weight_log'
    message       VARCHAR(255),
    reminder_time TIME NOT NULL,
    enabled       BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_reminders_user (user_id)
);

-- ============================
-- WORKOUTS (V1.1)
-- ============================
CREATE TABLE workouts (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    activity     VARCHAR(100) NOT NULL,
    duration_min INT,
    distance_km  DECIMAL(6,2),
    calories     INT,
    recorded_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_workouts_user (user_id)
);

-- ============================
-- MEALS (V1.1)
-- ============================
CREATE TABLE meals (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT NOT NULL,
    meal_type   ENUM('breakfast', 'lunch', 'dinner', 'snack') NOT NULL,
    calories    INT,
    protein_g   DECIMAL(5,2),
    carbs_g     DECIMAL(5,2),
    fat_g       DECIMAL(5,2),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_meals_user (user_id)
);