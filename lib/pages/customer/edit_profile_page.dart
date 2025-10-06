import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'package:path_provider/path_provider.dart';

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
  String? _goal;
  String? _height;
  String? _weight;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();

    if (mounted && data != null) {
      setState(() {
        _name = data['name'];
        _phone = data['phone'];
        _goal = data['goal'];
        _height = data['height']?.toString();
        _weight = data['weight']?.toString();
        _localImagePath = data['localImagePath'];
      });
    }
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await File(picked.path).copy(file.path);

    setState(() {
      _localImagePath = file.path;
    });
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': _name,
      'phone': _phone,
      'goal': _goal,
      'height': _height,
      'weight': _weight,
      'localImagePath': _localImagePath,
    });

    if (mounted) {
      Navigator.pop(context, true); // báo cho ProfilePage reload lại
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        centerTitle: true,
        backgroundColor: AppColors.toolbarBG,
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
                            backgroundImage:
                                (_localImagePath != null &&
                                    _localImagePath!.isNotEmpty &&
                                    File(_localImagePath!).existsSync())
                                ? FileImage(File(_localImagePath!))
                                : const AssetImage(
                                        'assets/images/avatar_placeholder.png',
                                      )
                                      as ImageProvider,
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
