import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:gym_bay_beo/widgets/confirm_logout_dialog.dart';

class AdminMembershipsPage extends StatefulWidget {
  const AdminMembershipsPage({Key? key}) : super(key: key);

  @override
  State<AdminMembershipsPage> createState() => _AdminMembershipsPageState();
}

class _AdminMembershipsPageState extends State<AdminMembershipsPage> {
  final CollectionReference membershipsRef = FirebaseFirestore.instance
      .collection('memberships');
  final CollectionReference customersRef = FirebaseFirestore.instance
      .collection('customers');

  String searchQuery = '';
  String selectedPriceFilter = 'Tất cả';
  DateTime? startDate;
  DateTime? endDate;
  List<String> matchedCustomerIds = [];
  Timer? _debounce;

  final NumberFormat moneyFmt = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
  );

  // Chọn khoảng ngày
  Future<void> _pickDateRange(BuildContext context) async {
    final values = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
      dialogBackgroundColor: AppColors.background,
    );

    if (values != null && values.length == 2) {
      setState(() {
        startDate = DateTime(values[0]!.year, values[0]!.month, values[0]!.day);
        endDate = DateTime(
          values[1]!.year,
          values[1]!.month,
          values[1]!.day,
          23,
          59,
          59,
        );
      });
    }
  }

  //Tìm khách hàng theo tên hoặc email
  Future<void> _searchCustomersByNameOrEmail(String query) async {
    _debounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        searchQuery = '';
        matchedCustomerIds = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final customerSnap = await customersRef.get();

      final matchedIds = customerSnap.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final q = query.toLowerCase();
            return name.contains(q) || email.contains(q);
          })
          .map((doc) => doc.id)
          .toList();

      if (mounted) {
        setState(() {
          searchQuery = query.toLowerCase();
          matchedCustomerIds = matchedIds;
        });
      }
    });
  }

  // 🧮 Lọc danh sách gói tập
  Stream<QuerySnapshot> _getFilteredMemberships() {
    Query query = membershipsRef;

    if (startDate != null && endDate != null) {
      query = query
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate!),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate!),
          );
    }

    switch (selectedPriceFilter) {
      case '0.5':
        query = query.where('pricePaid', isLessThan: 500000);
        break;
      case '0.5-1':
        query = query
            .where('pricePaid', isGreaterThanOrEqualTo: 500000)
            .where('pricePaid', isLessThanOrEqualTo: 1000000);
        break;
      case '1':
        query = query.where('pricePaid', isGreaterThan: 1000000);
        break;
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Danh sách đăng ký gói tập',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                accountName: const Text(
                  "Admin",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                accountEmail: const Text("admin@gymbaybeo.com"),
                currentAccountPicture: const CircleAvatar(
                  backgroundImage: AssetImage("assets/images/admin_avatar.png"),
                ),
              ),

              // Các menu điều hướng
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text("Tổng quan"),
                onTap: () => {
                  Navigator.pop(context),
                  Navigator.pushNamed(context, '/admin'),
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text("Quản lý khách hàng"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/customers');
                },
              ),
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text("Quản lý gói tập"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/packages');
                },
              ),
              // 🔥 Thêm menu quản lý PT
              ListTile(
                leading: const Icon(Icons.sports_gymnastics),
                title: const Text("Quản lý PT"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/pts');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text("Thống kê"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/statistics');
                },
              ),

              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  "Đăng xuất",
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  await showLogoutConfirmDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // --- Thanh tìm kiếm & lọc ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, email hoặc tên gói...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.deepPurple,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 15,
                      ),
                    ),
                    onChanged: _searchCustomersByNameOrEmail,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedPriceFilter,
                          decoration: InputDecoration(
                            labelText: 'Giá tiền',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                          ),
                          onChanged: (val) =>
                              setState(() => selectedPriceFilter = val!),
                          items: const [
                            DropdownMenuItem(
                              value: 'Tất cả',
                              child: Text('Tất cả'),
                            ),
                            DropdownMenuItem(
                              value: '0.5',
                              child: Text('Dưới 500k'),
                            ),
                            DropdownMenuItem(
                              value: '0.5-1',
                              child: Text('500k - 1 triệu'),
                            ),
                            DropdownMenuItem(
                              value: '1',
                              child: Text('Trên 1 triệu'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.adminPrimary,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => _pickDateRange(context),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            startDate != null && endDate != null
                                ? '${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate!)}'
                                : 'Lọc theo ngày',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- Danh sách gói tập ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilteredMemberships(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Không có đăng ký nào.'));
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final pkg = (data['packageName'] ?? '')
                        .toString()
                        .toLowerCase();

                    if (searchQuery.isNotEmpty &&
                        matchedCustomerIds.isNotEmpty) {
                      return matchedCustomerIds.contains(data['userId']);
                    }

                    return pkg.contains(searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('Không tìm thấy kết quả.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final userId = data['userId'] ?? '';
                      final pkg = data['packageName'] ?? '';
                      final created = (data['createdAt'] as Timestamp?)
                          ?.toDate();
                      final price = data['pricePaid'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('customers')
                            .doc(userId)
                            .get(),
                        builder: (context, userSnap) {
                          String name = 'Không xác định';
                          String img = '';
                          String email = '';
                          if (userSnap.hasData &&
                              userSnap.data != null &&
                              userSnap.data!.exists) {
                            final userData =
                                userSnap.data!.data()
                                    as Map<String, dynamic>? ??
                                {};
                            name = userData['name'] ?? 'Không rõ tên';
                            img = userData['imageUrl'] ?? '';
                            email = userData['email'] ?? '';
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple.shade100,
                                backgroundImage: img.isNotEmpty
                                    ? NetworkImage(img)
                                    : null,
                                child: img.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.deepPurple,
                                      )
                                    : null,
                              ),
                              title: Text(
                                pkg.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Khách: $name'),
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    price != null ? moneyFmt.format(price) : '',
                                    style: const TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                created != null
                                    ? DateFormat('dd/MM/yyyy').format(created)
                                    : '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
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
        ),
      ),
    );
  }
}
