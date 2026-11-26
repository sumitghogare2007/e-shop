import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'config.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

void main() {
  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel - Delicious Chicken Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF1E1E2C), // Dark theme for glass effect
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: const AdminLoginScreen(),
    );
  }
}

// 1. Admin Login
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  void _login() {
    if (_emailCtrl.text == 'admin' && _passCtrl.text == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Credentials')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GlassCard(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security, size: 60, color: Colors.white),
                const SizedBox(height: 20),
                const Text('Admin Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              )
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// 2. Dashboard Layout
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<dynamic> orders = [];
  List<dynamic> products = [];
  Map<String, dynamic> stats = {'dailySales': 0.0, 'dailyOrders': 0, 'pendingOrders': 0, 'completedOrders': 0};
  Map<String, dynamic> hensInventory = {'broiler_pieces': 0, 'broiler_kg': 0.0, 'native_pieces': 0, 'native_kg': 0.0};
  late IO.Socket socket;
  late AudioPlayer _audioPlayer;
  bool isMarathi = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    if (!kIsWeb) {
      // Allow playing sound even if the device is in silent mode on mobile
      _audioPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
      ));
    }
    _fetchInitialData();
    _connectSocket();
  }

  void _fetchInitialData() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/api/orders'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            orders = List.from(data['data']);
            _calculateStats();
          });
        }
      }
    } catch (e) {
      print('Error fetching orders via HTTP: $e');
    }
  }

  void _connectSocket() {
    socket = IO.io(AppConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Connected to Admin Socket');
    });

    socket.on('initial_orders', (data) {
      if (mounted) {
        setState(() {
          orders = List.from(data);
          _calculateStats();
        });
      }
    });

    socket.on('initial_products', (data) {
      if (mounted) {
        setState(() {
          products = List.from(data);
        });
      }
    });

    socket.on('product_updated', (data) {
      if (mounted) {
        setState(() {
          int idx = products.indexWhere((p) => p['id'] == data['id']);
          if (idx != -1) products[idx] = data;
        });
      }
    });

    socket.on('initial_hens', (data) {
      if (mounted) {
        setState(() {
          hensInventory = Map<String, dynamic>.from(data);
        });
      }
    });

    socket.on('hens_updated', (data) {
      if (mounted) {
        setState(() {
          hensInventory = Map<String, dynamic>.from(data);
        });
      }
    });

    socket.on('new_order', (data) {
      if (mounted) {
        setState(() {
          orders.insert(0, data);
          _calculateStats();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                Text('🔔 New Order Arrived! #${data['id']} - ${data['name']}', style: const TextStyle(fontSize: 16)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          )
        );
        
        // 🔔 Play notification sound
        try {
          print('Playing notification sound...');
          _audioPlayer.play(AssetSource('notification.mp3')).catchError((e) {
            print('Error playing sound: $e');
          });
        } catch (e) {
          print('Exception while playing sound: $e');
        }
      }
    });

    socket.on('order_deleted', (data) {
      if (mounted) {
        setState(() {
          orders.removeWhere((o) => o['id'] == data['id']);
          _calculateStats();
        });
      }
    });
  }

  void _calculateStats() {
    double revenue = 0.0;
    int pending = 0;
    int completed = 0;
    for (var o in orders) {
      double val = double.tryParse(o['total_price']?.toString() ?? '0') ?? 0.0;
      revenue += val;
      if (o['status'] == 'Pending') pending++;
      if (o['status'] == 'Delivered') completed++;
    }
    stats['dailySales'] = revenue;
    stats['dailyOrders'] = orders.length;
    stats['pendingOrders'] = pending;
    stats['completedOrders'] = completed;
  }

  void _updateOrderStatus(int id, String newStatus) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/api/orders/$id/status'),
      headers: AppConfig.authHeaders,
      body: jsonEncode({"status": newStatus})
    );
    if (response.statusCode == 200) {
      setState(() {
        int idx = orders.indexWhere((o) => o['id'] == id);
        if (idx != -1) {
          orders[idx]['status'] = newStatus;
        }
      });
    }
  }

  void _deleteOrder(int id) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/api/orders/$id'),
      headers: AppConfig.authHeaders,
    );
    if (response.statusCode == 200) {
      setState(() {
        orders.removeWhere((o) => o['id'] == id);
        _calculateStats();
      });
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
 

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 800;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Delicious Chicken Admin'.tr(isMarathi), style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.language, color: Colors.white),
                onPressed: () => setState(() => isMarathi = !isMarathi),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  socket.disconnect();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
                }
              )
            ],
          ),
          bottomNavigationBar: isMobile ? BottomNavigationBar(
            backgroundColor: const Color(0xFF1E1E2C),
            selectedItemColor: Colors.red,
            unselectedItemColor: Colors.white54,
            currentIndex: _selectedIndex,
            onTap: (idx) => setState(() => _selectedIndex = idx),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Orders'),
              BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
            ],
          ) : null,
          body: Row(
            children: [
              if (!isMobile) ...[
                NavigationRail(
                  backgroundColor: Colors.transparent,
                  unselectedIconTheme: const IconThemeData(color: Colors.white54),
                  unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
                  selectedIconTheme: const IconThemeData(color: Colors.white),
                  selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(icon: const Icon(Icons.shopping_cart), label: Text('Orders'.tr(isMarathi))),
                    NavigationRailDestination(icon: const Icon(Icons.inventory), label: Text('Products'.tr(isMarathi))),
                    NavigationRailDestination(icon: const Icon(Icons.bar_chart), label: Text('Reports'.tr(isMarathi))),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: Colors.white24),
              ],
              Expanded(
                child: _selectedIndex == 0 ? OrdersView(orders: orders, onStatusUpdate: _updateOrderStatus, onDeleteOrder: _deleteOrder, isMarathi: isMarathi)
                     : _selectedIndex == 1 ? ProductsView(products: products, isMarathi: isMarathi)
                     : ReportsView(stats: stats, hensInventory: hensInventory, isMarathi: isMarathi)
              )
            ],
          ),
        );
      }
    );
  }
}

