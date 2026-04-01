import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static final _roles = [
    _RoleData(UserRole.customer, 'Consumer', '🛒', 'Shop fresh local produce', AppColors.emerald),
    _RoleData(UserRole.driver, 'Driver', '🚗', 'Deliver orders and earn', AppColors.blue),
    _RoleData(UserRole.farmer, 'Farmer American Hero', '🏪', 'Sell your farm products', AppColors.orange),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final pad = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.surface950),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.emerald.withOpacity(0.2)),
                  ),
                  child: const Center(child: Text('🥬', style: TextStyle(fontSize: 40))),
                ),
                const SizedBox(height: 24),
                Text('FarmFresh', style: Theme.of(context).textTheme.displayLarge),
                Text('Hub', style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppColors.emerald, height: 0.9)),
                const SizedBox(height: 12),
                Text(
                  "FLORIDA'S PREMIER DECENTRALIZED FOOD NETWORK",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Role Cards
                ...List.generate(_roles.length, (i) {
                  final r = _roles[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RoleCard(
                      role: r,
                      onTap: () => app.setRole(r.role),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                // God Mode
                GestureDetector(
                  onTap: () => app.setRole(UserRole.owner),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.red.withOpacity(0.3), style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, color: AppColors.red, size: 16),
                        const SizedBox(width: 8),
                        Text('GOD MODE', style: TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface800.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: app.settings.maintenanceMode ? AppColors.error : AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        app.settings.maintenanceMode ? 'LOCKED' : 'ONLINE',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      Container(width: 1, height: 12, color: AppColors.surface700, margin: const EdgeInsets.symmetric(horizontal: 12)),
                      Text('Fee: ${app.settings.platformFeePercent.toInt()}%', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      Container(width: 1, height: 12, color: AppColors.surface700, margin: const EdgeInsets.symmetric(horizontal: 12)),
                      Text('${app.users.length} users', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleData {
  final UserRole role;
  final String label;
  final String emoji;
  final String description;
  final Color color;
  const _RoleData(this.role, this.label, this.emoji, this.description, this.color);
}

class _RoleCard extends StatelessWidget {
  final _RoleData role;
  final VoidCallback onTap;
  const _RoleCard({required this.role, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: role.color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: role.color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(role.emoji, style: const TextStyle(fontSize: 30))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(role.description, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.surface600, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
