// lib/services/membership_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/membership_model.dart';

class MembershipService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get packagesRef => _db.collection('packages');
  CollectionReference get userMembershipRef =>
      _db.collection('user_memberships');
  CollectionReference get usersRef => _db.collection('users');

  // Stream tất cả gói
  Stream<List<MembershipPackage>> streamPackages() {
    return packagesRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MembershipPackage.fromFirestore(d)).toList(),
        );
  }

  // Lấy 1 gói theo id
  Future<MembershipPackage> getPackageById(String id) async {
    final doc = await packagesRef.doc(id).get();
    return MembershipPackage.fromFirestore(doc);
  }

  // Thêm gói (admin)
  Future<void> addPackage(MembershipPackage pkg) async {
    await packagesRef.add(pkg.toMap());
  }

  // Update gói (admin)
  Future<void> updatePackage(String id, Map<String, dynamic> data) async {
    await packagesRef.doc(id).update(data);
  }

  // Kiểm tra có user nào đăng ký gói này không
  Future<bool> hasUsersInPackage(String packageId) async {
    final snap = await userMembershipRef
        .where('packageId', isEqualTo: packageId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // Xóa gói nếu không có ai đăng ký
  Future<void> deletePackageIfNoMembers(String id) async {
    final has = await hasUsersInPackage(id);
    if (has) throw Exception('Không thể xóa: đã có người đăng ký gói này.');
    await packagesRef.doc(id).delete();
  }

  // Stream membership hiện tại của user
  Stream<UserMembership?> streamCurrentUserMembership(String? uid) {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();
    return userMembershipRef
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('endDate', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snap) => snap.docs.isEmpty
              ? null
              : UserMembership.fromFirestore(snap.docs.first),
        );
  }

  // Lấy membership hiện tại once (không stream)
  Future<UserMembership?> getCurrentUserMembershipOnce(String? uid) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return null;
    final snap = await userMembershipRef
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('endDate', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserMembership.fromFirestore(snap.docs.first);
  }

  // Đăng ký gói (cộng dồn ngày nếu đang có gói active)
  Future<void> registerPackage({
    required MembershipPackage pkg,
    String? userId,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) throw Exception('Chưa đăng nhập');

    final now = DateTime.now();

    return _db.runTransaction((tx) async {
      // Lấy gói mới (đảm bảo tồn tại)
      final pkgDoc = await tx.get(packagesRef.doc(pkg.id));
      if (!pkgDoc.exists) throw Exception('Gói không tồn tại');

      // Lấy membership hiện tại (nếu có)
      final activeQuery = await userMembershipRef
          .where('userId', isEqualTo: uid)
          .where('isActive', isEqualTo: true)
          .orderBy('endDate', descending: true)
          .limit(1)
          .get();

      DateTime newStart = now;
      DateTime newEnd = now.add(
        Duration(days: pkg.durationDays + pkg.bonusDays),
      );
      double pricePaid = pkg.price * (1 - pkg.discountPercent / 100);

      if (activeQuery.docs.isNotEmpty) {
        final activeDoc = activeQuery.docs.first;
        final active = UserMembership.fromFirestore(activeDoc);

        // nếu endDate > now thì cộng dồn: newStart giữ start của active? (business choice)
        final currentEnd = active.endDate.isAfter(now) ? active.endDate : now;
        newStart = active.startDate.isBefore(now) ? now : active.startDate;
        newEnd = currentEnd.add(
          Duration(days: pkg.durationDays + pkg.bonusDays),
        );

        // set active cũ thành false
        tx.update(userMembershipRef.doc(active.id), {'isActive': false});
      }

      // Thêm record mới
      final newDocRef = userMembershipRef.doc();
      tx.set(newDocRef, {
        'userId': uid,
        'packageId': pkg.id,
        'packageName': pkg.name,
        'startDate': Timestamp.fromDate(newStart),
        'endDate': Timestamp.fromDate(newEnd),
        'totalDays': pkg.durationDays + pkg.bonusDays,
        'isActive': true,
        'pricePaid': pricePaid,
        'createdAt': Timestamp.now(),
      });

      // Cập nhật user (ghi lại lastPackage)
      tx.set(usersRef.doc(uid), {
        'lastPackageId': pkg.id,
        'lastPackageAt': Timestamp.now(),
      }, SetOptions(merge: true));
    });
  }

  // Stream tất cả user memberships (admin view)
  Stream<List<UserMembership>> streamAllUserMemberships() {
    return userMembershipRef
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserMembership.fromFirestore(d)).toList(),
        );
  }
}
