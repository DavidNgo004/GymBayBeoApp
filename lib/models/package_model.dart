// lib/models/package_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  String id;
  String title;
  String description;
  int durationDays; // số ngày gốc của gói (ví dụ: 30, 90, 180, 365)
  int bonusDays; // tặng thêm (ví dụ: 30 cho 6 tháng)
  int price; // giá VNĐ (sử dụng int để tránh vấn đề float)
  int discountPercent; // giảm giá phần trăm khi có khuyến mãi (0 nếu không)
  bool active;
  Timestamp createdAt;

  PackageModel({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    this.bonusDays = 0,
    required this.price,
    this.discountPercent = 0,
    this.active = true,
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  int get totalDays => durationDays + bonusDays;

  int get effectivePrice {
    if (discountPercent <= 0) return price;
    return ((price * (100 - discountPercent)) / 100).round();
  }

  factory PackageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PackageModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      durationDays: (data['durationDays'] ?? 30) as int,
      bonusDays: (data['bonusDays'] ?? 0) as int,
      price: (data['price'] ?? 0) as int,
      discountPercent: (data['discountPercent'] ?? 0) as int,
      active: (data['active'] ?? true) as bool,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'durationDays': durationDays,
      'bonusDays': bonusDays,
      'price': price,
      'discountPercent': discountPercent,
      'active': active,
      'createdAt': createdAt,
    };
  }
}
