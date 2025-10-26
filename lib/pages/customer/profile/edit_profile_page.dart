import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import '../../../services/cloudinary_customer.dart'; // có hàm upload & delete ảnh

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  String? _name;
  String? _phone;
  String? _gender;
  String? _goal;
  String? _height;
  String? _weight;
  String? _imageUrl; // URL hiện tại trên Cloudinary
  File? _newImageFile; // Ảnh mới vừa chọn, chưa upload

  @override
  void initState() {
    super.initState();
    loadCustomerData();
  }

  /// Lấy dữ liệu từ Firestore
  Future<void> loadCustomerData() async {
    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (mounted && data != null) {
      setState(() {
        _name = data['name'];
        _phone = data['phone'];
        _gender = data['gender'];
        _goal = data['goal'];
        _height = data['height']?.toString();
        _weight = data['weight']?.toString();
        _imageUrl = data['imageUrl'];
      });
    }
  }

  /// Chọn ảnh từ thư viện, chỉ hiển thị tạm trên UI
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _newImageFile = File(picked.path);
    });
  }

  /// Upload ảnh mới (nếu có) & xóa ảnh cũ (nếu có)
  /// Upload ảnh mới (nếu có) & xóa ảnh cũ (nếu có)
  Future<String?> _handleImageUpload() async {
    // Không có ảnh mới → giữ nguyên URL cũ
    if (_newImageFile == null) return _imageUrl;

    String? newUrl;

    try {
      // Nếu có ảnh cũ trên Cloudinary → xóa
      if (_imageUrl != null && _imageUrl!.contains('res.cloudinary.com')) {
        try {
          await CloudinaryService.deleteImage(_imageUrl!);
          debugPrint('Ảnh cũ đã được xóa khỏi Cloudinary');
        } catch (e) {
          debugPrint('Không thể xóa ảnh cũ: $e');
        }
      }

      // Upload ảnh mới
      newUrl = await CloudinaryService.uploadImage(_newImageFile!.path);
      debugPrint('Ảnh mới đã upload: $newUrl');
    } catch (e) {
      debugPrint('Lỗi upload ảnh: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải ảnh lên. Vui lòng thử lại.'),
        ),
      );
    }

    return newUrl ?? _imageUrl;
  }

  /// Lưu thông tin vào Firestore
  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đang lưu thay đổi...')));

    // Nếu có ảnh mới → xử lý upload
    final newUrl = await _handleImageUpload();

    await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .update({
          'name': _name,
          'phone': _phone,
          'gender': _gender,
          'goal': _goal,
          'height': _height,
          'weight': _weight,
          'imageUrl': newUrl,
        });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lưu thành công!')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _newImageFile != null
        ? FileImage(_newImageFile!)
        : (_imageUrl != null && _imageUrl!.isNotEmpty
              ? NetworkImage(_imageUrl!)
              : const AssetImage('assets/images/avatar_placeholder.png')
                    as ImageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textBtn,
      ),
      body: _name == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: imageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: InkWell(
                              onTap: pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 22,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Họ và tên',
                      initialValue: _name,
                      onSaved: (val) => _name = val,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Nhập tên' : null,
                    ),
                    _buildTextField(
                      label: 'Số điện thoại',
                      initialValue: _phone,
                      keyboardType: TextInputType.phone,
                      onSaved: (val) => _phone = val,
                      validator: (val) => val == null || val.length < 9
                          ? 'SĐT không hợp lệ'
                          : null,
                    ),
                    _buildTextField(
                      label: 'Chiều cao (cm)',
                      initialValue: _height,
                      keyboardType: TextInputType.number,
                      onSaved: (val) => _height = val,
                    ),
                    _buildTextField(
                      label: 'Cân nặng (kg)',
                      initialValue: _weight,
                      keyboardType: TextInputType.number,
                      onSaved: (val) => _weight = val,
                    ),
                    _buildTextField(
                      label: 'Mục tiêu tập luyện',
                      initialValue: _goal,
                      onSaved: (val) => _goal = val,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: DropdownButtonFormField<String>(
                        value: _gender ?? 'Khác',
                        decoration: InputDecoration(
                          labelText: 'Giới tính',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                          DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                          DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                        ],
                        onChanged: (val) => setState(() => _gender = val),
                        onSaved: (val) => _gender = val,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save, color: AppColors.textBtn),
                      label: const Text(
                        'Lưu thay đổi',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textBtn,
                        ),
                      ),
                      onPressed: saveProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
    TextInputType? keyboardType,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }
}
