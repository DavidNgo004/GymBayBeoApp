// lib/pages/customer/hire_pt_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'chat_with_pt_page.dart';

typedef OnHiredCallback = void Function(String hiredPtId);

class HirePTPage extends StatefulWidget {
  final String ptId;
  final OnHiredCallback? onHired;

  const HirePTPage({super.key, required this.ptId, this.onHired});

  @override
  State<HirePTPage> createState() => _HirePTPageState();
}

class _HirePTPageState extends State<HirePTPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Map<String, dynamic>? pt;
  bool loading = true;
  String? selectedPackage;
  final noteCtrl = TextEditingController();
  final packages = ['1 tuần', '1 tháng', '3 tháng', '6 tháng'];
  final now = DateTime.now();
  final endDate = null;

  @override
  void initState() {
    super.initState();
    _loadPT();
  }

  Future<void> _loadPT() async {
    final doc = await _firestore.collection('pts').doc(widget.ptId).get();
    if (doc.exists) {
      setState(() {
        pt = {...doc.data()!, 'id': doc.id};
      });
    }
    setState(() => loading = false);
  }

  Future<void> _hire() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // kiểm tra đã có PT chưa
    final custSnap = await _firestore
        .collection('customers')
        .doc(user.uid)
        .get();
    final currentPtId = custSnap.data()?['ptId'] as String?;

    if (currentPtId != null && currentPtId.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã có PT. Hãy hủy trước khi thuê PT khác.'),
        ),
      );
      return;
    }

    if (selectedPackage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn gói thuê.')));
      return;
    }

    final ptId = widget.ptId;
    final chatId = '${user.uid}_$ptId';

    // tạo hire record
    final hireRef = await _firestore.collection('pt_hires').add({
      'customerId': user.uid,
      'ptId': ptId,
      'package': selectedPackage,
      'note': noteCtrl.text.trim(),
      'status': 'active',
      'chatId': chatId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // cập nhật customers
    await _firestore.collection('customers').doc(user.uid).update({
      'ptId': ptId,
      'ptHiredAt': FieldValue.serverTimestamp(),
      'latestPtHireId': hireRef.id,
    });

    widget.onHired?.call(ptId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bạn đã thuê PT thành công.')));
    Navigator.of(context).maybePop();
  }

  Future<void> _cancelHire() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy thuê PT'),
        content: const Text('Bạn có chắc chắn muốn hủy thuê PT này không?'),
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
    );

    if (confirm != true) return;

    final q = await _firestore
        .collection('pt_hires')
        .where('customerId', isEqualTo: user.uid)
        .where('ptId', isEqualTo: widget.ptId)
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã hủy thuê PT.')));
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final id = pt?['id'] as String? ?? widget.ptId;
    final image = pt?['imageUrl'] as String? ?? '';
    final name = pt?['name'] ?? 'Huấn luyện viên';
    final desc = pt?['description'] ?? '';
    final exp = pt?['experience'] ?? '';
    final email = pt?['email'] ?? '';
    final phone = pt?['phone'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: 'pt-image-$id',
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                    )
                  : Container(height: 240, color: Colors.grey[200]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      Text(
                        'Kinh nghiệm: $exp năm',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(desc),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.email, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(email)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(phone)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Chọn gói thuê',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: packages.map((p) {
                      final sel = p == selectedPackage;
                      return ChoiceChip(
                        label: Text(p),
                        selected: sel,
                        onSelected: (v) =>
                            setState(() => selectedPackage = v ? p : null),
                        selectedColor: AppColors.primary.withOpacity(0.9),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú (tùy chọn)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _hire,
                    icon: const Icon(Icons.send),
                    label: const Text('Gửi yêu cầu thuê'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.textPrimary,
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
