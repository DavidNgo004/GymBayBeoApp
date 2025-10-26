import 'package:flutter/material.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'quick_hire_sheet.dart';
import 'package:gym_bay_beo/pages/customer/pt/hire_pt_page.dart';

class PTCard extends StatelessWidget {
  final Map<String, dynamic> pt;
  final Function(String pkg, String note) onQuickHire;

  const PTCard({super.key, required this.pt, required this.onQuickHire});

  @override
  Widget build(BuildContext context) {
    final id = pt['id'] as String;
    final name = pt['name'] ?? '';
    final image = pt['imageUrl'] ?? '';
    final exp = pt['experience'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HirePTPage(ptId: id, onHired: (_) {}),
          ),
        ),
        child: SizedBox(
          height: 140,
          child: Row(
            children: [
              Hero(
                tag: 'pt-image-$id',
                child: image.isNotEmpty
                    ? Image.network(image, width: 140, fit: BoxFit.cover)
                    : Container(
                        width: 140,
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, size: 60),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kinh nghiệm: $exp năm',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    HirePTPage(ptId: id, onHired: (_) {}),
                              ),
                            ),
                            child: const Text('Chi tiết'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            onPressed: () =>
                                showQuickHireSheet(context, pt, onQuickHire),
                            child: const Text(
                              'Thuê ngay',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
