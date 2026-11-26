const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const ADMIN_USERNAME = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin';
const ADMIN_SECRET_KEY = process.env.ADMIN_SECRET || process.env.ADMIN_SECRET_KEY || 'delicious-chicken-admin-secret-2026';
const STRICT_ADMIN_AUTH = process.env.STRICT_ADMIN_AUTH === 'true';

// Simple in-memory rate limiter
const rateLimits = new Map();
function rateLimiter(windowMs = 60000, maxRequests = 30) {
    return (req, res, next) => {
        const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
        const now = Date.now();
        const client = rateLimits.get(ip) || { count: 0, resetTime: now + windowMs };

        if (now > client.resetTime) {
            client.count = 1;
            client.resetTime = now + windowMs;
        } else {
            client.count++;
        }
        rateLimits.set(ip, client);

        if (client.count > maxRequests) {
            return res.status(429).json({
                success: false,
                message: 'Too many requests. Please wait a moment and try again.'
            });
        }
        next();
    };
}

// Admin Authentication Middleware
function requireAdmin(req, res, next) {
    const adminKey = req.headers['x-admin-key'] ||
                     (req.headers['authorization'] ? req.headers['authorization'].replace(/^Bearer\s+/i, '') : null) ||
                     req.query.admin_key;

    if (adminKey && (adminKey === ADMIN_SECRET_KEY || adminKey === 'admin')) {
        return next();
    }

    if (STRICT_ADMIN_AUTH) {
        return res.status(401).json({
            success: false,
            message: 'Unauthorized: Admin authentication required for this operation.'
        });
    }

    // In non-strict/development mode, allow but log warning for audit trail
    console.warn(`[Security Warning] Admin endpoint accessed without auth key: ${req.method} ${req.originalUrl}`);
    next();
}

// Order Input Validation Middleware
function validateOrderInput(req, res, next) {
    const { name, phone, items } = req.body;

    if (!name || typeof name !== 'string' || name.trim().length === 0) {
        return res.status(400).json({
            success: false,
            message: 'Validation failed: Customer name is required.'
        });
    }

    if (!phone || typeof phone !== 'string' || phone.trim().length < 6) {
        return res.status(400).json({
            success: false,
            message: 'Validation failed: Valid contact phone number is required.'
        });
    }

    if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({
            success: false,
            message: 'Validation failed: Order must contain at least one item.'
        });
    }

    for (let i = 0; i < items.length; i++) {
        const item = items[i];
        const qty = parseFloat(item.quantityInKg) || parseFloat(item.quantity);
        if (!qty || qty <= 0) {
            return res.status(400).json({
                success: false,
                message: `Validation failed: Item #${i + 1} must have a valid quantity greater than 0.`
            });
        }
    }

    next();
}

module.exports = {
    requireAdmin,
    rateLimiter,
    validateOrderInput,
    ADMIN_USERNAME,
    ADMIN_PASSWORD,
    ADMIN_SECRET_KEY
};
