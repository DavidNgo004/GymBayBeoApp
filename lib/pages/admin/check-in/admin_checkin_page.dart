// lib/pages/admin/admin_checkin_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gym_bay_beo/widgets/confirm_logout_dialog.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AdminCheckinPage extends StatefulWidget {
  const AdminCheckinPage({super.key});

  @override
  State<AdminCheckinPage> createState() => _AdminCheckinPageState();
}

class _AdminCheckinPageState extends State<AdminCheckinPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isScanning = true;

  Future<void> _handleScan(String uid) async {
    if (!_isScanning) return;
    setState(() => _isScanning = false);

    try {
      final userDoc = await _db.collection('customers').doc(uid).get();
      if (!userDoc.exists) {
        _showDialog("Không tìm thấy khách hàng!", isError: true);
        return;
      }

      final user = userDoc.data()!;
      final now = DateTime.now();
      final timestampNow = Timestamp.now();
      final todayKey = DateFormat('yyyy-MM-dd').format(now);

      final membershipSnap = await _db
          .collection('memberships')
          .where('userId', isEqualTo: uid)
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: timestampNow)
          .limit(1)
          .get();

      if (membershipSnap.docs.isEmpty) {
        _showDialog("❌ Chưa có hoặc gói tập đã hết hạn!");
        return;
      }

      final membership = membershipSnap.docs.first.data();

      final historySnap = await _db
          .collection('checkin_history')
          .where('userId', isEqualTo: uid)
          .where('dateKey', isEqualTo: todayKey)
          .get();

      final isFirstToday = historySnap.docs.isEmpty;

      if (isFirstToday) {
        int totalDays = (user['totalDays'] ?? 0) + 1;
        int monthDays = (user['monthDays'] ?? 0);
        int lastMonth = (user['lastCheckinMonth'] ?? now.month);

        if (lastMonth != now.month) monthDays = 0;
        monthDays++;

        await userDoc.reference.update({
          'totalDays': totalDays,
          'monthDays': monthDays,
          'lastCheckinMonth': now.month,
        });
      }

      /// ➤ Ghi lịch sử check-in
      await _db.collection('checkin_history').add({
        'userId': uid,
        'date': timestampNow,
        'dateKey': todayKey,
      });

      /// 🔔 ➤ Gửi thông báo check-in
      await _db.collection('notifications').add({
        'userId': uid,
        'title': 'Check-in thành công 🎉',
        'body':
            "Bạn đã check-in lúc ${DateFormat('HH:mm - dd/MM').format(now)} ✅",
        'type': 'checkin',
        'createdAt': timestampNow,
        'isRead': false,
      });

      _showDialog(
        "✅ Check-in thành công!\n"
        "${isFirstToday ? "🎉 +1 ngày tập" : "💪 Đã check-in hôm nay"}",
        user: user,
        membership: membership,
        checkinTime: now,
      );
    } catch (e) {
      _showDialog("Lỗi: $e", isError: true);
    }
  }

  void _showDialog(
    String msg, {
    bool isError = false,
    Map<String, dynamic>? user,
    Map<String, dynamic>? membership,
    DateTime? checkinTime,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 30,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error : Icons.check_circle,
                size: 75,
                color: isError ? Colors.red : Colors.green,
              ),
              const SizedBox(height: 12),
              Text(
                isError ? "Thất bại" : "THÀNH CÔNG ✅",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isError ? Colors.red : Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(msg, textAlign: TextAlign.center),
              const SizedBox(height: 18),

              if (user != null) _buildUserInfo(user, membership, checkinTime),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isScanning = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? Colors.red : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Đóng",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfo(
    Map<String, dynamic> user,
    Map<String, dynamic>? membership,
    DateTime? checkinTime,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: user['avatar'] != null && user['avatar'] != ""
                ? NetworkImage(user['avatar'])
                : null,
            child: user['avatar'] == null || user['avatar'] == ""
                ? const Icon(Icons.person, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? "Không rõ tên",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text("📞 ${user['phone'] ?? '---'}"),
                Text("📦 ${membership?['packageName'] ?? '---'}"),
                if (membership?['endDate'] != null)
                  Text(
                    "⏳ Hết hạn: ${DateFormat('dd/MM/yyyy').format((membership?['endDate'] as Timestamp).toDate())}",
                    style: const TextStyle(fontSize: 14),
                  ),
                if (checkinTime != null)
                  Text(
                    "🕒 Giờ check-in: ${DateFormat('HH:mm').format(checkinTime)}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Check-in Khách Hàng"),
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

              // Các menu điều hướng
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text("Tổng quan"),
                onTap: () => {
                  Navigator.pop(context),
                  Navigator.pushNamed(context, '/admin'),
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
              // 🔥 Thêm menu quản lý PT
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
                  Navigator.pushNamed(context, '/admin/statistics');
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
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Quét mã QR để Check-in",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final code = capture.barcodes.first.rawValue;
                if (code != null) _handleScan(code);
              },
            ),
          ),
        ],
      ),
    );
  }
}
