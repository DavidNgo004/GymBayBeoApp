import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gym_bay_beo/pages/pt/profile/profile_page.dart';
import 'package:gym_bay_beo/widgets/confirm_logout_dialog.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'students/pt_home_tab.dart';
import 'notification/pt_notification_page.dart';

class PTHomePage extends StatefulWidget {
  const PTHomePage({Key? key}) : super(key: key);

  @override
  State<PTHomePage> createState() => _PTHomePageState();
}

class _PTHomePageState extends State<PTHomePage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  String? imageUrl;
  String ptName = "";
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
      final data = snapshot.docs.first.data();
      setState(() {
        imageUrl = data['imageUrl'];
        ptDocId = snapshot.docs.first.id;
        ptName = data['name'] ?? "";
      });
    }
  }

  Widget buildNotificationBottomIcon() {
    if (ptDocId == null) return const Icon(Icons.notifications_none);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pt_notifications')
          .where('ptId', isEqualTo: ptDocId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unread = snapshot.data?.docs.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none),
            if (unread > 0)
              Positioned(
                top: -4,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$unread",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
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

  void _onTap(int index) async {
    if (index == 3) {
      showLogoutConfirmDialog(context);
      return;
    }

    if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
      _fetchUserInfo();
      return;
    }

    if (index == 2) {
      if (ptDocId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PTNotificationPage(ptId: ptDocId)),
        );
      }
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Xin chào, $ptName 👋",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _selectedIndex == 0
            ? PTHomeTab(ptDocId: ptDocId)
            : const SizedBox(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTap,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.secondary,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Trang chủ",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: "Thông tin",
            ),
            BottomNavigationBarItem(
              icon: buildNotificationBottomIcon(),
              label: "Thông báo",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.logout_rounded),
              label: "Đăng xuất",
            ),
          ],
        ),
      ),
    );
  }
}
