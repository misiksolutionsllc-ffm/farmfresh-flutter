import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class MerchantAppScreen extends StatefulWidget {
  const MerchantAppScreen({super.key});
  @override
  State<MerchantAppScreen> createState() => _MerchantAppScreenState();
}

class _MerchantAppScreenState extends State<MerchantAppScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final merchant = app.currentUser;
    if (merchant == null) return const SizedBox.shrink();

    final myProducts = app.products.where((p) => p.farmerId == app.currentUserId).toList();
    final myOrders = app.orders.where((o) => o.merchantId == app.currentUserId).toList();
    final myReviews = app.reviews.where((r) => myProducts.any((p) => p.id == r.productId)).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => app.setRole(null)),
        title: Text(['Orders', 'Inventory', 'Analytics', 'Profile'][_tab]),
      ),
      body: IndexedStack(index: _tab, children: [
        _buildOrders(app, myOrders),
        _buildInventory(app, myProducts),
        _buildAnalytics(app, myOrders, myProducts, merchant),
        _buildProfile(merchant),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.surface900.withOpacity(0.95),
        indicatorColor: AppColors.orange.withOpacity(0.15),
        destinations: [
          NavigationDestination(
            icon: Badge(label: Text('${myOrders.where((o) => o.status == 'Pending' || o.status == 'Processing').length}'), isLabelVisible: myOrders.any((o) => o.status == 'Pending' || o.status == 'Processing'), child: const Icon(Icons.receipt_long_outlined)),
            selectedIcon: const Icon(Icons.receipt_long), label: 'Orders',
          ),
          const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
          const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Analytics'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _tab == 1
          ? FloatingActionButton(
              onPressed: () => _showAddProductSheet(context, app),
              backgroundColor: AppColors.orange,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildOrders(AppProvider app, List<Order> orders) {
    if (orders.isEmpty) return const EmptyState(emoji: '📋', message: 'No orders yet');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final order = orders[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface800.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('#${order.id.substring(order.id.length - 6).toUpperCase()}', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'monospace')),
                Text(formatDate(order.date), style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
              StatusBadge(order.status),
            ]),
            const SizedBox(height: 12),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${item.image} ${item.name} × ${item.qty}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(formatCurrency(item.price * item.qty), style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ]),
            )),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(formatCurrency(order.fees.subtotal), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              if (order.status == 'Pending')
                ElevatedButton(
                  onPressed: () => app.updateOrderStatus(order.id, 'Processing'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                  child: const Text('Accept'),
                ),
              if (order.status == 'Processing')
                ElevatedButton(
                  onPressed: () => app.markReady(order.id),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                  child: const Text('✓ Mark Ready'),
                ),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildInventory(AppProvider app, List<Product> products) {
    if (products.isEmpty) return const EmptyState(emoji: '📦', message: 'No products yet');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface800.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.surface800, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(p.image, style: const TextStyle(fontSize: 30))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
              Row(children: [
                Text('${formatCurrency(p.price)}/${p.unit}', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 13)),
                Text(' • ${p.stock} in stock', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ]),
              Row(children: [
                const Icon(Icons.star, color: AppColors.warning, size: 12),
                Text(' ${p.rating} • ${p.sales} sold', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
            ])),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
              onPressed: () => app.deleteProduct(p.id),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildAnalytics(AppProvider app, List<Order> orders, List<Product> products, merchant) {
    final revenue = orders.where((o) => o.status == 'Delivered').fold(0.0, (s, o) => s + o.fees.subtotal);
    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
        children: [
          StatCard(label: 'Revenue', value: formatCurrency(revenue), icon: Icons.attach_money, color: AppColors.emerald),
          StatCard(label: 'Orders', value: '${orders.length}', icon: Icons.shopping_bag, color: AppColors.orange),
          StatCard(label: 'Products', value: '${products.length}', icon: Icons.inventory_2, color: AppColors.blue),
          StatCard(label: 'Avg Rating', value: '${merchant.rating?.toStringAsFixed(1) ?? '–'}', icon: Icons.star, color: AppColors.warning),
        ],
      ),
      const SizedBox(height: 24),
      Text('Top Products', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      ...products.toList()
        ..sort((a, b) => b.sales.compareTo(a.sales)),
      ...(products.toList()..sort((a, b) => b.sales.compareTo(a.sales))).take(5).map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(p.image, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
            Text('${p.sales} sold', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ])),
          Text(formatCurrency(p.price * p.sales), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      )),
    ]);
  }

  Widget _buildProfile(merchant) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircleAvatar(radius: 40, backgroundColor: AppColors.orange.withOpacity(0.2), child: Text(merchant.name[0], style: TextStyle(color: AppColors.orange, fontSize: 28, fontWeight: FontWeight.w700))),
      const SizedBox(height: 12),
      Text(merchant.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      Text(merchant.email, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      if (merchant.description != null) ...[
        const SizedBox(height: 8),
        Text(merchant.description!, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    ]));
  }

  void _showAddProductSheet(BuildContext context, AppProvider app) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '50');
    String unit = 'lb', category = 'Vegetables';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(builder: (ctx, setModalState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Add Product', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Product name')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Price'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Stock'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: unit, decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              dropdownColor: AppColors.surface800,
              items: ['lb', 'oz', 'each', 'doz', 'bunch', 'pint', 'loaf'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) => setModalState(() => unit = v!),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(
              value: category, decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              dropdownColor: AppColors.surface800,
              items: ['Fruits', 'Vegetables', 'Dairy', 'Bakery', 'Meat', 'Beverages'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) => setModalState(() => category = v!),
            )),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                app.addProduct(name: nameCtrl.text, price: double.tryParse(priceCtrl.text) ?? 0, unit: unit, category: category, stock: int.tryParse(stockCtrl.text) ?? 50);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text('Add Product'),
          )),
        ]),
      )),
    );
  }
}
