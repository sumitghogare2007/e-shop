const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const http = require('http');
const cors = require('cors');
const bodyParser = require('body-parser');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);

// Allow WebSockets and HTTP requests from anywhere since Flutter Web origins vary
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST", "PUT", "DELETE"]
    }
});

app.use(cors({ origin: '*' }));
app.use(bodyParser.json());

const PORT = process.env.PORT || 3000;

// Database connection
let db = null;
try {
    db = require('./db');
} catch (err) {
    console.warn('[DB] Warning: Could not initialize database module:', err.message);
}

// In-Memory Fallback Cache / Fast Access
let orders = [];
let orderIdCounter = 1;

let products = [
    { id: 1, chicken_type: 'Native', cut_type: 'Boneless', price_per_kg: 350.00, image_url: '' },
    { id: 2, chicken_type: 'Native', cut_type: 'Curry Cut', price_per_kg: 300.00, image_url: '' },
    { id: 3, chicken_type: 'Native', cut_type: 'Kaleja', price_per_kg: 250.00, image_url: '' },
    { id: 4, chicken_type: 'Native', cut_type: 'Full Chicken', price_per_kg: 280.00, image_url: '' },
    { id: 5, chicken_type: 'Native', cut_type: 'Mix', price_per_kg: 260.00, image_url: '' },
    { id: 6, chicken_type: 'Native', cut_type: 'Leg Piece', price_per_kg: 380.00, image_url: '' },

    { id: 7, chicken_type: 'Broiler', cut_type: 'Biryani Cut', price_per_kg: 220.00, image_url: '' },
    { id: 8, chicken_type: 'Broiler', cut_type: 'Sukka Cut', price_per_kg: 240.00, image_url: '' },
    { id: 9, chicken_type: 'Broiler', cut_type: 'Kaleja', price_per_kg: 180.00, image_url: '' },
    { id: 10, chicken_type: 'Broiler', cut_type: 'Full Chicken', price_per_kg: 200.00, image_url: '' },
    { id: 11, chicken_type: 'Broiler', cut_type: 'Mix', price_per_kg: 190.00, image_url: '' },
    { id: 12, chicken_type: 'Broiler', cut_type: 'Leg Piece', price_per_kg: 260.00, image_url: '' },
];

let totalHens = { broiler_pieces: 0, broiler_kg: 0.0, native_pieces: 0, native_kg: 0.0 };

// Initialize data from MySQL if available
async function initDatabase() {
    if (!db) return;
    try {
        // Sync products
        const [dbProducts] = await db.query('SELECT * FROM products ORDER BY id ASC');
        if (dbProducts && dbProducts.length > 0) {
            products = dbProducts.map(p => ({
                id: p.id,
                chicken_type: p.chicken_type,
                cut_type: p.cut_type,
                price_per_kg: parseFloat(p.price_per_kg),
                image_url: p.image_url || ''
            }));
            console.log(`[DB] Loaded ${products.length} products from MySQL.`);
        } else {
            console.log('[DB] Seeding products into MySQL...');
            for (const p of products) {
                await db.query(
                    'INSERT INTO products (id, chicken_type, cut_type, price_per_kg, image_url) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE price_per_kg = VALUES(price_per_kg)',
                    [p.id, p.chicken_type, p.cut_type, p.price_per_kg, p.image_url]
                );
            }
        }

        // Sync orders
        const [dbOrders] = await db.query('SELECT * FROM orders ORDER BY id DESC');
        if (dbOrders && dbOrders.length > 0) {
            orders = dbOrders.map(o => {
                let parsedItems = [];
                try {
                    parsedItems = typeof o.items === 'string' ? JSON.parse(o.items) : (o.items || []);
                } catch(e) {
                    parsedItems = [];
                }
                return {
                    id: o.id,
                    name: o.name || 'Guest',
                    phone: o.phone || 'N/A',
                    address: o.address || o.location || 'N/A',
                    items: parsedItems,
                    order_type: o.order_type || 'Pickup',
                    payment_type: o.payment_type || 'Cash on Delivery',
                    total_price: parseFloat(o.total_price) || 0.0,
                    status: o.status || 'Pending',
                    created_at: o.created_at ? new Date(o.created_at).toISOString() : new Date().toISOString()
                };
            });
            const maxId = Math.max(...orders.map(o => o.id), 0);
            orderIdCounter = maxId + 1;
            console.log(`[DB] Loaded ${orders.length} orders from MySQL.`);
        }
    } catch (err) {
        console.error('[DB] Error during database synchronization:', err.message);
    }
}

