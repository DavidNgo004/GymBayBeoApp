import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Stream<List<PackageModel>> getPackages() {
    return _db
        .collection('packages')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PackageModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addPackage(PackageModel package) async {
    await _db.collection('packages').add(package.toMap());
  }

  Future<void> deletePackage(String id) async {
    await _db.collection('packages').doc(id).delete();
  }
}
