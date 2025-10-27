import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../conf/app_colors.dart';
import '../chat/pt_chat_page.dart';

class PTNotificationPage extends StatefulWidget {
  final String? ptId;
  const PTNotificationPage({Key? key, this.ptId}) : super(key: key);

  @override
  State<PTNotificationPage> createState() => _PTNotificationPageState();
}

class _PTNotificationPageState extends State<PTNotificationPage> {
  // 🕒 Hàm định dạng thời gian
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

  // ✅ Đánh dấu đã đọc
  Future<void> _markAsRead(String id) async {
    await FirebaseFirestore.instance
        .collection('pt_notifications')
        .doc(id)
        .update({'isRead': true});
  }

  // ✅ Xóa thông báo
  Future<void> _deleteNotification(String id) async {
    await FirebaseFirestore.instance
        .collection('pt_notifications')
        .doc(id)
        .delete();
  }

  // ✅ Lấy thông tin khách hàng từ chatId
  Future<Map<String, dynamic>?> _getCustomerFromChat(String chatId) async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      if (!chatDoc.exists) return null;

      final chatData = chatDoc.data()!;
      String? customerId = chatData['userId'];

      // Nếu userId rỗng → tìm từ message gần nhất
      if (customerId == null || customerId.isEmpty) {
        final msgSnap = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        if (msgSnap.docs.isNotEmpty) {
          final senderId = msgSnap.docs.first['senderId'];
          if (senderId != widget.ptId) customerId = senderId;
        }
      }

      if (customerId == null) return null;

      final customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .get();

      if (!customerDoc.exists) return null;
      final customerData = customerDoc.data()!;
      customerData['uid'] = customerDoc.id;
      return customerData;
    } catch (e) {
      debugPrint('❌ Lỗi lấy khách hàng: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ptId == null) {
      return const Center(child: Text("Không xác định được PT."));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textBtn,
        title: const Text(
          "Thông báo của bạn",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pt_notifications')
            .where('ptId', isEqualTo: widget.ptId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;
          if (notifications.isEmpty) {
            return const Center(child: Text("Hiện chưa có thông báo nào."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? "Thông báo";
              final body = data['body'] ?? "";
              final createdAt = data['createdAt'] as Timestamp?;
              final isRead = data['isRead'] ?? false;
              final chatId = data['chatId'];

              return Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteNotification(doc.id),
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _getCustomerFromChat(chatId),
                  builder: (context, snapshot) {
                    final customer = snapshot.data;
                    final customerName = customer?['name'] ?? "Khách hàng";
                    final customerAvatar =
                        customer?['imageUrl'] ??
                        'https://cdn-icons-png.flaticon.com/512/149/149071.png';

                    return Card(
                      elevation: 3,
                      color: isRead ? Colors.white : Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(customerAvatar),
                        ),
                        title: Text(
                          title.contains("Tin nhắn")
                              ? "Tin nhắn của $customerName"
                              : title,
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(body),
                            if (createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  formatTime(createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () async {
                          await _markAsRead(doc.id);

                          final customerData = await _getCustomerFromChat(
                            chatId,
                          );
                          if (customerData == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Không tìm thấy thông tin khách hàng',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PTChatPage(
                                chatId: chatId,
                                customerId: customerData['uid'],
                                customerName:
                                    customerData['name'] ?? 'Khách hàng',
                                customerAvatar: customerData['imageUrl'] ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
