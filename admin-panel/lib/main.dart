import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:audioplayers/audioplayers.dart';
import 'config.dart';

// ============================================================================
// BRAND PALETTE & DESIGN SYSTEM (Matches Delicious Chicken Center Customer App)
// ============================================================================
class AppColors {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color primaryDarkRed = Color(0xFFC62828);
  static const Color primaryLightRed = Color(0xFFFFEBEE);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFF5F3FF);
}

// Reusable Clean White Card with subtle border and soft shadow
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AdminCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: border ?? Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }
    return content;
  }
}

// Backward-compatible alias for any residual GlassCard references
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdminCard(child: child);
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
      title: 'Delicious Chicken Center — Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryRed,
          primary: AppColors.primaryRed,
          surface: AppColors.surface,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const AdminLoginScreen(),
    );
  }
}

// ============================================================================
// 1. ADMIN LOGIN SCREEN
// ============================================================================
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController(text: 'admin');
  bool _obscurePassword = true;

  void _login() {
    if (_emailCtrl.text == 'admin' && _passCtrl.text == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Credentials. Use admin / admin'),
          backgroundColor: AppColors.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AdminCard(
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header Icon
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLightRed,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.restaurant_menu, size: 36, color: AppColors.primaryRed),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Delicious Chicken Center',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Admin Management Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Username field
                  const Text(
                    'Username',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Enter admin username',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  const Text(
                    'Password',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 28),

                  // Login Button
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Sign In to Dashboard',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Default credentials: admin / admin',
                      style: TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. DASHBOARD SCREEN (Sidebar, App Bar, Real-time Socket & State)
// ============================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<dynamic> orders = [];
  List<dynamic> products = [];
  Map<String, dynamic> stats = {
    'dailySales': 0.0,
    'dailyOrders': 0,
    'pendingOrders': 0,
    'completedOrders': 0,
  };
  Map<String, dynamic> hensInventory = {
    'broiler_pieces': 0,
    'broiler_kg': 0.0,
    'native_pieces': 0,
    'native_kg': 0.0,
  };
  late IO.Socket socket;
  late AudioPlayer _audioPlayer;
  bool isMarathi = false;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    if (!kIsWeb) {
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
      debugPrint('Error fetching orders via HTTP: $e');
    }
  }

  void _connectSocket() {
    socket = IO.io(AppConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      debugPrint('Connected to Admin Socket');
      if (mounted) setState(() => isConnected = true);
    });

    socket.onDisconnect((_) {
      if (mounted) setState(() => isConnected = false);
    });

    socket.on('initial_orders', (data) {
      if (mounted && data != null) {
        setState(() {
          orders = List.from(data);
          _calculateStats();
        });
      }
    });

    socket.on('initial_products', (data) {
      if (mounted && data != null) {
        setState(() {
          products = List.from(data);
        });
      }
    });

    socket.on('product_updated', (data) {
      if (mounted && data != null) {
        setState(() {
          int idx = products.indexWhere((p) => p['id'] == data['id']);
          if (idx != -1) {
            products[idx] = data;
          }
        });
      }
    });

    socket.on('initial_hens', (data) {
      if (mounted && data != null) {
        setState(() {
          hensInventory = Map<String, dynamic>.from(data);
        });
      }
    });

    socket.on('hens_updated', (data) {
      if (mounted && data != null) {
        setState(() {
          hensInventory = Map<String, dynamic>.from(data);
        });
      }
    });

    socket.on('new_order', (data) {
      if (mounted && data != null) {
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
                Expanded(
                  child: Text(
                    '🔔 New Order #${data['id']} from ${data['name']} (₹${data['total_price']})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        try {
          _audioPlayer.play(AssetSource('notification.mp3')).catchError((e) {
            debugPrint('Audio play error: $e');
          });
        } catch (_) {}
      }
    });

    socket.on('order_status_updated', (data) {
      if (mounted && data != null) {
        setState(() {
          int idx = orders.indexWhere((o) => o['id'] == data['id']);
          if (idx != -1) {
            orders[idx] = data;
            _calculateStats();
          }
        });
      }
    });

    socket.on('order_deleted', (data) {
      if (mounted && data != null) {
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
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/api/orders/$id/status'),
        headers: AppConfig.authHeaders,
        body: jsonEncode({"status": newStatus}),
      );
      if (response.statusCode == 200) {
        setState(() {
          int idx = orders.indexWhere((o) => o['id'] == id);
          if (idx != -1) {
            orders[idx]['status'] = newStatus;
            _calculateStats();
          }
        });
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  void _deleteOrder(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Order #$id?'.tr(isMarathi), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Text('Are you sure you want to delete this order? This cannot be undone.'.tr(isMarathi)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'.tr(isMarathi), style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete'.tr(isMarathi)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
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
      } catch (e) {
        debugPrint('Error deleting order: $e');
      }
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
        bool isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.border, height: 1),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restaurant, color: AppColors.primaryRed, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delicious Chicken Center'.tr(isMarathi),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    Text(
                      'Store Management Dashboard'.tr(isMarathi),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Real-time status indicator
              Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.successLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isConnected ? AppColors.success.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'Live Sync'.tr(isMarathi) : 'Connecting...'.tr(isMarathi),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isConnected ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Language toggle
              TextButton.icon(
                icon: const Icon(Icons.language, size: 18, color: AppColors.textMedium),
                label: Text(
                  isMarathi ? 'मराठी' : 'English',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                onPressed: () => setState(() => isMarathi = !isMarathi),
              ),
              const SizedBox(width: 8),

              // Logout
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
                onPressed: () {
                  socket.disconnect();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          bottomNavigationBar: isMobile
              ? BottomNavigationBar(
                  backgroundColor: Colors.white,
                  selectedItemColor: AppColors.primaryRed,
                  unselectedItemColor: AppColors.textMuted,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  currentIndex: _selectedIndex,
                  onTap: (idx) => setState(() => _selectedIndex = idx),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      activeIcon: const Icon(Icons.shopping_bag),
                      label: 'Orders'.tr(isMarathi),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.inventory_2_outlined),
                      activeIcon: const Icon(Icons.inventory_2),
                      label: 'Products'.tr(isMarathi),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.bar_chart_outlined),
                      activeIcon: const Icon(Icons.bar_chart),
                      label: 'Reports'.tr(isMarathi),
                    ),
                  ],
                )
              : null,
          body: Row(
            children: [
              if (!isMobile) ...[
                // Desktop Sidebar
                Container(
                  width: 230,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildNavItem(
                        index: 0,
                        icon: Icons.shopping_bag_outlined,
                        activeIcon: Icons.shopping_bag,
                        title: 'Orders'.tr(isMarathi),
                        badgeCount: stats['pendingOrders'],
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.inventory_2_outlined,
                        activeIcon: Icons.inventory_2,
                        title: 'Products'.tr(isMarathi),
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.bar_chart_outlined,
                        activeIcon: Icons.bar_chart,
                        title: 'Reports'.tr(isMarathi),
                      ),
                      const Spacer(),
                      // Store Summary in bottom of sidebar
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLightRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STORE STATUS'.tr(isMarathi),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryRed, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${orders.length} ${'Total Orders'.tr(isMarathi)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            Text(
                              '₹${stats['dailySales']} ${'Revenue'.tr(isMarathi)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    OrdersView(
                      orders: orders,
                      onStatusUpdate: _updateOrderStatus,
                      onDeleteOrder: _deleteOrder,
                      isMarathi: isMarathi,
                      stats: stats,
                    ),
                    ProductsView(
                      products: products,
                      isMarathi: isMarathi,
                    ),
                    ReportsView(
                      stats: stats,
                      hensInventory: hensInventory,
                      isMarathi: isMarathi,
                      orders: orders,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    int? badgeCount,
  }) {
    bool isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? AppColors.primaryLightRed : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedIndex = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? AppColors.primaryRed : AppColors.textMuted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primaryRed : AppColors.textMedium,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. ORDERS VIEW (Modern Clean Table / Cards & Status Filters)
// ============================================================================
class OrdersView extends StatefulWidget {
  final List<dynamic> orders;
  final Function(int, String) onStatusUpdate;
  final Function(int) onDeleteOrder;
  final bool isMarathi;
  final Map<String, dynamic> stats;

  const OrdersView({
    Key? key,
    required this.orders,
    required this.onStatusUpdate,
    required this.onDeleteOrder,
    this.isMarathi = false,
    required this.stats,
  }) : super(key: key);

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  List<dynamic> get filteredOrders {
    return widget.orders.where((order) {
      // Filter by status
      if (_selectedFilter != 'All' && (order['status'] ?? 'Pending') != _selectedFilter) {
        return false;
      }
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (order['name'] ?? '').toString().toLowerCase();
        final phone = (order['phone'] ?? '').toString().toLowerCase();
        final id = (order['id'] ?? '').toString().toLowerCase();
        return name.contains(query) || phone.contains(query) || id.contains(query);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isNarrow = constraints.maxWidth < 950;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Overview Cards
            _buildOverviewRow(isNarrow),
            const SizedBox(height: 24),

            // Orders Header with Search & Status Filters
            AdminCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Orders'.tr(widget.isMarathi),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Auto-updated in real-time via WebSockets'.tr(widget.isMarathi),
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLightRed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${filteredOrders.length} ${'Orders'.tr(widget.isMarathi)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 16),

                  // Search field & Status Filter Tabs
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Filter Pills
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip('All'),
                          _buildFilterChip('Pending'),
                          _buildFilterChip('Preparing'),
                          _buildFilterChip('Ready'),
                          _buildFilterChip('Out for Delivery'),
                          _buildFilterChip('Delivered'),
                        ],
                      ),

                      // Search box
                      SizedBox(
                        width: isNarrow ? double.infinity : 260,
                        height: 42,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search order, phone...'.tr(widget.isMarathi),
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            fillColor: AppColors.background,
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Orders Table or Cards
            if (filteredOrders.isEmpty)
              AdminCard(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text(
                        'No orders found'.tr(widget.isMarathi),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Incoming orders will appear here automatically.'.tr(widget.isMarathi),
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else if (isNarrow)
              // Mobile / Tablet Card View
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _buildMobileOrderCard(filteredOrders[i]),
              )
            else
              // Desktop Clean Data Table
              AdminCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.background),
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13),
                      dataTextStyle: const TextStyle(color: AppColors.textMedium, fontSize: 13),
                      dividerThickness: 1,
                      horizontalMargin: 20,
                      columnSpacing: 24,
                      columns: [
                        DataColumn(label: Text('ID'.tr(widget.isMarathi))),
                        DataColumn(label: Text('Customer'.tr(widget.isMarathi))),
                        DataColumn(label: Text('Type & Address'.tr(widget.isMarathi))),
                        DataColumn(label: Text('Items Breakdown'.tr(widget.isMarathi))),
                        DataColumn(label: Text('Total & Payment'.tr(widget.isMarathi))),
                        DataColumn(label: Text('Status'.tr(widget.isMarathi))),
                        DataColumn(label: Text('Actions'.tr(widget.isMarathi))),
                        DataColumn(label: Text('Delete'.tr(widget.isMarathi))),
                      ],
                      rows: filteredOrders.map<DataRow>((order) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLightRed,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${order['id']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed, fontSize: 12),
                                ),
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    order['name'] ?? 'Guest',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  Text(
                                    order['phone'] ?? 'N/A',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        order['order_type'] == 'Delivery' ? Icons.delivery_dining : Icons.storefront,
                                        size: 15,
                                        color: order['order_type'] == 'Delivery' ? AppColors.info : AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (order['order_type'] ?? 'Pickup').toString().tr(widget.isMarathi),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: order['order_type'] == 'Delivery' ? AppColors.info : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (order['order_type'] == 'Delivery' && order['address'] != null)
                                    SizedBox(
                                      width: 160,
                                      child: Text(
                                        order['address'].toString(),
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  _formatItemsSummary(order['items']),
                                  style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '₹${order['total_price']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                                  ),
                                  Text(
                                    order['payment_type'] ?? 'Cash on Delivery',
                                    style: TextStyle(
                                      color: order['payment_type'] == 'Online' ? AppColors.success : AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(_buildStatusBadge(order['status'] ?? 'Pending')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: ['Pending', 'Preparing', 'Ready', 'Out for Delivery', 'Delivered'].contains(order['status'])
                                        ? order['status']
                                        : 'Pending',
                                    style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500),
                                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                                    items: ['Pending', 'Preparing', 'Ready', 'Out for Delivery', 'Delivered'].map((s) {
                                      return DropdownMenuItem(value: s, child: Text(s.tr(widget.isMarathi)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) widget.onStatusUpdate(order['id'], val);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.primaryRed, size: 20),
                                tooltip: 'Delete Order',
                                onPressed: () => widget.onDeleteOrder(order['id']),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip(String filter) {
    bool isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(filter.tr(widget.isMarathi)),
      selected: isSelected,
      selectedColor: AppColors.primaryRed,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textMedium,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      side: BorderSide(color: isSelected ? AppColors.primaryRed : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (val) => setState(() => _selectedFilter = filter),
    );
  }

  Widget _buildOverviewRow(bool isNarrow) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(
          title: "Today's Revenue".tr(widget.isMarathi),
          value: '₹${widget.stats['dailySales']}',
          icon: Icons.payments_outlined,
          color: AppColors.success,
          bgLight: AppColors.successLight,
        ),
        _buildStatCard(
          title: 'Total Orders'.tr(widget.isMarathi),
          value: '${widget.stats['dailyOrders']}',
          icon: Icons.receipt_long_outlined,
          color: AppColors.info,
          bgLight: AppColors.infoLight,
        ),
        _buildStatCard(
          title: 'Pending Orders'.tr(widget.isMarathi),
          value: '${widget.stats['pendingOrders']}',
          icon: Icons.hourglass_top_outlined,
          color: AppColors.warning,
          bgLight: AppColors.warningLight,
        ),
        _buildStatCard(
          title: 'Completed Orders'.tr(widget.isMarathi),
          value: '${widget.stats['completedOrders']}',
          icon: Icons.check_circle_outline,
          color: AppColors.purple,
          bgLight: AppColors.purpleLight,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgLight,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileOrderCard(dynamic order) {
    return AdminCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID & Status Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLightRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${order['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed, fontSize: 13),
                ),
              ),
              _buildStatusBadge(order['status'] ?? 'Pending'),
            ],
          ),
          const SizedBox(height: 12),

          // Customer details
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                order['name'] ?? 'Guest',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.phone_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                order['phone'] ?? 'N/A',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Order Type and Address
          Row(
            children: [
              Icon(
                order['order_type'] == 'Delivery' ? Icons.delivery_dining : Icons.storefront,
                size: 16,
                color: order['order_type'] == 'Delivery' ? AppColors.info : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                (order['order_type'] ?? 'Pickup').toString().tr(widget.isMarathi),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: order['order_type'] == 'Delivery' ? AppColors.info : AppColors.warning,
                ),
              ),
              if (order['order_type'] == 'Delivery' && order['address'] != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '• ${order['address']}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Items summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatItemsSummary(order['items']),
              style: const TextStyle(color: AppColors.textDark, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Footer: Total & Status dropdown & Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${order['total_price']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16),
                  ),
                  Text(
                    order['payment_type'] ?? 'Cash on Delivery',
                    style: TextStyle(
                      color: order['payment_type'] == 'Online' ? AppColors.success : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: ['Pending', 'Preparing', 'Ready', 'Out for Delivery', 'Delivered'].contains(order['status'])
                            ? order['status']
                            : 'Pending',
                        style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.bold),
                        items: ['Pending', 'Preparing', 'Ready', 'Out for Delivery', 'Delivered'].map((s) {
                          return DropdownMenuItem(value: s, child: Text(s.tr(widget.isMarathi)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) widget.onStatusUpdate(order['id'], val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.primaryRed, size: 20),
                    onPressed: () => widget.onDeleteOrder(order['id']),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Delivered':
        bg = AppColors.successLight;
        fg = AppColors.success;
        break;
      case 'Preparing':
        bg = AppColors.infoLight;
        fg = AppColors.info;
        break;
      case 'Ready':
      case 'Out for Delivery':
        bg = AppColors.purpleLight;
        fg = AppColors.purple;
        break;
      case 'Pending':
      default:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: fg)),
          const SizedBox(width: 6),
          Text(
            status.tr(widget.isMarathi),
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatItemsSummary(dynamic items) {
    if (items != null && items is List && items.isNotEmpty) {
      return items.map((i) {
        final cType = i['chickenType']?.toString().tr(widget.isMarathi) ?? '';
        final cut = i['cutType']?.toString().tr(widget.isMarathi) ?? '';
        final qty = i['quantityInKg'] != null ? " (${i['quantityInKg']} kg)" : "";
        return "$cType $cut$qty";
      }).join(', ');
    }
    return '1 Item';
  }
}

// ============================================================================
// 4. PRODUCTS & PRICE MANAGEMENT VIEW
// ============================================================================
class ProductsView extends StatefulWidget {
  final List<dynamic> products;
  final bool isMarathi;

  const ProductsView({
    Key? key,
    required this.products,
    this.isMarathi = false,
  }) : super(key: key);

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  String _activeCategory = 'All';

  List<dynamic> get filteredProducts {
    if (_activeCategory == 'Native') {
      return widget.products.where((p) => p['chicken_type'] == 'Native').toList();
    }
    if (_activeCategory == 'Broiler') {
      return widget.products.where((p) => p['chicken_type'] == 'Broiler').toList();
    }
    return widget.products;
  }

  void _editPrice(BuildContext context, int id, String currentPrice) {
    final priceCtrl = TextEditingController(text: currentPrice);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Price per Kg'.tr(widget.isMarathi), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update daily rate for this cut:'.tr(widget.isMarathi), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '₹ ',
                labelText: 'Price per Kg (₹)'.tr(widget.isMarathi),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'.tr(widget.isMarathi), style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () async {
              if (priceCtrl.text.isNotEmpty) {
                await http.put(
                  Uri.parse('${AppConfig.apiBaseUrl}/api/products/$id/price'),
                  headers: AppConfig.authHeaders,
                  body: jsonEncode({"price_per_kg": priceCtrl.text}),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text('Save Price'.tr(widget.isMarathi)),
          ),
        ],
      ),
    );
  }

  void _addProduct(BuildContext context) {
    String selectedChickenType = 'Native';
    String selectedCutType = 'Boneless';
    final customCutCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Add New Product Cut'.tr(widget.isMarathi), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedChickenType,
                        decoration: InputDecoration(
                          labelText: 'Chicken Type'.tr(widget.isMarathi),
                        ),
                        items: ['Native', 'Broiler'].map((type) {
                          return DropdownMenuItem(value: type, child: Text(type.tr(widget.isMarathi)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedChickenType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCutType,
                        decoration: InputDecoration(
                          labelText: 'Cut Type'.tr(widget.isMarathi),
                        ),
                        items: ['Boneless', 'Curry Cut', 'Biryani Cut', 'Sukka Cut', 'Kaleja', 'Full Chicken', 'Mix', 'Leg Piece', 'Other/Custom...'].map((cut) {
                          return DropdownMenuItem(value: cut, child: Text(cut.tr(widget.isMarathi)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCutType = val);
                        },
                      ),
                      if (selectedCutType == 'Other/Custom...') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: customCutCtrl,
                          decoration: InputDecoration(
                            labelText: 'Enter Custom Cut Name'.tr(widget.isMarathi),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter cut name'.tr(widget.isMarathi) : null,
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          prefixText: '₹ ',
                          labelText: 'Price per Kg (₹)'.tr(widget.isMarathi),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter price'.tr(widget.isMarathi);
                          final p = double.tryParse(v);
                          if (p == null || p <= 0) return 'Please enter a valid price'.tr(widget.isMarathi);
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
                  child: Text('Cancel'.tr(widget.isMarathi), style: const TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final finalCut = selectedCutType == 'Other/Custom...' ? customCutCtrl.text.trim() : selectedCutType;
                      final finalPrice = double.parse(priceCtrl.text);

                      try {
                        final response = await http.post(
                          Uri.parse('${AppConfig.apiBaseUrl}/api/products'),
                          headers: AppConfig.authHeaders,
                          body: jsonEncode({
                            "chicken_type": selectedChickenType,
                            "cut_type": finalCut,
                            "price_per_kg": finalPrice,
                          }),
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          if (response.statusCode == 201) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Product Added Successfully!'.tr(widget.isMarathi)),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Network error adding product'.tr(widget.isMarathi)), backgroundColor: AppColors.primaryRed),
                          );
                        }
                      }
                    }
                  },
                  child: Text('Add Product'.tr(widget.isMarathi)),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Product Cut?'.tr(widget.isMarathi), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Text('Are you sure you want to delete "$type - $cut"? This cut will no longer be available for customer ordering.'.tr(widget.isMarathi)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'.tr(widget.isMarathi), style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () async {
              try {
                final response = await http.delete(
                  Uri.parse('${AppConfig.apiBaseUrl}/api/products/$id'),
                  headers: AppConfig.authHeaders,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (response.statusCode == 200) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Product Deleted Successfully!'.tr(widget.isMarathi)), backgroundColor: AppColors.success),
                    );
                  }
                }
              } catch (_) {
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text('Delete'.tr(widget.isMarathi)),
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
          // Header Row
          AdminCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Products & Today\'s Rates'.tr(widget.isMarathi),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live prices instantly sync across all customer apps'.tr(widget.isMarathi),
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _addProduct(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Add New Cut'.tr(widget.isMarathi)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category filter tabs
          Row(
            children: [
              _buildCategoryTab('All', 'All Cuts (${widget.products.length})'),
              const SizedBox(width: 10),
              _buildCategoryTab('Native', 'Native Chicken (गावरान)'),
              const SizedBox(width: 10),
              _buildCategoryTab('Broiler', 'Broiler Chicken (ब्रॉयलर)'),
            ],
          ),
          const SizedBox(height: 20),

          // Product Cards Grid
          LayoutBuilder(builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200
                ? 4
                : constraints.maxWidth > 850
                    ? 3
                    : constraints.maxWidth > 550
                        ? 2
                        : 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 180,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (ctx, i) {
                final prod = filteredProducts[i];
                bool isNative = prod['chicken_type'] == 'Native';

                return AdminCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isNative ? AppColors.warningLight : AppColors.primaryLightRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (prod['chicken_type'] ?? '').toString().tr(widget.isMarathi),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isNative ? AppColors.warning : AppColors.primaryRed,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 18),
                            tooltip: 'Delete Product',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _deleteProduct(context, prod['id'], prod['chicken_type'], prod['cut_type']),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (prod['cut_type'] ?? '').toString().tr(widget.isMarathi),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${prod['price_per_kg']}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                              ),
                              const Text(
                                ' / kg',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit, size: 15),
                          label: Text('Edit Price'.tr(widget.isMarathi), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryRed,
                            side: const BorderSide(color: AppColors.primaryRed),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _editPrice(context, prod['id'], prod['price_per_kg'].toString()),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String category, String label) {
    bool isSelected = _activeCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryRed,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(color: isSelected ? AppColors.primaryRed : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (val) => setState(() => _activeCategory = category),
    );
  }
}

// ============================================================================
// 5. REPORTS & INVENTORY VIEW
// ============================================================================
class ReportsView extends StatelessWidget {
  final Map<String, dynamic> stats;
  final Map<String, dynamic> hensInventory;
  final bool isMarathi;
  final List<dynamic> orders;

  const ReportsView({
    Key? key,
    required this.stats,
    required this.hensInventory,
    this.isMarathi = false,
    required this.orders,
  }) : super(key: key);

  void _editHens(BuildContext context, String type) {
    final pcsCtrl = TextEditingController(text: hensInventory['${type}_pieces'].toString());
    final kgCtrl = TextEditingController(text: hensInventory['${type}_kg'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${'Edit'.tr(isMarathi)} ${type == 'broiler' ? 'Total Hen Broiler'.tr(isMarathi) : 'Total Hen Native'.tr(isMarathi)}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pcsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Pieces Available'.tr(isMarathi),
                suffixText: 'pcs',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: kgCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Total Weight (Kg)'.tr(isMarathi),
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'.tr(isMarathi), style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () async {
              await http.put(
                Uri.parse('${AppConfig.apiBaseUrl}/api/inventory/hens'),
                headers: AppConfig.authHeaders,
                body: jsonEncode({
                  "${type}_pieces": pcsCtrl.text,
                  "${type}_kg": kgCtrl.text,
                }),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Save Inventory'.tr(isMarathi)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int deliveryOrders = orders.where((o) => o['order_type'] == 'Delivery').length;
    int pickupOrders = orders.where((o) => o['order_type'] == 'Pickup').length;
    int onlinePayments = orders.where((o) => o['payment_type'] == 'Online').length;
    int codPayments = orders.where((o) => o['payment_type'] != 'Online').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Top Metrics
          AdminCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales & Inventory Reports'.tr(isMarathi),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aggregated statistics from Google Cloud Firestore'.tr(isMarathi),
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryRed),
                      const SizedBox(width: 8),
                      Text(
                        'Live Today'.tr(isMarathi),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Metric Cards Row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildBigStatCard('Total Revenue'.tr(isMarathi), '₹${stats['dailySales']}', Icons.attach_money, AppColors.success, AppColors.successLight),
              _buildBigStatCard('Total Orders'.tr(isMarathi), '${stats['dailyOrders']}', Icons.receipt_long, AppColors.info, AppColors.infoLight),
              _buildBigStatCard('Pending Orders'.tr(isMarathi), '${stats['pendingOrders']}', Icons.hourglass_empty, AppColors.warning, AppColors.warningLight),
              _buildBigStatCard('Delivered Orders'.tr(isMarathi), '${stats['completedOrders']}', Icons.task_alt, AppColors.purple, AppColors.purpleLight),
            ],
          ),
          const SizedBox(height: 28),

          // Section 2: Hen Stock Inventory
          Text(
            'Live Hen Stock Inventory'.tr(isMarathi),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHensCard(
                  context,
                  title: 'Total Hen Broiler'.tr(isMarathi),
                  type: 'broiler',
                  accentColor: AppColors.primaryRed,
                  icon: Icons.egg_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHensCard(
                  context,
                  title: 'Total Hen Native'.tr(isMarathi),
                  type: 'native',
                  accentColor: const Color(0xFFB45309), // Amber brown
                  icon: Icons.pets_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Section 3: Fulfillment & Payment Breakdown
          Text(
            'Fulfillment & Payment Breakdown'.tr(isMarathi),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order Fulfillment'.tr(isMarathi), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                          const Icon(Icons.local_shipping_outlined, color: AppColors.info, size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildProgressRow('Home Delivery'.tr(isMarathi), deliveryOrders, orders.length, AppColors.info),
                      const SizedBox(height: 12),
                      _buildProgressRow('Store Pickup'.tr(isMarathi), pickupOrders, orders.length, AppColors.warning),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Distribution'.tr(isMarathi), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                          const Icon(Icons.account_balance_wallet_outlined, color: AppColors.success, size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildProgressRow('Online Payment'.tr(isMarathi), onlinePayments, orders.length, AppColors.success),
                      const SizedBox(height: 12),
                      _buildProgressRow('Cash on Delivery'.tr(isMarathi), codPayments, orders.length, AppColors.primaryRed),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int count, int total, Color color) {
    double pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
            Text('$count orders (${(pct * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: AppColors.border,
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildBigStatCard(String title, String value, IconData icon, Color color, Color bgLight) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildHensCard(BuildContext context, {
    required String title,
    required String type,
    required Color accentColor,
    required IconData icon,
  }) {
    return AdminCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 14),
                label: Text('Update'.tr(isMarathi), style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _editHens(context, type),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pieces'.tr(isMarathi), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        '${hensInventory['${type}_pieces']} ${'pcs'.tr(isMarathi)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weight'.tr(isMarathi), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        '${hensInventory['${type}_kg']} ${'kg'.tr(isMarathi)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. BILINGUAL DICTIONARY (English & Marathi)
// ============================================================================
extension Translation on String {
  String tr(bool isMarathi) {
    if (!isMarathi) return this;
    const dictionary = {
      'Delicious Chicken Center': 'डिलिशिअस चिकन सेंटर',
      'Delicious Chicken Admin': 'डिलिशिअस चिकन ॲडमिन',
      'Store Management Dashboard': 'दुकान व्यवस्थापन डॅशबोर्ड',
      'Orders': 'ऑर्डर्स',
      'Products': 'उत्पादने',
      'Reports': 'अहवाल',
      'Live Sync': 'थेट जोडणी',
      'Connecting...': 'जोडत आहे...',
      'Live Orders': 'लाइव्ह ऑर्डर्स',
      'Live Orders (Auto-Updated)': 'लाइव्ह ऑर्डर्स (स्वयं-अद्यतनित)',
      'Auto-updated in real-time via WebSockets': 'वेबसॉकेट्सद्वारे थेट अद्यतनित',
      'Customer': 'ग्राहक',
      'Location': 'स्थान',
      'Type': 'प्रकार',
      'Type & Address': 'प्रकार आणि पत्ता',
      'Items Breakdown': 'वस्तू तपशील',
      'Total & Payment': 'एकूण आणि पेमेंट',
      'Total': 'एकूण',
      'Payment': 'पेमेंट',
      'Status': 'स्थिती',
      'Actions': 'क्रिया',
      'Completed': 'पूर्ण झाले',
      'Manage Products': 'उत्पादने व्यवस्थापित करा',
      'Manage Products & Today\'s Rates': 'उत्पादने आणि आजचे दर व्यवस्थापित करा',
      'Live prices instantly sync across all customer apps': 'थेट दर सर्व ग्राहक ॲप्सवर त्वरित अद्यतनित होतात',
      'Cut': 'कट',
      'Price/Kg': 'किंमत/किलो',
      'Price per Kg (₹)': 'किंमत प्रति किलो (₹)',
      'Live Sales Reports': 'लाइव्ह विक्री अहवाल',
      'Sales & Inventory Reports': 'विक्री आणि स्टॉक अहवाल',
      'Aggregated statistics from Google Cloud Firestore': 'गुगल क्लाउड फायरस्टोअरवरून संकलित आकडेवारी',
      'Total Business Amt': 'एकूण व्यवसाय रक्कम',
      'Total Revenue': 'एकूण महसूल',
      'Total Orders': 'एकूण ऑर्डर्स',
      'Pending Orders': 'प्रलंबित ऑर्डर्स',
      'Completed Orders': 'पूर्ण झालेल्या ऑर्डर्स',
      'Delivered Orders': 'वितरित ऑर्डर्स',
      'Today\'s Revenue': 'आजचा महसूल',
      'Live Hen Stock Inventory': 'थेट कोंबडी साठा',
      'Total Hen Broiler': 'एकूण ब्रॉयलर कोंबडी',
      'Total Hen Native': 'एकूण गावरान कोंबडी',
      'Pieces Available': 'उपलब्ध नग (तुकडे)',
      'Total Weight (Kg)': 'एकूण वजन (किलो)',
      'pieces': 'तुकडे',
      'Pieces': 'नग',
      'Weight': 'वजन',
      'pcs': 'नग',
      'kg': 'किलो',
      'Edit': 'सुधारा',
      'Save': 'जतन करा',
      'Save Price': 'किंमत जतन करा',
      'Save Inventory': 'साठा जतन करा',
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
      'Pickup': 'दुकान पिकअप',
      'Delivery': 'घरपोच डिलिव्हरी',
      'Home Delivery': 'घरपोच डिलिव्हरी',
      'Store Pickup': 'दुकान पिकअप',
      'Store Pickup / Delivery': 'पिकअप / डिलिव्हरी',
      '+ Add Product': '+ उत्पादन जोडा',
      'Add New Cut': 'नवीन कट जोडा',
      'Add New Product': 'नवीन उत्पादन जोडा',
      'Add New Product Cut': 'नवीन उत्पादन कट जोडा',
      'Chicken Type': 'कोंबडीचा प्रकार',
      'Cut Type': 'कट प्रकार',
      'Enter Custom Cut Name': 'सानुकूल कट नाव प्रविष्ट करा',
      'Enter Custom Cut Type': 'सानुकूल कट प्रकार प्रविष्ट करा',
      'Please enter cut type': 'कृपया कट प्रकार प्रविष्ट करा',
      'Please enter cut name': 'कृपया कट नाव प्रविष्ट करा',
      'Please enter price': 'कृपया किंमत प्रविष्ट करा',
      'Please enter a valid price': 'कृपया वैध किंमत प्रविष्ट करा',
      'Product Added Successfully!': 'उत्पादन यशस्वीरित्या जोडले गेले!',
      'Failed to add product: ': 'उत्पादन जोडण्यात अयशस्वी: ',
      'Network error adding product': 'उत्पादन जोडताना नेटवर्क त्रुटी आली',
      'Are you sure you want to delete this product?': 'तुम्हाला खात्री आहे की तुम्ही हे उत्पादन हटवू इच्छिता?',
      'Delete Product Cut?': 'उत्पादन कट हटवायचे का?',
      'Confirm Deletion': 'हटवण्याची पुष्टी करा',
      'Product Deleted Successfully!': 'उत्पादन यशस्वीरित्या हटवले गेले!',
      'Failed to delete product': 'उत्पादन हटवण्यात अयशस्वी',
      'Network error deleting product': 'उत्पादन हटवताना नेटवर्क त्रुटी आली',
      'Order Fulfillment': 'ऑर्डर पूर्तता',
      'Payment Distribution': 'पेमेंट वितरण',
      'Online Payment': 'ऑनलाइन पेमेंट',
      'Cash on Delivery': 'कॅश ऑन डिलिव्हरी',
      'Search order, phone...': 'ऑर्डर, फोन शोधा...',
      'No orders found': 'कोणतीही ऑर्डर सापडली नाही',
      'Incoming orders will appear here automatically.': 'येणाऱ्या ऑर्डर्स आपोआप येथे दिसतील.',
      'Live Today': 'आजचे थेट',
      'Revenue': 'महसूल',
      'STORE STATUS': 'दुकान स्थिती',
      'Update': 'सुधारा',
    };
    return dictionary[this] ?? this;
  }
}
