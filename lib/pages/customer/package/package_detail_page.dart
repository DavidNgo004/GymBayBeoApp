import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/package_model.dart';
import '../../../services/notification_service.dart';
import '../../../services/firestore_service.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import '../customer_home.dart';

class PackageDetailPage extends StatefulWidget {
  final String packageId;
  final String userId;

  const PackageDetailPage({
    Key? key,
    required this.packageId,
    required this.userId,
  }) : super(key: key);

  @override
  State<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends State<PackageDetailPage> {
  final FirestoreService _fs = FirestoreService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("Chi tiết gói tập"),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<PackageModel>(
          future: _fs.getPackageById(widget.packageId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final pkg = snapshot.data!;
            final formatter = NumberFormat.currency(
              locale: "vi_VN",
              symbol: "₫",
              decimalDigits: 0,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Icon(
                          Icons.fitness_center,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: Text(
                          pkg.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Center(
                        child: Text(
                          pkg.description,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),

                      const Divider(height: 30),

                      _buildText("Thời hạn gốc:", "${pkg.durationDays} ngày"),
                      _space(),
                      _buildText("Ưu đãi thêm:", "${pkg.bonusDays} ngày"),
                      _space(),
                      _buildText("Tổng thời hạn:", "${pkg.totalDays} ngày"),

                      const Divider(height: 30),

                      _buildText(
                        "Giá gốc:",
                        formatter.format(pkg.price),
                        lineThrough: true,
                        color: Colors.grey,
                      ),
                      _space(),
                      _buildText(
                        "Giá ưu đãi:",
                        formatter.format(pkg.effectivePrice),
                        bold: true,
                        color: AppColors.discountPackage,
                      ),

                      if (pkg.discountPercent > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Giảm ${pkg.discountPercent}%",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],

                      const SizedBox(height: 30),

                      /// Nút thanh toán
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.payment, color: Colors.white),
                          label: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Xác nhận thanh toán",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                          onPressed: _isLoading
                              ? null
                              : () => _confirmPayment(context, pkg),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildText(
    String left,
    String right, {
    bool bold = false,
    bool lineThrough = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          right,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            decoration: lineThrough ? TextDecoration.lineThrough : null,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _space() => const SizedBox(height: 8);

  /// ✅ Thanh toán offline + kích hoạt ngay trong app
  Future<void> _confirmPayment(BuildContext context, PackageModel pkg) async {
    setState(() => _isLoading = true);

    try {
      final notiService = NotificationService();

      // Lưu thanh toán thành công
      await FirebaseFirestore.instance.collection("payments").add({
        "userId": widget.userId,
        "packageId": pkg.id,
        "amount": pkg.effectivePrice,
        "status": "success",
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Kích hoạt gói
      await _fs.registerPackageForUser(userId: widget.userId, pkg: pkg);

      // Thông báo
      await notiService.sendNotification(
        userId: widget.userId,
        title: "Thanh toán thành công",
        body:
            "Gói ${pkg.title} đã được kích hoạt với thời hạn ${pkg.totalDays} ngày 🎉",
        type: "package",
        data: {"packageId": pkg.id},
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomePage()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
