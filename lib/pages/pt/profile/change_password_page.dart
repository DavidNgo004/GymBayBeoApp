import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isVisible1 = false;
  bool _isVisible2 = false;
  bool _isVisible3 = false;
  bool _isLoading = false;

  // Hàm đổi mật khẩu
  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu mới và xác nhận không trùng khớp!'),
        ),
      );
      return;
    }

    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy tài khoản đang đăng nhập.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Xác thực lại người dùng
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // Đổi mật khẩu
      await user.updatePassword(newPassword);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!')));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Lỗi: ${e.message}';
      if (e.code == 'wrong-password') {
        msg = 'Mật khẩu hiện tại không đúng!';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, //giao diện tự đẩy lên khi bàn phím mở
      appBar: AppBar(
        title: const Text(
          "Đổi mật khẩu",
          style: TextStyle(color: AppColors.textBtn),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBtn),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Image.network(
                "https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExZWFyazV4cnRiemczb3k2OXN4YnZuZjZxb28yNjVpamxyeG85ZWg3bSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0HlVp02RFuc91Cus/giphy.gif",
                height: 300,
              ),
              const SizedBox(height: 20),

              // Mật khẩu hiện tại
              TextField(
                controller: currentPasswordController,
                obscureText: !_isVisible1,
                decoration: InputDecoration(
                  labelText: "Mật khẩu hiện tại",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isVisible1 ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.primary,
                    ),
                    onPressed: () => setState(() => _isVisible1 = !_isVisible1),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Mật khẩu mới
              TextField(
                controller: newPasswordController,
                obscureText: !_isVisible2,
                decoration: InputDecoration(
                  labelText: "Mật khẩu mới",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isVisible2 ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _isVisible2 = !_isVisible2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Xác nhận mật khẩu mới
              TextField(
                controller: confirmPasswordController,
                obscureText: !_isVisible3,
                decoration: InputDecoration(
                  labelText: "Xác nhận mật khẩu mới",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isVisible3 ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _isVisible3 = !_isVisible3),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Nút xác nhận
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Xác nhận đổi mật khẩu",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textBtn,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
