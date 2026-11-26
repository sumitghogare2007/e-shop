const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const http = require('http');
const cors = require('cors');
const bodyParser = require('body-parser');
const { Server } = require('socket.io');

const firestoreService = require('./services/firestoreService');
const { isConfigured } = require('./firebase');
const {
    requireAdmin,
    rateLimiter,
    validateOrderInput,
    ADMIN_USERNAME,
    ADMIN_PASSWORD,
    ADMIN_SECRET_KEY
} = require('./middleware/authMiddleware');

const app = express();
const server = http.createServer(app);

// Cross-Origin Resource Sharing
app.use(cors({ origin: '*' }));
app.use(bodyParser.json());

// Initialize Socket.IO
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST", "PUT", "DELETE"]
    }
});

const PORT = process.env.PORT || 3000;

// Initialize products and seed if empty
firestoreService.initProducts()
    .then(products => console.log(`[Startup] Initialized with ${products.length} products.`))
    .catch(err => console.error('[Startup] Error initializing products:', err.message));

// ==========================================
// REAL-TIME SOCKET.IO HANDLERS
// ==========================================

io.on('connection', async (socket) => {
    console.log(`[Socket.IO] Client connected: ${socket.id}`);

    try {
        const [orders, products, hens] = await Promise.all([
            firestoreService.getAllOrders(),
            firestoreService.getAllProducts(),
            firestoreService.getHensInventory()
        ]);

        socket.emit('initial_orders', orders);
        socket.emit('initial_products', products);
        socket.emit('initial_hens', hens);
    } catch (e) {
        console.error('[Socket.IO] Error sending initial payload:', e.message);
    }

    socket.on('disconnect', () => {
        console.log(`[Socket.IO] Client disconnected: ${socket.id}`);
    });
});

// ==========================================
// ADMIN AUTHENTICATION
// ==========================================

app.post('/api/admin/login', (req, res) => {
    const { username, password } = req.body;
    if (username === ADMIN_USERNAME && password === ADMIN_PASSWORD) {
        return res.json({
            success: true,
            message: 'Admin authenticated successfully',
            admin_key: ADMIN_SECRET_KEY
        });
    }
    return res.status(401).json({
        success: false,
        message: 'Invalid admin username or password'
    });
});

// ==========================================
// ORDER API ENDPOINTS
// ==========================================

// Place an order (Rate limited + validated + server-verified prices)
app.post('/api/orders', rateLimiter(60000, 20), validateOrderInput, async (req, res) => {
    try {
        console.log(`[HTTP] Order submission received from ${req.body.name || 'Guest'} (${req.body.phone})`);

        const createdOrder = await firestoreService.createOrder(req.body);

        // Instant broadcast to connected admin panels and apps
        io.emit('new_order', createdOrder);
        console.log(`[HTTP] Order #${createdOrder.id} successfully created and broadcasted (Total: ₹${createdOrder.total_price})`);

        res.status(201).json({
            success: true,
            id: createdOrder.id,
            message: 'Order placed securely and relayed!',
            data: createdOrder
        });
    } catch (err) {
        console.error('[HTTP] Error placing order:', err.message);
        res.status(500).json({ success: false, message: 'Failed to process order', error: err.message });
    }
});

// Retrieve all orders
app.get('/api/orders', async (req, res) => {
    try {
        const orders = await firestoreService.getAllOrders();
        res.json({ success: true, data: orders });
    } catch (err) {
        console.error('[HTTP] Error fetching orders:', err.message);
        res.status(500).json({ success: false, message: 'Failed to fetch orders' });
    }
});

// Retrieve specific order by ID
app.get('/api/orders/:id', async (req, res) => {
    try {
        const order = await firestoreService.getOrderById(req.params.id);
        if (!order) {
            return res.status(404).json({ success: false, message: 'Order not found' });
        }
        res.json({ success: true, data: order });
    } catch (err) {
        console.error('[HTTP] Error fetching order:', err.message);
        res.status(500).json({ success: false, message: 'Failed to fetch order' });
    }
});

// Update order status (Admin operation)
app.put('/api/orders/:id/status', requireAdmin, async (req, res) => {
    try {
        const { status } = req.body;
        if (!status) {
            return res.status(400).json({ success: false, message: 'Status is required' });
        }

        const updatedOrder = await firestoreService.updateOrderStatus(req.params.id, status);
        if (!updatedOrder) {
            return res.status(404).json({ success: false, message: 'Order not found' });
        }

        // Broadcast status update
        io.emit('order_status_updated', updatedOrder);
        console.log(`[HTTP] Order #${req.params.id} status updated to: ${status}`);

        res.json({ success: true, message: 'Status successfully updated', data: updatedOrder });
    } catch (err) {
        console.error('[HTTP] Error updating order status:', err.message);
        res.status(500).json({ success: false, message: 'Failed to update order status' });
    }
});

// Delete an order (Admin operation)
app.delete('/api/orders/:id', requireAdmin, async (req, res) => {
    try {
        const success = await firestoreService.deleteOrder(req.params.id);
        if (!success) {
            return res.status(404).json({ success: false, message: 'Order not found' });
        }

        io.emit('order_deleted', { id: parseInt(req.params.id) });
        console.log(`[HTTP] Order #${req.params.id} deleted`);

        res.json({ success: true, message: 'Order deleted successfully' });
    } catch (err) {
        console.error('[HTTP] Error deleting order:', err.message);
        res.status(500).json({ success: false, message: 'Failed to delete order' });
    }
});

// ==========================================
// PRODUCT API ENDPOINTS
// ==========================================

