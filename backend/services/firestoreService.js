const fs = require('fs');
const path = require('path');
const { db, isConfigured } = require('../firebase');

// Ensure local persistence directory exists for offline/dev fallback
const DATA_DIR = path.join(__dirname, '..', 'data');
if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
}
const LOCAL_DB_PATH = path.join(DATA_DIR, 'local_db.json');

// Default Seed Products
const DEFAULT_PRODUCTS = [
    { id: 1, chicken_type: 'Native', cut_type: 'Boneless', price_per_kg: 350.00, image_url: 'native_boneless.jpg', available: true },
    { id: 2, chicken_type: 'Native', cut_type: 'Curry Cut', price_per_kg: 300.00, image_url: 'native_curry.jpg', available: true },
    { id: 3, chicken_type: 'Native', cut_type: 'Kaleja', price_per_kg: 250.00, image_url: 'broiler_biryani.jpg', available: true },
    { id: 4, chicken_type: 'Native', cut_type: 'Full Chicken', price_per_kg: 280.00, image_url: 'broiler_sukka.jpg', available: true },
    { id: 5, chicken_type: 'Native', cut_type: 'Mix', price_per_kg: 260.00, image_url: '', available: true },
    { id: 6, chicken_type: 'Native', cut_type: 'Leg Piece', price_per_kg: 380.00, image_url: '', available: true },
    { id: 7, chicken_type: 'Broiler', cut_type: 'Biryani Cut', price_per_kg: 220.00, image_url: '', available: true },
    { id: 8, chicken_type: 'Broiler', cut_type: 'Sukka Cut', price_per_kg: 240.00, image_url: '', available: true },
    { id: 9, chicken_type: 'Broiler', cut_type: 'Kaleja', price_per_kg: 180.00, image_url: '', available: true },
    { id: 10, chicken_type: 'Broiler', cut_type: 'Full Chicken', price_per_kg: 200.00, image_url: '', available: true },
    { id: 11, chicken_type: 'Broiler', cut_type: 'Mix', price_per_kg: 190.00, image_url: '', available: true },
    { id: 12, chicken_type: 'Broiler', cut_type: 'Leg Piece', price_per_kg: 260.00, image_url: '', available: true }
];

const DEFAULT_HENS = {
    broiler_pieces: 0,
    broiler_kg: 0.0,
    native_pieces: 0,
    native_kg: 0.0,
    updated_at: new Date().toISOString()
};

// Local storage helper for resilient fallback
function loadLocalDb() {
    try {
        if (fs.existsSync(LOCAL_DB_PATH)) {
            const data = fs.readFileSync(LOCAL_DB_PATH, 'utf8');
            return JSON.parse(data);
        }
    } catch (e) {
        console.error('[Storage] Error reading local_db.json:', e.message);
    }
    return {
        products: DEFAULT_PRODUCTS,
        orders: [],
        inventory: DEFAULT_HENS,
        counters: { orders: 0, products: 12 }
    };
}

function saveLocalDb(data) {
    try {
        fs.writeFileSync(LOCAL_DB_PATH, JSON.stringify(data, null, 2), 'utf8');
    } catch (e) {
        console.error('[Storage] Error writing local_db.json:', e.message);
    }
}

let localDb = loadLocalDb();

class FirestoreService {
    constructor() {
        this.isCloudActive = isConfigured && db !== null;
        console.log(`[FirestoreService] Initialized. Cloud Firestore Mode: ${this.isCloudActive ? 'ACTIVE' : 'FALLBACK PERSISTENCE'}`);
    }

    // Atomic Counter for sequential integer IDs (ensures Flutter client 'int id' never crashes)
    async getNextSequence(sequenceName) {
        if (!this.isCloudActive) {
            localDb.counters = localDb.counters || {};
            localDb.counters[sequenceName] = (localDb.counters[sequenceName] || 0) + 1;
            saveLocalDb(localDb);
            return localDb.counters[sequenceName];
        }

        const counterRef = db.collection('counters').doc(sequenceName);
        try {
            const nextVal = await db.runTransaction(async (t) => {
                const doc = await t.get(counterRef);
                let currentVal = 0;
                if (doc.exists) {
                    currentVal = doc.data().current || 0;
                }
                const newVal = currentVal + 1;
                t.set(counterRef, { current: newVal, updated_at: new Date().toISOString() }, { merge: true });
                return newVal;
            });
            return nextVal;
        } catch (err) {
            console.error(`[Firestore] Counter transaction error for ${sequenceName}:`, err.message);
            // Fallback counter logic
            const snapshot = await db.collection(sequenceName === 'orders' ? 'orders' : 'products').get();
            let maxId = 0;
            snapshot.forEach(d => {
                const id = parseInt(d.data().id);
                if (!isNaN(id) && id > maxId) maxId = id;
            });
            const newVal = maxId + 1;
            await counterRef.set({ current: newVal, updated_at: new Date().toISOString() }, { merge: true });
            return newVal;
        }
    }

