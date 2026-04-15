// ============================================================
// EdemFarm Data Models — ported from lib/store.ts
// ============================================================

class AppConfig {
  static const double taxRate = 0.07;
  static const double platformFee = 0.10;
  static const double deliveryBase = 4.99;
  static const int pointsRate = 10;
  static const double pointValue = 0.01;
}

enum UserRole { customer, driver, farmer, owner }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.customer: return 'Consumer';
      case UserRole.driver: return 'Driver';
      case UserRole.farmer: return 'Farmer American Hero';
      case UserRole.owner: return 'Admin';
    }
  }
}

class Document {
  final String type;
  final String? name;
  String status; // pending, approved, rejected, expired
  final String date;
  String? uri;
  String? uploadedAt;
  String? expirationDate;
  String? rejectionReason;
  String? reviewedBy;
  String? reviewedAt;
  String? reuploadFeedback;

  Document({
    required this.type,
    this.name,
    this.status = 'pending',
    required this.date,
    this.uri,
    this.uploadedAt,
    this.expirationDate,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    this.reuploadFeedback,
  });

  Map<String, dynamic> toJson() => {
    'type': type, 'name': name, 'status': status, 'date': date,
    'uri': uri, 'uploadedAt': uploadedAt, 'expirationDate': expirationDate,
    'rejectionReason': rejectionReason, 'reviewedBy': reviewedBy,
    'reviewedAt': reviewedAt, 'reuploadFeedback': reuploadFeedback,
  };

  factory Document.fromJson(Map<String, dynamic> j) => Document(
    type: j['type'] ?? '', name: j['name'], status: j['status'] ?? 'pending',
    date: j['date'] ?? '', uri: j['uri'], uploadedAt: j['uploadedAt'],
    expirationDate: j['expirationDate'], rejectionReason: j['rejectionReason'],
    reviewedBy: j['reviewedBy'], reviewedAt: j['reviewedAt'],
    reuploadFeedback: j['reuploadFeedback'],
  );
}

class UserAddress {
  String street;
  String city;
  String state;
  String zip;
  String? country;
  String? label;

  UserAddress({
    required this.street, required this.city, required this.state,
    required this.zip, this.country, this.label,
  });

  String get formatted => '$street, $city, $state $zip';

  Map<String, dynamic> toJson() => {
    'street': street, 'city': city, 'state': state, 'zip': zip,
    'country': country, 'label': label,
  };

  factory UserAddress.fromJson(Map<String, dynamic> j) => UserAddress(
    street: j['street'] ?? '', city: j['city'] ?? '',
    state: j['state'] ?? '', zip: j['zip'] ?? '',
    country: j['country'], label: j['label'],
  );
}

class User {
  final String id;
  String name;
  UserRole role;
  String email;
  String? phone;
  String status; // active, banned
  bool verified;
  UserAddress? address;
  List<String> favorites;
  int points;
  double wallet;
  double credits;
  String? referralCode;
  int referralCount;
  // Driver fields
  double? rating;
  int? trips;
  double? earnings;
  bool? online;
  int? acceptanceRate;
  String? bankLast4;
  String? cardLast4;
  String? vehicleMake;
  String? vehicleModel;
  String? vehicleYear;
  String? vehiclePlate;
  // Merchant fields
  double? revenue;
  String? description;
  double? totalSpent;
  String? loyaltyTier;
  List<Document> documents;

