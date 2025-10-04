import 'package:flutter/material.dart';
import '../services/auth_service.dart';

Future<void> showLogoutConfirmDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Xác nhận đăng xuất"),
      content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
      actions: [
        TextButton(
          child: const Text("Hủy"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text("Đăng xuất"),
          onPressed: () {
            Navigator.pop(context);
            AuthService.logout(context);
          },
        ),
      ],
    ),
  );
}
