import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class CustomerAppScreen extends StatefulWidget {
  const CustomerAppScreen({super.key});
  @override
  State<CustomerAppScreen> createState() => _CustomerAppScreenState();
}

class _CustomerAppScreenState extends State<CustomerAppScreen> {
  int _tab = 0;
  String _search = '';
  String _category = 'All';
  Product? _selectedProduct;

  static const _categories = ['All', 'Fruits', 'Vegetables', 'Dairy', 'Bakery'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.currentUser;
    final products = app.products.where((p) => p.status == 'active').toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => app.setRole(null)),
        title: Text(['Shop', 'Cart', 'Orders', 'Profile'][_tab]),
        actions: [
          if (app.unreadNotificationCount > 0)
            Badge(
              label: Text('${app.unreadNotificationCount}'),
              child: IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
            )
          else
            IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _buildShop(app, products),
          _buildCart(app),
          _buildOrders(app),
          _buildProfile(app, user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.surface900.withOpacity(0.95),
        indicatorColor: AppColors.emerald.withOpacity(0.15),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
          NavigationDestination(
            icon: Badge(label: Text('${app.cartCount}'), isLabelVisible: app.cartCount > 0, child: const Icon(Icons.shopping_cart_outlined)),
            selectedIcon: Badge(label: Text('${app.cartCount}'), isLabelVisible: app.cartCount > 0, child: const Icon(Icons.shopping_cart)),
            label: 'Cart',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      // Floating cart button
      floatingActionButton: _tab == 0 && app.cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _tab = 1),
              backgroundColor: AppColors.emerald,
              label: Text('${app.cartCount} items • ${formatCurrency(app.cartTotal)}'),
              icon: const Icon(Icons.shopping_cart),
            )
          : null,
    );
  }

  Widget _buildShop(AppProvider app, List<Product> products) {
    final filtered = products.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _category == 'All' || p.category == _category;
      return matchSearch && matchCat;
    }).toList();

    return CustomScrollView(
      slivers: [
        // Welcome banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.emerald.withOpacity(0.15), AppColors.surface800.withOpacity(0.3)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.emerald.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: TextStyle(color: AppColors.emerald, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Fresh from the farm', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('${products.length} products available', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ),
        // Search
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              ),
            ),
          ),
        ),
        // Categories
        SliverToBoxAdapter(
          child: SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: AppColors.emerald,
                  backgroundColor: AppColors.surface800,
                  labelStyle: TextStyle(color: _category == c ? Colors.white : AppColors.textMuted, fontSize: 13),
                  side: BorderSide(color: _category == c ? AppColors.emerald : Colors.white.withOpacity(0.05)),
                ),
              )).toList(),
            ),
          ),
        ),
        // Product Grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: filtered.isEmpty
              ? const SliverToBoxAdapter(child: EmptyState(emoji: '🔍', message: 'No products found'))
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ProductCard(
                      product: filtered[i],
                      cartQty: app.cart.cast<CartItem?>().firstWhere((c) => c?.id == filtered[i].id, orElse: () => null)?.qty ?? 0,
                      onAdd: () => app.addToCart(filtered[i]),
                      onIncrement: () => app.updateCartQty(filtered[i].id, 1),
                      onDecrement: () => app.updateCartQty(filtered[i].id, -1),
                    ),
                    childCount: filtered.length,
                  ),
                ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildCart(AppProvider app) {
    if (app.cart.isEmpty) {
      return EmptyState(
        emoji: '🛒', message: 'Your cart is empty',
        action: ElevatedButton(onPressed: () => setState(() => _tab = 0), child: const Text('Start Shopping')),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...app.cart.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface800.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50, decoration: BoxDecoration(color: AppColors.surface800, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(item.image, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                  Text(formatCurrency(item.price * item.qty), style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              )),
              Row(children: [
                _QtyButton(icon: Icons.remove, onTap: () => app.updateCartQty(item.id, -1)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.qty}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                _QtyButton(icon: Icons.add, onTap: () => app.updateCartQty(item.id, 1), filled: true),
              ]),
            ],
          ),
        )),
        const SizedBox(height: 12),
        // Summary
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _SummaryRow('Subtotal', formatCurrency(app.cartTotal)),
            _SummaryRow('Delivery', formatCurrency(app.settings.deliveryBaseFee)),
            _SummaryRow('Tax (${(app.settings.taxRate * 100).toInt()}%)', formatCurrency(app.cartTotal * app.settings.taxRate)),
            const Divider(color: AppColors.surface700, height: 24),
            _SummaryRow('Total', formatCurrency(app.cartTotal + app.settings.deliveryBaseFee + app.cartTotal * app.settings.taxRate + app.cartTotal * app.settings.platformFeePercent / 100), bold: true),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { app.placeOrder(); setState(() => _tab = 2); }, child: const Text('Place Order'))),
          ]),
        ),
      ],
    );
  }

  Widget _buildOrders(AppProvider app) {
    final myOrders = app.orders.where((o) => o.customerId == app.currentUserId).toList();
    if (myOrders.isEmpty) return const EmptyState(emoji: '📦', message: 'No orders yet');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myOrders.length,
      itemBuilder: (_, i) {
        final order = myOrders[i];
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
              Text('#${order.id.substring(order.id.length - 6).toUpperCase()}', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'monospace')),
              StatusBadge(order.status),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: order.items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.surface900, borderRadius: BorderRadius.circular(10)),
              child: Text('${item.image} ${item.name} × ${item.qty}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            )).toList()),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(formatCurrency(order.total), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              if (order.status == 'Pending' || order.status == 'Processing')
                TextButton(
                  onPressed: () => app.cancelOrder(order.id, app.currentUserId!, 'Cancelled by customer'),
                  child: Text('Cancel', style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
            ]),
            Text(formatDate(order.date), style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
        );
      },
    );
  }

  Widget _buildProfile(AppProvider app, User? user) {
    if (user == null) return const SizedBox.shrink();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Center(child: Column(children: [
        CircleAvatar(radius: 40, backgroundColor: AppColors.emerald.withOpacity(0.2), child: Text(user.name[0], style: TextStyle(color: AppColors.emerald, fontSize: 28, fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(user.email, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ProfileStat('${user.points}', 'Points'),
          Container(width: 1, height: 30, color: AppColors.surface700, margin: const EdgeInsets.symmetric(horizontal: 20)),
          _ProfileStat(formatCurrency(user.credits), 'Credits'),
          Container(width: 1, height: 30, color: AppColors.surface700, margin: const EdgeInsets.symmetric(horizontal: 20)),
          _ProfileStat(user.loyaltyTier ?? 'Bronze', 'Tier'),
        ]),
      ])),
    ]);
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final int cartQty;
  final VoidCallback onAdd, onIncrement, onDecrement;
  const _ProductCard({required this.product, required this.cartQty, required this.onAdd, required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 5,
          child: Stack(children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.surface800, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: Center(child: Text(product.image, style: const TextStyle(fontSize: 52))),
            ),
            if (product.organic)
              Positioned(top: 8, left: 8, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('🌿 Organic', style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w600)),
              )),
            if (product.stock == 0)
              Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                child: Center(child: Text('Sold Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600))),
              ),
          ]),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.star, color: AppColors.warning, size: 13),
                const SizedBox(width: 3),
                Text('${product.rating} (${product.reviews})', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(formatCurrency(product.price), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  Text('/${product.unit}', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ]),
                if (product.stock > 0)
                  cartQty > 0
                      ? Row(children: [
                          _QtyButton(icon: Icons.remove, onTap: onDecrement),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('$cartQty', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700, fontSize: 14))),
                          _QtyButton(icon: Icons.add, onTap: onIncrement, filled: true),
                        ])
                      : GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.emerald.withOpacity(0.2))),
                            child: Icon(Icons.add, color: AppColors.emerald, size: 18),
                          ),
                        ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _QtyButton({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: filled ? AppColors.emerald : AppColors.surface900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: filled ? Colors.white : AppColors.textMuted),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: bold ? Colors.white : AppColors.textMuted, fontWeight: bold ? FontWeight.w700 : FontWeight.normal, fontSize: bold ? 16 : 14)),
        Text(value, style: TextStyle(color: bold ? Colors.white : AppColors.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.normal, fontSize: bold ? 16 : 14)),
      ]),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value, label;
  const _ProfileStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: AppColors.emerald, fontSize: 18, fontWeight: FontWeight.w700)),
      Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
    ]);
  }
}
