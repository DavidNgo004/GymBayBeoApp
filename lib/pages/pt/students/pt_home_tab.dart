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

  Future<DocumentSnapshot<Map<String, dynamic>>> getPTInfo() async {
    return FirebaseFirestore.instance.collection('pts').doc(ptDocId).get();
  }

  @override
  Widget build(BuildContext context) {
    if (ptDocId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // ✅ PT INFO HEADER — UI Gradient đẹp hơn
        FutureBuilder(
          future: getPTInfo(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final data = snapshot.data!.data();
            if (data == null) return const SizedBox();

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundImage: NetworkImage(
                      data['imageUrl'] ??
                          'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'PT chưa xác định',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "📞 ${data['phone'] ?? '---'}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "🎯 Kinh nghiệm: ${data['experience'] ?? '---'} năm",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // ✅ TIÊU ĐỀ DANH SÁCH HỌC VIÊN
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: const Text(
            "Danh sách học viên",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder(
            stream: getActiveHires(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final hires = snapshot.data!.docs;
              if (hires.isEmpty) {
                return const Center(child: Text("Chưa có học viên đang tập"));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: hires.length,
                itemBuilder: (context, index) {
                  final hire = hires[index].data();

                  return FutureBuilder(
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
                              builder: (_) => StudentDetailPage(
                                customer: customer,
                                hire: hire,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.06),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            leading: CircleAvatar(
                              radius: 28,
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
                              "Mục tiêu: ${customer['goal']} kg",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.secondary,
                              size: 26,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
