# FarmFresh Hub — Flutter

Florida's premier decentralized food network. Cross-platform mobile app built with Flutter.

## Tech Stack

- **Framework**: Flutter 3.24+ / Dart 3.5+
- **State**: Provider (ChangeNotifier)
- **Persistence**: SharedPreferences (localStorage)
- **Fonts**: Google Fonts (Playfair Display + DM Sans)
- **Icons**: Lucide Icons
- **Animations**: Flutter Animate

## Getting Started

```bash
# Make sure Flutter SDK is installed
flutter --version

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Run on web
flutter run -d chrome

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

## Project Structure

```
lib/
├── main.dart                    # Entry point + app shell
├── models/
│   └── models.dart              # All data models (User, Product, Order, etc.)
├── providers/
│   └── app_provider.dart        # State management + business logic + seed data
├── screens/
│   ├── role_selection.dart      # Landing screen
│   ├── customer/
│   │   └── customer_app.dart    # Shop, cart, orders, profile
│   ├── driver/
│   │   └── driver_app.dart      # Dashboard, deliveries, earnings
│   ├── merchant/
│   │   └── merchant_app.dart    # Orders, inventory, analytics
│   └── admin/
│       └── admin_app.dart       # Overview, users, settings, database
├── theme/
│   └── app_theme.dart           # Dark theme, brand colors, typography
└── widgets/
    ├── toast_overlay.dart       # Toast notifications
    └── shared_widgets.dart      # StatusBadge, StatCard, GlassCard, etc.
```

## Features

All 4 roles from the original app:
- **Consumer**: Browse products, add to cart, checkout, order history
- **Driver**: Online toggle, accept deliveries, pickup/complete flow, earnings
- **Merchant**: Order queue, inventory CRUD, sales analytics
- **Admin**: Platform overview, user management, fee controls, database viewer

## Design

- Dark theme (Slate 950 background)
- Brand colors: Emerald (Consumer), Blue (Driver), Orange (Merchant), Red (Admin)
- Playfair Display for headings, DM Sans for body
- Material 3 with custom glass-morphism cards

## Shared Backend

Both the Flutter app and the Next.js PWA use the same data models and business logic. The backend (Express + tRPC + Drizzle) can serve both clients via API.
