import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';

class PTStudentSchedulePage extends StatefulWidget {
  final String customerId;
  final String customerName;

  const PTStudentSchedulePage({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<PTStudentSchedulePage> createState() => _PTStudentSchedulePageState();
}

class _PTStudentSchedulePageState extends State<PTStudentSchedulePage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ===========================
  // THÊM / CHỈNH SỬA LỊCH TẬP
  // ===========================
  Future<void> _addOrEditWorkoutDialog({DocumentSnapshot? doc}) async {
    final isEditing = doc != null;
    final data = doc?.data() as Map<String, dynamic>? ?? {};

    DateTime selectedDate = (data['date'] != null)
        ? (data['date'] as Timestamp).toDate()
        : DateTime.now();

    List<Map<String, String>> exercises = [];
    if (data['exercises'] != null) {
      for (var e in data['exercises']) {
        exercises.add({
          'name': e['name'] ?? '',
          'sets': e['sets'] ?? '',
          'reps': e['reps'] ?? '',
          'notes': e['notes'] ?? '',
        });
      }
    }
    if (exercises.isEmpty) {
      exercises.add({'name': '', 'sets': '', 'reps': '', 'notes': ''});
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    // ======================
                    // HEADER (cố định)
                    // ======================
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            isEditing
                                ? 'Chỉnh sửa lịch tập'
                                : 'Tạo lịch tập mới',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat(
                                    'EEEE, dd/MM/yyyy',
                                    'vi',
                                  ).format(selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => selectedDate = picked);
                                  }
                                },
                                child: const Text('Chọn ngày'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ======================
                    // NỘI DUNG CUỘN
                    // ======================
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            ...List.generate(exercises.length, (index) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        initialValue: exercises[index]['name'],
                                        decoration: const InputDecoration(
                                          labelText: 'Tên bài tập',
                                        ),
                                        onChanged: (v) =>
                                            exercises[index]['name'] = v,
                                      ),
                                      TextFormField(
                                        initialValue: exercises[index]['sets'],
                                        decoration: const InputDecoration(
                                          labelText: 'Số hiệp (sets)',
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) =>
                                            exercises[index]['sets'] = v,
                                      ),
                                      TextFormField(
                                        initialValue: exercises[index]['reps'],
                                        decoration: const InputDecoration(
                                          labelText: 'Số lần (reps)',
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) =>
                                            exercises[index]['reps'] = v,
                                      ),
                                      TextFormField(
                                        initialValue: exercises[index]['notes'],
                                        decoration: const InputDecoration(
                                          labelText: 'Ghi chú',
                                        ),
                                        onChanged: (v) =>
                                            exercises[index]['notes'] = v,
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            setDialogState(() {
                                              exercises.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textPrimary,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  exercises.add({
                                    'name': '',
                                    'sets': '',
                                    'reps': '',
                                    'notes': '',
                                  });
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm bài tập'),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),

                    // ======================
                    // FOOTER CỐ ĐỊNH
                    // ======================
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textPrimary,
                            ),
                            onPressed: () async {
                              if (exercises.isEmpty ||
                                  exercises.first['name']!.trim().isEmpty) {
                                return;
                              }

                              // Lấy ngày chỉ tính đến ngày (bỏ giờ)
                              final selectedDateOnly = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                              );

                              // Tạo dữ liệu mới
                              final newData = {
                                'userId': widget.customerId,
                                'ptId': _auth.currentUser!.uid,
                                'createdBy': 'pt',
                                'createdAt': FieldValue.serverTimestamp(),
                                'date': Timestamp.fromDate(selectedDateOnly),
                                'exercises': exercises,
                              };

                              if (isEditing) {
                                // Nếu đang chỉnh sửa -> cập nhật luôn
                                await _firestore
                                    .collection('workout_schedules')
                                    .doc(doc!.id)
                                    .update(newData);
                              } else {
                                // Kiểm tra xem đã có lịch cùng ngày (với cùng userId + ptId) chưa
                                final existing = await _firestore
                                    .collection('workout_schedules')
                                    .where(
                                      'userId',
                                      isEqualTo: widget.customerId,
                                    )
                                    .where(
                                      'ptId',
                                      isEqualTo: _auth.currentUser!.uid,
                                    )
                                    .get();

                                // Tìm document có cùng ngày (so sánh ngày/tháng/năm)
                                DocumentSnapshot<Map<String, dynamic>>?
                                sameDayDoc;
                                for (var d in existing.docs) {
                                  final existingDate =
                                      (d.data()['date'] as Timestamp).toDate();
                                  if (existingDate.year ==
                                          selectedDateOnly.year &&
                                      existingDate.month ==
                                          selectedDateOnly.month &&
                                      existingDate.day ==
                                          selectedDateOnly.day) {
                                    sameDayDoc = d;
                                    break;
                                  }
                                }

                                if (sameDayDoc != null) {
                                  // Nếu đã có lịch cùng ngày -> gộp bài tập
                                  final existingExercises =
                                      List<Map<String, dynamic>>.from(
                                        sameDayDoc.data()?['exercises'] ?? [],
                                      );
                                  existingExercises.addAll(exercises);

                                  await _firestore
                                      .collection('workout_schedules')
                                      .doc(sameDayDoc.id)
                                      .update({'exercises': existingExercises});
                                } else {
                                  // Nếu chưa có -> tạo mới
                                  await _firestore
                                      .collection('workout_schedules')
                                      .add(newData);
                                }
                              }

                              if (context.mounted) Navigator.pop(context);
                            },

                            child: Text(isEditing ? 'Cập nhật' : 'Lưu'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================
  // STREAM LẤY LỊCH CỦA HV & PT NÀY
  // ==========================
  Stream<QuerySnapshot<Map<String, dynamic>>> _getScheduleStream() {
    return _firestore
        .collection('workout_schedules')
        .where('userId', isEqualTo: widget.customerId)
        .where('ptId', isEqualTo: _auth.currentUser!.uid)
        .snapshots();
  }

  // ==========================
  // HÀM XÓA LỊCH
  // ==========================
  Future<void> _deleteSchedule(String id) async {
    await _firestore.collection('workout_schedules').doc(id).delete();
  }

  // ==========================
  // GIAO DIỆN CHÍNH
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 24),
            const SizedBox(width: 10),
            Text(
              'Lịch tập - ${widget.customerName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _addOrEditWorkoutDialog(),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getScheduleStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có lịch tập nào.'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final exercises = List.from(data['exercises'] ?? []);
              final date = (data['date'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: exercises.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "• ${e['name']} (${e['sets']} sets x ${e['reps']} reps)\n  Ghi chú: ${e['notes']}",
                        ),
                      );
                    }).toList(),
                  ),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _addOrEditWorkoutDialog(doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Center(
                                child: Text(
                                  'Xác nhận xóa',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              content: const Text(
                                'Bạn có chắc chắn muốn xóa lịch tập này không?',
                                style: TextStyle(fontSize: 15),
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade300,
                                        foregroundColor: Colors.black,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Hủy'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Xóa',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _deleteSchedule(doc.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã xóa lịch tập.'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
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
