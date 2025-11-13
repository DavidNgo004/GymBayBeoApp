import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'package:gym_bay_beo/services/notification_service.dart';

class WorkoutSchedulePage extends StatefulWidget {
  const WorkoutSchedulePage({super.key});

  @override
  State<WorkoutSchedulePage> createState() => _WorkoutSchedulePageState();
}

class _WorkoutSchedulePageState extends State<WorkoutSchedulePage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi');
    _checkTodayWorkout(); // kiểm tra khi vào màn hình
  }

  // lưu thông báo vào Firestore
  Future<void> _checkTodayWorkout() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final query = await _firestore
        .collection('workout_schedules')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .get();

    bool hasWorkoutToday = false;

    for (var doc in query.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final scheduleDate = DateTime(date.year, date.month, date.day);
      final isNotified = data['isNotified'] ?? false;

      if (scheduleDate == today && !isNotified) {
        hasWorkoutToday = true;

        // Gửi thông báo vào Firestore
        await NotificationService().sendNotification(
          userId: _auth.currentUser!.uid,
          title: "Đến giờ tập rồi 💪",
          body:
              "Hôm nay (${date.day}/${date.month}) bạn có buổi tập đã được sắp xếp. Hãy chuẩn bị nhé!",
          type: "workout",
          data: {'scheduleId': doc.id},
        );

        // Cập nhật trạng thái đã gửi thông báo
        await doc.reference.update({'isNotified': true});
      }
    }

    if (!mounted) return;

    // Không cần show dialog nữa — thông báo sẽ hiển thị trong NotificationPage
  }

  // ==========================
  // HỘP THOẠI THÊM / CHỈNH SỬA
  // ==========================
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
                    // Header
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

                    // Nội dung danh sách bài tập
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
                                foregroundColor: AppColors.textPrimary,
                                backgroundColor: AppColors.primary,
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

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGradient,
                              foregroundColor: AppColors.divider,
                            ),
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

                              final selectedDateOnly = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                              );

                              final newData = {
                                'userId': _auth.currentUser!.uid,
                                'ptId': '',
                                'createdBy': 'customer',
                                'createdAt': FieldValue.serverTimestamp(),
                                'date': Timestamp.fromDate(selectedDateOnly),
                                'exercises': exercises,
                                'isNotified': false,
                              };

                              if (isEditing) {
                                await _firestore
                                    .collection('workout_schedules')
                                    .doc(doc!.id)
                                    .update(newData);
                              } else {
                                final existing = await _firestore
                                    .collection('workout_schedules')
                                    .where(
                                      'userId',
                                      isEqualTo: _auth.currentUser!.uid,
                                    )
                                    .get();

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
                                  await _firestore
                                      .collection('workout_schedules')
                                      .add(newData);
                                }
                              }

                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Text(
                              isEditing ? 'Cập nhật' : 'Lưu',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _getWorkoutStream() {
    return _firestore
        .collection('workout_schedules')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .snapshots();
  }

  Future<void> _deleteWorkout(String docId) async {
    await _firestore.collection('workout_schedules').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Lịch tập luyện',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            onPressed: () => _addOrEditWorkoutDialog(),
            tooltip: 'Thêm lịch tập',
          ),
        ],
      ),
      body: Column(
        children: [
          // Ảnh tiêu đề
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.network(
              'https://media2.giphy.com/media/v1.Y2lkPTZjMDliOTUyNW85cHE2ZjRrMTNiN2VmcXV1Y2JidWN2MW1rNHR6OGViZGMxYXg1diZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/pt0EKLDJmVvlS/giphy.gif',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
          ),

          // Danh sách lịch tập
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getWorkoutStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có lịch tập nào.'));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final date = (data['date'] as Timestamp).toDate();
                    final exercises = List.from(data['exercises'] ?? []);
                    final createdBy = data['createdBy'] ?? 'customer';
                    final isOwnSchedule = createdBy == 'customer';

                    return GestureDetector(
                      onTap: () => _addOrEditWorkoutDialog(doc: doc),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.boxShadow.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ngày
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'EEEE, dd/MM/yyyy',
                                      'vi',
                                    ).format(date),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Danh sách bài tập
                              ...exercises.map<Widget>((e) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "• ",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "${e['name']} (${e['sets']} hiệp x ${e['reps']} lần)\nGhi chú: ${e['notes']}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              const SizedBox(height: 12),
                              Divider(color: Colors.grey.shade300),

                              // Hành động (chỉnh sửa / xóa)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isOwnSchedule) ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blueAccent,
                                        size: 22,
                                      ),
                                      onPressed: () =>
                                          _addOrEditWorkoutDialog(doc: doc),
                                      tooltip: 'Chỉnh sửa',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                        size: 22,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Center(
                                              child: Text(
                                                'Xác nhận xóa',
                                                style: TextStyle(
                                                  color: AppColors.caution,
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
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors
                                                          .primaryGradient,
                                                      foregroundColor:
                                                          AppColors.divider,
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text('Hủy'),
                                                  ),
                                                  ElevatedButton(
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              AppColors.primary,
                                                        ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      'Xóa',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _deleteWorkout(doc.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Đã xóa lịch tập.',
                                                ),
                                                backgroundColor:
                                                    Colors.redAccent,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      tooltip: 'Xóa',
                                    ),
                                  ] else
                                    Text(
                                      "📋 Lịch tập do PT tạo",
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
