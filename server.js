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

// IN-MEMORY STORES (No Database required for this demo!)
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


// =======================
// WEBSOCKET (SOCKET.IO)
// =======================

io.on('connection', (socket) => {
    console.log(`[Socket] Admin/User connected: ${socket.id}`);

    // Send the current list of orders immediately to newly connected admins
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
app.post('/api/orders', (req, res) => {
    console.log(`[HTTP] Incoming Order Request at ${new Date().toISOString()}`);
    console.log(`[HTTP] Request Body:`, JSON.stringify(req.body, null, 2));

    const { name, phone, address, items, order_type, payment_type, total_price } = req.body;

    const newOrder = {
        id: orderIdCounter++,
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

// Update order status (Admin updating status via REST)
app.put('/api/orders/:id/status', (req, res) => {
    const orderId = parseInt(req.params.id);
    const { status } = req.body;

    const order = orders.find(o => o.id === orderId);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    order.status = status;
    io.emit('order_status_updated', order); // Optionally notify customers who are listening

    res.json({ success: true, message: 'Status successfully updated', data: order });
});

// Delete an order (Admin clearing history)
app.delete('/api/orders/:id', (req, res) => {
    const orderId = parseInt(req.params.id);
    const initialLength = orders.length;
    orders = orders.filter(o => o.id !== orderId);
    
    if (orders.length === initialLength) {
        return res.status(404).json({ success: false, message: 'Order not found' });
    }

    io.emit('order_deleted', { id: orderId });
    res.json({ success: true, message: 'Order deleted successfully' });
});

// Update product price (Admin updating price)
app.put('/api/products/:id/price', (req, res) => {
    const productId = parseInt(req.params.id);
    const { price_per_kg } = req.body;

    const product = products.find(p => p.id === productId);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found' });

    product.price_per_kg = parseFloat(price_per_kg);

    // Broadcast the update to all connected clients (especially the mobile app)
    io.emit('product_updated', product);

    res.json({ success: true, message: 'Price successfully updated', data: product });
});

// Dashboard Analytics (Realtime)
app.get('/api/reports', (req, res) => {
    const totalOrders = orders.length;
    const totalRevenue = orders.reduce((sum, order) => sum + order.total_price, 0);

    res.json({
        success: true,
        data: {
            totalRevenue: totalRevenue,
            totalOrders: totalOrders,
            dailyRevenue: totalRevenue, // For demo, all are today
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

// Start the combined HTTP & WebSockets Node Server
server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 In-Memory Delicious Chicken Socket Server running on http://0.0.0.0:${PORT}`);
});
