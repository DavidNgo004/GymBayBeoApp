// lib/pages/admin/packages_admin_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/package_model.dart';
import '../../../services/firestore_service.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';

class PackagesAdminPage extends StatefulWidget {
  const PackagesAdminPage({Key? key}) : super(key: key);

  @override
  State<PackagesAdminPage> createState() => _PackagesAdminPageState();
}

class _PackagesAdminPageState extends State<PackagesAdminPage> {
  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý gói tập'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openPackageForm(context),
          ),
        ],
      ),
      body: StreamBuilder<List<PackageModel>>(
        stream: _fs.packagesStream(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('Chưa có gói tập nào.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final pkg = list[index];
              return _packageCard(pkg);
            },
          );
        },
      ),
    );
  }

  Widget _packageCard(PackageModel pkg) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          pkg.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(pkg.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              'Thời gian: ${pkg.durationDays} ngày + tặng ${pkg.bonusDays} ngày',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Giá: ${NumberFormat.currency(locale: "vi_VN", symbol: "₫").format(pkg.effectivePrice)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (pkg.discountPercent > 0)
              Text(
                'Ưu đãi: giảm ${pkg.discountPercent}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.discountPackage,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _openPackageForm(context, pkg: pkg),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                try {
                  await _fs.deletePackage(pkg.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Xóa gói thành công!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không thể xóa: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Form thêm/chỉnh sửa gói
  Future<void> _openPackageForm(
    BuildContext context, {
    PackageModel? pkg,
  }) async {
    final _title = TextEditingController(text: pkg?.title ?? '');
    final _description = TextEditingController(text: pkg?.description ?? '');
    final _price = TextEditingController(text: pkg?.price.toString() ?? '');
    final _duration = TextEditingController(
      text: pkg?.durationDays.toString() ?? '',
    );
    final _bonus = TextEditingController(text: pkg?.bonusDays.toString() ?? '');
    final _discount = TextEditingController(
      text: pkg?.discountPercent.toString() ?? '',
    );
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(pkg == null ? 'Thêm gói tập' : 'Chỉnh sửa gói tập'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Tên gói'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nhập tên gói' : null,
                ),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nhập mô tả' : null,
                ),
                TextFormField(
                  controller: _duration,
                  decoration: const InputDecoration(
                    labelText: 'Số ngày cơ bản',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null
                      ? 'Nhập số ngày hợp lệ'
                      : null,
                ),
                TextFormField(
                  controller: _bonus,
                  decoration: const InputDecoration(labelText: 'Số ngày bonus'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null
                      ? 'Nhập số ngày hợp lệ'
                      : null,
                ),
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null
                      ? 'Nhập giá hợp lệ'
                      : null,
                ),
                TextFormField(
                  controller: _discount,
                  decoration: const InputDecoration(labelText: 'Giảm giá (%)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null
                      ? 'Nhập số hợp lệ'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final newPkg = PackageModel(
                id: pkg?.id ?? '',
                title: _title.text,
                description: _description.text,
                durationDays: int.parse(_duration.text),
                bonusDays: int.parse(_bonus.text),
                price: int.parse(_price.text),
                discountPercent: int.parse(_discount.text),
              );
              try {
                if (pkg == null) {
                  await _fs.addPackage(newPkg);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm gói thành công!')),
                  );
                } else {
                  await _fs.updatePackage(newPkg);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật gói thành công!')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
