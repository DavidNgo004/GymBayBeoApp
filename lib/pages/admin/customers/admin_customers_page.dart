// lib/pages/admin/customers/admin_customers_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'customer_detail_page.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  final _customersRef = FirebaseFirestore.instance.collection('customers');
  final _membershipsRef = FirebaseFirestore.instance.collection('memberships');
  final _ptsRef = FirebaseFirestore.instance.collection('pts');

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khách hàng'),
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 2,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm theo tên hoặc email...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                setState(() {
                  _searchQuery = v.trim().toLowerCase();
                });
              },
            ),
          ),

          // 🧾 Danh sách khách hàng
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _customersRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Chưa có khách hàng nào."));
                }

                final customers = snapshot.data!.docs;

                // 🔍 Lọc theo tìm kiếm
                final filtered = customers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text("Không tìm thấy khách hàng phù hợp."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final customerId = doc.id;
                    final name = data['name'] ?? 'Chưa có tên';
                    final email = data['email'] ?? '';
                    final phone = data['phone'] ?? '';
                    final img = data['imageUrl'];
                    final ptId = data['ptId'];

                    return FutureBuilder(
                      future: Future.wait([
                        _membershipsRef
                            .where('userId', isEqualTo: customerId)
                            .limit(1)
                            .get(),
                        if (ptId != null && ptId != '')
                          _ptsRef.doc(ptId).get()
                        else
                          Future.value(null),
                      ]),
                      builder:
                          (context, AsyncSnapshot<List<dynamic>> resultSnap) {
                            if (!resultSnap.hasData) {
                              return const SizedBox.shrink();
                            }

                            final membershipSnap =
                                resultSnap.data![0] as QuerySnapshot;
                            final ptDoc = resultSnap.data!.length > 1
                                ? resultSnap.data![1] as DocumentSnapshot?
                                : null;

                            // PT
                            String ptName = ptDoc != null && ptDoc.exists
                                ? (ptDoc['name'] ?? 'Chưa có tên PT')
                                : "Chưa có PT";

                            // Gói tập
                            String pkgName = "Chưa có gói tập";
                            bool hasPackage = false;

                            if (membershipSnap.docs.isNotEmpty) {
                              final m =
                                  membershipSnap.docs.first.data()
                                      as Map<String, dynamic>;
                              pkgName =
                                  m['packageName'] ?? "Gói không xác định";
                              hasPackage = true;
                            }

                            // ✅ chỉ hiện tick nếu có PT hoặc có gói tập
                            bool showTick =
                                (ptId != null && ptId != '') || hasPackage;

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 26,
                                  backgroundImage: img != null
                                      ? NetworkImage(img)
                                      : null,
                                  child: img == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        email,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        phone,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "PT: $ptName",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      Text(
                                        "Gói tập: $pkgName",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: showTick
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : const SizedBox.shrink(),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CustomerDetailPage(
                                        customerId: customerId,
                                      ),
                                    ),
                                  );
                                },
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
      ),
    );
  }
}
