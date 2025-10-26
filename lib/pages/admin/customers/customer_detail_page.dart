// lib/pages/admin/customers/customer_detail_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';

class CustomerDetailPage extends StatefulWidget {
  final String customerId;
  const CustomerDetailPage({super.key, required this.customerId});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  DocumentSnapshot? _customerDoc;
  DocumentSnapshot? _ptDoc;
  DocumentSnapshot? _membershipDoc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    try {
      final customerSnap = await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customerId)
          .get();

      DocumentSnapshot? ptSnap;
      DocumentSnapshot? membershipSnap;

      if (customerSnap.exists) {
        final data = customerSnap.data() as Map<String, dynamic>?;

        if (data != null) {
          final ptId = data['ptId'];

          // 🔹 Lấy PT nếu có
          if (ptId != null && ptId != "") {
            ptSnap = await FirebaseFirestore.instance
                .collection('pts')
                .doc(ptId)
                .get();
          }

          // 🔹 Lấy membership theo userId
          final membershipQuery = await FirebaseFirestore.instance
              .collection('memberships')
              .where('userId', isEqualTo: widget.customerId)
              .limit(1)
              .get();

          if (membershipQuery.docs.isNotEmpty) {
            membershipSnap = membershipQuery.docs.first;
          }
        }
      }

      setState(() {
        _customerDoc = customerSnap;
        _ptDoc = ptSnap;
        _membershipDoc = membershipSnap;
        _loading = false;
      });
    } catch (e) {
      print("❌ Lỗi load dữ liệu khách hàng: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_customerDoc == null || !_customerDoc!.exists) {
      return const Scaffold(
        body: Center(child: Text("Không tìm thấy khách hàng.")),
      );
    }

    final customerData = _customerDoc!.data() as Map<String, dynamic>;
    final name = customerData['name'] ?? 'Chưa có tên';
    final email = customerData['email'] ?? '';
    final phone = customerData['phone'] ?? '';
    final gender = customerData['gender'] ?? '';
    final goal = customerData['goal'] ?? '';
    final height = customerData['height'] ?? '';
    final weight = customerData['weight'] ?? '';
    final img = customerData['imageUrl'];

    final ptName = _ptDoc != null && _ptDoc!.exists
        ? (_ptDoc!.data() as Map<String, dynamic>)['name'] ?? 'Chưa có tên PT'
        : "Chưa có PT";

    final membershipData = _membershipDoc?.data() as Map<String, dynamic>?;
    final pkgName = membershipData?['packageName'] ?? 'Chưa có gói tập';
    final endDate = membershipData?['endDate']?.toDate();

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ảnh đại diện
            CircleAvatar(
              radius: 50,
              backgroundImage: img != null ? NetworkImage(img) : null,
              child: img == null ? const Icon(Icons.person, size: 60) : null,
            ),
            const SizedBox(height: 16),

            // (1) Thông tin cá nhân
            _buildSectionTitle("Thông tin cá nhân"),
            _buildInfoRow("Tên", name),
            _buildInfoRow("Email", email),
            _buildInfoRow("Số điện thoại", phone),
            _buildInfoRow("Giới tính", gender),
            _buildInfoRow("Chiều cao", height),
            _buildInfoRow("Cân nặng", weight),
            _buildInfoRow("Mục tiêu", goal),
            const SizedBox(height: 16),

            // (2) Gói tập hiện tại
            _buildSectionTitle("Gói tập hiện tại"),
            _buildInfoRow("Tên gói", pkgName),
            if (endDate != null)
              _buildInfoRow(
                "Ngày kết thúc",
                "${endDate.day}/${endDate.month}/${endDate.year}",
              ),
            const SizedBox(height: 16),

            // (4) Thông tin PT
            _buildSectionTitle("Huấn luyện viên (PT)"),
            _buildInfoRow("Tên PT", ptName),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.purpleAccent, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white, // cần để shader phủ lên
              letterSpacing: 0.8,
              shadows: [
                Shadow(
                  color: Colors.purpleAccent.withOpacity(0),
                  blurRadius: 8,
                  offset: const Offset(0, 0),
                ),
                Shadow(
                  color: Colors.indigo.withOpacity(0),
                  blurRadius: 6,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
