class AppConfig {
  // Set to true to force local development (http://localhost:3000)
  static const bool forceLocalDev = false;

  // Environment override or default to production for deployed app
  static const bool _isProductionFlag = bool.fromEnvironment('PRODUCTION', defaultValue: true);

  // Active production flag: defaults to true for Web/Vercel deployment unless forceLocalDev is enabled
  static bool get isProduction => forceLocalDev ? false : _isProductionFlag;

  // Production Render Backend URL
  static const String productionUrl = String.fromEnvironment(
    'PROD_URL',
    defaultValue: 'https://delicious-chicken.onrender.com',
  );

  // Local Development Backend URL
  static const String developmentUrl = String.fromEnvironment(
    'DEV_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Active Base URL (normalized without trailing slash to prevent duplicate paths)
  static String get apiBaseUrl =>
      (isProduction ? productionUrl : developmentUrl).replaceAll(RegExp(r'/+$'), '');

  // Active Socket.IO URL (same backend root without trailing slash)
  static String get socketUrl => apiBaseUrl;
}
