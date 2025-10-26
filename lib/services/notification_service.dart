import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;

  // --- Gửi thông báo ---
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = "general",
    Map<String, dynamic>? data,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data ?? {},
      'isRead': false,
      'isShown': false, // ✅ đánh dấu chưa hiển thị
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Lấy danh sách thông báo của user ---
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- Kiểm tra lịch tập trong ngày và gửi thông báo ---
  Future<void> checkWorkoutScheduleAndNotify(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final query = await _db
        .collection('workout_schedules')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      final isNotified = data['isNotified'] ?? false;
      final date = (data['date'] as Timestamp).toDate();

      if (!isNotified) {
        await sendNotification(
          userId: userId,
          title: "Đến giờ tập rồi 💪",
          body:
              "Hôm nay (${date.day}/${date.month}) bạn có buổi tập đã được PT sắp xếp. Hãy chuẩn bị nhé!",
          type: "workout",
          data: {'scheduleId': doc.id},
        );

        await doc.reference.update({'isNotified': true});
      }
    }
  }

  // --- Đánh dấu đã đọc ---
  Future<void> markAsRead(DocumentReference docRef) async {
    await docRef.update({'isRead': true});
  }

  // --- Đánh dấu đã hiển thị (show notification) ---
  Future<void> markAsShown(DocumentReference docRef) async {
    await docRef.update({'isShown': true});
  }
}
