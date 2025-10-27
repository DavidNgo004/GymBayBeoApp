import 'package:flutter/material.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'package:gym_bay_beo/pages/pt/chat/pt_chat_page.dart';
import 'package:gym_bay_beo/pages/pt/students/pt_student_schedule_page.dart';
import 'student_info_row.dart';

class StudentDetailPage extends StatelessWidget {
  final Map<String, dynamic> customer;
  final Map<String, dynamic> hire;

  const StudentDetailPage({
    super.key,
    required this.customer,
    required this.hire,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(customer['name'] ?? "Học viên"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                customer['imageUrl'] ??
                    'https://cdn-icons-png.flaticon.com/512/149/149071.png',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              customer['name'] ?? "",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              customer['email'] ?? "",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            StudentInfoRow(
              label: "Chiều cao",
              value: "${customer['height']} cm",
            ),
            StudentInfoRow(
              label: "Cân nặng",
              value: "${customer['weight']} kg",
            ),
            StudentInfoRow(label: "Mục tiêu", value: "${customer['goal']} kg"),
            StudentInfoRow(label: "Gói tập", value: hire['package']),
            StudentInfoRow(label: "Trạng thái", value: hire['status']),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 12,
                ),
              ),
              icon: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.textPrimary,
              ),
              label: const Text(
                "Tạo lịch tập cho học viên",
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PTStudentSchedulePage(
                      customerId: hire['customerId'],
                      customerName: customer['name'],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              icon: const Icon(Icons.chat_outlined),
              label: const Text("Nhắn tin với học viên"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PTChatPage(
                      chatId: hire['chatId'],
                      customerId: hire['customerId'],
                      customerName: customer['name'],
                      customerAvatar: customer['imageUrl'],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