// 3. Orders View
class OrdersView extends StatelessWidget {
  final List<dynamic> orders;
  final Function(int, String) onStatusUpdate;
  final Function(int) onDeleteOrder;
  final bool isMarathi;

  const OrdersView({Key? key, required this.orders, required this.onStatusUpdate, required this.onDeleteOrder, this.isMarathi = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Orders (Auto-Updated)'.tr(isMarathi), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 20),
          SizedBox(
            height: 500,
            child: GlassCard(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    dataTextStyle: const TextStyle(color: Colors.white),
                    columns: [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Customer'.tr(isMarathi))),
                    DataColumn(label: Text('Location'.tr(isMarathi))),
                    DataColumn(label: Text('Type'.tr(isMarathi))),
                    DataColumn(label: Text('Payment'.tr(isMarathi))),
                    DataColumn(label: Text('Status'.tr(isMarathi))),
                    DataColumn(label: Text('Actions'.tr(isMarathi))),
                    DataColumn(label: Text('Delete'.tr(isMarathi))),
                  ],
                  rows: orders.map<DataRow>((order) {
                    return DataRow(cells: [
                      DataCell(Text('#${order['id']}')),
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(order['name']),
                          Text(order['phone'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )),
                      DataCell(Text((order['order_type'] == 'Delivery' && order['address'] != null) ? order['address'].toString() : '-', style: const TextStyle(color: Colors.yellow, fontSize: 12))),
                      DataCell(Text(
                        order['items'] != null && order['items'] is List && (order['items'] as List).isNotEmpty
                            ? (order['items'] as List).map((i) => '${i['chickenType']?.toString().tr(isMarathi) ?? ''} ${i['cutType']?.toString().tr(isMarathi) ?? ''}${i['quantityInKg'] != null ? " (${i['quantityInKg']} kg)" : ""}').join(', ')
                            : order['order_type'].toString().tr(isMarathi),
                        style: const TextStyle(color: Colors.white),
                      )),
                      DataCell(Text(order['payment_type'] == 'Online' ? 'Completed'.tr(isMarathi) : '₹${order['total_price']}', style: TextStyle(color: order['payment_type'] == 'Online' ? Colors.green : Colors.white))),
                      DataCell(Text(order['status'].toString().tr(isMarathi), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      DataCell(Theme(
                        data: Theme.of(context).copyWith(canvasColor: Colors.grey[800]),
                        child: DropdownButton<String>(
                          value: order['status'] ?? 'Pending',
                          style: const TextStyle(color: Colors.white),
                          items: ['Pending', 'Preparing', 'Ready', 'Out for Delivery', 'Delivered']
                              .toSet().toList()
                              .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) {
                            if (val != null) onStatusUpdate(order['id'], val);
                          },
                        ),
                      )),
                      DataCell(IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => onDeleteOrder(order['id']),
                      )),
                    ]);
                  }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 4. Products View
class ProductsView extends StatelessWidget {
  final List<dynamic> products;
  final bool isMarathi;
  const ProductsView({Key? key, required this.products, this.isMarathi = false}) : super(key: key);

  void _editPrice(BuildContext context, int id, String currentPrice) {
    TextEditingController _priceCtrl = TextEditingController(text: currentPrice);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Edit Price', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _priceCtrl,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Price per Kg', labelStyle: TextStyle(color: Colors.white70)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await http.put(
                Uri.parse('${AppConfig.apiBaseUrl}/api/products/$id/price'),
                headers: AppConfig.authHeaders,
                body: jsonEncode({"price_per_kg": _priceCtrl.text})
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save')
          )
        ],
      )
    );
  }

  void _addProduct(BuildContext context) {
    String selectedChickenType = 'Native';
    String selectedCutType = 'Boneless';
    final TextEditingController _customCutCtrl = TextEditingController();
    final TextEditingController _priceCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.2))),
              title: Text('Add New Product'.tr(isMarathi), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(canvasColor: const Color(0xFF1E1E2C)),
                        child: DropdownButtonFormField<String>(
                          value: selectedChickenType,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Chicken Type'.tr(isMarathi),
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                          ),
                          items: ['Native', 'Broiler'].map((type) {
                            return DropdownMenuItem(value: type, child: Text(type.tr(isMarathi)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedChickenType = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Theme(
                        data: Theme.of(context).copyWith(canvasColor: const Color(0xFF1E1E2C)),
                        child: DropdownButtonFormField<String>(
                          value: selectedCutType,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Cut Type'.tr(isMarathi),
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                          ),
                          items: ['Boneless', 'Curry Cut', 'Biryani Cut', 'Sukka Cut', 'Kaleja', 'Full Chicken', 'Mix', 'Leg Piece', 'Other/Custom...'].map((cut) {
                            return DropdownMenuItem(value: cut, child: Text(cut.tr(isMarathi)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedCutType = val;
                              });
                            }
                          },
                        ),
                      ),
                      if (selectedCutType == 'Other/Custom...') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _customCutCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Enter Custom Cut Type'.tr(isMarathi),
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter cut type'.tr(isMarathi);
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceCtrl,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Price per Kg (₹)'.tr(isMarathi),
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter price'.tr(isMarathi);
                          final p = double.tryParse(v);
                          if (p == null || p <= 0) return 'Please enter a valid price'.tr(isMarathi);
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel'.tr(isMarathi), style: const TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      final finalCutType = selectedCutType == 'Other/Custom...' ? _customCutCtrl.text.trim() : selectedCutType;
                      final finalPrice = double.parse(_priceCtrl.text);

                      try {
                        final response = await http.post(
                          Uri.parse('${AppConfig.apiBaseUrl}/api/products'),
                          headers: AppConfig.authHeaders,
                          body: jsonEncode({
                            "chicken_type": selectedChickenType,
                            "cut_type": finalCutType,
                            "price_per_kg": finalPrice,
                          }),
                        );

                        if (response.statusCode == 201) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Product Added Successfully!'.tr(isMarathi)), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add product: ${response.statusCode}'.tr(isMarathi)), backgroundColor: Colors.red),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Network error adding product'.tr(isMarathi)), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Text('Add'.tr(isMarathi), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteProduct(BuildContext context, int id, String type, String cut) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.2))),
        title: Text('Confirm Deletion'.tr(isMarathi), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '${'Are you sure you want to delete this product?'.tr(isMarathi)}\n($type - $cut)',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'.tr(isMarathi), style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final response = await http.delete(
                  Uri.parse('${AppConfig.apiBaseUrl}/api/products/$id'),
                  headers: AppConfig.authHeaders,
                );
                Navigator.pop(ctx);
                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Product Deleted Successfully!'.tr(isMarathi)), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete product'.tr(isMarathi)), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Network error deleting product'.tr(isMarathi)), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Delete'.tr(isMarathi), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Manage Products'.tr(isMarathi), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _addProduct(context), 
                child: Text('+ Add Product'.tr(isMarathi))
              )
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: GlassCard(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    dataTextStyle: const TextStyle(color: Colors.white),
                    columns: [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Type'.tr(isMarathi))),
                      DataColumn(label: Text('Cut'.tr(isMarathi))),
                      DataColumn(label: Text('Price/Kg'.tr(isMarathi))),
                      DataColumn(label: Text('Actions'.tr(isMarathi))),
                    ],
                    rows: products.map<DataRow>((prod) => DataRow(cells: [
                      DataCell(Text('${prod['id']}')),
                      DataCell(Text(prod['chicken_type'].toString().tr(isMarathi))),
                      DataCell(Text(prod['cut_type'].toString().tr(isMarathi))),
                      DataCell(Text('₹${prod['price_per_kg']}')),
                      DataCell(Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editPrice(context, prod['id'], prod['price_per_kg'].toString())),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(context, prod['id'], prod['chicken_type'].toString(), prod['cut_type'].toString())),
                        ],
                      )),
                    ])).toList(),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// 5. Reports View
