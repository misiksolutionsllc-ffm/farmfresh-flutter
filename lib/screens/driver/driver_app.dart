import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class DriverAppScreen extends StatefulWidget {
  const DriverAppScreen({super.key});
  @override
  State<DriverAppScreen> createState() => _DriverAppScreenState();
}

class _DriverAppScreenState extends State<DriverAppScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final driver = app.currentUser;
    if (driver == null) return const SizedBox.shrink();

    final available = app.deliveries.where((d) => d.driverId == null && d.status == 'Pending').toList();
    final myDeliveries = app.deliveries.where((d) => d.driverId == app.currentUserId).toList();
    final active = myDeliveries.cast().firstWhere((d) => d != null && d.status != 'Delivered', orElse: () => null);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => app.setRole(null)),
        title: Text(['Dashboard', 'Deliveries', 'Earnings', 'Profile'][_tab]),
      ),
      body: IndexedStack(index: _tab, children: [
        _buildDashboard(app, driver, available, active),
        _buildDeliveries(app, available),
        _buildEarnings(app, driver),
        _buildProfile(driver),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.surface900.withOpacity(0.95),
        indicatorColor: AppColors.blue.withOpacity(0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Deliveries'),
          NavigationDestination(icon: Icon(Icons.attach_money), selectedIcon: Icon(Icons.attach_money), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboard(AppProvider app, driver, List available, active) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Online toggle
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: (driver.online ?? false) ? AppColors.blue.withOpacity(0.08) : AppColors.surface800.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: (driver.online ?? false) ? AppColors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((driver.online ?? false) ? "You're Online" : "You're Offline", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text((driver.online ?? false) ? '${available.length} deliveries available' : 'Go online to start earning', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ]),
          GestureDetector(
            onTap: app.toggleDriverOnline,
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: (driver.online ?? false) ? AppColors.blue : AppColors.surface800,
                borderRadius: BorderRadius.circular(20),
                border: (driver.online ?? false) ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: (driver.online ?? false) ? [BoxShadow(color: AppColors.blue.withOpacity(0.3), blurRadius: 16)] : null,
              ),
              child: Icon(Icons.power_settings_new, color: (driver.online ?? false) ? Colors.white : AppColors.textMuted, size: 28),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Stats
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
        children: [
          StatCard(label: 'Earnings', value: formatCurrency(driver.earnings), icon: Icons.attach_money, color: AppColors.emerald),
          StatCard(label: 'Trips', value: '${driver.trips ?? 0}', icon: Icons.navigation, color: AppColors.blue),
          StatCard(label: 'Rating', value: '${driver.rating?.toStringAsFixed(1) ?? '–'}', icon: Icons.star, color: AppColors.warning),
          StatCard(label: 'Acceptance', value: '${driver.acceptanceRate ?? 0}%', icon: Icons.trending_up, color: const Color(0xFF8B5CF6)),
        ],
      ),
      const SizedBox(height: 16),

      // Active delivery
      if (active != null) ...[
        GlassCard(
          borderColor: AppColors.blue.withOpacity(0.2),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.flash_on, color: AppColors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('Active Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const Spacer(),
              StatusBadge(active.status),
            ]),
            const SizedBox(height: 16),
            _AddressRow(color: AppColors.blue, label: 'Pickup', address: active.pickup),
            const SizedBox(height: 10),
            _AddressRow(color: AppColors.emerald, label: 'Dropoff', address: active.dropoff),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(active.distance, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              Text(formatCurrency(active.pay), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            if (active.status == 'Accepted')
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => app.pickupJob(active.id),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
                child: const Text('Confirm Pickup'),
              )),
            if (active.status == 'Picked Up')
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => app.completeJob(active.id),
                child: const Text('Complete Delivery'),
              )),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildDeliveries(AppProvider app, List available) {
    if (available.isEmpty) return const EmptyState(emoji: '📦', message: 'No deliveries available');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: available.length,
      itemBuilder: (_, i) {
        final d = available[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface800.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('#${d.id.substring(d.id.length - 6)}', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'monospace')),
              Text(formatCurrency(d.pay), style: TextStyle(color: AppColors.emerald, fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            _AddressRow(color: AppColors.blue, label: 'Pickup', address: d.pickup),
            const SizedBox(height: 8),
            _AddressRow(color: AppColors.emerald, label: 'Dropoff', address: d.dropoff),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(d.distance, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ElevatedButton(
                onPressed: () => app.acceptJob(d.id),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10)),
                child: const Text('Accept'),
              ),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildEarnings(AppProvider app, driver) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.blue.withOpacity(0.1), AppColors.surface800.withOpacity(0.3)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.blue.withOpacity(0.1)),
        ),
        child: Column(children: [
          Text('AVAILABLE BALANCE', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(formatCurrency(driver.earnings), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: (driver.earnings ?? 0) > 0 ? () => app.driverPayout(driver.earnings ?? 0, 'bank') : null,
            icon: const Icon(Icons.account_balance),
            label: const Text('Cash Out'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (app.transactions.isEmpty)
        Center(child: Text('No transactions', style: TextStyle(color: AppColors.textMuted)))
      else
        ...app.transactions.map((tx) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
              Text('${formatDate(tx.date)} • ${tx.method}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
            Text(
              '${tx.amount < 0 ? '-' : '+'}${formatCurrency(tx.amount.abs())}',
              style: TextStyle(color: tx.amount < 0 ? AppColors.error : AppColors.emerald, fontWeight: FontWeight.w700),
            ),
          ]),
        )),
    ]);
  }

  Widget _buildProfile(driver) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircleAvatar(radius: 40, backgroundColor: AppColors.blue.withOpacity(0.2), child: Text(driver.name[0], style: TextStyle(color: AppColors.blue, fontSize: 28, fontWeight: FontWeight.w700))),
      const SizedBox(height: 12),
      Text(driver.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      Text(driver.email, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.star, color: AppColors.warning, size: 16),
        const SizedBox(width: 4),
        Text('${driver.rating ?? '–'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        Text(' • ${driver.trips ?? 0} trips', style: TextStyle(color: AppColors.textMuted)),
      ]),
    ]));
  }
}

class _AddressRow extends StatelessWidget {
  final Color color;
  final String label, address;
  const _AddressRow({required this.color, required this.label, required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        Text(address, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ])),
    ]);
  }
}
