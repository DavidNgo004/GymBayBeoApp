import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'register_page.dart';
import '../customer/customer_home.dart';
import '../pt/pt_home.dart';
import '../admin/admin_home.dart';
import 'package:gym_bay_beo/pages/home_page.dart';
import 'package:gym_bay_beo/pages/auth/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passController.text,
          );

      if (mounted) {
        await _navigateByRole(userCredential.user!.uid);
      }
    } on FirebaseAuthException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Tên đăng nhập hoặc mật khẩu không đúng",
              style: TextStyle(color: AppColors.txtError),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginGoogle() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final uid = userCredential.user!.uid;
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();

      // Nếu user chưa tồn tại trong Firestore
      if (!doc.exists) {
        await docRef.set({
          "uid": uid,
          "name": googleUser.displayName ?? "Google User",
          "email": googleUser.email,
          "phone": "",
          "gender": "Khác",
          "role": "customer",
          "createdAt": FieldValue.serverTimestamp(),
        });

        // Thêm dữ liệu vào bảng customers
        await FirebaseFirestore.instance.collection('customers').doc(uid).set({
          'createdAt': FieldValue.serverTimestamp(),
          'uid': uid,
          'email': googleUser.email,
          'goal': '',
          'height': '',
          'weight': '',
          'imageUrl':
              userCredential.user?.photoURL ??
              'https://res.cloudinary.com/drzg13ngi/image/upload/v1760013365/gymbaybeo/35_kdnpv7.jpg',
          'name': googleUser.displayName ?? "Google User",
          'phone': '',
          'gender': 'Khác',

          //Thông tin phục vụ QR Check-in
          'qrCode': uid, // UID phục vụ quét QR
          'totalDays': 0, // Số ngày tập tổng
          'monthDays': 0, // Số ngày tập trong tháng
          'lastCheckinMonth':
              DateTime.now().month, // Theo dõi để reset mỗi tháng
        });
      }

      if (mounted) {
        await _navigateByRole(uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Lỗi Google Sign-In: $e",
              style: TextStyle(color: AppColors.txtError),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateByRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    String role = doc.data()?['role'] ?? 'customer';

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đăng nhập thành công!"),
        backgroundColor: AppColors.success,
      ),
    );

    Widget nextPage;
    if (role == 'admin') {
      nextPage = AdminHomePage();
    } else if (role == 'pt') {
      nextPage = const PTHomePage();
    } else {
      nextPage = const CustomerHomePage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
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
                const SizedBox(height: 32),
                Image.asset('assets/images/logo.png', height: 180),
                const Text(
                  "Gym Bay Béo",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Đăng nhập để bắt đầu luyện tập ",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 30),

                _buildTextField(
                  _emailController,
                  "Email",
                  false,
                  keyboard: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 16),
                _buildTextField(
                  _passController,
                  "Mật khẩu",
                  true,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textField,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Quên mật khẩu?",
                      style: TextStyle(color: AppColors.txtLink),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginEmail,
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
                            "Đăng nhập",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textBtn,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Image.asset(
                      'assets/images/google_logo01.png',
                      height: 24,
                    ),
                    label: const Text("Đăng nhập với Google"),
                    onPressed: _isLoading ? null : _loginGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: const Text(
                    "Bạn chưa có tài khoản? Đăng ký",
                    style: TextStyle(
                      color: AppColors.txtLink,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                  child: const Text(
                    "Quay về trang chủ",
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool obscure, {
    TextInputType keyboard = TextInputType.text,
    required TextStyle style,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure ? _obscurePassword : false,
      keyboardType: keyboard,
      validator: (val) {
        if (val == null || val.isEmpty) return "Vui lòng nhập $label";
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          label == "Email" ? Icons.email : Icons.lock,
          color: AppColors.primary,
        ),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
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
      style: style,
    );
  }
}
