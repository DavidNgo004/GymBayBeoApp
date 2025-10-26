import 'package:flutter/material.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'package:gym_bay_beo/pages/customer/pt/chat_with_pt_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyPTView extends StatelessWidget {
  final Map<String, dynamic> ptData;
  final VoidCallback onCancel;

  const MyPTView({super.key, required this.ptData, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final id = ptData['id'] as String;
    final name = ptData['name'] ?? '';
    final image = ptData['imageUrl'] ?? '';
    final desc = ptData['description'] ?? '';
    final email = ptData['email'] ?? '';
    final phone = ptData['phone'] ?? '';
    final exp = ptData['experience'] ?? '';

    return SingleChildScrollView(
      child: Column(
        children: [
          Hero(
            tag: 'pt-image-$id',
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 240,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, size: 80),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(desc),
                const SizedBox(height: 8),
                Text('Kinh nghiệm: $exp năm'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.email, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(email)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.phone, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(phone)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat với PT'),
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          final chatId = '${user.uid}_$id';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatWithPTPage(
                                ptId: id,
                                chatId: chatId,
                                ptAvatar: ptData['imageUrl'],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        label: const Text(
                          'Hủy thuê',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        onPressed: onCancel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
