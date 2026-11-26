class AppConfig {
  // Switch to true to target production Render backend
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);

  // Production Render Backend URL
  static const String productionUrl = String.fromEnvironment(
    'PROD_URL',
    defaultValue: 'https://delicious-chicken-backend.onrender.com',
  );

  // Development Localhost URL
  static const String developmentUrl = String.fromEnvironment(
    'DEV_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Admin secret key for authorized operations
  static const String adminKey = String.fromEnvironment(
    'ADMIN_KEY',
    defaultValue: 'delicious-chicken-admin-secret-2026',
  );

  // Active Base URL
  static String get apiBaseUrl => isProduction ? productionUrl : developmentUrl;

  // Active Socket.IO URL
  static String get socketUrl => isProduction ? productionUrl : developmentUrl;

  // Common headers for authenticated admin HTTP requests
  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'x-admin-key': adminKey,
  };
}
