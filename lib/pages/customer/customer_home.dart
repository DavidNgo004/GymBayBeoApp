import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../conf/app_colors.dart';
import '../../services/auth_service.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;
  String? userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()?['name'] != null) {
        setState(() {
          userName = doc['name'];
        });
      }
    }
  }

  void _onItemTapped(int index) async {
    if (index == 3) {
      await AuthService.logout(context);
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
          IconButton(icon: const Icon(Icons.account_circle), onPressed: () {}),
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
                "https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExOWgyZjlhbHl6a3c2MHUzbWFrM2w5d2lweTZhZmtzdnV1YWY3enRmMSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/hV0pccEE0jLfelZPCC/giphy.gif",
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
