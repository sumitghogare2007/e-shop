class AppConfig {
  // Set to true to force local development (http://localhost:3000)
  static const bool forceLocalDev = false;

  // Environment override or default to production for deployed app
  static const bool _isProductionFlag = bool.fromEnvironment('PRODUCTION', defaultValue: true);

  // Active production flag
  static bool get isProduction => forceLocalDev ? false : _isProductionFlag;

  // Production Render Backend URL
  static const String productionUrl = String.fromEnvironment(
    'PROD_URL',
    defaultValue: 'https://delicious-chicken.onrender.com',
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

  // Active Base URL (normalized without trailing slash)
  static String get apiBaseUrl =>
      (isProduction ? productionUrl : developmentUrl).replaceAll(RegExp(r'/+$'), '');

  // Active Socket.IO URL
  static String get socketUrl => apiBaseUrl;

  // Common headers for authenticated admin HTTP requests
  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'x-admin-key': adminKey,
  };
}
