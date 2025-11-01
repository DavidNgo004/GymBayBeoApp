// lib/pages/admin/admin_home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_bay_beo/widgets/confirm_logout_dialog.dart';
import 'package:gym_bay_beo/pages/admin/new_package_register/admin_recent_memberships_card.dart';

class AdminHomePage extends StatelessWidget {
  AdminHomePage({Key? key}) : super(key: key);

  // Firestore references
  CollectionReference get usersRef =>
      FirebaseFirestore.instance.collection('users');
  CollectionReference get customersRef =>
      FirebaseFirestore.instance.collection('customers');
  CollectionReference get packagesRef =>
      FirebaseFirestore.instance.collection('packages');
  CollectionReference get membershipsRef =>
      FirebaseFirestore.instance.collection('memberships');

  final NumberFormat _moneyFmt = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đã làm mới')));
            },
          ),
        ],
      ),

      // Drawer menu cho admin
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
                onTap: () => Navigator.pop(context),
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

      // Nội dung trang
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTopStatsRow(context),
            const SizedBox(height: 18),
            _buildQuickActions(context),
            const SizedBox(height: 18),

            AdminRecentMembershipsCard(
              membershipsRef: membershipsRef,
              moneyFmt: _moneyFmt,
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  /// Row thống kê trên cùng
  Widget _buildTopStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Hội viên',
            stream: usersRef.snapshots(),
            valueBuilder: (snap) => (snap.size - 1).toString(),
            icon: Icons.people,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Gói tập',
            stream: packagesRef.snapshots(),
            valueBuilder: (snap) => snap.size.toString(),
            icon: Icons.card_membership,
            color: Colors.orange,
          ),
        ),
      ],
    ).wrapWithColumnBelow(
      bottom: Row(
        children: [
          Expanded(
            child: _statCard(
              title: 'Membership active',
              stream: membershipsRef
                  .where('endDate', isGreaterThan: Timestamp.now())
                  .snapshots(),
              valueBuilder: (snap) => snap.size.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _revenueCard()),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required Stream<QuerySnapshot> stream,
    required String Function(QuerySnapshot) valueBuilder,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snap) {
            final value = snap.hasData ? valueBuilder(snap.data!) : '...';
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _revenueCard() {
    final since = DateTime.now().subtract(const Duration(days: 30));
    final q = membershipsRef.where(
      'createdAt',
      isGreaterThan: Timestamp.fromDate(since),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: StreamBuilder<QuerySnapshot>(
          stream: q.snapshots(),
          builder: (context, snap) {
            double total = 0;
            if (snap.hasData) {
              for (final d in snap.data!.docs) {
                final data = d.data() as Map<String, dynamic>;
                final p = (data['pricePaid'] ?? 0);
                if (p is int)
                  total += p.toDouble();
                else if (p is double)
                  total += p;
                else if (p is String)
                  total += double.tryParse(p) ?? 0;
              }
            }
            final money = _moneyFmt.format(total);
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.purple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Doanh thu 30 ngày',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        money,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Quick action cards (thêm PT ở đây)
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionTile(
            context,
            title: 'Quản lý gói',
            subtitle: 'Thêm / sửa / xóa',
            icon: Icons.card_membership,
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, '/admin/packages'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionTile(
            context,
            title: 'Quản lý KH',
            subtitle: 'Thông tin & gói tập',
            icon: Icons.person_search,
            color: Colors.indigo,
            onTap: () => Navigator.pushNamed(context, '/admin/customers'),
          ),
        ),
      ],
    ).wrapWithColumnBelow(
      bottom: Row(
        children: [
          // Thêm ô quản lý PT hiện đại
          Expanded(
            child: _actionTile(
              context,
              title: 'Quản lý PT',
              subtitle: 'Huấn luyện viên',
              icon: Icons.sports_gymnastics,
              color: Colors.teal,
              onTap: () => Navigator.pushNamed(context, '/admin/pts'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionTile(
              context,
              title: 'Check-in',
              subtitle: 'Quầy tiếp tân',
              icon: Icons.qr_code_scanner,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/admin/checkin'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiện ích sắp xếp Row → Column
extension _RowColumnHelper on Widget {
  Widget wrapWithColumnBelow({required Widget bottom}) {
    return Column(children: [this, const SizedBox(height: 12), bottom]);
  }
}
