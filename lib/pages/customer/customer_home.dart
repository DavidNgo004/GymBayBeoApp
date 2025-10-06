import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../conf/app_colors.dart';
import 'package:gym_bay_beo/widgets/confirm_logout_dialog.dart';
import 'package:gym_bay_beo/pages/customer/profile_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;
  String? userName;
  String? localImagePath;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name'];
          localImagePath = doc.data()?['localImagePath'];
        });
      }
    }
  }

  void _onItemTapped(int index) async {
    if (index == 3) {
      await showLogoutConfirmDialog(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          userName != null ? "Xin chào, $userName" : "Xin chào...",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.toolbarBG,
        foregroundColor: AppColors.textBtn,
        elevation: 2,
        actions: [
          GestureDetector(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    name: userName ?? '',
                    localImagePath: localImagePath ?? '',
                  ),
                ),
              );
              if (updated == true) {
                _fetchUserInfo(); // 🔄 Cập nhật lại sau khi chỉnh sửa
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    (localImagePath != null &&
                        localImagePath!.isNotEmpty &&
                        File(localImagePath!).existsSync())
                    ? FileImage(File(localImagePath!))
                    : const AssetImage('assets/images/avatar_placeholder.png')
                          as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                "https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExbDJrY3oxYWpybmFsbm02N2Z3dWtxZjN0a2ZuaXptMThnNjM3MDZqYyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/DtkOAxWAFUkCI/giphy.gif",
                height: 300,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildMenuCard(Icons.fitness_center, "Gói tập", () {}),
                  _buildMenuCard(Icons.calendar_today, "Lịch tập", () {}),
                  _buildMenuCard(Icons.qr_code_scanner, "Check-in", () {}),
                  _buildMenuCard(Icons.show_chart, "Tiến trình", () {}),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.unSelectedItem,
        backgroundColor: AppColors.toolbarBG,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: "Gói tập",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Lịch tập",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Đăng xuất"),
        ],
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 5,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 50, color: AppColors.toolbarBG),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
