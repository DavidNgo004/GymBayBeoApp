import 'package:flutter/material.dart';
import '../../conf/app_colors.dart';

class PTHomePage extends StatelessWidget {
  const PTHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PT Dashboard"),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text(
          "Chào mừng Huấn luyện viên (PT)!",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