    // ==========================================
    // PRODUCTS
    // ==========================================

    async initProducts() {
        if (!this.isCloudActive) {
            if (!localDb.products || localDb.products.length === 0) {
                localDb.products = [...DEFAULT_PRODUCTS];
                localDb.counters = localDb.counters || {};
                localDb.counters.products = 12;
                saveLocalDb(localDb);
            }
            return localDb.products;
        }

        try {
            const productsRef = db.collection('products');
            const snapshot = await productsRef.get();

            if (snapshot.empty) {
                console.log('[Firestore] Products collection empty. Seeding initial chicken products...');
                const batch = db.batch();
                for (const p of DEFAULT_PRODUCTS) {
                    const docRef = productsRef.doc(p.id.toString());
                    batch.set(docRef, {
                        ...p,
                        created_at: new Date().toISOString(),
                        updated_at: new Date().toISOString()
                    });
                }
                const counterRef = db.collection('counters').doc('products');
                batch.set(counterRef, { current: 12, updated_at: new Date().toISOString() }, { merge: true });
                await batch.commit();
                console.log('✅ [Firestore] Seeded 12 chicken products successfully.');
            }

            return await this.getAllProducts();
        } catch (err) {
            console.error('[Firestore] Error initializing products:', err.message);
            return DEFAULT_PRODUCTS;
        }
    }

    async getAllProducts() {
        if (!this.isCloudActive) {
            return localDb.products || [];
        }

        try {
            const snapshot = await db.collection('products').get();
            const products = [];
            snapshot.forEach(doc => {
                const data = doc.data();
                products.push({
                    id: parseInt(data.id) || parseInt(doc.id),
                    chicken_type: data.chicken_type,
                    cut_type: data.cut_type,
                    price_per_kg: parseFloat(data.price_per_kg),
                    image_url: data.image_url || '',
                    available: data.available !== false
                });
            });
            // Sort by ID ascending
            return products.sort((a, b) => a.id - b.id);
        } catch (err) {
            console.error('[Firestore] Error getting products:', err.message);
            return localDb.products || DEFAULT_PRODUCTS;
        }
    }

    async addProduct(productData) {
        const nextId = await this.getNextSequence('products');
        const newProduct = {
            id: nextId,
            chicken_type: productData.chicken_type,
            cut_type: productData.cut_type,
            price_per_kg: parseFloat(productData.price_per_kg),
            image_url: productData.image_url || '',
            available: productData.available !== false,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        };

        if (this.isCloudActive) {
            await db.collection('products').doc(nextId.toString()).set(newProduct);
        }

        localDb.products = localDb.products || [];
        localDb.products.push(newProduct);
        saveLocalDb(localDb);

        return newProduct;
    }

    async updateProductPrice(id, newPrice) {
        const numericId = parseInt(id);
        const parsedPrice = parseFloat(newPrice);
        const updatedAt = new Date().toISOString();

        if (this.isCloudActive) {
            const docRef = db.collection('products').doc(numericId.toString());
            const doc = await docRef.get();
            if (!doc.exists) {
                // Try finding by field
                const querySnap = await db.collection('products').where('id', '==', numericId).limit(1).get();
                if (querySnap.empty) return null;
                await querySnap.docs[0].ref.update({ price_per_kg: parsedPrice, updated_at: updatedAt });
            } else {
                await docRef.update({ price_per_kg: parsedPrice, updated_at: updatedAt });
            }
        }

        const product = (localDb.products || []).find(p => p.id === numericId);
        if (product) {
            product.price_per_kg = parsedPrice;
            product.updated_at = updatedAt;
            saveLocalDb(localDb);
            return product;
        }

        return { id: numericId, price_per_kg: parsedPrice, updated_at: updatedAt };
    }