class ReportsView extends StatelessWidget {
  final Map<String, dynamic> stats;
  final Map<String, dynamic> hensInventory;
  final bool isMarathi;
  const ReportsView({Key? key, required this.stats, required this.hensInventory, this.isMarathi = false}) : super(key: key);

  void _editHens(BuildContext context, String type) {
    TextEditingController _pcsCtrl = TextEditingController(text: hensInventory['${type}_pieces'].toString());
    TextEditingController _kgCtrl = TextEditingController(text: hensInventory['${type}_kg'].toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('${'Edit'.tr(isMarathi)} ${type == 'broiler' ? 'Total Hen Broiler'.tr(isMarathi) : 'Total Hen Native'.tr(isMarathi)}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _pcsCtrl, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'pieces'.tr(isMarathi), labelStyle: const TextStyle(color: Colors.white70))),
            TextField(controller: _kgCtrl, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'kg'.tr(isMarathi), labelStyle: const TextStyle(color: Colors.white70))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel'.tr(isMarathi))),
          ElevatedButton(
            onPressed: () async {
              await http.put(
                Uri.parse('${AppConfig.apiBaseUrl}/api/inventory/hens'),
                headers: AppConfig.authHeaders,
                body: jsonEncode({
                  "${type}_pieces": _pcsCtrl.text,
                  "${type}_kg": _kgCtrl.text,
                })
              );
              Navigator.pop(ctx);
            },
            child: Text('Save'.tr(isMarathi))
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Sales Reports'.tr(isMarathi), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildStatCard('Total Business Amt'.tr(isMarathi), '₹${stats['dailySales']}', Colors.green),
              _buildStatCard('Total Orders'.tr(isMarathi), '${stats['dailyOrders']}', Colors.blue),
              _buildStatCard('Pending Orders'.tr(isMarathi), '${stats['pendingOrders']}', Colors.orange),
              _buildStatCard('Completed Orders'.tr(isMarathi), '${stats['completedOrders']}', Colors.purple),
              
              _buildHensCard(context, 'Total Hen Broiler'.tr(isMarathi), 'broiler', Colors.redAccent),
              _buildHensCard(context, 'Total Hen Native'.tr(isMarathi), 'native', Colors.brown),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHensCard(BuildContext context, String title, String type, Color color) {
    return Container(
      width: 250,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.white70))),
                IconButton(icon: const Icon(Icons.edit, color: Colors.white54, size: 20), onPressed: () => _editHens(context, type), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
            const SizedBox(height: 8),
            Text('${hensInventory['${type}_pieces']} ${'pieces'.tr(isMarathi)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text('${hensInventory['${type}_kg']} ${'kg'.tr(isMarathi)}', style: const TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 200, // Fixed width for wrap
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

extension Translation on String {
  String tr(bool isMarathi) {
    if (!isMarathi) return this;
    const dictionary = {
      'Delicious Chicken Admin': 'डिलिशिअस चिकन ॲडमिन',
      'Orders': 'ऑर्डर्स',
      'Products': 'उत्पादने',
      'Reports': 'अहवाल',
      'Live Orders (Auto-Updated)': 'लाइव्ह ऑर्डर्स (स्वयं-अद्यतनित)',
      'Customer': 'ग्राहक',
      'Location': 'स्थान',
      'Type': 'प्रकार',
      'Total': 'एकूण',
      'Payment': 'पेमेंट',
      'Status': 'स्थिती',
      'Actions': 'क्रिया',
      'Completed': 'पूर्ण झाले',
      'Manage Products': 'उत्पादने व्यवस्थापित करा',
      'Cut': 'कट',
      'Price/Kg': 'किंमत/किलो',
      'Live Sales Reports': 'लाइव्ह विक्री अहवाल',
      'Total Business Amt': 'एकूण व्यवसाय रक्कम',
      'Total Orders': 'एकूण ऑर्डर्स',
      'Pending Orders': 'प्रलंबित ऑर्डर्स',
      'Completed Orders': 'पूर्ण झालेल्या ऑर्डर्स',
      'Total Hen Broiler': 'एकूण ब्रॉयलर कोंबडी',
      'Total Hen Native': 'एकूण गावरान कोंबडी',
      'pieces': 'तुकडे',
      'kg': 'किलो',
      'Edit': 'सुधारा',
      'Save': 'जतन करा',
      'Cancel': 'रद्द करा',
      'Delete': 'हटवा',
      'Native': 'गावरान',
      'Broiler': 'ब्रॉयलर',
      'Boneless': 'बोनलेस',
      'Curry Cut': 'करी कट',
      'Biryani Cut': 'बिर्याणी कट',
      'Sukka Cut': 'सुक्का कट',
      'Kaleja': 'कलेजी',
      'Full Chicken': 'अख्खी कोंबडी',
      'Mix': 'मिक्स',
      'Leg Piece': 'लेग पीस',
      'Pending': 'प्रलंबित',
      'Preparing': 'तयार होत आहे',
      'Ready': 'तयार',
      'Out for Delivery': 'डिलिव्हरीसाठी बाहेर',
      'Delivered': 'वितरित झाले',
      '+ Add Product': '+ उत्पादन जोडा',
      'Add New Product': 'नवीन उत्पादन जोडा',
      'Chicken Type': 'कोंबडीचा प्रकार',
      'Cut Type': 'कट प्रकार',
      'Enter Custom Cut Type': 'सानुकूल कट प्रकार प्रविष्ट करा',
      'Price per Kg (₹)': 'किंमत प्रति किलो (₹)',
      'Please enter cut type': 'कृपया कट प्रकार प्रविष्ट करा',
      'Please enter price': 'कृपया किंमत प्रविष्ट करा',
      'Please enter a valid price': 'कृपया वैध किंमत प्रविष्ट करा',
      'Product Added Successfully!': 'उत्पादन यशस्वीरित्या जोडले गेले!',
      'Failed to add product: ': 'उत्पादन जोडण्यात अयशस्वी: ',
      'Network error adding product': 'उत्पादन जोडताना नेटवर्क त्रुटी आली',
      'Are you sure you want to delete this product?': 'तुम्हाला खात्री आहे की तुम्ही हे उत्पादन हटवू इच्छिता?',
      'Confirm Deletion': 'हटवण्याची पुष्टी करा',
      'Product Deleted Successfully!': 'उत्पादन यशस्वीरित्या हटवले गेले!',
      'Failed to delete product': 'उत्पादन हटवण्यात अयशस्वी',
      'Network error deleting product': 'उत्पादन हटवताना नेटवर्क त्रुटी आली'
    };
    return dictionary[this] ?? this;
  }
}

