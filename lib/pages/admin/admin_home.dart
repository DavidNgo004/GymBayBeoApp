import 'package:flutter/material.dart';
import '../../conf/app_colors.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Quản trị viên"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: mở cài đặt admin
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildAdminTile(Icons.people, "Quản lý khách hàng", () {
              // TODO: điều hướng sang màn quản lý khách hàng
            }),
            _buildAdminTile(Icons.sports_gymnastics, "Quản lý PT", () {
              // TODO: điều hướng sang quản lý PT
            }),
            _buildAdminTile(Icons.card_membership, "Quản lý gói tập", () {
              // TODO: quản lý gói tập
            }),
            _buildAdminTile(Icons.bar_chart, "Thống kê & Doanh thu", () {
              // TODO: thống kê
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
