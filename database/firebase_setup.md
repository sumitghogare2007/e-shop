# Option A: Firebase Setup Guide

To use Firebase as the backend for the Delicious Chicken Center app, follow these integration steps. The Flutter app has an abstraction layer to switch seamlessly, but this is the required backend configuration.

## 1. Firebase Project Creation
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Create a project** and name it `Delicious Chicken Center`.
3. Disable Google Analytics for this test project (unless needed).
4. Click **Create Project**.

## 2. Authentication Setup
1. In the sidebar, select **Authentication** and click **Get Started**.
2. Under the **Sign-in method** tab, enable **Anonymous** (for quick dev) and/or **Phone Number** (for OTP).
3. If using Phone Auth, configure your app's SHA-1 and SHA-256 keys in the Firebase Project Settings.

## 3. Firestore Database Collections
We use `Cloud Firestore` to structure the datastore. Navigate to **Firestore Database** -> **Create database** (Start in Test Mode).

Create the following root collections:

### Collection: `products`
* Document ID: Auto-ID
  * `chicken_type`: String (e.g., "Native", "Broiler")
  * `cut_type`: String (e.g., "Boneless", "Curry Cut")
  * `price_per_kg`: Number 
  * `image_url`: String

### Collection: `users`
* Document ID: User's UID from Firebase Auth
  * `name`: String
  * `phone`: String
  * `email`: String
  * `address`: String
  * `lat`: Number
  * `lng`: Number

### Collection: `orders`
* Document ID: Auto-ID
  * `user_id`: String (matches User UID)
  * `product_id`: String (matches Product Auto-ID)
  * `quantity`: Number
  * `total_price`: Number
  * `order_type`: String ("Pickup", "Delivery")
  * `status`: String ("Pending", "Preparing", "Ready", "Out for Delivery", "Delivered")
  * `payment_type`: String ("COD", "UPI")
  * `created_at`: Timestamp

## 4. Flutter Integration Checklist
If choosing Firebase over the Node/MySQL option:
1. Run `flutter pub add firebase_core cloud_firestore firebase_auth` in both `mobile-app` and `admin-panel`.
2. Follow the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) commands to link both Apps to your Firebase project.
   * `dart pub global activate flutterfire_cli`
   * `flutterfire configure`
3. Inject the `FirebaseDatabaseService` in the main provider instead of `NodeDatabaseService`.
