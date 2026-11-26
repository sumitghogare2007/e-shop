class AppConfig {
  // Switch to true to target production Render backend
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);

  // Production Render Backend URL
  // Update this to your deployed Render service URL: e.g. https://delicious-chicken-backend.onrender.com
  static const String productionUrl = String.fromEnvironment(
    'PROD_URL',
    defaultValue: 'https://delicious-chicken-backend.onrender.com',
  );

  // Development Localhost URL
  static const String developmentUrl = String.fromEnvironment(
    'DEV_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Active Base URL (used for REST HTTP requests)
  static String get apiBaseUrl => isProduction ? productionUrl : developmentUrl;

  // Active Socket.IO URL (used for real-time WebSocket connection)
  static String get socketUrl => isProduction ? productionUrl : developmentUrl;
}
