# Delicious Chicken Center - Full Stack Application

## Overview
A complete web and mobile application for ordering chicken with real-time tracking, powered by a robust Node.js + Express.js backend with MySQL database persistence and Socket.io live updates, paired with an elegant Flutter Web Admin dashboard and Customer Web/Mobile app.

---

## ⚡ Quick Start (Run Everything on Web)

Run all 3 services (Backend, Admin Panel, and Customer Panel) and automatically launch them in your browser with a single command from the project root:

```bash
npm start
```
*(or `node run_all.js`)*

This starts:
* **Backend API & WebSockets:** [http://localhost:3000](http://localhost:3000)
* **Admin Panel Web:** [http://localhost:8000](http://localhost:8000) *(Credentials: `admin` / `admin`)*
* **Customer Panel Web:** [http://localhost:8001](http://localhost:8001)

---

## 📁 Folder Structure
The workspace is split into four logic units:
* `/mobile-app` -> Customer-facing Application (Flutter Web & Mobile)
* `/admin-panel` -> Restaurant Management Dashboard (Flutter Web & Mobile)
* `/backend` -> Node.js + Express.js unified REST API + Socket.IO + MySQL
* `/database` -> MySQL schema (`schema.sql`) and Firebase setup instructions.

---

## 🗄️ Database Architecture
* **Engine:** MySQL 8.0 (Database: `delicious_chicken`)
* **Tables:** `products`, `orders`, `users`
* **Realtime Sync:** Changes in MySQL and REST endpoints immediately emit WebSockets events via Socket.io to all connected web/mobile clients.
* **Resilience:** The backend operates with hybrid MySQL persistence and an automatic in-memory fallback cache so the application continues to run seamlessly even if the database is offline.

---

## 🛠️ Individual Service Commands

### Backend API
```bash
cd backend
node server.js
```

### Admin Panel
```bash
# Serve production web build:
cd admin-panel
node serve.js

# Or run live in Flutter debug mode:
flutter run -d chrome --web-port 8000
```

### Customer Panel
```bash
# Serve production web build:
cd mobile-app
node serve.js

# Or run live in Flutter debug mode:
flutter run -d chrome --web-port 8001
```

### Building Web Bundles
```bash
# From workspace root:
npm run build
```
