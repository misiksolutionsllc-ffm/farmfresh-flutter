import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../chat_photo.dart';

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
    final active = myDeliveries.isNotEmpty ? myDeliveries.cast<Delivery?>().firstWhere((d) => d != null && d!.status != 'Delivered', orElse: () => null) : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => app.setRole(null)),
        title: Text(['Dashboard', 'Deliveries', 'Earnings', 'Profile'][_tab]),
      ),
      body: IndexedStack(index: _tab, children: [
        _buildDashboard(app, driver, available, active),
        _buildDeliveries(app, available),
        _buildEarnings(app, driver),
        _buildProfile(app, driver),
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

  Widget _buildDashboard(AppProvider app, User driver, List<Delivery> available, Delivery? active) {
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
            // Navigation buttons
            if (active.status == 'Accepted' || active.status == 'Picked Up') ...[
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () {
                    final lat = active.status == 'Accepted' ? 26.6620 : 26.6540;
                    final lng = active.status == 'Accepted' ? -80.2710 : -80.2620;
                    launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'), mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('Google Maps', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.blue, side: BorderSide(color: AppColors.blue.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () {
                    final lat = active.status == 'Accepted' ? 26.6620 : 26.6540;
                    final lng = active.status == 'Accepted' ? -80.2710 : -80.2620;
                    launchUrl(Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d'), mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.navigation, size: 16),
                  label: const Text('Apple Maps', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: BorderSide(color: Colors.white.withOpacity(0.1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
              ]),
              const SizedBox(height: 8),
              // Chat button
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: () {
                  final order = app.orders.cast<dynamic>().firstWhere((o) => o.id == active.orderId, orElse: () => null);
                  final customerName = order != null ? (app.users.firstWhere((u) => u.id == order.customerId, orElse: () => app.users.first).name) : 'Customer';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => OrderChatScreen(orderId: active.id, otherName: customerName, otherRole: 'Customer')));
                },
                icon: const Text('💬', style: TextStyle(fontSize: 16)),
                label: const Text('Chat with Customer'),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6), side: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
              const SizedBox(height: 8),
            ],
            if (active.status == 'Accepted')
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: () => app.pickupJob(active.id),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Photo & Pickup'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
              )),
            if (active.status == 'Picked Up')
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: () => app.completeJob(active.id),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Photo & Complete'),
              )),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildDeliveries(AppProvider app, List<Delivery> available) {
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

  Widget _buildEarnings(AppProvider app, User driver) {
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

  Widget _buildProfile(AppProvider app, User driver) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Hero card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.blue.withOpacity(0.08), AppColors.surface800.withOpacity(0.3)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(children: [
          Row(children: [
            CircleAvatar(radius: 30, backgroundColor: AppColors.blue.withOpacity(0.2), child: Text(driver.name.isNotEmpty ? driver.name[0] : '?', style: TextStyle(color: AppColors.blue, fontSize: 24, fontWeight: FontWeight.w700))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(driver.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Text(driver.email, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              if (driver.phone?.isNotEmpty ?? false)
                Text(driver.phone!, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ])),
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.blue, size: 20),
              onPressed: () => _showEditProfile(app, driver),
            ),
          ]),
          const SizedBox(height: 16),
          // Stats row
          Row(children: [
            _ProfileStat(formatCurrency(driver.earnings), 'Earnings', AppColors.emerald),
            _ProfileStat('${driver.trips ?? 0}', 'Trips', AppColors.blue),
            _ProfileStat('${driver.acceptanceRate ?? 0}%', 'Accept', AppColors.warning),
            _ProfileStat('${driver.rating?.toStringAsFixed(1) ?? '–'}', 'Rating', const Color(0xFF8B5CF6)),
          ]),
        ]),
      ),
      const SizedBox(height: 16),

      // Earnings & Payout
      _SectionCard(title: '💰 Earnings & Payouts', children: [
        Row(children: [
          _EarningBox('Available', formatCurrency(driver.earnings), AppColors.emerald),
          const SizedBox(width: 8),
          _EarningBox('Lifetime', formatCurrency((driver.trips ?? 0) * 8.5), Colors.white),
        ]),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: (driver.earnings ?? 0) > 0 ? () => app.driverPayout(driver.earnings ?? 0, 'bank') : null,
          icon: const Icon(Icons.account_balance, size: 18),
          label: const Text('Withdraw to Bank'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, disabledBackgroundColor: AppColors.surface800),
        )),
      ]),
      const SizedBox(height: 12),

      // Bank Account
      _SectionCard(
        title: '🏦 Bank Account',
        trailing: TextButton(child: Text(driver.bankLast4 != null ? 'Edit' : 'Add', style: const TextStyle(color: AppColors.blue, fontSize: 12)), onPressed: () => _showBankModal(app, driver)),
        children: [
          if (driver.bankLast4 != null)
            _InfoTile(Icons.account_balance, 'Bank Account •••• ${driver.bankLast4}', 'Checking • Direct Deposit', trailing: _VerifiedBadge())
          else
            _AddButton('Add bank account for payouts', () => _showBankModal(app, driver)),
          if (driver.cardLast4 != null) ...[
            const SizedBox(height: 8),
            _InfoTile(Icons.credit_card, 'Visa •••• ${driver.cardLast4}', 'For instant payouts'),
          ],
        ],
      ),
      const SizedBox(height: 12),

      // Vehicle
      _SectionCard(
        title: '🚗 Vehicle',
        trailing: TextButton(child: Text(driver.vehicleMake != null ? 'Edit' : 'Add', style: const TextStyle(color: AppColors.blue, fontSize: 12)), onPressed: () => _showVehicleModal(app, driver)),
        children: [
          if (driver.vehicleMake != null)
            _InfoTile(Icons.directions_car, '${driver.vehicleYear ?? ''} ${driver.vehicleMake} ${driver.vehicleModel ?? ''}', 'Plate: ${driver.vehiclePlate ?? '—'}')
          else
            _AddButton('Add vehicle information', () => _showVehicleModal(app, driver)),
        ],
      ),
      const SizedBox(height: 12),

      // Performance
      _SectionCard(title: '📊 Performance', children: [
        _ProgressRow('Acceptance Rate', (driver.acceptanceRate ?? 0) / 100, AppColors.blue),
        const SizedBox(height: 10),
        _ProgressRow('Rating Score', (driver.rating ?? 0) / 5, AppColors.warning),
        const SizedBox(height: 10),
        _ProgressRow('Trip Goal (200)', ((driver.trips ?? 0) / 200).clamp(0.0, 1.0), AppColors.emerald),
      ]),
      const SizedBox(height: 12),

      // Documents
      _SectionCard(title: '📋 Documents', children: [
        if (driver.documents.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('No documents uploaded yet', style: TextStyle(color: AppColors.textMuted, fontSize: 12))))
        else
          ...driver.documents.map((doc) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.description, color: AppColors.textMuted, size: 16),
                const SizedBox(width: 8),
                Text(doc.type, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
              StatusBadge(doc.status),
            ]),
          )),
      ]),
      const SizedBox(height: 80),
    ]);
  }

  void _showEditProfile(AppProvider app, User driver) {
    final nameCtl = TextEditingController(text: driver.name);
    final phoneCtl = TextEditingController(text: driver.phone ?? '');
    final emailCtl = TextEditingController(text: driver.email);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _Input(nameCtl, 'Full Name', Icons.person),
          const SizedBox(height: 12),
          _Input(phoneCtl, 'Phone Number', Icons.phone),
          const SizedBox(height: 12),
          _Input(emailCtl, 'Email', Icons.email),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              app.updateUserProfile(app.currentUserId!, name: nameCtl.text, phone: phoneCtl.text, email: emailCtl.text);
              Navigator.pop(context);
              app.showToast('Profile updated!');
            },
            child: const Text('Save Changes'),
          )),
        ]),
      ),
    );
  }

  void _showBankModal(AppProvider app, User driver) {
    final bankNameCtl = TextEditingController();
    final routingCtl = TextEditingController();
    final accountCtl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(driver.bankLast4 != null ? 'Edit Bank Account' : 'Add Bank Account', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.shield, color: AppColors.blue, size: 14),
            const SizedBox(width: 6),
            Text('AES-256 encrypted • Never shared', style: TextStyle(color: AppColors.blue, fontSize: 11)),
          ]),
          const SizedBox(height: 16),
          _Input(bankNameCtl, 'Bank Name', Icons.account_balance),
          const SizedBox(height: 12),
          _Input(routingCtl, 'Routing Number (9 digits)', Icons.numbers, mono: true),
          const SizedBox(height: 12),
          _Input(accountCtl, 'Account Number', Icons.lock, mono: true, obscure: true),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (bankNameCtl.text.isNotEmpty && routingCtl.text.length == 9 && accountCtl.text.isNotEmpty) {
                app.updateUserProfile(app.currentUserId!, bankLast4: accountCtl.text.substring(accountCtl.text.length - 4));
                Navigator.pop(context);
                app.showToast('Bank account saved!');
              }
            },
            child: const Text('Save Bank Account'),
          )),
          if (driver.bankLast4 != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: () {
              app.updateUserProfile(app.currentUserId!, bankLast4: '');
              Navigator.pop(context);
              app.showToast('Bank account removed');
            }, child: const Text('Remove bank account', style: TextStyle(color: AppColors.error, fontSize: 13))),
          ],
        ]),
      ),
    );
  }

  void _showVehicleModal(AppProvider app, User driver) {
    final yearCtl = TextEditingController(text: driver.vehicleYear ?? '');
    final makeCtl = TextEditingController(text: driver.vehicleMake ?? '');
    final modelCtl = TextEditingController(text: driver.vehicleModel ?? '');
    final plateCtl = TextEditingController(text: driver.vehiclePlate ?? '');
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.surface900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Vehicle Information', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _Input(yearCtl, 'Year', Icons.calendar_today)),
            const SizedBox(width: 12),
            Expanded(child: _Input(makeCtl, 'Make', Icons.directions_car)),
          ]),
          const SizedBox(height: 12),
          _Input(modelCtl, 'Model', Icons.car_repair),
          const SizedBox(height: 12),
          _Input(plateCtl, 'License Plate', Icons.badge, mono: true),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (makeCtl.text.isNotEmpty && modelCtl.text.isNotEmpty) {
                app.updateUserProfile(app.currentUserId!,
                  vehicleMake: makeCtl.text, vehicleModel: modelCtl.text,
                  vehicleYear: yearCtl.text, vehiclePlate: plateCtl.text.toUpperCase());
                Navigator.pop(context);
                app.showToast('Vehicle info saved!');
              }
            },
            child: const Text('Save Vehicle'),
          )),
        ]),
      ),
    );
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

class _ProfileStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _ProfileStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.surface900.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ]),
    ));
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;
  const _SectionCard({required this.title, this.trailing, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _EarningBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _EarningBox(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface900, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ]),
    ));
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget? trailing;
  const _InfoTile(this.icon, this.title, this.subtitle, {this.trailing});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface900, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.blue, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ])),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text('Verified', style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08), style: BorderStyle.solid),
      ),
      child: Center(child: Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
    ));
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ProgressRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0), minHeight: 6,
        backgroundColor: Colors.white.withOpacity(0.05), valueColor: AlwaysStoppedAnimation(color),
      )),
    ]);
  }
}

Widget _Input(TextEditingController ctl, String hint, IconData icon, {bool mono = false, bool obscure = false}) {
  return TextField(
    controller: ctl, obscureText: obscure,
    style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: mono ? 'monospace' : null),
    decoration: InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
      filled: true, fillColor: AppColors.surface800,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.blue.withOpacity(0.3))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