    async deleteProduct(id) {
        const numericId = parseInt(id);

        if (this.isCloudActive) {
            const docRef = db.collection('products').doc(numericId.toString());
            await docRef.delete();
            const querySnap = await db.collection('products').where('id', '==', numericId).get();
            querySnap.forEach(d => d.ref.delete());
        }

        if (localDb.products) {
            localDb.products = localDb.products.filter(p => p.id !== numericId);
            saveLocalDb(localDb);
        }

        return true;
    }

    // ==========================================
    // ORDER CALCULATION & VERIFICATION
    // ==========================================

    async calculateAndVerifyOrder(items) {
        const currentProducts = await this.getAllProducts();
        const verifiedItems = [];
        let calculatedTotal = 0.0;

        for (const item of items) {
            // Find matched product by ID or by (chicken_type + cut_type)
            let matched = null;
            if (item.productId || item.product_id) {
                const targetId = parseInt(item.productId || item.product_id);
                matched = currentProducts.find(p => p.id === targetId);
            }
            if (!matched && item.chickenType && item.cutType) {
                matched = currentProducts.find(p =>
                    p.chicken_type.toLowerCase() === item.chickenType.toLowerCase() &&
                    p.cut_type.toLowerCase() === item.cutType.toLowerCase()
                );
            }
            if (!matched && item.cutType) {
                matched = currentProducts.find(p =>
                    p.cut_type.toLowerCase() === item.cutType.toLowerCase()
                );
            }

            const unitPrice = matched ? matched.price_per_kg : (parseFloat(item.pricePerKg) || 250.0);
            const quantity = parseFloat(item.quantityInKg) || parseFloat(item.quantity) || 1.0;
            const itemTotal = Math.round((unitPrice * quantity) * 100) / 100;

            calculatedTotal += itemTotal;

            verifiedItems.push({
                productId: matched ? matched.id : null,
                chickenType: matched ? matched.chicken_type : (item.chickenType || 'Native'),
                cutType: matched ? matched.cut_type : (item.cutType || 'Standard Cut'),
                unitPrice: unitPrice,
                quantityInKg: quantity,
                itemTotal: itemTotal
            });
        }

        calculatedTotal = Math.round(calculatedTotal * 100) / 100;
        return { verifiedItems, calculatedTotal };
    }

    // ==========================================
    // ORDERS
    // ==========================================

    async createOrder(orderInput) {
        const nextId = await this.getNextSequence('orders');

        // Security requirement: Never trust client total, calculate strictly on backend
        const rawItems = Array.isArray(orderInput.items) ? orderInput.items : [];
        const { verifiedItems, calculatedTotal } = await this.calculateAndVerifyOrder(rawItems);

        const now = new Date().toISOString();
        const newOrder = {
            id: nextId,
            customer_name: orderInput.name || orderInput.customer_name || 'Guest',
            name: orderInput.name || orderInput.customer_name || 'Guest', // Compatibility alias
            phone: orderInput.phone || 'N/A',
            address: orderInput.address || orderInput.location || 'N/A',
            latitude: orderInput.latitude ? parseFloat(orderInput.latitude) : null,
            longitude: orderInput.longitude ? parseFloat(orderInput.longitude) : null,
            items: verifiedItems,
            total_price: calculatedTotal,
            order_type: orderInput.order_type || 'Pickup',
            payment_type: orderInput.payment_type || 'Cash on Delivery',
            payment_status: orderInput.payment_status || (orderInput.payment_type === 'Online' ? 'Completed' : 'Pending'),
            status: 'Pending',
            created_at: now,
            updated_at: now
        };

        if (this.isCloudActive) {
            await db.collection('orders').doc(nextId.toString()).set(newOrder);
        }

        localDb.orders = localDb.orders || [];
        localDb.orders.unshift(newOrder);
        saveLocalDb(localDb);

        return newOrder;
    }

    async getAllOrders() {
        if (!this.isCloudActive) {
            return localDb.orders || [];
        }

        try {
            const snapshot = await db.collection('orders').orderBy('id', 'desc').get();
            const orders = [];
            snapshot.forEach(doc => {
                orders.push(doc.data());
            });
            return orders;
        } catch (err) {
            console.error('[Firestore] Error getting orders (falling back to unindexed query):', err.message);
            const snapshot = await db.collection('orders').get();
            const orders = [];
            snapshot.forEach(doc => orders.push(doc.data()));
            return orders.sort((a, b) => (b.id || 0) - (a.id || 0));
        }
    }

