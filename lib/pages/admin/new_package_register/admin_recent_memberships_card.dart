import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';

class AdminRecentMembershipsCard extends StatelessWidget {
  final CollectionReference membershipsRef;
  final NumberFormat moneyFmt;

  const AdminRecentMembershipsCard({
    Key? key,
    required this.membershipsRef,
    required this.moneyFmt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Tiêu đề + nút Show All ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đăng ký mới',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/admin/memberships'),
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // --- Dữ liệu đăng ký mới ---
            StreamBuilder<QuerySnapshot>(
              stream: membershipsRef
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Chưa có đăng ký mới.'),
                  );
                }

                final docs = snap.data!.docs;

                return Column(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final userId = data['userId'] ?? '';
                    final pkg = data['packageName'] ?? data['packageId'] ?? '';
                    final created = (data['createdAt'] as Timestamp?)?.toDate();
                    final price = data['pricePaid'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: (userId != null && userId != '')
                          ? FirebaseFirestore.instance
                                .collection('customers')
                                .doc(userId)
                                .get()
                          : Future.value(null),
                      builder: (context, userSnap) {
                        String name = 'Không xác định';
                        String img = '';
                        String email = '';
                        if (userSnap.hasData &&
                            userSnap.data != null &&
                            userSnap.data!.exists) {
                          final userData =
                              userSnap.data!.data() as Map<String, dynamic>? ??
                              {};
                          name = userData['name'] ?? 'Khách hàng không rõ tên';
                          img = userData['imageUrl'] ?? '';
                          email = userData['email'] ?? '';
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50.withOpacity(
                              0.6,
                            ), // màu nền item
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade100,
                              child: img != ''
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        img,
                                        fit: BoxFit.cover,
                                        width: 40,
                                        height: 40,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                            ),
                            title: Text(
                              pkg.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [Text('$name')],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  email,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  price != null ? moneyFmt.format(price) : '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              created != null
                                  ? DateFormat('dd/MM/yy').format(created)
                                  : '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
