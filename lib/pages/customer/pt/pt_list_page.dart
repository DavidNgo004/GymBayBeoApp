import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'pt_card.dart';
import 'my_pt_view.dart';
import 'package:gym_bay_beo/services/customer/pt_list_service.dart';

class PTListPage extends StatefulWidget {
  const PTListPage({super.key});

  @override
  State<PTListPage> createState() => _PTListPageState();
}

class _PTListPageState extends State<PTListPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? currentPtId;
  Map<String, dynamic>? currentPtData;
  bool loading = true;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _customerStream;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _customerStream = _firestore
          .collection('customers')
          .doc(user.uid)
          .snapshots();
      _customerStream!.listen((snap) {
        if (!mounted) return;
        if (!snap.exists) {
          setState(() {
            currentPtId = null;
            currentPtData = null;
            loading = false;
          });
          return;
        }
        final data = snap.data();
        final ptId = data?['ptId'] as String?;
        if (ptId != currentPtId) {
          setState(() => currentPtId = ptId);
          if (ptId != null)
            PTListService.loadPtData(ptId).then((pt) {
              if (!mounted) return;
              setState(() {
                currentPtData = pt;
                loading = false;
              });
            });
          else {
            setState(() {
              currentPtData = null;
              loading = false;
            });
          }
        } else {
          setState(() => loading = false);
        }
      });
    } else {
      _customerStream = null;
      loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Huấn luyện viên (PT)'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
      ),
      body: currentPtId == null
          ? Column(
              children: [
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Bạn chưa thuê PT nào.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.caution,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('pts')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('Hiện chưa có PT nào.'),
                        );
                      }
                      final pts = docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        data['id'] = d.id;
                        return data;
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: pts.length,
                        itemBuilder: (context, i) => PTCard(
                          pt: pts[i],
                          onQuickHire: (pkg, note) => PTListService.quickHire(
                            context,
                            pts[i]['id'],
                            pkg,
                            note,
                            onDone: () =>
                                setState(() => currentPtId = pts[i]['id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : MyPTView(
              ptData: currentPtData!,
              onCancel: () => PTListService.cancelHire(
                context,
                onDone: () => setState(() {
                  currentPtId = null;
                  currentPtData = null;
                }),
              ),
            ),
    );
  }
}