    async getOrderById(id) {
        const numericId = parseInt(id);

        if (this.isCloudActive) {
            const doc = await db.collection('orders').doc(numericId.toString()).get();
            if (doc.exists) return doc.data();

            // Try fallback query by 'id' attribute
            const querySnap = await db.collection('orders').where('id', '==', numericId).limit(1).get();
            if (!querySnap.empty) return querySnap.docs[0].data();
        }

        return (localDb.orders || []).find(o => o.id === numericId) || null;
    }

    async updateOrderStatus(id, newStatus) {
        const numericId = parseInt(id);
        const updatedAt = new Date().toISOString();

        let updatedOrder = null;

        if (this.isCloudActive) {
            const docRef = db.collection('orders').doc(numericId.toString());
            const doc = await docRef.get();
            if (doc.exists) {
                await docRef.update({ status: newStatus, updated_at: updatedAt });
                updatedOrder = { ...doc.data(), status: newStatus, updated_at: updatedAt };
            } else {
                const querySnap = await db.collection('orders').where('id', '==', numericId).limit(1).get();
                if (!querySnap.empty) {
                    await querySnap.docs[0].ref.update({ status: newStatus, updated_at: updatedAt });
                    updatedOrder = { ...querySnap.docs[0].data(), status: newStatus, updated_at: updatedAt };
                }
            }
        }

        const localOrder = (localDb.orders || []).find(o => o.id === numericId);
        if (localOrder) {
            localOrder.status = newStatus;
            localOrder.updated_at = updatedAt;
            saveLocalDb(localDb);
            if (!updatedOrder) updatedOrder = localOrder;
        }

        return updatedOrder;
    }

    async deleteOrder(id) {
        const numericId = parseInt(id);

        if (this.isCloudActive) {
            const docRef = db.collection('orders').doc(numericId.toString());
            await docRef.delete();
            const querySnap = await db.collection('orders').where('id', '==', numericId).get();
            querySnap.forEach(d => d.ref.delete());
        }

        if (localDb.orders) {
            localDb.orders = localDb.orders.filter(o => o.id !== numericId);
            saveLocalDb(localDb);
        }

        return true;
    }

    // ==========================================
    // INVENTORY (HENS)
    // ==========================================

    async getHensInventory() {
        if (!this.isCloudActive) {
            return localDb.inventory || DEFAULT_HENS;
        }

        try {
            const doc = await db.collection('inventory').doc('hens').get();
            if (doc.exists) {
                return doc.data();
            } else {
                await db.collection('inventory').doc('hens').set(DEFAULT_HENS);
                return DEFAULT_HENS;
            }
        } catch (err) {
            console.error('[Firestore] Error getting hens inventory:', err.message);
            return localDb.inventory || DEFAULT_HENS;
        }
    }

    async updateHensInventory(updateData) {
        const current = await this.getHensInventory();
        const updated = {
            broiler_pieces: updateData.broiler_pieces !== undefined ? parseInt(updateData.broiler_pieces) || 0 : current.broiler_pieces,
            broiler_kg: updateData.broiler_kg !== undefined ? parseFloat(updateData.broiler_kg) || 0.0 : current.broiler_kg,
            native_pieces: updateData.native_pieces !== undefined ? parseInt(updateData.native_pieces) || 0 : current.native_pieces,
            native_kg: updateData.native_kg !== undefined ? parseFloat(updateData.native_kg) || 0.0 : current.native_kg,
            updated_at: new Date().toISOString()
        };

        if (this.isCloudActive) {
            await db.collection('inventory').doc('hens').set(updated, { merge: true });
        }

        localDb.inventory = updated;
        saveLocalDb(localDb);

        return updated;
    }

    // ==========================================
    // REPORTS / ANALYTICS
    // ==========================================

    async getReports() {
        const orders = await this.getAllOrders();
        let totalRevenue = 0.0;
        let pendingOrders = 0;
        let completedOrders = 0;

        for (const o of orders) {
            const amount = parseFloat(o.total_price) || 0.0;
            totalRevenue += amount;
            if (o.status === 'Pending') pendingOrders++;
            if (o.status === 'Delivered') completedOrders++;
        }

        return {
            totalRevenue: Math.round(totalRevenue * 100) / 100,
            totalOrders: orders.length,
            dailyRevenue: Math.round(totalRevenue * 100) / 100,
            dailyOrders: orders.length,
            pendingOrders: pendingOrders,
            completedOrders: completedOrders
        };
    }
}

module.exports = new FirestoreService();