// Retrieve all products
app.get('/api/products', async (req, res) => {
    try {
        const products = await firestoreService.getAllProducts();
        res.json({ success: true, data: products });
    } catch (err) {
        console.error('[HTTP] Error fetching products:', err.message);
        res.status(500).json({ success: false, message: 'Failed to fetch products' });
    }
});

// Update product price (Admin operation)
app.put('/api/products/:id/price', requireAdmin, async (req, res) => {
    try {
        const { price_per_kg } = req.body;
        if (price_per_kg === undefined || isNaN(parseFloat(price_per_kg))) {
            return res.status(400).json({ success: false, message: 'Valid price_per_kg is required' });
        }

        const updatedProduct = await firestoreService.updateProductPrice(req.params.id, price_per_kg);
        if (!updatedProduct) {
            return res.status(404).json({ success: false, message: 'Product not found' });
        }

        // Broadcast price update
        io.emit('product_updated', updatedProduct);
        console.log(`[HTTP] Product #${req.params.id} price updated to: ₹${price_per_kg}`);

        res.json({ success: true, message: 'Price successfully updated', data: updatedProduct });
    } catch (err) {
        console.error('[HTTP] Error updating product price:', err.message);
        res.status(500).json({ success: false, message: 'Failed to update product price' });
    }
});

// Add new product (Admin operation)
app.post('/api/products', requireAdmin, async (req, res) => {
    try {
        const { chicken_type, cut_type, price_per_kg } = req.body;
        if (!chicken_type || !cut_type || price_per_kg === undefined) {
            return res.status(400).json({ success: false, message: 'Missing required fields (chicken_type, cut_type, price_per_kg)' });
        }

        const newProduct = await firestoreService.addProduct(req.body);
        const allProducts = await firestoreService.getAllProducts();

        // Broadcast refreshed products
        io.emit('initial_products', allProducts);
        console.log(`[HTTP] New product added: #${newProduct.id} ${newProduct.chicken_type} - ${newProduct.cut_type}`);

        res.status(201).json({ success: true, message: 'Product added successfully', data: newProduct });
    } catch (err) {
        console.error('[HTTP] Error adding product:', err.message);
        res.status(500).json({ success: false, message: 'Failed to add product' });
    }
});

// Delete product (Admin operation)
app.delete('/api/products/:id', requireAdmin, async (req, res) => {
    try {
        await firestoreService.deleteProduct(req.params.id);
        const allProducts = await firestoreService.getAllProducts();

        // Broadcast refreshed products
        io.emit('initial_products', allProducts);
        console.log(`[HTTP] Product #${req.params.id} deleted`);

        res.json({ success: true, message: 'Product deleted successfully' });
    } catch (err) {
        console.error('[HTTP] Error deleting product:', err.message);
        res.status(500).json({ success: false, message: 'Failed to delete product' });
    }
});

// ==========================================
// INVENTORY (HENS)
// ==========================================

// Retrieve hens inventory
app.get('/api/inventory/hens', async (req, res) => {
    try {
        const hens = await firestoreService.getHensInventory();
        res.json({ success: true, data: hens });
    } catch (err) {
        console.error('[HTTP] Error fetching inventory:', err.message);
        res.status(500).json({ success: false, message: 'Failed to fetch inventory' });
    }
});

// Update hens inventory (Admin operation)
app.put('/api/inventory/hens', requireAdmin, async (req, res) => {
    try {
        const updatedHens = await firestoreService.updateHensInventory(req.body);

        io.emit('hens_updated', updatedHens);
        console.log('[HTTP] Hens inventory updated:', updatedHens);

        res.json({ success: true, message: 'Hens inventory updated', data: updatedHens });
    } catch (err) {
        console.error('[HTTP] Error updating inventory:', err.message);
        res.status(500).json({ success: false, message: 'Failed to update inventory' });
    }
});

// ==========================================
// REPORTS & ANALYTICS
// ==========================================

app.get('/api/reports', async (req, res) => {
    try {
        const reports = await firestoreService.getReports();
        res.json({ success: true, data: reports });
    } catch (err) {
        console.error('[HTTP] Error generating reports:', err.message);
        res.status(500).json({ success: false, message: 'Failed to generate reports' });
    }
});

// ==========================================
// HEALTH CHECK
// ==========================================

app.get('/api/health', async (req, res) => {
    try {
        const [orders, products] = await Promise.all([
            firestoreService.getAllOrders(),
            firestoreService.getAllProducts()
        ]);

        res.json({
            status: 'online',
            service: 'Delicious Chicken Center Backend',
            database: isConfigured ? 'cloud_firestore' : 'local_persistent',
            ordersCount: orders.length,
            productsCount: products.length,
            timestamp: new Date().toISOString()
        });
    } catch (err) {
        res.status(500).json({ status: 'error', error: err.message });
    }
});

// Global 404 Handler
app.use((req, res) => {
    res.status(404).json({ success: false, message: `Route not found: ${req.method} ${req.originalUrl}` });
});

// Global Error Handler
app.use((err, req, res, next) => {
    console.error('[Server Error]', err.stack);
    res.status(500).json({ success: false, message: 'Internal server error', error: err.message });
});

// Start the HTTP & Socket.IO server
server.listen(PORT, '0.0.0.0', () => {
    console.log(`🍗 Delicious Chicken Center Production API & Socket Server running on port ${PORT}`);
    console.log(`📡 Database mode: ${isConfigured ? 'Firebase Cloud Firestore' : 'Local Persistent Storage'}`);
});
