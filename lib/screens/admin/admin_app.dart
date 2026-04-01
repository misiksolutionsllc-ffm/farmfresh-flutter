import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminAppScreen extends StatefulWidget {
  const AdminAppScreen({super.key});
  @override
  State<AdminAppScreen> createState() => _AdminAppScreenState();
}

class _AdminAppScreenState extends State<AdminAppScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => app.setRole(null)),
        title: Row(children: [
          const Text('🛡️ ', style: TextStyle(fontSize: 18)),
          Text(['Overview', 'Users', 'Orders', 'Settings', 'Database'][_tab]),
        ]),
      ),
      body: IndexedStack(index: _tab, children: [
        _buildOverview(app),
        _buildUsers(app),
        _buildOrders(app),
        _buildSettings(app),
        _buildDatabase(app),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.surface900.withOpacity(0.95),
        indicatorColor: AppColors.red.withOpacity(0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          NavigationDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: 'Database'),
        ],
      ),
    );
  }

  Widget _buildOverview(AppProvider app) {
    final totalRevenue = app.orders.where((o) => o.status == 'Delivered').fold(0.0, (s, o) => s + o.total);
    final platformFees = app.orders.where((o) => o.status == 'Delivered').fold(0.0, (s, o) => s + o.fees.platform);

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Header
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.red.withOpacity(0.08), AppColors.surface800.withOpacity(0.3)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.red.withOpacity(0.1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Platform Overview', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Real-time system health', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 16),

      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
        children: [
          StatCard(label: 'Total Revenue', value: formatCurrency(totalRevenue), icon: Icons.attach_money, color: AppColors.emerald),
          StatCard(label: 'Platform Fees', value: formatCurrency(platformFees), icon: Icons.show_chart, color: AppColors.red),
          StatCard(label: 'Users', value: '${app.users.length}', icon: Icons.people, color: AppColors.blue),
          StatCard(label: 'Orders', value: '${app.orders.length}', icon: Icons.receipt_long, color: AppColors.orange),
        ],
      ),
      const SizedBox(height: 16),

      // User breakdown
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Users by Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _RoleRow('Customers', app.users.where((u) => u.role == UserRole.customer).length, AppColors.emerald, Icons.shopping_cart),
        _RoleRow('Drivers', app.users.where((u) => u.role == UserRole.driver).length, AppColors.blue, Icons.local_shipping),
        _RoleRow('Farmers', app.users.where((u) => u.role == UserRole.farmer).length, AppColors.orange, Icons.store),
      ])),
      const SizedBox(height: 16),

      // Recent orders
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recent Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...app.orders.take(5).map((o) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#${o.id.substring(o.id.length - 6)}', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'monospace')),
              Text('${o.items.length} items', style: const TextStyle(color: Colors.white, fontSize: 13)),
            ]),
            Row(children: [StatusBadge(o.status), const SizedBox(width: 12), Text(formatCurrency(o.total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))]),
          ]),
        )),
      ])),
    ]);
  }

  Widget _buildUsers(AppProvider app) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: app.users.length,
      itemBuilder: (_, i) {
        final user = app.users[i];
        final roleColor = AppColors.roleColor(user.role.name);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface800.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(children: [
            CircleAvatar(radius: 20, backgroundColor: roleColor.withOpacity(0.2), child: Text(user.name[0], style: TextStyle(color: roleColor, fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              Text(user.email, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ])),
            StatusBadge(user.role.label),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                user.status == 'active' ? Icons.person_off_outlined : Icons.person_add_outlined,
                color: user.status == 'active' ? AppColors.textMuted : AppColors.emerald,
                size: 20,
              ),
              onPressed: () => app.toggleUserStatus(user.id),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildOrders(AppProvider app) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: app.orders.length,
      itemBuilder: (_, i) {
        final order = app.orders[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface800.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('#${order.id.substring(order.id.length - 6).toUpperCase()}', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'monospace')),
              StatusBadge(order.status),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Customer', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(app.users.cast<User?>().firstWhere((u) => u?.id == order.customerId, orElse: () => null)?.name ?? '–', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ])),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Farmer', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(app.users.cast<User?>().firstWhere((u) => u?.id == order.merchantId, orElse: () => null)?.name ?? '–', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ])),
              Text(formatCurrency(order.total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildSettings(AppProvider app) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Maintenance mode
      GlassCard(
        borderColor: app.settings.maintenanceMode ? AppColors.red.withOpacity(0.2) : null,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.warning_amber, color: app.settings.maintenanceMode ? AppColors.red : AppColors.textMuted),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Maintenance Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text('Lock platform for all users', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
          ]),
          Switch(
            value: app.settings.maintenanceMode,
            onChanged: (v) => app.updateSetting('maintenanceMode', v),
            activeColor: AppColors.red,
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Fee sliders
      _SettingSlider(
        label: 'Platform Fee',
        value: app.settings.platformFeePercent,
        display: '${app.settings.platformFeePercent.toInt()}%',
        min: 0, max: 30,
        onChanged: (v) => app.updateSetting('platformFeePercent', v),
      ),
      _SettingSlider(
        label: 'Delivery Base Fee',
        value: app.settings.deliveryBaseFee,
        display: formatCurrency(app.settings.deliveryBaseFee),
        min: 0, max: 20,
        onChanged: (v) => app.updateSetting('deliveryBaseFee', v),
      ),
      _SettingSlider(
        label: 'Tax Rate',
        value: app.settings.taxRate * 100,
        display: '${(app.settings.taxRate * 100).toStringAsFixed(0)}%',
        min: 0, max: 20,
        onChanged: (v) => app.updateSetting('taxRate', v / 100),
      ),
      _SettingSlider(
        label: 'Membership Price',
        value: app.settings.membershipPrice,
        display: formatCurrency(app.settings.membershipPrice),
        min: 0, max: 50,
        onChanged: (v) => app.updateSetting('membershipPrice', v),
      ),
    ]);
  }

  Widget _buildDatabase(AppProvider app) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Database', style: Theme.of(context).textTheme.headlineMedium),
        TextButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface800,
              title: const Text('⚠️ Nuke Data?', style: TextStyle(color: Colors.white)),
              content: const Text('This will delete all orders, deliveries, transactions, and reviews.', style: TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(onPressed: () { app.nukeData(); Navigator.pop(context); }, child: Text('Nuke', style: TextStyle(color: AppColors.error))),
              ],
            ),
          ),
          icon: Icon(Icons.delete_outline, color: AppColors.red, size: 18),
          label: Text('Nuke Data', style: TextStyle(color: AppColors.red, fontSize: 13)),
        ),
      ]),
      const SizedBox(height: 16),

      GridView.count(
        crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.6,
        children: [
          _DbCard('Users', app.users.length),
          _DbCard('Products', app.products.length),
          _DbCard('Orders', app.orders.length),
          _DbCard('Deliveries', app.deliveries.length),
          _DbCard('Reviews', app.reviews.length),
          _DbCard('Promos', app.promos.length),
          _DbCard('Notifications', app.notifications.length),
          _DbCard('Transactions', app.transactions.length),
        ],
      ),
    ]);
  }
}

class _RoleRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _RoleRow(this.label, this.count, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
        Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ]),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  final String label, display;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  const _SettingSlider({required this.label, required this.value, required this.display, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          Text(display, style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        Slider(value: value.clamp(min, max), min: min, max: max, activeColor: AppColors.red, onChanged: onChanged),
      ]),
    );
  }
}

class _DbCard extends StatelessWidget {
  final String label;
  final int count;
  const _DbCard(this.label, this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20, fontFamily: 'monospace')),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]),
    );
  }
}
