import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gym_bay_beo/pages/customer/check-in/checkin_history_page.dart';
import 'package:intl/intl.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'package:gym_bay_beo/pages/customer/package/packages_page.dart';
import 'package:gym_bay_beo/pages/customer/schedule/workout_schedule_page.dart';
import 'package:gym_bay_beo/pages/customer/progress/progress_page.dart';
import 'package:gym_bay_beo/pages/customer/check-in/checkin_page.dart';
import 'package:gym_bay_beo/pages/customer/pt/pt_list_page.dart';
import 'package:gym_bay_beo/pages/customer/pt/chat_with_pt_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  String formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    return DateFormat('dd/MM/yyyy').format(time);
  }

  void navigateByType(
    BuildContext context,
    String type,
    String userId,
    Map<String, dynamic> data,
  ) {
    if (type == 'package') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PackagesPage(userId: userId)),
      );
    } else if (type == 'workout') {
      Navigator.pop(context, 'go_to_schedule');
    } else if (type == 'progress') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProgressPage()),
      );
    } else if (type == 'checkin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CheckinHistoryPage()),
      );
    } else if (type == 'pt_request') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PTListPage()),
      );
    } else if (type == 'chat') {
      final chatId = data['chatId'];
      final ptId = data['ptId'];

      if (ptId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy thông tin PT.")),
        );
        return;
      }

      // 🔹 Lấy thông tin PT từ Firestore
      FirebaseFirestore.instance
          .collection('pts')
          .doc(ptId)
          .get()
          .then((ptDoc) {
            if (!ptDoc.exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Không tìm thấy dữ liệu PT.")),
              );
              return;
            }

            final ptData = ptDoc.data()!;
            final ptName = ptData['name'] ?? 'Huấn luyện viên';
            final ptAvatar = ptData['imageUrl'] ?? '';
            final user = FirebaseAuth.instance.currentUser;

            if (user == null) return;

            // 🔹 Nếu không có chatId, tạo theo định dạng userId_ptId
            final chatIdToUse = chatId ?? '${user.uid}_$ptId';

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatWithPTPage(
                  chatId: chatIdToUse,
                  ptId: ptId,
                  ptName: ptName,
                  ptAvatar: ptAvatar,
                ),
              ),
            );
          })
          .catchError((e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi khi tải thông tin PT: $e")),
            );
          });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không có trang phù hợp cho thông báo này"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          "Thông báo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Không có thông báo nào",
                style: TextStyle(color: AppColors.primary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 6),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? "Thông báo";
              final body = data['body'] ?? "";
              final isRead = data['isRead'] ?? false;
              final type = data['type'] ?? "";
              final createdAt = data['createdAt'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: isRead ? Colors.white : Colors.blue[50],
                child: Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => doc.reference.delete(),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: isRead
                          ? Colors.grey[300]
                          : AppColors.secondary.withOpacity(0.2),
                      child: Icon(
                        Icons.notifications,
                        color: isRead ? Colors.grey[600] : AppColors.secondary,
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          createdAt != null ? formatTime(createdAt) : "",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (!isRead) {
                        await doc.reference.update({'isRead': true});
                      }
                      navigateByType(context, type, userId, data);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
