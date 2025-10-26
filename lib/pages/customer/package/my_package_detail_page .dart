// lib/pages/customer/package_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/package_model.dart';
import '../../../services/firestore_service.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';

class MyPackageDetailPage extends StatefulWidget {
  final String packageId;
  final String userId;

  const MyPackageDetailPage({
    Key? key,
    required this.packageId,
    required this.userId,
  }) : super(key: key);

  @override
  State<MyPackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends State<MyPackageDetailPage> {
  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Gói tập của tôi"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: FutureBuilder<PackageModel>(
        future: _fs.getPackageById(widget.packageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text("Không tìm thấy thông tin gói tập."),
            );
          }

          final pkg = snapshot.data!;
          final formatter = NumberFormat.currency(
            locale: "vi_VN",
            symbol: "₫",
            decimalDigits: 0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Ảnh đầu trang
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    "https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExbG96MmM2cGJ0d2poeXY2bDN3aWRjd3kwM295NW5wMTlveDU4ZTR1ZSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0HlAIjBrMwsha2UE/giphy.gif",
                    height: 305,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),

                // Card thông tin
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 6,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryGradient!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              pkg.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBtn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              pkg.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textBtn,
                              ),
                            ),
                          ),
                          const Divider(height: 30, color: AppColors.divider),

                          _buildInfoRow(
                            "Thời hạn gốc:",
                            "${pkg.durationDays} ngày",
                          ),
                          _buildInfoRow(
                            "Ưu đãi tặng thêm:",
                            "${pkg.bonusDays} ngày",
                          ),
                          _buildInfoRow("Tổng cộng:", "${pkg.totalDays} ngày"),

                          const Divider(height: 30, color: AppColors.divider),

                          _buildInfoRow(
                            "Giá gốc:",
                            formatter.format(pkg.price),
                            valueStyle: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.caution,
                              color: AppColors.caution,
                            ),
                          ),
                          _buildInfoRow(
                            "Giá sau ưu đãi:",
                            formatter.format(pkg.effectivePrice),
                            valueStyle: const TextStyle(
                              fontSize: 18,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (pkg.discountPercent > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Giảm ${pkg.discountPercent}%",
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Hàm build hàng thông tin
  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textBtn,
            ),
          ),
          Text(
            value,
            style: valueStyle ?? const TextStyle(color: AppColors.textBtn),
          ),
        ],
      ),
    );
  }
}
