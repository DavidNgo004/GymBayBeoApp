import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

Future<void> generateFakeWeightData() async {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final uid = auth.currentUser?.uid;

  if (uid == null) {
    print('⚠️ Chưa đăng nhập — không thể thêm dữ liệu test');
    return;
  }

  final random = Random();

  // Xóa dữ liệu cũ (nếu cần)
  final colRef = firestore
      .collection('customers')
      .doc(uid)
      .collection('weightHistory');
  final oldDocs = await colRef.get();
  for (final d in oldDocs.docs) {
    await d.reference.delete();
  }

  // Tạo dữ liệu ngẫu nhiên cho 12 tháng trong năm 2025
  double startWeight = 68;
  for (int month = 1; month <= 12; month++) {
    // Giảm ngẫu nhiên 0–1.5kg mỗi tháng
    startWeight -= random.nextDouble() * 1.5;

    final fakeDate = DateTime(2025, month, 15, 10, 0);
    await colRef.add({
      'createdAt': Timestamp.fromDate(fakeDate),
      'weight': double.parse(startWeight.toStringAsFixed(1)),
    });
  }

  print('✅ Đã tạo dữ liệu cân nặng giả cho 12 tháng trong năm 2025!');
}
