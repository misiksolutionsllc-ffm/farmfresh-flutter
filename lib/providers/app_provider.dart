import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AppProvider extends ChangeNotifier {
  // State
  UserRole? _role;
  String? _currentUserId;
  PlatformSettings settings = PlatformSettings();
  List<User> users = [];
  List<Product> products = [];
  List<Order> orders = [];
  List<Delivery> deliveries = [];
  List<Transaction> transactions = [];
  List<Review> reviews = [];
  List<PromoCode> promos = [];
  List<AppNotification> notifications = [];
  List<CartItem> cart = [];

  // Toast
  String? toastMessage;
  String toastType = 'success';

  // Getters
  UserRole? get role => _role;
  String? get currentUserId => _currentUserId;
  User? get currentUser => users.cast<User?>().firstWhere(
        (u) => u?.id == _currentUserId, orElse: () => null);

  int get cartCount => cart.fold(0, (s, i) => s + i.qty);
  double get cartTotal => cart.fold(0.0, (s, i) => s + i.price * i.qty);

  int get unreadNotificationCount =>
      notifications.where((n) => n.userId == _currentUserId && !n.read).length;

  AppProvider() {
    _initSeedData();
    _loadFromDisk();
  }

  // ============================================
  // Role & User
  // ============================================
  void setRole(UserRole? role) {
    _role = role;
    if (role != null) {
      final user = users.cast<User?>().firstWhere(
            (u) => u?.role == role, orElse: () => null);
      _currentUserId = user?.id;
    } else {
      _currentUserId = null;
    }
    notifyListeners();
  }

  // ============================================
  // Toast
  // ============================================
  void showToast(String message, [String type = 'success']) {
    toastMessage = message;
    toastType = type;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      if (toastMessage == message) {
        toastMessage = null;
        notifyListeners();
      }
    });
  }

  void hideToast() {
    toastMessage = null;
    notifyListeners();
  }

  // ============================================
  // Cart Operations
  // ============================================
  void addToCart(Product product) {
    final idx = cart.indexWhere((c) => c.id == product.id);
    if (idx >= 0) {
      cart[idx].qty++;
    } else {
      cart.add(CartItem(
        id: product.id,
        name: product.name,
        price: product.price,
        image: product.image,
        farmerId: product.farmerId,
      ));
    }
    showToast('${product.name} added to cart');
    notifyListeners();
  }

  void updateCartQty(String id, int delta) {
    final idx = cart.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      cart[idx].qty += delta;
      if (cart[idx].qty <= 0) cart.removeAt(idx);
      notifyListeners();
    }
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  // ============================================
  // Order Operations
  // ============================================
  void placeOrder() {
    if (cart.isEmpty || _currentUserId == null) return;
    final merchantId = cart.first.farmerId;
    final subtotal = cartTotal;
    final fees = OrderFees(
      subtotal: subtotal,
      delivery: settings.deliveryBaseFee,
      platform: subtotal * (settings.platformFeePercent / 100),
      tax: subtotal * settings.taxRate,
    );
    final order = Order(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      customerId: _currentUserId!,
      merchantId: merchantId,
      items: cart.map((c) => OrderItem(
        id: c.id, name: c.name, price: c.price, qty: c.qty, image: c.image,
      )).toList(),
      total: fees.total,
      date: DateTime.now().toIso8601String(),
      fees: fees,
    );
    orders.insert(0, order);

    // Update totalSpent
    final uIdx = users.indexWhere((u) => u.id == _currentUserId);
    if (uIdx >= 0) {
      users[uIdx].totalSpent = (users[uIdx].totalSpent ?? 0) + order.total;
    }

    clearCart();
    showToast('Order placed successfully!');
    _saveToDisk();
  }

  void updateOrderStatus(String orderId, String status) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      orders[idx].status = status;
      notifyListeners();
      _saveToDisk();
    }
  }

  void markReady(String orderId) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    orders[idx].status = 'Ready';

    final order = orders[idx];
    final driverPay = (order.fees.delivery) + order.fees.tip;
    final merchant = users.cast<User?>().firstWhere(
          (u) => u?.id == order.merchantId, orElse: () => null);
    final customer = users.cast<User?>().firstWhere(
          (u) => u?.id == order.customerId, orElse: () => null);

    deliveries.add(Delivery(
      id: 'del-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      pickup: merchant?.address?.formatted ?? merchant?.name ?? 'Merchant',
      dropoff: customer?.address?.formatted ?? customer?.name ?? 'Customer',
      pay: driverPay,
    ));
    showToast('Marked ready for pickup!');
    notifyListeners();
    _saveToDisk();
  }

  void cancelOrder(String orderId, String customerId, String reason) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    final order = orders[idx];
    if (order.status != 'Pending' && order.status != 'Processing') return;

    final refund = order.status == 'Pending' ? order.total : order.total * 0.9;
    orders[idx].status = 'Cancelled';
    orders[idx].rejectionReason = reason;

    final uIdx = users.indexWhere((u) => u.id == customerId);
    if (uIdx >= 0) users[uIdx].credits += refund;

    showToast('Order cancelled');
    notifyListeners();
    _saveToDisk();
  }

  // ============================================
  // Delivery Operations
  // ============================================
  void acceptJob(String deliveryId) {
    final idx = deliveries.indexWhere((d) => d.id == deliveryId);
    if (idx >= 0 && _currentUserId != null) {
      deliveries[idx].driverId = _currentUserId;
      deliveries[idx].status = 'Accepted';
      showToast('Delivery accepted!');
      notifyListeners();
      _saveToDisk();
    }
  }

  void pickupJob(String deliveryId) {
    final idx = deliveries.indexWhere((d) => d.id == deliveryId);
    if (idx >= 0) {
      deliveries[idx].status = 'Picked Up';
      final oIdx = orders.indexWhere((o) => o.id == deliveries[idx].orderId);
      if (oIdx >= 0) orders[oIdx].status = 'Picked Up';
      showToast('Picked up! Head to customer');
      notifyListeners();
      _saveToDisk();
    }
  }

  void completeJob(String deliveryId) {
    final idx = deliveries.indexWhere((d) => d.id == deliveryId);
    if (idx < 0) return;
    final delivery = deliveries[idx];
    deliveries[idx].status = 'Delivered';

    final oIdx = orders.indexWhere((o) => o.id == delivery.orderId);
    if (oIdx >= 0) orders[oIdx].status = 'Delivered';

    if (delivery.driverId != null) {
      final uIdx = users.indexWhere((u) => u.id == delivery.driverId);
      if (uIdx >= 0) {
        users[uIdx].earnings = (users[uIdx].earnings ?? 0) + delivery.pay;
        users[uIdx].trips = (users[uIdx].trips ?? 0) + 1;
      }
    }
    showToast('Delivery complete! 💰');
    notifyListeners();
    _saveToDisk();
  }

  void driverPayout(double amount, String method) {
    if (_currentUserId == null) return;
    final uIdx = users.indexWhere((u) => u.id == _currentUserId);
    if (uIdx >= 0) {
      users[uIdx].earnings = (users[uIdx].earnings ?? 0) - amount;
      transactions.insert(0, Transaction(
        id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
        type: 'Payout',
        amount: -amount,
        date: DateTime.now().toIso8601String(),
        status: 'Processing',
        method: method == 'card' ? 'Instant Transfer' : 'Bank Transfer',
      ));
      showToast('Payout initiated!');
      notifyListeners();
      _saveToDisk();
    }
  }

  // ============================================
  // Product Operations
  // ============================================
  void addProduct({
    required String name, required double price, String unit = 'lb',
    String category = 'Vegetables', int stock = 50, String? description,
  }) {
    products.add(Product(
      id: 'p-${DateTime.now().millisecondsSinceEpoch}',
      farmerId: _currentUserId ?? '',
      name: name, price: price, unit: unit, category: category,
      stock: stock, description: description,
    ));
    showToast('Product added!');
    notifyListeners();
    _saveToDisk();
  }

  void updateProduct(String id, {
    String? name, double? price, String? unit, String? category,
    int? stock, String? description,
  }) {
    final idx = products.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      if (name != null) products[idx].name = name;
      if (price != null) products[idx].price = price;
      if (unit != null) products[idx].unit = unit;
      if (category != null) products[idx].category = category;
      if (stock != null) products[idx].stock = stock;
      if (description != null) products[idx].description = description;
      showToast('Product updated');
      notifyListeners();
      _saveToDisk();
    }
  }

  void deleteProduct(String id) {
    products.removeWhere((p) => p.id == id);
    showToast('Product deleted');
    notifyListeners();
    _saveToDisk();
  }

  // ============================================
  // User / Admin Operations
  // ============================================
  void toggleUserStatus(String userId) {
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      users[idx].status = users[idx].status == 'active' ? 'banned' : 'active';
      showToast('User ${users[idx].status}');
      notifyListeners();
      _saveToDisk();
    }
  }

  void toggleDriverOnline() {
    if (_currentUserId == null) return;
    final idx = users.indexWhere((u) => u.id == _currentUserId);
    if (idx >= 0) {
      users[idx].online = !(users[idx].online ?? false);
      showToast(users[idx].online == true ? "You're online!" : 'Going offline', 
                users[idx].online == true ? 'success' : 'info');
      notifyListeners();
    }
  }

  void updateUserProfile(String userId, {String? name, String? phone, String? email,
    String? bankLast4, String? cardLast4, String? vehicleMake, String? vehicleModel,
    String? vehicleYear, String? vehiclePlate, UserAddress? address}) {
    final idx = users.indexWhere((u) => u.id == userId);
    if (idx == -1) return;
    final u = users[idx];
    if (name != null) u.name = name;
    if (phone != null) u.phone = phone;
    if (email != null) u.email = email;
    if (bankLast4 != null) u.bankLast4 = bankLast4;
    if (cardLast4 != null) u.cardLast4 = cardLast4;
    if (vehicleMake != null) u.vehicleMake = vehicleMake;
    if (vehicleModel != null) u.vehicleModel = vehicleModel;
    if (vehicleYear != null) u.vehicleYear = vehicleYear;
    if (vehiclePlate != null) u.vehiclePlate = vehiclePlate;
    if (address != null) u.address = address;
    notifyListeners();
    _saveToDisk();
  }

  void updateSetting(String key, dynamic value) {
    switch (key) {
      case 'platformFeePercent': settings.platformFeePercent = value.toDouble(); break;
      case 'deliveryBaseFee': settings.deliveryBaseFee = value.toDouble(); break;
      case 'taxRate': settings.taxRate = value.toDouble(); break;
      case 'membershipPrice': settings.membershipPrice = value.toDouble(); break;
      case 'maintenanceMode': settings.maintenanceMode = value; break;
    }
    notifyListeners();
    _saveToDisk();
  }

  void nukeData() {
    orders.clear();
    deliveries.clear();
    transactions.clear();
    reviews.clear();
    showToast('Data nuked!', 'error');
    notifyListeners();
    _saveToDisk();
  }

  void markNotificationRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      notifications[idx].read = true;
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (final n in notifications) {
      if (n.userId == _currentUserId) n.read = true;
    }
    notifyListeners();
  }

  // ============================================
  // Persistence
  // ============================================
  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ff_settings', jsonEncode(settings.toJson()));
      await prefs.setString('ff_users', jsonEncode(users.map((u) => u.toJson()).toList()));
      await prefs.setString('ff_products', jsonEncode(products.map((p) => p.toJson()).toList()));
      await prefs.setString('ff_orders', jsonEncode(orders.map((o) => o.toJson()).toList()));
      await prefs.setString('ff_deliveries', jsonEncode(deliveries.map((d) => d.toJson()).toList()));
      await prefs.setString('ff_transactions', jsonEncode(transactions.map((t) => t.toJson()).toList()));
      await prefs.setString('ff_reviews', jsonEncode(reviews.map((r) => r.toJson()).toList()));
    } catch (e) {
      print('Save error: $e');
    }
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString('ff_settings');
      if (s != null) settings = PlatformSettings.fromJson(jsonDecode(s));
      final u = prefs.getString('ff_users');
      if (u != null) users = (jsonDecode(u) as List).map((j) => User.fromJson(j)).toList();
      final p = prefs.getString('ff_products');
      if (p != null) products = (jsonDecode(p) as List).map((j) => Product.fromJson(j)).toList();
      final o = prefs.getString('ff_orders');
      if (o != null) orders = (jsonDecode(o) as List).map((j) => Order.fromJson(j)).toList();
      final d = prefs.getString('ff_deliveries');
      if (d != null) deliveries = (jsonDecode(d) as List).map((j) => Delivery.fromJson(j)).toList();
      final t = prefs.getString('ff_transactions');
      if (t != null) transactions = (jsonDecode(t) as List).map((j) => Transaction.fromJson(j)).toList();
      final r = prefs.getString('ff_reviews');
      if (r != null) reviews = (jsonDecode(r) as List).map((j) => Review.fromJson(j)).toList();
      notifyListeners();
    } catch (e) {
      print('Load error: $e');
    }
  }

  // ============================================
  // Clean Launch Data
  // ============================================
  void _initSeedData() {
    users = [
      User(id: 'u1', name: 'New Customer', role: UserRole.customer, email: 'customer@farmfresh.app', points: 0, credits: 0, referralCode: 'FRESH10', referralCount: 0, totalSpent: 0, loyaltyTier: 'Bronze'),
      User(id: 'u2', name: 'New Driver', role: UserRole.driver, email: 'driver@farmfresh.app', rating: 0, trips: 0, earnings: 0, online: false, acceptanceRate: 0),
      User(id: 'u3', name: 'New Farmer', role: UserRole.farmer, email: 'farmer@farmfresh.app', rating: 0, revenue: 0),
      User(id: 'u4', name: 'Platform Admin', role: UserRole.owner, email: 'misiksolutionsllc@gmail.com', verified: true),
    ];

    products = [];
    orders = [];
    transactions = [];

    promos = [
      PromoCode(code: 'FRESH20', discount: 0.20, type: 'percent', label: '20% Off', usedCount: 0, minOrder: 20),
      PromoCode(code: 'WELCOME5', discount: 5.00, type: 'flat', label: '\$5 Off First Order', usedCount: 0),
      PromoCode(code: 'FREEDELIVERY', discount: 0, type: 'free_delivery', label: 'Free Delivery', usedCount: 0, minOrder: 25),
    ];

    reviews = [];
  }
}
