import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/package_model.dart';

class PackagesPage extends StatelessWidget {
  const PackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Available Packages")),
      body: StreamBuilder<List<PackageModel>>(
        stream: service.getPackages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No packages found"));
          }
          return ListView(
            children: snapshot.data!
                .map(
                  (pkg) => ListTile(
                    title: Text(pkg.name),
                    subtitle: Text("${pkg.price} VND"),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