  User({
    required this.id, required this.name, required this.role,
    required this.email, this.phone, this.status = 'active',
    this.verified = false, this.address, this.favorites = const [],
    this.points = 0, this.wallet = 0, this.credits = 0,
    this.referralCode, this.referralCount = 0,
    this.rating, this.trips, this.earnings, this.online,
    this.acceptanceRate, this.bankLast4, this.cardLast4,
    this.vehicleMake, this.vehicleModel, this.vehicleYear, this.vehiclePlate,
    this.revenue, this.description, this.totalSpent,
    this.loyaltyTier, this.documents = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'role': role.name, 'email': email,
    'phone': phone, 'status': status, 'verified': verified,
    'address': address?.toJson(), 'favorites': favorites,
    'points': points, 'wallet': wallet, 'credits': credits,
    'referralCode': referralCode, 'referralCount': referralCount,
    'rating': rating, 'trips': trips, 'earnings': earnings,
    'online': online, 'acceptanceRate': acceptanceRate,
    'bankLast4': bankLast4, 'cardLast4': cardLast4,
    'vehicleMake': vehicleMake, 'vehicleModel': vehicleModel,
    'vehicleYear': vehicleYear, 'vehiclePlate': vehiclePlate,
    'revenue': revenue, 'description': description,
    'totalSpent': totalSpent, 'loyaltyTier': loyaltyTier,
    'documents': documents.map((d) => d.toJson()).toList(),
  };

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] ?? '', name: j['name'] ?? '',
    role: UserRole.values.firstWhere((r) => r.name == j['role'], orElse: () => UserRole.customer),
    email: j['email'] ?? '', phone: j['phone'],
    status: j['status'] ?? 'active', verified: j['verified'] ?? false,
    address: j['address'] != null ? UserAddress.fromJson(j['address']) : null,
    favorites: List<String>.from(j['favorites'] ?? []),
    points: j['points'] ?? 0, wallet: (j['wallet'] ?? 0).toDouble(),
    credits: (j['credits'] ?? 0).toDouble(),
    referralCode: j['referralCode'], referralCount: j['referralCount'] ?? 0,
    rating: j['rating']?.toDouble(), trips: j['trips'],
    earnings: j['earnings']?.toDouble(), online: j['online'],
    acceptanceRate: j['acceptanceRate'],
    bankLast4: j['bankLast4'], cardLast4: j['cardLast4'],
    vehicleMake: j['vehicleMake'], vehicleModel: j['vehicleModel'],
    vehicleYear: j['vehicleYear'], vehiclePlate: j['vehiclePlate'],
    revenue: j['revenue']?.toDouble(), description: j['description'],
    totalSpent: j['totalSpent']?.toDouble(), loyaltyTier: j['loyaltyTier'],
    documents: (j['documents'] as List?)?.map((d) => Document.fromJson(d)).toList() ?? [],
  );
}

class Product {
  final String id;
  final String farmerId;
  String name;
  double price;
  String unit;
  String image;
  String category;
  int stock;
  String status; // active, inactive
  int sales;
  double rating;
  int reviews;
  String? description;
  bool organic;
  bool vegan;
  bool glutenFree;

  Product({
    required this.id, required this.farmerId, required this.name,
    required this.price, this.unit = 'lb', this.image = '🥬',
    this.category = 'Vegetables', this.stock = 50,
    this.status = 'active', this.sales = 0, this.rating = 0,
    this.reviews = 0, this.description, this.organic = false,
    this.vegan = false, this.glutenFree = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'farmerId': farmerId, 'name': name, 'price': price,
    'unit': unit, 'image': image, 'category': category, 'stock': stock,
    'status': status, 'sales': sales, 'rating': rating, 'reviews': reviews,
    'description': description, 'organic': organic, 'vegan': vegan,
    'glutenFree': glutenFree,
  };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'], farmerId: j['farmerId'], name: j['name'],
    price: (j['price'] ?? 0).toDouble(), unit: j['unit'] ?? 'lb',
    image: j['image'] ?? '🥬', category: j['category'] ?? 'Vegetables',
    stock: j['stock'] ?? 0, status: j['status'] ?? 'active',
    sales: j['sales'] ?? 0, rating: (j['rating'] ?? 0).toDouble(),
    reviews: j['reviews'] ?? 0, description: j['description'],
    organic: j['organic'] ?? false, vegan: j['vegan'] ?? false,
    glutenFree: j['glutenFree'] ?? false,
  );
}

