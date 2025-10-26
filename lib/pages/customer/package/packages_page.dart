// lib/pages/customer/packages_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/package_model.dart';
import '../../../models/membership_model.dart';
import '../../../services/firestore_service.dart';
import 'package_detail_page.dart';
import 'package:gym_bay_beo/pages/customer/package/my_package_detail_page%20.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';

class PackagesPage extends StatelessWidget {
  final String userId;
  const PackagesPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Gói tập',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- Active membership ---
          StreamBuilder<UserMembership?>(
            stream: fs.userActiveMembershipStream(userId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _buildActiveCardLoading();
              }
              final membership = snap.data;
              if (membership == null) {
                return _buildNoActiveCard(context);
              }
              return FutureBuilder<PackageModel>(
                future: fs.getPackageById(membership.packageId),
                builder: (c, snapPkg) {
                  if (!snapPkg.hasData) return _buildActiveCardLoading();
                  final pkg = snapPkg.data!;
                  return _buildActiveCard(context, pkg, membership);
                },
              );
            },
          ),
          const SizedBox(height: 12),
          // --- List all packages ---
          Expanded(
            child: StreamBuilder<List<PackageModel>>(
              stream: fs.packagesStream(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty)
                  return const Center(child: Text('Chưa có gói tập nào.'));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final pkg = list[index];
                    return _buildPackageCard(context, pkg);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCardLoading() => Padding(
    padding: const EdgeInsets.all(12.0),
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
  );

  Widget _buildNoActiveCard(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12.0),
    child: Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12), // Đặt độ bo góc ở đây
              child: Image.network(
                "https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExYmZ4aHhhY2RpbWx4eXk3NndhNGtidDBlZDljenJhdWZxdzdhYXExdCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/26ufmxqYx0DYcWhzi/giphy.gif",
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'Bạn chưa có gói tập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Chọn gói phù hợp và bắt đầu luyện tập ngay!',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildActiveCard(
    BuildContext context,
    PackageModel pkg,
    UserMembership membership,
  ) {
    final remaining = membership.remainingDays;
    final f = DateFormat('dd/MM/yyyy');
    final endStr = f.format(membership.endDate);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      child: Card(
        color: AppColors.cardbgCurrent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text(
                  '$remaining',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Còn $remaining ngày - Hết hạn: $endStr',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.caution,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gói: ${pkg.durationDays} ngày + tặng ${pkg.bonusDays} ngày',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.discountPackage,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyPackageDetailPage(
                        packageId: pkg.id,
                        userId: membership.userId,
                      ),
                    ),
                  );
                },
                child: const Text('Chi tiết'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, PackageModel pkg) {
    return Card(
      color: AppColors.cardbg,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PackageDetailPage(packageId: pkg.id, userId: userId),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // left badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '${pkg.totalDays}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('ngày', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // middle info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pkg.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // right: price + button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${NumberFormat.currency(locale: "vi_VN", symbol: "₫").format(pkg.effectivePrice)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (pkg.discountPercent > 0)
                    Text(
                      '${pkg.discountPercent}% OFF',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PackageDetailPage(
                            packageId: pkg.id,
                            userId: userId,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Đăng ký',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
