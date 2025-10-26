import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../conf/app_colors.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _rePassController = TextEditingController();

  String _gender = 'Nam'; // mặc định là Nam
  bool _obscurePassword = true;
  bool _obscureRePassword = true;
  bool _isLoading = false;

  final RegExp passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{6,}$',
  );

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Kiểm tra email đã tồn tại chưa
      final list = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        _emailController.text.trim(),
      );
      if (list.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Email đã tồn tại")));
        setState(() => _isLoading = false);
        return;
      }

      // Tạo user mới
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passController.text,
          );

      final uid = userCredential.user!.uid;
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      // =========================
      // Lưu vào bảng "users"
      // =========================
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'phone': phone,
        'email': email,
        'gender': _gender,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // =========================
      // Lưu thêm vào bảng "customers"
      // =========================
      await FirebaseFirestore.instance.collection('customers').doc(uid).set({
        'createdAt': FieldValue.serverTimestamp(),
        'uid': uid,
        'email': email,
        'goal': '',
        'height': '',
        'weight': '',
        'imageUrl':
            'https://res.cloudinary.com/drzg13ngi/image/upload/v1760013365/gymbaybeo/35_kdnpv7.jpg',
        'name': name,
        'phone': phone,
        'gender': _gender,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đăng ký thành công!")));

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Lỗi khi đăng ký tài khoản")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset("assets/images/logo.png", height: 120),
                const SizedBox(height: 5),
                const Text(
                  "Gym Bay Béo",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  "Đăng ký để bắt đầu luyện tập",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Tên khách hàng
                _buildTextField(
                  _nameController,
                  "Tên khách hàng",
                  false,
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),

                // Số điện thoại
                _buildTextField(
                  _phoneController,
                  "Số điện thoại",
                  false,
                  keyboard: TextInputType.phone,
                  icon: Icons.phone,
                ),
                const SizedBox(height: 16),

                // Email
                _buildTextField(
                  _emailController,
                  "Email",
                  false,
                  keyboard: TextInputType.emailAddress,
                  icon: Icons.email,
                ),
                const SizedBox(height: 16),

                // Giới tính
                _buildGenderField(),
                const SizedBox(height: 16),

                // Mật khẩu
                _buildTextField(
                  _passController,
                  "Mật khẩu",
                  true,
                  icon: Icons.lock,
                  isMainPassword: true,
                ),
                const SizedBox(height: 16),

                // Nhập lại mật khẩu
                _buildTextField(
                  _rePassController,
                  "Nhập lại mật khẩu",
                  true,
                  icon: Icons.lock,
                  isRePassword: true,
                  validator: (val) {
                    if (val != _passController.text) {
                      return "Mật khẩu không khớp";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Nút đăng ký
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Đăng ký",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textBtn,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Link sang Login
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    "Bạn đã có tài khoản? Đăng nhập",
                    style: TextStyle(
                      color: AppColors.txtLink,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Field nhập liệu
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool obscure, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    IconData? icon,
    bool isMainPassword = false,
    bool isRePassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure
          ? (isMainPassword ? _obscurePassword : _obscureRePassword)
          : false,
      keyboardType: keyboard,
      validator:
          validator ??
          (val) {
            if (val == null || val.isEmpty) return "Vui lòng nhập $label";
            if (label == "Mật khẩu" && !passwordRegex.hasMatch(val)) {
              return "Mật khẩu ít nhất 6 ký tự, có 1 chữ hoa, 1 số, 1 ký tự đặc biệt";
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                  (isMainPassword ? _obscurePassword : _obscureRePassword)
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    if (isMainPassword) {
                      _obscurePassword = !_obscurePassword;
                    } else if (isRePassword) {
                      _obscureRePassword = !_obscureRePassword;
                    }
                  });
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }

  /// Dropdown chọn giới tính
  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      value: _gender,
      items: const [
        DropdownMenuItem(value: 'Nam', child: Text('Nam')),
        DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
        DropdownMenuItem(value: 'Khác', child: Text('Khác')),
      ],
      decoration: InputDecoration(
        labelText: "Giới tính",
        prefixIcon: const Icon(Icons.male, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      onChanged: (val) => setState(() => _gender = val ?? 'Nam'),
    );
  }
}
