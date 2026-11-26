class AppConfig {
  // Update this IP address to your laptop's IP if running Admin Panel on a different device
  // If running on the same laptop, you can use 'localhost'
  static const String serverIp = 'localhost:3000'; 
  
  static const String apiBaseUrl = 'http://$serverIp';
  static const String socketUrl = 'http://$serverIp';
}