initDatabase();

// =======================
// WEBSOCKET (SOCKET.IO)
// =======================

io.on('connection', (socket) => {
    console.log(`[Socket] Client connected: ${socket.id}`);

    // Send the current list of orders, products, and hens immediately
    socket.emit('initial_orders', orders);
    socket.emit('initial_products', products);
    socket.emit('initial_hens', totalHens);

    socket.on('disconnect', () => {
        console.log(`[Socket] Disconnected: ${socket.id}`);
    });
});

// =======================
// REST APIs & BROADCASTING
// =======================

// Place Order (Called by Mobile App Flutter HTTP POST)
app.post('/api/orders', async (req, res) => {
    console.log(`[HTTP] Incoming Order Request at ${new Date().toISOString()}`);
    console.log(`[HTTP] Request Body:`, JSON.stringify(req.body, null, 2));

    const { name, phone, address, items, order_type, payment_type, total_price } = req.body;

    let assignedId = orderIdCounter++;
    const newOrder = {
        id: assignedId,
        name: name || 'Guest',
        phone: phone || 'N/A',
        address: address || 'N/A',
        items: items || [], // Array of products
        order_type: order_type || 'Pickup',
        payment_type: payment_type || 'Cash on Delivery',
        total_price: parseFloat(total_price) || 0.0,
        status: 'Pending',
        created_at: new Date().toISOString()
    };

    // Store in MySQL if connected
    if (db) {
        try {
            const [result] = await db.query(
                'INSERT INTO orders (name, phone, address, items, total_price, order_type, payment_type, status, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                    newOrder.name,
                    newOrder.phone,
                    newOrder.address,
                    JSON.stringify(newOrder.items),
                    newOrder.total_price,
                    newOrder.order_type,
                    newOrder.payment_type,
                    newOrder.status,
                    newOrder.address
                ]
            );
            if (result && result.insertId) {
                newOrder.id = result.insertId;
                if (result.insertId >= orderIdCounter) {
                    orderIdCounter = result.insertId + 1;
                }
            }
        } catch (dbErr) {
            console.error('[DB] Order MySQL insert error (fallback to memory):', dbErr.message);
        }
    }

    // Store in memory
    orders.unshift(newOrder); // Add to top

    // ⚡ INSTANT BROADCAST TO ADMIN PANEL ⚡
    io.emit('new_order', newOrder);

    console.log(`[HTTP] Order #${newOrder.id} successfully processed and Broadcasted to WebSockets!`);

    res.status(201).json({ success: true, id: newOrder.id, message: 'Order placed securely and relayed!', data: newOrder });
});

// Get all orders (Alternative for Refreshing)
app.get('/api/orders', (req, res) => {
    res.json({ success: true, data: orders });
});

// Get specific order by ID (Used by Tracking screen)
app.get('/api/orders/:id', (req, res) => {
    const orderId = parseInt(req.params.id);
    const order = orders.find(o => o.id === orderId);
    if (!order) {
        return res.status(404).json({ success: false, message: 'Order not found' });
    }
    res.json({ success: true, data: order });
});

// Update order status (Admin updating status via REST)
app.put('/api/orders/:id/status', async (req, res) => {
    const orderId = parseInt(req.params.id);
    const { status } = req.body;

    const order = orders.find(o => o.id === orderId);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    order.status = status;

    if (db) {
        try {
            await db.query('UPDATE orders SET status = ? WHERE id = ?', [status, orderId]);
        } catch (dbErr) {
            console.error('[DB] Status update error:', dbErr.message);
        }
    }

    io.emit('order_status_updated', order); // Notify customers & admin

    res.json({ success: true, message: 'Status successfully updated', data: order });
});

// Delete an order (Admin clearing history)
app.delete('/api/orders/:id', async (req, res) => {
    const orderId = parseInt(req.params.id);
    const initialLength = orders.length;
    orders = orders.filter(o => o.id !== orderId);

    if (orders.length === initialLength) {
        return res.status(404).json({ success: false, message: 'Order not found' });
    }

    if (db) {
        try {
            await db.query('DELETE FROM orders WHERE id = ?', [orderId]);
        } catch (dbErr) {
            console.error('[DB] Delete order error:', dbErr.message);
        }
    }

    io.emit('order_deleted', { id: orderId });
    res.json({ success: true, message: 'Order deleted successfully' });
});

