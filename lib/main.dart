import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/role_selection.dart';
import 'screens/customer/customer_app.dart';
import 'screens/driver/driver_app.dart';
import 'screens/merchant/merchant_app.dart';
import 'screens/admin/admin_app.dart';
import 'widgets/toast_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface950,
    ),
  );
  runApp(const FarmFreshApp());
}

class FarmFreshApp extends StatelessWidget {
  const FarmFreshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'FarmFresh Hub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return Stack(
          children: [
            _buildScreen(app),
            const ToastOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildScreen(AppProvider app) {
    if (app.role == null) return const RoleSelectionScreen();
    switch (app.role!) {
      case UserRole.customer: return const CustomerAppScreen();
      case UserRole.driver: return const DriverAppScreen();
      case UserRole.farmer: return const MerchantAppScreen();
      case UserRole.owner: return const AdminAppScreen();
    }
  }
}
// v1.0.1
