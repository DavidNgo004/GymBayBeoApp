import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package_model.dart';
import '../models/membership_model.dart';
import '../models/trainer_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- TRAINERS ---

  Stream<List<TrainerModel>> trainersStream() {
    return _db
        .collection('trainers')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TrainerModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addTrainer(TrainerModel trainer) {
    return _db.collection('trainers').add(trainer.toMap());
  }

  Future<void> updateTrainer(TrainerModel trainer) {
    return _db.collection('trainers').doc(trainer.id).update(trainer.toMap());
  }

  Future<void> deleteTrainer(String id) {
    return _db.collection('trainers').doc(id).delete();
  }

  // --- PACKAGES ---

  /// Stream danh sách gói tập
  Stream<List<PackageModel>> packagesStream() {
    return _db
        .collection('packages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PackageModel.fromDoc(d)).toList());
  }

  /// Lấy thông tin 1 gói theo ID
  Future<PackageModel> getPackageById(String id) async {
    final doc = await _db.collection('packages').doc(id).get();
    return PackageModel.fromDoc(doc);
  }

  /// Thêm gói mới
  Future<String> addPackage(PackageModel pkg) async {
    final ref = await _db.collection('packages').add(pkg.toMap());
    return ref.id;
  }

  /// Cập nhật gói
  Future<void> updatePackage(PackageModel pkg) async {
    await _db.collection('packages').doc(pkg.id).update(pkg.toMap());
  }

  /// Kiểm tra xem gói này có đang được sử dụng (membership còn hạn không)
  Future<bool> isPackageInUse(String packageId) async {
    try {
      final now = DateTime.now();

      // Chỉ query theo packageId để tránh lỗi "requires index"
      final q = await _db
          .collection('memberships')
          .where('packageId', isEqualTo: packageId)
          .get();

      // Lọc client-side: chỉ tính membership còn hạn
      final active = q.docs.any((doc) {
        final endDate = (doc['endDate'] as Timestamp).toDate();
        return endDate.isAfter(now);
      });

      return active;
    } catch (e) {
      print('Lỗi khi kiểm tra package in use: $e');
      return false;
    }
  }

  /// Xoá gói nếu không có ai đang dùng
  Future<void> deletePackage(String packageId) async {
    final used = await isPackageInUse(packageId);
    if (used) {
      throw Exception('Không thể xóa: Đã có người đăng ký gói này.');
    }

    await _db.collection('packages').doc(packageId).delete();
    print('Đã xóa gói $packageId thành công.');
  }

  // --- MEMBERSHIPS ---

  /// Stream membership đang hoạt động của user
  Stream<UserMembership?> userActiveMembershipStream(String userId) {
    return _db
        .collection('memberships')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;

          final now = DateTime.now();
          final validDocs = snap.docs.where((doc) {
            final endDate = (doc['endDate'] as Timestamp).toDate();
            return endDate.isAfter(now);
          }).toList();

          if (validDocs.isEmpty) return null;

          validDocs.sort((a, b) {
            final aEnd = (a['endDate'] as Timestamp).toDate();
            final bEnd = (b['endDate'] as Timestamp).toDate();
            return bEnd.compareTo(aEnd);
          });

          return UserMembership.fromFirestore(validDocs.first);
        });
  }

  /// Lấy membership đang hoạt động (active) của user
  Future<UserMembership?> getUserActiveMembership(String userId) async {
    final snap = await _db
        .collection('memberships')
        .where('userId', isEqualTo: userId)
        .get();

    if (snap.docs.isEmpty) return null;

    final now = DateTime.now();
    final validDocs = snap.docs.where((doc) {
      final endDate = (doc['endDate'] as Timestamp).toDate();
      return endDate.isAfter(now);
    }).toList();

    if (validDocs.isEmpty) return null;

    validDocs.sort((a, b) {
      final aEnd = (a['endDate'] as Timestamp).toDate();
      final bEnd = (b['endDate'] as Timestamp).toDate();
      return bEnd.compareTo(aEnd);
    });

    return UserMembership.fromFirestore(validDocs.first);
  }

  /// Đăng ký gói cho user
  Future<void> registerPackageForUser({
    required String userId,
    required PackageModel pkg,
  }) async {
    final now = DateTime.now();
    final active = await getUserActiveMembership(userId);

    if (active == null) {
      final start = Timestamp.fromDate(now);
      final endDate = now.add(Duration(days: pkg.totalDays));
      final newDoc = {
        'userId': userId,
        'packageId': pkg.id,
        'packageName': pkg.title,
        'startDate': start,
        'endDate': Timestamp.fromDate(endDate),
        'totalDays': pkg.totalDays,
        'isActive': true,
        'pricePaid': pkg.effectivePrice.toDouble(),
        'createdAt': Timestamp.now(),
      };
      await _db.collection('memberships').add(newDoc);
    } else {
      final currentEnd = active.endDate;
      final newEnd = currentEnd.add(Duration(days: pkg.totalDays));
      await _db.collection('memberships').doc(active.id).update({
        'endDate': Timestamp.fromDate(newEnd),
        'packageId': pkg.id,
        'packageName': pkg.title,
      });
    }
  }

  /// Stream lịch sử các gói user đã đăng ký
  Stream<List<UserMembership>> userMembershipsStream(String userId) {
    return _db
        .collection('memberships')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserMembership.fromFirestore(d)).toList(),
        );
  }

  /// Stream tất cả membership (Admin)
  Stream<List<UserMembership>> allMembershipsStream() {
    return _db
        .collection('memberships')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserMembership.fromFirestore(d)).toList(),
        );
  }
}
