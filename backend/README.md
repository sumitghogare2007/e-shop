# Delicious Chicken Center — Production Backend API & Real-time Server

High-performance Node.js / Express backend with **Google Cloud Firestore** persistence and **Socket.IO** real-time synchronization for the Delicious Chicken Center customer application and admin panel.

---

## 1. Architecture Overview

- **Runtime:** Node.js (v18+)
- **Web Framework:** Express 5
- **Primary Database:** Google Cloud Firestore (via `firebase-admin` SDK)
- **Real-Time Layer:** Socket.IO v4 (WebSockets with polling fallback)
- **Hosting Target:** [Render](https://render.com) Web Service
- **Security:** Admin token authorization, rate limiting on sensitive routes, and server-side price recalculation.

```
[Flutter Customer App] <---+                               +---> [Cloud Firestore]
                           |--- HTTP REST & Socket.IO ---> |
[Flutter Admin Panel]  <---+                               +---> [Real-time Events]
```

---

## 2. Directory Structure

```text
backend/
├── data/                    # Fallback persistent storage (for offline local development)
│   └── local_db.json
├── middleware/
│   └── authMiddleware.js    # Rate limiting, admin key check, order validation
├── services/
│   └── firestoreService.js  # Atomic counters, products, orders, inventory & reports
├── firebase.js              # Centralized Firebase Admin SDK initializer
├── package.json             # Node dependencies and scripts
├── render.yaml              # Render Blueprint configuration
├── server.js                # Express & Socket.IO server entrypoint
├── .env.example             # Template for environment configuration
└── README.md                # Comprehensive documentation
```

---

## 3. Firebase Firestore Project Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create or select your project (e.g. `delicious-chicken-center`).
2. Navigate to **Build** > **Firestore Database** and click **Create Database**.
   - Choose production mode or test mode.
   - Select your preferred cloud region (e.g. `asia-south1` or `us-central1`).
3. Generate your Service Account credentials:
   - Click the gear icon ⚙️ (Project settings) > **Service accounts**.
   - Select **Firebase Admin SDK** (Node.js).
   - Click **Generate new private key** and download the resulting `.json` file.
   - **IMPORTANT:** Keep this key secret. Never commit it to GitHub.

---

## 4. Environment Variables

Create a `.env` file in the `backend/` directory based on `.env.example`:

| Variable | Description | Example |
|---|---|---|
| `PORT` | Server listen port | `3000` |
| `ADMIN_USERNAME` | Admin login username | `admin` |
| `ADMIN_PASSWORD` | Admin login password | `admin` |
| `ADMIN_SECRET_KEY` | Admin authorization key | `delicious-chicken-admin-secret-2026` |
| `STRICT_ADMIN_AUTH` | Enforce admin key on mutating routes | `true` |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | Raw JSON or Base64 string of service account file | `{"type":"service_account",...}` |
| `FIREBASE_PROJECT_ID` | (Alternative) Project ID | `delicious-chicken-center` |
| `FIREBASE_CLIENT_EMAIL` | (Alternative) Service Account Email | `firebase-adminsdk-xxx@...` |
| `FIREBASE_PRIVATE_KEY` | (Alternative) RSA Private Key | `"-----BEGIN PRIVATE KEY-----\n..."` |
| `FIREBASE_SERVICE_ACCOUNT_PATH`| (Alternative local file) | `./serviceAccountKey.json` |

---

## 5. Local Installation & Running

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Start server
npm start
```

When started without cloud credentials, the server runs in resilient local fallback mode with JSON persistence (`data/local_db.json`), ensuring you can test immediately offline.

---

## 6. REST API Reference

### Orders
- `POST /api/orders` — Submit customer order (validates items, recalculates rate from Firestore, emits `new_order`).
- `GET /api/orders` — List all orders sorted newest first.
- `GET /api/orders/:id` — Retrieve details for a specific order.
- `PUT /api/orders/:id/status` — Update status (`Pending`, `Preparing`, `Ready`, `Out for Delivery`, `Delivered`). Requires Admin.
- `DELETE /api/orders/:id` — Delete order. Requires Admin.

### Products
- `GET /api/products` — List all chicken cuts and rates.
- `POST /api/products` — Add a new product cut. Requires Admin.
- `PUT /api/products/:id/price` — Update price per kg. Requires Admin.
- `DELETE /api/products/:id` — Remove a product cut. Requires Admin.

### Inventory & Reports
- `GET /api/inventory/hens` — Get Broiler & Native total pieces and kg.
- `PUT /api/inventory/hens` — Update inventory counts. Requires Admin.
- `GET /api/reports` — Aggregated daily sales and order count statistics.

### Admin & System
- `POST /api/admin/login` — Authenticate admin credentials and retrieve `admin_key`.
- `GET /api/health` — Health check endpoint reporting service status, database type, and records count.

---

## 7. Socket.IO Real-time Events

| Event Name | Direction | Payload Description |
|---|---|---|
| `initial_orders` | Server → Client | Array of all current orders upon connection |
| `initial_products` | Server → Client | Array of all current products upon connection |
| `initial_hens` | Server → Client | Inventory object upon connection |
| `new_order` | Server → Broadcast | Newly placed order object |
| `order_status_updated` | Server → Broadcast | Updated order object with new status |
| `order_deleted` | Server → Broadcast | `{ id: <numeric_id> }` |
| `product_updated` | Server → Broadcast | Product object with updated `price_per_kg` |
| `hens_updated` | Server → Broadcast | Updated inventory object |

---

## 8. Deployment on Render

1. Log into your [Render Dashboard](https://dashboard.render.com).
2. Click **New +** > **Web Service**.
3. Connect your GitHub repository: `sumitghogare2007/e-shop`.
4. Configure service settings:
   - **Name:** `delicious-chicken-backend`
   - **Root Directory:** `backend`
   - **Environment:** `Node`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
5. Under **Environment Variables**, add:
   - `FIREBASE_SERVICE_ACCOUNT_KEY`: Paste the full contents of your `serviceAccountKey.json` as a single line (or base64 encoded).
   - `ADMIN_USERNAME`: `admin`
   - `ADMIN_PASSWORD`: `<your-secure-password>`
   - `ADMIN_SECRET_KEY`: `<your-secure-random-key>`
   - `STRICT_ADMIN_AUTH`: `true`
6. Click **Deploy Web Service**.
7. Render will provide your public URL:
   `https://delicious-chicken-backend.onrender.com`
8. Verify deployment by visiting:
   `https://delicious-chicken-backend.onrender.com/api/health`

---

## 9. Troubleshooting

- **Firestore authentication error:** Ensure `FIREBASE_SERVICE_ACCOUNT_KEY` has valid JSON without truncated quotes, or set individual variables `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, and `FIREBASE_PRIVATE_KEY` (ensure `\n` newlines are preserved).
- **CORS errors in browser:** The backend includes permissive CORS (`*`) for Flutter Web clients. If issues persist, verify requests use `https://` when the client is served over HTTPS on Vercel.
- **Port Conflict:** Set `PORT=3000` or any free port in your `.env`. On Render, `PORT` is assigned automatically.
