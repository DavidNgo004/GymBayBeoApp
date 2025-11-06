import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_bay_beo/pages/admin/new_package_register/memberships_page.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:gym_bay_beo/services/app_globals.dart';

import 'firebase_options.dart';
import 'models/admin_account.dart';
import 'conf/app_theme.dart';

import 'package:gym_bay_beo/pages/home_page.dart';
import 'package:gym_bay_beo/pages/admin/admin_home.dart';
import 'package:gym_bay_beo/pages/pt/pt_home.dart';
import 'package:gym_bay_beo/pages/customer/customer_home.dart';
import 'package:gym_bay_beo/pages/admin/package-management/pakages_admin_page.dart';
import 'package:gym_bay_beo/pages/admin/pt-management/pt_management_page.dart';
import 'package:gym_bay_beo/pages/admin/customers/admin_customers_page.dart';
import 'package:gym_bay_beo/pages/admin/check-in/admin_checkin_page.dart';
import 'package:gym_bay_beo/pages/admin/statistics/statistics_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('vi_VN', null); // format ngày theo Việt Nam

  try {
    if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
  } catch (e) {
    print("Firebase init error: $e");
  }
  await createDefaultAdmin(); // Tạo tài khoản admin mặc định

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gym Bay Béo",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: const AuthGate(), // kiểm tra đăng nhập
      routes: {
        '/admin': (c) => AdminHomePage(),
        '/admin/packages': (c) => const PackagesAdminPage(),
        '/admin/pts': (context) => const PTManagementPage(),
        '/admin/customers': (context) => const AdminCustomersPage(),
        '/admin/checkin': (context) => AdminCheckinPage(),
        "/customerHome": (_) => const CustomerHomePage(),
        '/admin/memberships': (context) => const AdminMembershipsPage(),
        '/admin/statistics': (context) => StatisticsPage(),
      },
    );
  }
}

// ==========================================================
// Kiểm tra đăng nhập Firebase & điều hướng theo role
// ==========================================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Chưa đăng nhập
        if (!snapshot.hasData) {
          return const HomePage();
        }

        // Đã đăng nhập → kiểm tra role
        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snap.data?.data() as Map<String, dynamic>? ?? {};
            final role = data['role'] ?? 'customer';

            if (role == 'admin') return AdminHomePage();
            if (role == 'pt') return const PTHomePage();
            return const CustomerHomePage();
          },
        );
      },
    );
  }
}
