import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gym_bay_beo/pages/admin/admin_home.dart';
import 'package:gym_bay_beo/pages/admin/pakages_admin_page.dart';
import 'package:gym_bay_beo/pages/customer/customer_home.dart';
import 'package:gym_bay_beo/pages/home_page.dart';
import 'package:gym_bay_beo/models/admin_account.dart';
import 'package:gym_bay_beo/pages/admin/pt_management_page.dart';
import 'package:gym_bay_beo/pages/admin/customers/admin_customers_page.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'conf/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null); // format ngày theo Việt Nam

  try {
    if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }
    // Chỉ khởi tạo Firebase nếu chưa tồn tại app mặc định
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app(); // Dùng lại app đã init
    }
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  await createDefaultAdmin();

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
      home: const HomePage(),
      routes: {
        '/admin': (c) => AdminHomePage(),
        '/admin/packages': (c) => const PackagesAdminPage(),
        '/admin/pts': (context) => const PTManagementPage(),
        '/admin/customers': (context) => const AdminCustomersPage(),
        "/customerHome": (_) => const CustomerHomePage(),
      },
    );
  }
}
