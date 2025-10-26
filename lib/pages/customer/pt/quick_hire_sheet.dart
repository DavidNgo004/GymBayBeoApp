import 'package:flutter/material.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';

void showQuickHireSheet(
  BuildContext context,
  Map<String, dynamic> pt,
  Function(String pkg, String note) onConfirm,
) {
  final packages = ['1 tuần', '1 tháng', '3 tháng', '6 tháng'];
  String selected = packages[1];
  final noteCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: MediaQuery.of(ctx).viewInsets,
        child: StatefulBuilder(
          builder: (context, setStateSB) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thuê ${pt['name']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Chọn gói thuê'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: packages.map((p) {
                      final sel = p == selected;
                      return ChoiceChip(
                        label: Text(p),
                        selected: sel,
                        onSelected: (_) => setStateSB(() => selected = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Ghi chú (tùy chọn)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Yêu cầu cho PT',
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onConfirm(selected, noteCtrl.text.trim());
                    },
                    child: const Text(
                      'Xác nhận thuê',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
