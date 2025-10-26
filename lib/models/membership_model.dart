// lib/models/membership_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MembershipPackage {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationDays; // số ngày gói cơ bản
  final int bonusDays; // tặng thêm (ví dụ 30 ngày)
  final double discountPercent; // giảm %
  final String? promotion; // chuỗi mô tả ưu đãi
  final Timestamp createdAt;

  MembershipPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    this.bonusDays = 0,
    this.discountPercent = 0.0,
    this.promotion,
    required this.createdAt,
  });

  factory MembershipPackage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MembershipPackage(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      durationDays: (data['durationDays'] ?? 0),
      bonusDays: (data['bonusDays'] ?? 0),
      discountPercent: (data['discountPercent'] ?? 0).toDouble(),
      promotion: data['promotion'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'durationDays': durationDays,
    'bonusDays': bonusDays,
    'discountPercent': discountPercent,
    'promotion': promotion,
    'createdAt': createdAt,
  };
}

class UserMembership {
  final String id;
  final String userId;
  final String packageId;
  final String packageName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final bool isActive;
  final double pricePaid;
  final Timestamp createdAt;

  UserMembership({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.packageName,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.isActive,
    required this.pricePaid,
    required this.createdAt,
  });

  factory UserMembership.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserMembership(
      id: doc.id,
      userId: data['userId'] ?? '',
      packageId: data['packageId'] ?? '',
      packageName: data['packageName'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalDays: (data['totalDays'] ?? 0),
      isActive: (data['isActive'] ?? true),
      pricePaid: (data['pricePaid'] ?? 0).toDouble(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'packageId': packageId,
    'packageName': packageName,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'totalDays': totalDays,
    'isActive': isActive,
    'pricePaid': pricePaid,
    'createdAt': createdAt,
  };

  int get remainingDays {
    final now = DateTime.now();
    return endDate.isAfter(now) ? endDate.difference(now).inDays : 0;
  }
}
