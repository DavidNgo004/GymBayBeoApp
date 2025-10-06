import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';

Future<void> showLogoutConfirmDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Bạn muốn đăng xuất?"),
      backgroundColor: AppColors.background,
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.cancel, color: AppColors.textBtn),
          label: const Text("Hủy", style: TextStyle(color: AppColors.textBtn)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.logout, color: AppColors.textBtn),
          label: const Text(
            "Đăng xuất",
            style: TextStyle(color: AppColors.textBtn),
          ),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            Navigator.pop(context);
            AuthService.logout(context);
          },
        ),
      ],
    ),
  );
}
