import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PTListService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<Map<String, dynamic>?> loadPtData(String ptId) async {
    final doc = await _firestore.collection('pts').doc(ptId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return {...data, 'id': doc.id};
  }

  static Future<void> quickHire(
    BuildContext context,
    String ptId,
    String pkg,
    String note, {
    required VoidCallback onDone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final custSnap = await _firestore
        .collection('customers')
        .doc(user.uid)
        .get();
    if (!custSnap.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy tài khoản khách hàng.')),
      );
      return;
    }

    if (custSnap.data()?['ptId'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã có PT. Hãy hủy trước khi thuê PT khác.'),
        ),
      );
      return;
    }

    final chatId = '${user.uid}_$ptId';
    final hireRef = await _firestore.collection('pt_hires').add({
      'customerId': user.uid,
      'ptId': ptId,
      'package': pkg,
      'note': note,
      'status': 'active',
      'chatId': chatId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('customers').doc(user.uid).update({
      'ptId': ptId,
      'ptHiredAt': FieldValue.serverTimestamp(),
      'latestPtHireId': hireRef.id,
    });

    onDone();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Thuê PT thành công!')));
  }

  static Future<void> cancelHire(
    BuildContext context, {
    required VoidCallback onDone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hủy thuê PT'),
            content: const Text('Bạn chắc chắn muốn hủy thuê PT hiện tại?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Không'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Có'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final q = await _firestore
        .collection('pt_hires')
        .where('customerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) {
      await _firestore.collection('pt_hires').doc(q.docs.first.id).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    }

    await _firestore.collection('customers').doc(user.uid).update({
      'ptId': FieldValue.delete(),
      'ptHiredAt': FieldValue.delete(),
      'latestPtHireId': FieldValue.delete(),
    });

    onDone();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã hủy thuê PT.')));
  }
}
