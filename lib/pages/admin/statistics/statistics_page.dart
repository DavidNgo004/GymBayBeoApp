import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'admin_statistics_chart.dart';
import 'package:gym_bay_beo/widgets/confirm_logout_dialog.dart';

class StatisticsPage extends StatelessWidget {
  // 🔥 ĐỔI SANG PAYMENTS
  final CollectionReference paymentsRef = FirebaseFirestore.instance.collection(
    'payments',
  );

  final NumberFormat moneyFmt = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Thống kê'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: AppColors.textPrimary,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                accountName: const Text(
                  "Admin",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                accountEmail: const Text("admin@gymbaybeo.com"),
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: AssetImage("assets/images/admin_avatar.png"),
                ),
              ),

              // Menu
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text("Tổng quan"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin');
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text("Quản lý khách hàng"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/customers');
                },
              ),
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text("Quản lý gói tập"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/packages');
                },
              ),
              ListTile(
                leading: const Icon(Icons.sports_gymnastics),
                title: const Text("Quản lý PT"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/pts');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text("Thống kê"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  "Đăng xuất",
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  await showLogoutConfirmDialog(context);
                },
              ),
            ],
          ),
        ),
      ),

      // BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminStatisticsChart(
              paymentsRef: paymentsRef, // 🔥 TRUYỀN PAYMENTS
              moneyFmt: moneyFmt,
            ),
          ],
        ),
      ),
    );
  }
}
