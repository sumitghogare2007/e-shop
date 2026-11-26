-- Option B: MySQL Database Schema for Delicious Chicken Center

CREATE DATABASE IF NOT EXISTS delicious_chicken;
USE delicious_chicken;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255),
    address TEXT,
    lat DECIMAL(10, 8),
    lng DECIMAL(11, 8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products Table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    chicken_type VARCHAR(50) NOT NULL, -- e.g., 'Native', 'Broiler'
    cut_type VARCHAR(50) NOT NULL, -- e.g., 'Boneless', 'Curry Cut', etc.
    price_per_kg DECIMAL(10, 2) NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders Table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    items JSON,
    user_id INT NULL,
    product_id INT NULL,
    quantity DECIMAL(10, 2) NULL, -- quantity in kg
    total_price DECIMAL(10, 2) NOT NULL,
    order_type VARCHAR(50) NOT NULL DEFAULT 'Pickup',
    status VARCHAR(50) DEFAULT 'Pending',
    payment_type VARCHAR(50) NOT NULL DEFAULT 'Cash on Delivery',
    location TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed Initial Products Data
INSERT INTO products (chicken_type, cut_type, price_per_kg, image_url) VALUES
('Native', 'Boneless', 350.00, ''),
('Native', 'Curry Cut', 300.00, ''),
('Native', 'Kaleja', 250.00, ''),
('Native', 'Full Chicken', 280.00, ''),
('Native', 'Mix', 260.00, ''),
('Native', 'Leg Piece', 380.00, ''),
('Broiler', 'Biryani Cut', 220.00, ''),
('Broiler', 'Sukka Cut', 240.00, ''),
('Broiler', 'Kaleja', 180.00, ''),
('Broiler', 'Full Chicken', 200.00, ''),
('Broiler', 'Mix', 190.00, ''),
('Broiler', 'Leg Piece', 260.00, '');
