class AppConfig {
  // Update this IP address to your laptop's IP when using USB tethering
  // Common USB tethering IP is 192.168.42.129
  // Current hardcoded IP for orders: 10.102.164.76
  // Current hardcoded IP for tracking: 10.96.115.76
  
  static const String serverIp = 'localhost:3000'; 
  
  static const String apiBaseUrl = 'http://$serverIp';
  static const String socketUrl = 'http://$serverIp';
}
