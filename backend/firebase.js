const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const { getApps, initializeApp, cert, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

let isConfigured = false;
let db = null;
let appInstance = null;

function initializeFirebase() {
    const existingApps = getApps();
    if (existingApps.length > 0) {
        appInstance = existingApps[0];
        db = getFirestore();
        return { app: appInstance, db, isConfigured: true };
    }

    try {
        let credential = null;

        // Strategy 1: Raw JSON string or Base64-encoded string in FIREBASE_SERVICE_ACCOUNT_KEY
        if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
            let keyStr = process.env.FIREBASE_SERVICE_ACCOUNT_KEY.trim();
            // Remove any accidental wrapping quotes added by environment inputs
            if ((keyStr.startsWith('"') && keyStr.endsWith('"')) || (keyStr.startsWith("'") && keyStr.endsWith("'"))) {
                keyStr = keyStr.slice(1, -1).trim();
            }
            // Check if base64 encoded
            if (!keyStr.startsWith('{')) {
                try {
                    const decoded = Buffer.from(keyStr, 'base64').toString('utf8');
                    if (decoded.trim().startsWith('{')) {
                        keyStr = decoded.trim();
                    }
                } catch (e) {
                    // Not valid base64, proceed as raw string
                }
            }
            const serviceAccount = JSON.parse(keyStr);
            credential = cert(serviceAccount);
            console.log(`[Firebase] Initialized using FIREBASE_SERVICE_ACCOUNT_KEY (Project: ${serviceAccount.project_id || 'detected'})`);
        }
        // Strategy 2: Service Account JSON file path
        else if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
            const resolvedPath = path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
            if (fs.existsSync(resolvedPath)) {
                const serviceAccount = require(resolvedPath);
                credential = cert(serviceAccount);
                console.log(`[Firebase] Initialized using service account file at: ${resolvedPath}`);
            } else {
                console.warn(`[Firebase] Warning: Specified FIREBASE_SERVICE_ACCOUNT_PATH not found at ${resolvedPath}`);
            }
        }
        // Strategy 3: Individual Environment Variables (Render-friendly)
        else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
            const privateKey = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
            credential = cert({
                projectId: process.env.FIREBASE_PROJECT_ID,
                clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                privateKey: privateKey
            });
            console.log(`[Firebase] Initialized using individual environment variables for project: ${process.env.FIREBASE_PROJECT_ID}`);
        }
        // Strategy 4: Standard GOOGLE_APPLICATION_CREDENTIALS or Application Default
        else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
            credential = applicationDefault();
            console.log(`[Firebase] Initialized using GOOGLE_APPLICATION_CREDENTIALS: ${process.env.GOOGLE_APPLICATION_CREDENTIALS}`);
        }
        // Strategy 5: Check default local serviceAccountKey.json if present
        else {
            const defaultLocalPath = path.join(__dirname, 'serviceAccountKey.json');
            if (fs.existsSync(defaultLocalPath)) {
                const serviceAccount = require(defaultLocalPath);
                credential = cert(serviceAccount);
                console.log(`[Firebase] Initialized using local serviceAccountKey.json`);
            }
        }

        if (credential) {
            appInstance = initializeApp({
                credential: credential
            });
            db = getFirestore();
            db.settings({ ignoreUndefinedProperties: true });
            isConfigured = true;
            console.log('✅ [Firebase] Cloud Firestore connected successfully.');
        } else {
            console.warn('⚠️ [Firebase] No Firebase credentials detected in environment variables.');
            console.warn('⚠️ [Firebase] To connect Cloud Firestore, set one of:');
            console.warn('   1. FIREBASE_SERVICE_ACCOUNT_KEY (JSON string or base64)');
            console.warn('   2. FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY');
            console.warn('   3. FIREBASE_SERVICE_ACCOUNT_PATH (path to serviceAccountKey.json)');
            console.warn('⚠️ [Firebase] Running in development fallback mode with local persistence.');
        }
    } catch (err) {
        console.error('❌ [Firebase] Initialization error:', err.message);
        isConfigured = false;
        db = null;
    }

    return { app: appInstance, db, isConfigured };
}

const firebaseInstance = initializeFirebase();

module.exports = {
    app: firebaseInstance.app,
    db: firebaseInstance.db,
    isConfigured: firebaseInstance.isConfigured,
    FieldValue
};
