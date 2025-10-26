import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gym_bay_beo/pages/pt/profile/profile_page.dart';
import 'package:gym_bay_beo/widgets/confirm_logout_dialog.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'students/pt_home_tab.dart';
import 'pt_notification_page.dart'; // Trang thông báo của PT

class PTHomePage extends StatefulWidget {
  const PTHomePage({Key? key}) : super(key: key);

  @override
  State<PTHomePage> createState() => _PTHomePageState();
}

class _PTHomePageState extends State<PTHomePage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  String? imageUrl;
  String? ptDocId;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('pts')
        .where('userId', isEqualTo: user!.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      setState(() {
        imageUrl = doc['imageUrl'];
        ptDocId = doc.id;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      showLogoutConfirmDialog(context);
      return;
    } else if (index == 2) {
      if (ptDocId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PTNotificationPage(ptId: ptDocId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chưa xác định được thông tin PT")),
        );
      }
      return;
    }

    setState(() => _selectedIndex = index);
  }

  /// ✅ Hàm tạo icon thông báo có badge — có thể tái sử dụng
  Widget buildNotificationIcon(BuildContext context, String? ptDocId) {
    if (ptDocId == null) {
      return IconButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Chưa xác định được thông tin PT")),
          );
        },
        icon: const Icon(Icons.notifications_none, color: Colors.black),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pt_notifications')
          .where('ptId', isEqualTo: ptDocId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PTNotificationPage(ptId: ptDocId),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_none, color: Colors.black),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        title: const Text(
          "Trang chủ Huấn luyện viên",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          buildNotificationIcon(context, ptDocId), // 🔔 Gọi hàm đã tách riêng
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
              _fetchUserInfo();
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: Hero(
                tag: 'user-avatar',
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                      ? NetworkImage(imageUrl!)
                      : const AssetImage('assets/images/avatar_placeholder.png')
                            as ImageProvider,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? PTHomeTab(ptDocId: ptDocId)
          : _selectedIndex == 1
          ? const Center(child: Text("Lịch tập của học viên"))
          : const Center(child: Text("Thông báo")),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Lịch tập",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Thông báo",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Đăng xuất"),
        ],
      ),
    );
  }
}