class OrderItem {
  final String id;
  final String name;
  final double price;
  int qty;
  final String image;

  OrderItem({
    required this.id, required this.name, required this.price,
    this.qty = 1, this.image = '🥬',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'price': price, 'qty': qty, 'image': image,
  };

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    id: j['id'], name: j['name'], price: (j['price'] ?? 0).toDouble(),
    qty: j['qty'] ?? 1, image: j['image'] ?? '🥬',
  );
}

class OrderFees {
  final double subtotal;
  final double delivery;
  final double platform;
  final double tax;
  final double tip;
  final double discount;

  const OrderFees({
    this.subtotal = 0, this.delivery = 0, this.platform = 0,
    this.tax = 0, this.tip = 0, this.discount = 0,
  });

  double get total => subtotal + delivery + platform + tax + tip - discount;

  Map<String, dynamic> toJson() => {
    'subtotal': subtotal, 'delivery': delivery, 'platform': platform,
    'tax': tax, 'tip': tip, 'discount': discount,
  };

  factory OrderFees.fromJson(Map<String, dynamic> j) => OrderFees(
    subtotal: (j['subtotal'] ?? 0).toDouble(),
    delivery: (j['delivery'] ?? 0).toDouble(),
    platform: (j['platform'] ?? 0).toDouble(),
    tax: (j['tax'] ?? 0).toDouble(),
    tip: (j['tip'] ?? 0).toDouble(),
    discount: (j['discount'] ?? 0).toDouble(),
  );
}

class Order {
  final String id;
  final String customerId;
  final String merchantId;
  final List<OrderItem> items;
  final double total;
  String status;
  final String date;
  String? driverId;
  final OrderFees fees;
  String? instructions;
  String? rejectionReason;

  Order({
    required this.id, required this.customerId, required this.merchantId,
    required this.items, required this.total, this.status = 'Pending',
    required this.date, this.driverId, required this.fees,
    this.instructions, this.rejectionReason,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'customerId': customerId, 'merchantId': merchantId,
    'items': items.map((i) => i.toJson()).toList(), 'total': total,
    'status': status, 'date': date, 'driverId': driverId,
    'fees': fees.toJson(), 'instructions': instructions,
    'rejectionReason': rejectionReason,
  };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'], customerId: j['customerId'], merchantId: j['merchantId'],
    items: (j['items'] as List).map((i) => OrderItem.fromJson(i)).toList(),
    total: (j['total'] ?? 0).toDouble(), status: j['status'] ?? 'Pending',
    date: j['date'] ?? '', driverId: j['driverId'],
    fees: OrderFees.fromJson(j['fees'] ?? {}),
    instructions: j['instructions'], rejectionReason: j['rejectionReason'],
  );
}

class Delivery {
  final String id;
  final String orderId;
  String? driverId;
  final String pickup;
  final String dropoff;
  final double pay;
  String status;
  final String distance;

  Delivery({
    required this.id, required this.orderId, this.driverId,
    required this.pickup, required this.dropoff, required this.pay,
    this.status = 'Pending', this.distance = '3.2 mi',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'orderId': orderId, 'driverId': driverId,
    'pickup': pickup, 'dropoff': dropoff, 'pay': pay,
    'status': status, 'distance': distance,
  };

  factory Delivery.fromJson(Map<String, dynamic> j) => Delivery(
    id: j['id'], orderId: j['orderId'], driverId: j['driverId'],
    pickup: j['pickup'] ?? '', dropoff: j['dropoff'] ?? '',
    pay: (j['pay'] ?? 0).toDouble(), status: j['status'] ?? 'Pending',
    distance: j['distance'] ?? '3.2 mi',
  );
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final String date;
  final String status;
  final String method;

  const Transaction({
    required this.id, required this.type, required this.amount,
    required this.date, required this.status, required this.method,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'amount': amount,
    'date': date, 'status': status, 'method': method,
  };

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
    id: j['id'], type: j['type'] ?? '', amount: (j['amount'] ?? 0).toDouble(),
    date: j['date'] ?? '', status: j['status'] ?? '', method: j['method'] ?? '',
  );
}

class Review {
  final String id;
  final String productId;
  final String customerId;
  final String customerName;
  final int rating;
  final String comment;
  final String date;
  String status;
  String? merchantResponse;
  String? merchantResponseDate;

