import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// 🔹 Lấy dữ liệu từ bảng 'customers' thay vì 'users'
  Future<void> loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          userData = doc.data();
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi tải dữ liệu người dùng: $e");
    }
  }

  /// Ẩn email
  String hideEmail(String email) {
    final parts = email.split('@');
    final name = parts[0];
    if (name.length <= 2) return '***@${parts[1]}';
    return '${name.substring(0, 2)}***@${parts[1]}';
  }

  /// Ẩn số điện thoại
  String hidePhone(String phone) {
    if (phone.length < 6) return phone;
    return '${phone.substring(0, 3)}***${phone.substring(phone.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textBtn,
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// Ảnh đại diện (Cloudinary)
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          (userData!['imageUrl'] != null &&
                              userData!['imageUrl'].toString().isNotEmpty)
                          ? NetworkImage(userData!['imageUrl'])
                          : const AssetImage(
                                  'assets/images/avatar_placeholder.png',
                                )
                                as ImageProvider,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Thông tin người dùng
                  _buildInfoTile('Tên', userData!['name'] ?? 'Khách hàng'),
                  _buildInfoTile('Email', hideEmail(user.email ?? '')),
                  _buildInfoTile(
                    'Số điện thoại',
                    hidePhone(userData!['phone'] ?? 'Chưa có'),
                  ),
                  _buildInfoTile('Giới tính', userData!['gender'] ?? '—'),
                  _buildInfoTile(
                    'Chiều cao',
                    '${userData!['height'] ?? '—'} cm',
                  ),
                  _buildInfoTile(
                    'Cân nặng',
                    '${userData!['weight'] ?? '—'} kg',
                  ),
                  _buildInfoTile(
                    'Mục tiêu tập luyện',
                    userData!['goal'] ?? '—',
                  ),

                  const SizedBox(height: 30),

                  /// Nút sửa thông tin
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit, color: AppColors.textBtn),
                    label: const Text(
                      'Thay đổi thông tin',
                      style: TextStyle(fontSize: 16, color: AppColors.textBtn),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                      if (result == true) {
                        setState(() => userData = null);
                        await loadUserData();
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  /// Nút đổi mật khẩu
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Đổi mật khẩu',
                      style: TextStyle(fontSize: 16, color: AppColors.primary),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        tileColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
