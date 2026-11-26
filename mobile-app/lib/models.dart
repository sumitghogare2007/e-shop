import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'config.dart';

class Product {
  final int id;
  final String chickenType;
  final String cutType;
  final double pricePerKg;
  final String imageUrl;

  Product({
    required this.id,
    required this.chickenType,
    required this.cutType,
    required this.pricePerKg,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      chickenType: json['chicken_type'],
      cutType: json['cut_type'],
      pricePerKg: double.parse(json['price_per_kg'].toString()),
      imageUrl: json['image_url'],
    );
  }
}

class AppState extends ChangeNotifier {
  List<Product> products = [
    Product(id: 1, chickenType: 'Native', cutType: 'Boneless', pricePerKg: 350.00, imageUrl: ''),
    Product(id: 2, chickenType: 'Native', cutType: 'Curry Cut', pricePerKg: 300.00, imageUrl: ''),
    Product(id: 3, chickenType: 'Native', cutType: 'Kaleja', pricePerKg: 250.00, imageUrl: ''),
    Product(id: 4, chickenType: 'Native', cutType: 'Full Chicken', pricePerKg: 280.00, imageUrl: ''),
    Product(id: 5, chickenType: 'Native', cutType: 'Mix', pricePerKg: 260.00, imageUrl: ''),
    Product(id: 6, chickenType: 'Native', cutType: 'Leg Piece', pricePerKg: 380.00, imageUrl: ''),
    
    Product(id: 7, chickenType: 'Broiler', cutType: 'Biryani Cut', pricePerKg: 220.00, imageUrl: ''),
    Product(id: 8, chickenType: 'Broiler', cutType: 'Sukka Cut', pricePerKg: 240.00, imageUrl: ''),
    Product(id: 9, chickenType: 'Broiler', cutType: 'Kaleja', pricePerKg: 180.00, imageUrl: ''),
    Product(id: 10, chickenType: 'Broiler', cutType: 'Full Chicken', pricePerKg: 200.00, imageUrl: ''),
    Product(id: 11, chickenType: 'Broiler', cutType: 'Mix', pricePerKg: 190.00, imageUrl: ''),
    Product(id: 12, chickenType: 'Broiler', cutType: 'Leg Piece', pricePerKg: 260.00, imageUrl: ''),
  ]; // Fallback if API fails

  Product? selectedProduct;
  double quantityInKg = 1.0;
  String orderType = 'Pickup';
  Map<String, String> userDetails = {};
  IO.Socket? socket;

  AppState() {
    Future.microtask(() => _connectSocket());
  }