// Get all products
app.get('/api/products', (req, res) => {
    res.json({ success: true, data: products });
});

// Update product price (Admin updating price)
app.put('/api/products/:id/price', async (req, res) => {
    const productId = parseInt(req.params.id);
    const { price_per_kg } = req.body;

    const product = products.find(p => p.id === productId);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    product.price_per_kg = parseFloat(price_per_kg);

    if (db) {
        try {
            await db.query('UPDATE products SET price_per_kg = ? WHERE id = ?', [product.price_per_kg, productId]);
        } catch (dbErr) {
            console.error('[DB] Update price error:', dbErr.message);
        }
    }

    // Broadcast the update to all connected clients (especially the mobile app)
    io.emit('product_updated', product);

    res.json({ success: true, message: 'Price successfully updated', data: product });
});

// Add new product (Admin adding product)
app.post('/api/products', async (req, res) => {
    const { chicken_type, cut_type, price_per_kg, image_url } = req.body;
    if (!chicken_type || !cut_type || price_per_kg === undefined) {
        return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    let nextId = products.length > 0 ? Math.max(...products.map(p => p.id)) + 1 : 1;

    const newProduct = {
        id: nextId,
        chicken_type: chicken_type,
        cut_type: cut_type,
        price_per_kg: parseFloat(price_per_kg),
        image_url: image_url || ''
    };

    if (db) {
        try {
            const [result] = await db.query(
                'INSERT INTO products (chicken_type, cut_type, price_per_kg, image_url) VALUES (?, ?, ?, ?)',
                [newProduct.chicken_type, newProduct.cut_type, newProduct.price_per_kg, newProduct.image_url]
            );
            if (result && result.insertId) {
                newProduct.id = result.insertId;
            }
        } catch (dbErr) {
            console.error('[DB] Product insert error:', dbErr.message);
        }
    }

    products.push(newProduct);

    // Broadcast updated products list to all clients (reactive sync)
    io.emit('initial_products', products);

    res.status(201).json({ success: true, message: 'Product added successfully', data: newProduct });
});

// Delete product (Admin deleting product)
app.delete('/api/products/:id', async (req, res) => {
    const productId = parseInt(req.params.id);
    const index = products.findIndex(p => p.id === productId);
    if (index === -1) {
        return res.status(404).json({ success: false, message: 'Product not found' });
    }

    products.splice(index, 1);

    if (db) {
        try {
            await db.query('DELETE FROM products WHERE id = ?', [productId]);
        } catch (dbErr) {
            console.error('[DB] Product delete error:', dbErr.message);
        }
    }

    // Broadcast updated products list to all clients (reactive sync)
    io.emit('initial_products', products);

    res.json({ success: true, message: 'Product deleted successfully' });
});

// Dashboard Analytics (Realtime)
app.get('/api/reports', (req, res) => {
    const totalOrders = orders.length;
    const totalRevenue = orders.reduce((sum, order) => sum + (parseFloat(order.total_price) || 0), 0);

    res.json({
        success: true,
        data: {
            totalRevenue: totalRevenue,
            totalOrders: totalOrders,
            dailyRevenue: totalRevenue,
            dailyOrders: totalOrders
        }
    });
});

// Get total hens
app.get('/api/inventory/hens', (req, res) => {
    res.json({ success: true, data: totalHens });
});

// Update total hens
app.put('/api/inventory/hens', (req, res) => {
    const { broiler_pieces, broiler_kg, native_pieces, native_kg } = req.body;
    if (broiler_pieces !== undefined) totalHens.broiler_pieces = parseInt(broiler_pieces) || 0;
    if (broiler_kg !== undefined) totalHens.broiler_kg = parseFloat(broiler_kg) || 0.0;
    if (native_pieces !== undefined) totalHens.native_pieces = parseInt(native_pieces) || 0;
    if (native_kg !== undefined) totalHens.native_kg = parseFloat(native_kg) || 0.0;

    io.emit('hens_updated', totalHens);
    res.json({ success: true, message: 'Hens inventory updated', data: totalHens });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({
        status: 'online',
        database: db ? 'connected' : 'in-memory',
        ordersCount: orders.length,
        productsCount: products.length,
        timestamp: new Date().toISOString()
    });
});

// Start the combined HTTP & WebSockets Node Server
server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Delicious Chicken Center API & Socket Server running on http://0.0.0.0:${PORT}`);
});
