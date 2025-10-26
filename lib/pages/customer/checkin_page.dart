import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gym_bay_beo/pages/customer/checkin_history_page.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  String? qrData;
  String? name;
  String? imageUrl;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerQR();
  }

  Future<void> _loadCustomerQR() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid);
    final doc = await ref.get();

    if (doc.exists) {
      // ✅ Nếu chưa có QR → tạo luôn
      qrData = doc['qrCode'] ?? user.uid;

      if (!doc.data()!.containsKey('qrCode')) {
        await ref.update({'qrCode': qrData});
      }

      setState(() {
        name = doc['name'] ?? "Khách hàng";
        imageUrl = doc['imageUrl'];
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Check-in"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imageUrl != null)
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: NetworkImage(imageUrl!),
                    ),
                  const SizedBox(height: 12),

                  Text(
                    name ?? "Khách hàng",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ✅ QR Code UID khách hàng
                  QrImageView(
                    data: qrData ?? "unknown",
                    size: 220,
                    version: QrVersions.auto,
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    "Đưa mã này cho lễ tân để Check-in",
                    style: TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 28),

                  /// ✅ Nút chuyển sang lịch sử check-in
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.history),
                    label: const Text(
                      "Lịch sử Check-in",
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckinHistoryPage(),
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
