import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_bay_beo/services/cloudinary_service.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'package:gym_bay_beo/widgets/confirm_logout_dialog.dart';

class PTManagementPage extends StatefulWidget {
  const PTManagementPage({super.key});

  @override
  State<PTManagementPage> createState() => _PTManagementPageState();
}

class _PTManagementPageState extends State<PTManagementPage> {
  final CollectionReference ptsRef = FirebaseFirestore.instance.collection(
    'pts',
  );
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _expCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  String _gender = 'Nam';
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  File? _selectedImage;
  String? _uploadedImageUrl;

  // === CHỌN ẢNH ===
  Future<void> _pickImage(StateSetter setStateDialog) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setStateDialog(() => _selectedImage = File(picked.path));
    }
  }

  // === THÊM PT ===
  void _showAddPTDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Thêm Huấn Luyện Viên'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(setStateDialog),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.deepPurple,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nhập họ tên' : null,
                  ),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.length < 9 ? 'SĐT không hợp lệ' : null,
                  ),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Email không hợp lệ'
                        : null,
                  ),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Ít nhất 6 ký tự' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    items: const [
                      DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                      DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                    ],
                    onChanged: (v) =>
                        setStateDialog(() => _gender = v ?? 'Nam'),
                    decoration: const InputDecoration(labelText: 'Giới tính'),
                  ),
                  TextFormField(
                    controller: _expCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kinh nghiệm (năm)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả / Giới thiệu',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.deepPurple),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        setStateDialog(() => _isLoading = true);
                        try {
                          String? imageUrl;
                          if (_selectedImage != null) {
                            imageUrl = await CloudinaryService.uploadImage(
                              _selectedImage!,
                            );
                          }

                          final credential = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                                email: _emailCtrl.text.trim(),
                                password: _passCtrl.text.trim(),
                              );
                          final userId = credential.user!.uid;

                          await usersRef.doc(userId).set({
                            'uid': userId,
                            'name': _nameCtrl.text.trim(),
                            'email': _emailCtrl.text.trim(),
                            'phone': _phoneCtrl.text.trim(),
                            'role': 'pt',
                            'gender': _gender,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          await ptsRef.add({
                            'userId': userId,
                            'name': _nameCtrl.text.trim(),
                            'email': _emailCtrl.text.trim(),
                            'phone': _phoneCtrl.text.trim(),
                            'gender': _gender,
                            'experience': _expCtrl.text.trim(),
                            'description': _descCtrl.text.trim(),
                            'imageUrl': imageUrl,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thêm HLV thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          _nameCtrl.clear();
                          _phoneCtrl.clear();
                          _emailCtrl.clear();
                          _passCtrl.clear();
                          _expCtrl.clear();
                          _descCtrl.clear();
                          _selectedImage = null;
                        } on FirebaseAuthException catch (e) {
                          String message = 'Lỗi khi tạo tài khoản.';
                          if (e.code == 'email-already-in-use') {
                            message = 'Email này đã được sử dụng.';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        } finally {
                          setStateDialog(() => _isLoading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text(
                'Thêm',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === CHỈNH SỬA PT ===
  void _showEditPTDialog(String ptId, Map<String, dynamic> data) {
    final TextEditingController nameCtrl = TextEditingController(
      text: data['name'],
    );
    final TextEditingController phoneCtrl = TextEditingController(
      text: data['phone'],
    );
    final TextEditingController expCtrl = TextEditingController(
      text: data['experience']?.toString() ?? '',
    );
    final TextEditingController descCtrl = TextEditingController(
      text: data['description'] ?? '',
    );
    String gender = data['gender'] ?? 'Nam';
    bool isSaving = false;
    File? newImage;
    String? newImageUrl;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Chỉnh sửa Huấn Luyện Viên'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      setStateDialog(() => newImage = File(picked.path));
                    }
                  },
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage: newImage != null
                        ? FileImage(newImage!)
                        : (data['imageUrl'] != null
                                  ? NetworkImage(data['imageUrl'])
                                  : null)
                              as ImageProvider?,
                    child: newImage == null && data['imageUrl'] == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.deepPurple,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                ),
                TextFormField(
                  initialValue: data['email'],
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Email (không thể sửa)',
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: gender,
                  items: const [
                    DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                    DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                  ],
                  onChanged: (v) => setStateDialog(() => gender = v ?? 'Nam'),
                  decoration: const InputDecoration(labelText: 'Giới tính'),
                ),
                TextFormField(
                  controller: expCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kinh nghiệm (năm)',
                  ),
                ),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả / Giới thiệu',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                if (isSaving)
                  const CircularProgressIndicator(color: Colors.deepPurple),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setStateDialog(() => isSaving = true);
                      try {
                        if (newImage != null) {
                          if (data['imageUrl'] != null) {
                            await CloudinaryService.deleteImage(
                              data['imageUrl'],
                            );
                          }
                          newImageUrl = await CloudinaryService.uploadImage(
                            newImage!,
                          );
                        }

                        await ptsRef.doc(ptId).update({
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'gender': gender,
                          'experience': expCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          if (newImageUrl != null) 'imageUrl': newImageUrl,
                        });
                        final userId = data['userId'];
                        if (userId != null) {
                          await usersRef.doc(userId).update({
                            'name': nameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'gender': gender,
                          });
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cập nhật thành công!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi khi cập nhật: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      } finally {
                        setStateDialog(() => isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  // === XÓA PT (Firestore + Authentication + Cloudinary) ===
  Future<void> _deletePT(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa Huấn Luyện Viên'),
        content: const Text('Bạn có chắc muốn xóa PT này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ptDoc = await ptsRef.doc(id).get();
      if (ptDoc.exists) {
        final userId = ptDoc['userId'];
        final imageUrl = ptDoc['imageUrl'];
        try {
          if (imageUrl != null) {
            await CloudinaryService.deleteImage(imageUrl);
          }
          await ptsRef.doc(id).delete();
          await usersRef.doc(userId).delete();
          await FirebaseAuth.instance.currentUser?.delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa PT thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // === GIAO DIỆN CHÍNH ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Huấn Luyện Viên'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
            ),
          ),
        ),
        foregroundColor: Colors.white,
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
              // Thêm menu quản lý PT
              ListTile(
                leading: const Icon(Icons.sports_gymnastics),
                title: const Text("Quản lý PT"),
                onTap: () {
                  Navigator.pop(context);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPTDialog,
        backgroundColor: Colors.deepPurple,
        foregroundColor: AppColors.textPrimary,
        icon: const Icon(Icons.add),
        label: const Text("Thêm PT"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ptsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có huấn luyện viên nào.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: data['imageUrl'] != null
                        ? NetworkImage(data['imageUrl'])
                        : null,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: data['imageUrl'] == null
                        ? Text(
                            data['name'] != null &&
                                    data['name'].toString().isNotEmpty
                                ? data['name'][0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.deepPurple),
                          )
                        : null,
                  ),
                  title: Text(
                    data['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '📞 ${data['phone'] ?? ''}\nEmail: ${data['email'] ?? ''}\nKinh nghiệm: ${data['experience'] ?? '0'} năm',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => _showEditPTDialog(docs[i].id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deletePT(docs[i].id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
