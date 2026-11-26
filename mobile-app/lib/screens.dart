import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'models.dart';
import 'dart:async';
import 'config.dart';

// ============================================================================
// THEME CONSTANTS & PALETTE
// ============================================================================
const Color primaryRed = Color(0xFFE53935);
const Color primaryYellow = Color(0xFFFFB300);
const Color backgroundLight = Color(0xFFF8F9FA);
const Color textDark = Color(0xFF1E293B);
const Color textMuted = Color(0xFF64748B);

// ============================================================================
// REUSABLE SUBTLE GLASSMORPHISM CARD
// ============================================================================
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Border? border;

  const GlassCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 18.0,
    this.backgroundColor,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: Colors.white.withValues(alpha: 0.75),
                  width: 1.2,
                ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }
    return cardContent;
  }
}

// ============================================================================
// 1. SPLASH SCREEN
// ============================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    _animController.forward();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Stack(
        children: [
          // Subtle ambient warm background glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryRed.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryYellow.withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                backgroundColor: Colors.white.withValues(alpha: 0.90),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: primaryRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryRed.withValues(alpha: 0.2), width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 42, color: primaryRed),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Delicious Chicken Center',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Fresh • Tender • Hygienic',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryRed),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. HOME SCREEN (CATEGORIES)
// ============================================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isMar = state.isMarathi;

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text(
          'Delicious Chicken Center'.tr(isMar),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              icon: const Icon(Icons.language, size: 18),
              label: Text(
                isMar ? 'English' : 'मराठी',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: () => context.read<AppState>().toggleLanguage(),
            ),
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Welcome Header Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Chicken Category'.tr(isMar),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fresh & Quality Cuts'.tr(isMar),
                        style: const TextStyle(fontSize: 14, color: textMuted),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(radius: 4, backgroundColor: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'Open • Fresh Stock Today'.tr(isMar),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // Category Card 1: Native Chicken (गावरान)
              _buildCategoryCard(
                context,
                title: 'Native Chicken'.tr(isMar),
                subtitle: 'Traditional, organic, and flavorful.'.tr(isMar),
                imagePath: 'assets/native.png',
                startingPrice: '₹250/kg',
                isMarathi: isMar,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryScreen(chickenType: 'Native'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // Category Card 2: Broiler Chicken (ब्रॉयलर)
              _buildCategoryCard(
                context,
                title: 'Broiler Chicken'.tr(isMar),
                subtitle: 'Soft, tender, and quick to cook.'.tr(isMar),
                imagePath: 'assets/broiler.png',
                startingPrice: '₹180/kg',
                isMarathi: isMar,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryScreen(chickenType: 'Broiler'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imagePath,
    required String startingPrice,
    required bool isMarathi,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Product Thumbnail
          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryRed.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryRed.withValues(alpha: 0.1)),
            ),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: textMuted, height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${'Starting from'.tr(isMarathi)} ',
                      style: const TextStyle(fontSize: 12, color: textMuted),
                    ),
                    Text(
                      startingPrice,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Forward Pill
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryRed.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryRed),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. CATEGORY SCREEN (PRODUCT CUTS)
// ============================================================================
class CategoryScreen extends StatelessWidget {
  final String chickenType;
  const CategoryScreen({Key? key, required this.chickenType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isMar = state.isMarathi;
    final products = state.products.where((p) => p.chickenType == chickenType).toList();

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text(
          '$chickenType Chicken'.tr(isMar),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 950 ? 4 : (constraints.maxWidth > 650 ? 3 : 2);
          double childAspectRatio = constraints.maxWidth > 650 ? 0.80 : 0.76;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final prod = products[index];
                  final imageAsset = prod.cutType.toLowerCase().contains('boneless')
                      ? 'assets/cuts.png'
                      : 'assets/curry_cut.png';

                  return GlassCard(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Image Thumbnail Container
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Image.asset(imageAsset, fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Cut Name
                        Text(
                          prod.cutType.tr(isMar),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Price
                        Text(
                          '₹${prod.pricePerKg.toStringAsFixed(0)} / kg',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryRed,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Select Button
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              context.read<AppState>().selectProduct(prod);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                              );
                            },
                            child: Text(
                              'Select'.tr(isMar),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 4. CHECKOUT SCREEN
// ============================================================================
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String phone = '';
  final TextEditingController _addressCtrl = TextEditingController();
  String paymentType = 'Cash on Delivery';
  bool _isLoading = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isMar = state.isMarathi;
    final prod = state.selectedProduct;

    if (prod == null) {
      return Scaffold(
        backgroundColor: backgroundLight,
        appBar: AppBar(title: Text('Checkout'.tr(isMar))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_basket_outlined, size: 64, color: textMuted),
              const SizedBox(height: 16),
              Text(
                'No item selected'.tr(isMar),
                style: const TextStyle(fontSize: 18, color: textDark, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Back to Menu'.tr(isMar), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text('Checkout'.tr(isMar), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PRODUCT SUMMARY GLASS CARD
                GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset(
                          prod.cutType.toLowerCase().contains('boneless')
                              ? 'assets/cuts.png'
                              : 'assets/curry_cut.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${prod.chickenType} Chicken • ${prod.cutType}'.tr(isMar),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${prod.pricePerKg.toStringAsFixed(0)} / kg',
                              style: const TextStyle(
                                fontSize: 14,
                                color: primaryRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. QUANTITY SELECTOR & TOTAL AMOUNT
                GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quantity (kg):'.tr(isMar),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: primaryRed, size: 20),
                                  onPressed: () => state.updateQuantity(-0.5),
                                  splashRadius: 20,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    '${state.quantityInKg} kg',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, color: primaryRed, size: 20),
                                  onPressed: () => state.updateQuantity(0.5),
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const Divider(height: 28, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:'.tr(isMar),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textMuted),
                          ),
                          Text(
                            '₹${state.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. ORDER TYPE (PICKUP VS DELIVERY) TOGGLE
                GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Preference'.tr(isMar),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTogglePill(
                              label: 'Pickup'.tr(isMar),
                              icon: Icons.storefront_outlined,
                              isSelected: state.orderType == 'Pickup',
                              onTap: () => state.setOrderType('Pickup'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTogglePill(
                              label: 'Delivery'.tr(isMar),
                              icon: Icons.delivery_dining_outlined,
                              isSelected: state.orderType == 'Delivery',
                              onTap: () => state.setOrderType('Delivery'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. CUSTOMER DETAILS FORM
                GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Details'.tr(isMar),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          style: const TextStyle(color: textDark, fontSize: 15),
                          decoration: _inputDecoration(
                            labelText: 'Name'.tr(isMar),
                            prefixIcon: Icons.person_outline,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter your name'.tr(isMar)
                              : null,
                          onSaved: (v) => name = v?.trim() ?? '',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          style: const TextStyle(color: textDark, fontSize: 15),
                          decoration: _inputDecoration(
                            labelText: 'Phone'.tr(isMar),
                            prefixIcon: Icons.phone_outlined,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().length < 10)
                              ? 'Enter valid phone number'.tr(isMar)
                              : null,
                          onSaved: (v) => phone = v?.trim() ?? '',
                        ),
                        if (state.orderType == 'Delivery') ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _addressCtrl,
                            style: const TextStyle(color: textDark, fontSize: 15),
                            decoration: _inputDecoration(
                              labelText: 'Delivery Address'.tr(isMar),
                              prefixIcon: Icons.home_outlined,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter delivery address'.tr(isMar)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: primaryRed),
                              icon: const Icon(Icons.my_location, size: 16),
                              label: Text(
                                'Take current location'.tr(isMar),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                _addressCtrl.text = "Fetching location...";
                                Future.delayed(const Duration(milliseconds: 800), () {
                                  if (mounted) setState(() => _addressCtrl.text = "Current GPS Location");
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. PAYMENT METHOD
                GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method'.tr(isMar),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTogglePill(
                              label: 'Cash on Delivery'.tr(isMar),
                              icon: Icons.payments_outlined,
                              isSelected: paymentType == 'Cash on Delivery',
                              onTap: () => setState(() => paymentType = 'Cash on Delivery'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTogglePill(
                              label: 'Online'.tr(isMar),
                              icon: Icons.qr_code_scanner,
                              isSelected: paymentType == 'Online',
                              onTap: () => setState(() => paymentType = 'Online'),
                            ),
                          ),
                        ],
                      ),
                      if (paymentType == 'Online') ...[
                        const SizedBox(height: 18),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Scan & Pay via UPI'.tr(isMar),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Image.asset('assets/scanner.png', height: 210, fit: BoxFit.contain),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 6. PLACE ORDER PRIMARY RED BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (!(_formKey.currentState?.validate() ?? false)) return;
                            _formKey.currentState?.save();

                            setState(() => _isLoading = true);

                            int newOrderId = 0;
                            try {
                              final response = await http
                                  .post(
                                    Uri.parse('${AppConfig.apiBaseUrl}/api/orders'),
                                    headers: {"Content-Type": "application/json"},
                                    body: jsonEncode({
                                      "name": name,
                                      "phone": phone,
                                      "address": state.orderType == 'Delivery'
                                          ? _addressCtrl.text
                                          : 'Pickup In-Store',
                                      "order_type": state.orderType,
                                      "payment_type": paymentType,
                                      "total_price": state.totalPrice,
                                      "items": [
                                        {
                                          "chickenType": prod.chickenType,
                                          "cutType": prod.cutType,
                                          "quantityInKg": state.quantityInKg,
                                        }
                                      ]
                                    }),
                                  )
                                  .timeout(const Duration(seconds: 15));

                              if (response.statusCode == 201) {
                                final data = jsonDecode(response.body);
                                newOrderId = data['id'];
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Order Placed Successfully!'.tr(isMar)),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TrackingScreen(orderId: newOrderId),
                                  ),
                                );
                              } else {
                                throw Exception('Server Error: ${response.statusCode}');
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Network Error. Please try again.'.tr(isMar)),
                                  backgroundColor: primaryRed,
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            '${'Place Order'.tr(isMar)} • ₹${state.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTogglePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryRed : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText, required IconData prefixIcon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: textMuted, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: textMuted, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryRed, width: 1.5),
      ),
    );
  }
}

// ============================================================================
// 5. ORDER TRACKING SCREEN (CLEAN GLASS STEPPER)
// ============================================================================
class TrackingScreen extends StatefulWidget {
  final int orderId;
  const TrackingScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _pulseController;
  IO.Socket? socket;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _connectSocket();
    _fetchInitialOrderStatus();
  }

  void _fetchInitialOrderStatus() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/api/orders/${widget.orderId}'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] && json['data'] != null) {
          final status = json['data']['status'];
          int newStep = 0;
          if (status == 'Preparing') newStep = 1;
          if (status == 'Quality Check') newStep = 2;
          if (status == 'Ready' || status == 'Out for Delivery') newStep = 3;
          if (status == 'Delivered') newStep = 4;
          if (mounted) {
            setState(() {
              _currentStep = newStep;
            });
          }
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  void _connectSocket() {
    socket = IO.io(AppConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket!.on('order_status_updated', (data) {
      if (mounted && data['id'] == widget.orderId) {
        String status = data['status'];
        int newStep = 0;
        if (status == 'Preparing') newStep = 1;
        if (status == 'Quality Check') newStep = 2;
        if (status == 'Ready' || status == 'Out for Delivery') newStep = 3;
        if (status == 'Delivered') newStep = 4;

        setState(() {
          _currentStep = newStep;
        });
      }
    });
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMar = context.watch<AppState>().isMarathi;
    final List<Map<String, dynamic>> steps = [
      {'title': 'Order Received'.tr(isMar), 'subtitle': 'We have received your order.'.tr(isMar), 'icon': Icons.receipt_long_outlined},
      {'title': 'Preparing'.tr(isMar), 'subtitle': 'Your chicken is being freshly cut.'.tr(isMar), 'icon': Icons.kitchen_outlined},
      {'title': 'Quality Check'.tr(isMar), 'subtitle': 'Ensuring everything is perfect.'.tr(isMar), 'icon': Icons.verified_outlined},
      {'title': 'Out for Delivery'.tr(isMar), 'subtitle': 'Order is on its way to you.'.tr(isMar), 'icon': Icons.delivery_dining_outlined},
      {'title': 'Delivered'.tr(isMar), 'subtitle': 'Enjoy your meal!'.tr(isMar), 'icon': Icons.check_circle_outline},
    ];

    double progress = (_currentStep / (steps.length - 1)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: Text('Live Tracking'.tr(isMar), style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ORDER SUMMARY HEADER GLASS CARD
                GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #DCC${widget.orderId}'.tr(isMar),
                                style: const TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Arriving in 25 Mins'.tr(isMar),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryRed),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryRed.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delivery_dining, color: primaryRed, size: 24),
                          )
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Smooth Progress Line
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(primaryRed),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. VERTICAL STATUS STEPPER
                GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...List.generate(steps.length, (index) {
                        bool isCompleted = index < _currentStep;
                        bool isActive = index == _currentStep;
                        var step = steps[index];

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      Color circleColor;
                                      if (isCompleted) {
                                        circleColor = primaryRed;
                                      } else if (isActive) {
                                        circleColor = primaryRed.withValues(
                                          alpha: 0.3 + (_pulseController.value * 0.7),
                                        );
                                      } else {
                                        circleColor = const Color(0xFFE2E8F0);
                                      }

                                      return Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: circleColor,
                                          border: Border.all(
                                            color: isActive ? primaryRed : Colors.transparent,
                                            width: 2,
                                          ),
                                          boxShadow: isActive
                                              ? [
                                                  BoxShadow(
                                                    color: primaryRed.withValues(alpha: 0.35),
                                                    blurRadius: 10 * _pulseController.value,
                                                    spreadRadius: 1,
                                                  )
                                                ]
                                              : [],
                                        ),
                                        child: Icon(
                                          isCompleted ? Icons.check : step['icon'],
                                          size: 18,
                                          color: (isCompleted || isActive) ? Colors.white : textMuted,
                                        ),
                                      );
                                    },
                                  ),
                                  if (index != steps.length - 1)
                                    Expanded(
                                      child: Container(
                                        width: 2.5,
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        color: isCompleted ? primaryRed : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 28),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step['title'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isActive ? primaryRed : (isCompleted ? textDark : textMuted),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        step['subtitle'],
                                        style: const TextStyle(fontSize: 13, color: textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 3. ACTION BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('tel:+919876543210');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.call, size: 18),
                        label: Text('Call Store'.tr(isMar)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryRed,
                          side: const BorderSide(color: primaryRed, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=Delicious+Chicken+Center");
                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.platformDefault);
                            }
                          } catch (e) {
                            // Ignored
                          }
                        },
                        icon: const Icon(Icons.map, size: 18),
                        label: Text('View Map'.tr(isMar)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Back to Home'.tr(isMar),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMuted),
                    ),
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