  void _connectSocket() {
    try {
      socket = IO.io(AppConfig.socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      socket!.on('initial_products', (data) {
        if (data != null) {
          products = (data as List).map((p) => Product.fromJson(p)).toList();
          notifyListeners();
        }
      });

      socket!.on('product_updated', (data) {
        if (data != null) {
          Product updated = Product.fromJson(data);
          int idx = products.indexWhere((p) => p.id == updated.id);
          if (idx != -1) {
            products[idx] = updated;
            if (selectedProduct?.id == updated.id) {
               selectedProduct = updated;
            }
            notifyListeners();
          }
        }
      });

      socket!.on('connect_error', (err) {
        print('[Socket] Connection error: $err — Using fallback product data.');
      });
    } catch (e) {
      print('[Socket] Failed to connect: $e — Using fallback product data.');
    }
  }

  double get totalPrice => (selectedProduct?.pricePerKg ?? 0) * quantityInKg;

  void selectProduct(Product prod) {
    selectedProduct = prod;
    quantityInKg = 1.0;
    notifyListeners();
  }

  void updateQuantity(double amt) {
    double newQty = double.parse((quantityInKg + amt).toStringAsFixed(1));
    if (newQty > 0) {
      quantityInKg = newQty;
      notifyListeners();
    }
  }

  void setOrderType(String type) {
    orderType = type;
    notifyListeners();
  }

  void setUserDetails(Map<String, String> details) {
    userDetails = details;
    notifyListeners();
  }

  bool isMarathi = false;
  void toggleLanguage() {
    isMarathi = !isMarathi;
    notifyListeners();
  }
}

extension Translation on String {
  String tr(bool isMarathi) {
    if (!isMarathi) return this;
    const dictionary = {
      'Delicious Chicken Center': 'डिलिशिअस चिकन सेंटर',
      'Categories': 'श्रेण्या',
      'Native': 'गावरान',
      'Broiler': 'ब्रॉयलर',
      'Native Chicken': 'गावरान कोंबडी',
      'Broiler Chicken': 'ब्रॉयलर कोंबडी',
      'Boneless': 'बोनलेस',
      'Curry Cut': 'करी कट',
      'Biryani Cut': 'बिर्याणी कट',
      'Sukka Cut': 'सुक्का कट',
      'Checkout': 'चेकआउट',
      'Quantity (kg):': 'प्रमाण (किलो):',
      'Total:': 'एकूण:',
      'Order Type': 'ऑर्डरचा प्रकार',
      'Pickup': 'पिकअप',
      'Delivery': 'डिलिव्हरी',
      'Name': 'नाव',
      'Phone': 'फोन',
      'Delivery Address': 'डिलिव्हरी पत्ता',
      'Take current location': 'सध्याचे ठिकाण मिळवा',
      'Payment Method': 'पेमेंट पद्धत',
      'Cash on Delivery': 'कॅश ऑन डिलिव्हरी',
      'Online': 'ऑनलाइन',
      'Scan QR Code to Pay:': 'पेमेंटसाठी QR कोड स्कॅन करा:',
      'Place Order': 'ऑर्डर करा',
      'Live Tracking': 'लाइव्ह ट्रॅकिंग',
      'Order Placed': 'ऑर्डर स्वीकारली',
      'We have received your order.': 'आम्हाला तुमची ऑर्डर मिळाली आहे.',
      'Preparing': 'तयार होत आहे',
      'Your chicken is being freshly cut.': 'तुमचे चिकन ताजे कापले जात आहे.',
      'Out for Delivery / Ready': 'डिलिव्हरीसाठी बाहेर / तयार',
      'Order is on its way to you.': 'तुमची ऑर्डर तुमच्या वाटेवर आहे.',
      'Delivered': ' वितरित केले',
      'Enjoy your meal!': 'जेवणाचा आनंद घ्या!',
      'Estimated Time: 25 Mins': 'अंदाजे वेळ: 25 मिनिटे',
      'No item selected': 'कोणताही आयटम निवडला नाही',
      'Select': 'निवडा',
      'Please enter your name': 'कृपया तुमचे नाव टाका',
      'Enter valid phone number': 'कृपया वैध फोन नंबर टाका',
      'Order Placed Successfully!': 'ऑर्डर यशस्वी झाली!',
      'Network Error. Please try again.': 'नेटवर्क त्रुटी. पुन्हा प्रयत्न करा.',
      'Kaleja': 'लिव्हर/पोटी (लिव्हर)',
      'Full Chicken': 'अख्खी कोंबडी (Full)',
      'Mix': 'मिक्स कट (Mix)',
      'Leg Piece': 'लेग पीस (Leg)',
      'Traditional, organic, and flavorful.': 'पारंपारिक, सेंद्रिय आणि चविष्ट.',
      'Soft, tender, and quick to cook.': 'मऊ, कोमल आणि पटकन शिजणारे.',
      'Call Store': 'दुकानदाराला कॉल करा',
      'Back to Menu': 'मेनूकडे परत जा',
      'Please enter delivery address': 'कृपया डिलिव्हरी पत्ता टाका',
      'View Map': 'नकाशा पहा',
      'Order Received': 'ऑर्डर स्वीकारली',
      'Quality Check': 'गुणवत्ता तपासणी',
      'Ensuring everything is perfect.': 'सर्व काही योग्य असल्याची खात्री करत आहोत.',
      'Arriving in 25 Mins': '२५ मिनिटांत पोहोचत आहे',
      'Select Chicken Category': 'कोंबडीचा प्रकार निवडा',
      'Fresh & Quality Cuts': 'ताजे आणि दर्जेदार चिकन',
      'Starting from': 'सुरुवात',
      'Delivery Preference': 'डिलिव्हरी प्राधान्य',
      'Customer Details': 'ग्राहकाची माहिती',
      'Selected Product': 'निवडलेले उत्पादन',
      'Order Summary': 'ऑर्डर सारांश',
      'Back to Home': 'मुख्य पृष्ठावर जा',
      'Scan & Pay via UPI': 'UPI द्वारे स्कॅन करून पैसे भरा',
      'Open • Fresh Stock Today': 'खुले • आजचा ताजा स्टॉक',
    };
    return dictionary[this] ?? this;
  }
}
