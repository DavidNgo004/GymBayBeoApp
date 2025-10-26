import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'student_detail_page.dart';

class PTHomeTab extends StatelessWidget {
  final String? ptDocId;

  const PTHomeTab({super.key, required this.ptDocId});

  Stream<QuerySnapshot<Map<String, dynamic>>> getActiveHires() {
    if (ptDocId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('pt_hires')
        .where('ptId', isEqualTo: ptDocId)
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: getActiveHires(),
      builder: (context, snapshot) {
        if (ptDocId == null || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final hires = snapshot.data!.docs;
        if (hires.isEmpty) {
          return const Center(child: Text("Bạn chưa có học viên nào."));
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: hires.length,
            itemBuilder: (context, index) {
              final hire = hires[index].data();
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('customers')
                    .doc(hire['customerId'])
                    .get(),
                builder: (context, customerSnap) {
                  if (!customerSnap.hasData) return const SizedBox.shrink();
                  final customer = customerSnap.data!.data();
                  if (customer == null) return const SizedBox.shrink();

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentDetailPage(customer: customer, hire: hire),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey.shade100],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            customer['imageUrl'] ??
                                'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                          ),
                        ),
                        title: Text(
                          customer['name'] ?? 'Không rõ tên',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "Gói: ${hire['package']}  |  Mục tiêu: ${customer['goal']}kg",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
