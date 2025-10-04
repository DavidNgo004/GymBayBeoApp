import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/package_model.dart';

class ManagePackagesPage extends StatelessWidget {
  const ManagePackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Packages")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Package Name"),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pkg = PackageModel(
                      id: '',
                      name: nameController.text,
                      price: double.tryParse(priceController.text) ?? 0,
                    );
                    await service.addPackage(pkg);
                    nameController.clear();
                    priceController.clear();
                  },
                  child: const Text("Add Package"),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PackageModel>>(
              stream: service.getPackages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final packages = snapshot.data!;
                return ListView.builder(
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final pkg = packages[index];
                    return ListTile(
                      title: Text(pkg.name),
                      subtitle: Text("${pkg.price} VND"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => service.deletePackage(pkg.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