  Review({
    required this.id, required this.productId, required this.customerId,
    required this.customerName, required this.rating, required this.comment,
    required this.date, this.status = 'pending',
    this.merchantResponse, this.merchantResponseDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'productId': productId, 'customerId': customerId,
    'customerName': customerName, 'rating': rating, 'comment': comment,
    'date': date, 'status': status, 'merchantResponse': merchantResponse,
    'merchantResponseDate': merchantResponseDate,
  };

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: j['id'], productId: j['productId'], customerId: j['customerId'],
    customerName: j['customerName'] ?? '', rating: j['rating'] ?? 0,
    comment: j['comment'] ?? '', date: j['date'] ?? '',
    status: j['status'] ?? 'pending',
    merchantResponse: j['merchantResponse'],
    merchantResponseDate: j['merchantResponseDate'],
  );
}

class PromoCode {
  final String code;
  final double discount;
  final String type; // percent, flat, free_delivery
  final String label;
  double? minOrder;
  int usedCount;
  bool active;

  PromoCode({
    required this.code, required this.discount, required this.type,
    required this.label, this.minOrder, this.usedCount = 0, this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'code': code, 'discount': discount, 'type': type, 'label': label,
    'minOrder': minOrder, 'usedCount': usedCount, 'active': active,
  };

  factory PromoCode.fromJson(Map<String, dynamic> j) => PromoCode(
    code: j['code'], discount: (j['discount'] ?? 0).toDouble(),
    type: j['type'] ?? 'percent', label: j['label'] ?? '',
    minOrder: j['minOrder']?.toDouble(), usedCount: j['usedCount'] ?? 0,
    active: j['active'] ?? true,
  );
}

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  bool read;
  final String createdAt;

  AppNotification({
    required this.id, required this.userId, required this.type,
    required this.title, required this.message, this.read = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'userId': userId, 'type': type, 'title': title,
    'message': message, 'read': read, 'createdAt': createdAt,
  };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'], userId: j['userId'] ?? '', type: j['type'] ?? '',
    title: j['title'] ?? '', message: j['message'] ?? '',
    read: j['read'] ?? false, createdAt: j['createdAt'] ?? '',
  );
}

class PlatformSettings {
  double platformFeePercent;
  double deliveryBaseFee;
  double taxRate;
  double membershipPrice;
  bool maintenanceMode;

  PlatformSettings({
    this.platformFeePercent = 10,
    this.deliveryBaseFee = 4.99,
    this.taxRate = 0.07,
    this.membershipPrice = 9.99,
    this.maintenanceMode = false,
  });

  Map<String, dynamic> toJson() => {
    'platformFeePercent': platformFeePercent, 'deliveryBaseFee': deliveryBaseFee,
    'taxRate': taxRate, 'membershipPrice': membershipPrice,
    'maintenanceMode': maintenanceMode,
  };

  factory PlatformSettings.fromJson(Map<String, dynamic> j) => PlatformSettings(
    platformFeePercent: (j['platformFeePercent'] ?? 10).toDouble(),
    deliveryBaseFee: (j['deliveryBaseFee'] ?? 4.99).toDouble(),
    taxRate: (j['taxRate'] ?? 0.07).toDouble(),
    membershipPrice: (j['membershipPrice'] ?? 9.99).toDouble(),
    maintenanceMode: j['maintenanceMode'] ?? false,
  );
}

// Cart item wraps an OrderItem with farmerId
class CartItem extends OrderItem {
  final String farmerId;

  CartItem({
    required super.id, required super.name, required super.price,
    super.qty, super.image, required this.farmerId,
  });
}
