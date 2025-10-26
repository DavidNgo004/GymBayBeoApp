import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CheckinHistoryPage extends StatelessWidget {
  const CheckinHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Lịch sử Check-in")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('checkin_history')
            .where('userId', isEqualTo: userId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Chưa có lịch sử check-in"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data();
              final date = (data['date'] as Timestamp).toDate();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(
                    "Check-in ngày ${date.day}/${date.month}/${date.year}",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
