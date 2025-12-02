// progress_page.dart
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:gym_bay_beo/pages/customer/test_diagram.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with TickerProviderStateMixin {
  String? uid;
  DocumentSnapshot<Map<String, dynamic>>? userDoc;
  bool loading = true;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _weightHistoryStream;

  // UI state
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];
  WeightRangeFilter _detailFilter = WeightRangeFilter.last30;

  // animation controllers
  late final AnimationController _chartFadeController;

  @override
  void initState() {
    super.initState();
    _chartFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    final user = FirebaseAuth.instance.currentUser;
    uid = user?.uid;
    if (uid != null) _subscribeUser();
    // generateFakeWeightData(); // dùng để test diagram weight
  }

  void _subscribeUser() {
    final docRef = FirebaseFirestore.instance.collection('customers').doc(uid);
    _userSub = docRef.snapshots().listen(
      (snapshot) {
        setState(() {
          userDoc = snapshot;
          loading = false;
          _weightHistoryStream = docRef
              .collection('weightHistory')
              .orderBy('createdAt', descending: false)
              .snapshots();
        });
      },
      onError: (e) {
        setState(() {
          loading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _chartFadeController.dispose();
    super.dispose();
  }

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return double.tryParse(s.replaceAll(',', '.'));
    }
    return null;
  }

  double? _heightMetersFromStored(dynamic raw) {
    final parsed = _parseDouble(raw);
    if (parsed == null) return null;
    if (parsed > 3) return parsed / 100.0;
    return parsed;
  }

  double? _computeBMI(double? weightKg, double? heightM) {
    if (weightKg == null || heightM == null || heightM <= 0) return null;
    return weightKg / (heightM * heightM);
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  // Load checkin counts for the current month. Returns null if none exist.
  Future<List<int>?> _loadCheckinCountsForMonth() async {
    if (uid == null) return null;
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final last = DateTime(now.year, now.month + 1, 0);
    final days = last.day;
    final counts = List<int>.filled(days, 0);
    try {
      final q = await FirebaseFirestore.instance
          .collection('checkins')
          .where('userId', isEqualTo: uid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(first))
          .where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(
              last.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
            ),
          )
          .get();

      if (q.docs.isEmpty) return null;

      for (final d in q.docs) {
        final map = d.data();
        final ts = map['timestamp'];
        DateTime? dt;
        if (ts is Timestamp)
          dt = ts.toDate();
        else if (map['timestamp'] is Map &&
            map['timestamp']['_seconds'] != null) {
          final seconds = map['timestamp']['_seconds'] as int;
          dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
        if (dt == null) continue;
        final dayIdx = dt.day - 1;
        if (dayIdx >= 0 && dayIdx < counts.length) counts[dayIdx] += 1;
      }
      return counts;
    } catch (_) {
      return null;
    }
  }

  // Utility: get int safely
  int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is num) return v.toInt();
    return 0;
  }

  // When year changes animate chart fade
  void _onYearChanged(int year) async {
    if (year == _selectedYear) return;
    await _chartFadeController.reverse();
    setState(() {
      _selectedYear = year;
    });
    await _chartFadeController.forward();
  }

  // Build line chart points for selected year from docs (documents must be ordered by createdAt ascending)
  Widget _buildLineChartForYear(
    List<Map<String, dynamic>> progressData,
    String label,
    String unit,
  ) {
    // Nếu không có dữ liệu
    if (progressData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Chưa có dữ liệu cho $label',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // Sắp xếp dữ liệu theo tháng tăng dần
    progressData.sort((a, b) => a['month'].compareTo(b['month']));

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label theo năm',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: progressData
                          .map(
                            (e) => FlSpot(
                              e['month'].toDouble(),
                              e['value'].toDouble(),
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: Colors.blueAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent.withOpacity(0.3),
                            Colors.blueAccent.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, barData) => true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: Colors.blueAccent,
                              strokeWidth: 0,
                              strokeColor: Colors.transparent,
                            ),
                      ),
                    ),
                  ],
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.black26),
                      bottom: BorderSide(color: Colors.black26),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          // Hiển thị tháng 1 đến 12
                          if (value >= 1 && value <= 12) {
                            return Text(
                              'T${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()} $unit',
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} $unit\nTháng ${spot.x.toInt()}',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  minX: 1,
                  maxX: 12,
                  minY:
                      progressData
                          .map((e) => e['value'].toDouble())
                          .reduce((a, b) => a < b ? a : b) -
                      2,
                  maxY:
                      progressData
                          .map((e) => e['value'].toDouble())
                          .reduce((a, b) => a > b ? a : b) +
                      2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog for adding/editing weight/height
  Future<void> _showEditHeightWeightDialog({
    required bool askHeightMeters,
    required bool askWeight,
  }) async {
    final heightRaw = userDoc?.data()?['height'];
    final weightRaw = userDoc?.data()?['weight'];

    final initialHeightMeters =
        _heightMetersFromStored(heightRaw)?.toString() ?? '';
    final initialWeight = _parseDouble(weightRaw)?.toString() ?? '';

    final heightController = TextEditingController(text: initialHeightMeters);
    final weightController = TextEditingController(text: initialWeight);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cập nhật chỉ số cơ thể'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (askHeightMeters)
                TextField(
                  controller: heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Chiều cao (m)',
                    hintText: 'Ví dụ: 1.75',
                  ),
                ),
              if (askWeight)
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cân nặng (kg)',
                    hintText: 'Ví dụ: 68.5',
                  ),
                ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel, size: 20),
                  label: const Text('Hủy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 20),
                  label: const Text('Lưu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  onPressed: () async {
                    final docRef = FirebaseFirestore.instance
                        .collection('customers')
                        .doc(uid);
                    final batch = FirebaseFirestore.instance.batch();
                    final updates = <String, dynamic>{};

                    double? newHeightMeters;
                    double? newWeightKg;

                    if (askHeightMeters) {
                      final input = heightController.text.trim();
                      if (input.isNotEmpty) {
                        final p = double.tryParse(input.replaceAll(',', '.'));
                        if (p != null && p > 0) {
                          updates['height'] = p.toString();
                          newHeightMeters = p;
                        }
                      }
                    }
                    if (askWeight) {
                      final input = weightController.text.trim();
                      if (input.isNotEmpty) {
                        final p = double.tryParse(input.replaceAll(',', '.'));
                        if (p != null && p > 0) {
                          updates['weight'] = p.toString();
                          newWeightKg = p;
                          final wRef = docRef.collection('weightHistory').doc();
                          batch.set(wRef, {
                            'weight': p,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        }
                      }
                    }

                    if (updates.isNotEmpty) batch.update(docRef, updates);

                    try {
                      if (newHeightMeters == null) {
                        final hStored =
                            updates['height'] ?? userDoc?.data()?['height'];
                        newHeightMeters = _heightMetersFromStored(hStored);
                      }
                      if (newWeightKg == null) {
                        final wStored =
                            updates['weight'] ?? userDoc?.data()?['weight'];
                        newWeightKg = _parseDouble(wStored);
                      }
                      if (newHeightMeters != null && newWeightKg != null) {
                        final bmiVal = _computeBMI(
                          newWeightKg,
                          newHeightMeters,
                        );
                        if (bmiVal != null) {
                          final bmiRef = docRef.collection('bmiHistory').doc();
                          batch.set(bmiRef, {
                            'bmi': bmiVal,
                            'weight': newWeightKg,
                            'height': newHeightMeters,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        }
                      }
                      await batch.commit();
                    } catch (e) {
                      if (updates.isNotEmpty) await docRef.update(updates);
                      if (newWeightKg != null) {
                        await docRef.collection('weightHistory').add({
                          'weight': newWeightKg,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
                    }

                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBasicInfoCard(
    double? curWeight,
    double? heightMeters,
    double? targetWeight,
    double? bmi,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cơ bản',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _rowInfo('Họ tên', userDoc?.data()?['name'] ?? '-'),
            const SizedBox(height: 8),
            _rowInfo('Email', userDoc?.data()?['email'] ?? '-'),
            const SizedBox(height: 8),
            _rowInfo('Giới tính', userDoc?.data()?['gender'] ?? '-'),
            const SizedBox(height: 8),
            _rowInfo(
              'Chiều cao (m)',
              heightMeters != null
                  ? heightMeters.toStringAsFixed(2)
                  : 'Chưa cập nhật',
            ),
            const SizedBox(height: 8),
            _rowInfo(
              'Cân nặng (kg)',
              curWeight != null
                  ? curWeight.toStringAsFixed(1)
                  : 'Chưa cập nhật',
            ),
            const SizedBox(height: 8),
            _rowInfo(
              'Mục tiêu (kg)',
              targetWeight != null
                  ? targetWeight.toStringAsFixed(1)
                  : 'Chưa cập nhật',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    onPressed: () => _showEditHeightWeightDialog(
                      askHeightMeters: true,
                      askWeight: true,
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Cập nhật chỉ số'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    onPressed: () {
                      if (bmi != null) {
                        final cat = _bmiCategory(bmi);
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Chỉ số BMI'),
                            content: Text(
                              'BMI: ${bmi.toStringAsFixed(1)}\nTrạng thái: $cat',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(c).pop(),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        _showEditHeightWeightDialog(
                          askHeightMeters: true,
                          askWeight: true,
                        );
                      }
                    },
                    icon: const Icon(Icons.monitor_heart),
                    label: Text(
                      bmi != null ? 'BMI: ${bmi.toStringAsFixed(1)}' : 'BMI: -',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionStatsCard({
    required int monthDaysCount,
    required int totalDaysCount,
  }) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final double percent = (monthDaysCount / daysInMonth).clamp(0.0, 1.0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê buổi tập trong tháng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Tổng buổi trong tháng: $monthDaysCount'),
            const SizedBox(height: 6),
            Text('Tổng buổi toàn thời gian: $totalDaysCount'),
            const SizedBox(height: 12),

            // 🔥 Animated progress bar giữ nguyên hiệu ứng và màu
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: percent),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: val,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      color: AppColors.secondary, // ✅ Giữ nguyên màu cũ
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // ✅ Hiển thị theo dạng: "12 / 31 buổi trong tháng"
                      '${monthDaysCount} / ${daysInMonth} buổi trong tháng',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Main build
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final data = userDoc?.data() ?? {};
    final curWeight = _parseDouble(data['weight']);
    final heightMeters = _heightMetersFromStored(data['height']);
    final targetWeight = _parseDouble(data['goal']);
    final bmi = _computeBMI(curWeight, heightMeters);

    final monthDaysFromDoc = (data['monthDays'] is num)
        ? (data['monthDays'] as num).toInt()
        : (data['monthDays'] is String
              ? int.tryParse(data['monthDays']) ?? 0
              : 0);
    final totalDaysFromDoc = (data['totalDays'] is num)
        ? (data['totalDays'] as num).toInt()
        : (data['totalDays'] is String
              ? int.tryParse(data['totalDays']) ?? 0
              : 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        title: const Text(
          'Tiến trình luyện tập',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => loading = true);
          await Future.delayed(const Duration(milliseconds: 300));
          if (uid != null) _subscribeUser();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Weight history stream -> top chart
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _weightHistoryStream,
                builder: (context, snapshot) {
                  // compute available years
                  final docs = snapshot.data?.docs ?? [];
                  final years = <int>{};
                  for (final d in docs) {
                    final ts = d.data()['createdAt'];
                    if (ts is Timestamp) years.add(ts.toDate().year);
                  }
                  _availableYears = years.isEmpty
                      ? [DateTime.now().year]
                      : (years.toList()..sort());
                  if (!_availableYears.contains(_selectedYear))
                    _selectedYear = _availableYears.last;

                  // start chart fade
                  if (_chartFadeController.status != AnimationStatus.forward) {
                    _chartFadeController.forward();
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: _buildLineChartForYear(
                      docs
                          .map((d) {
                            final m = d.data();
                            final createdAt = m['createdAt'];
                            DateTime? dt;
                            if (createdAt is Timestamp) {
                              dt = createdAt.toDate();
                            } else if (createdAt is Map &&
                                createdAt['_seconds'] != null) {
                              final seconds = createdAt['_seconds'] as int;
                              dt = DateTime.fromMillisecondsSinceEpoch(
                                seconds * 1000,
                              );
                            }
                            final month = dt?.month ?? 0;
                            final value = _parseDouble(m['weight']) ?? 0.0;
                            return {'month': month, 'value': value};
                          })
                          .where((e) => (e['month'] as int) > 0)
                          .toList(),
                      'Cân nặng',
                      'kg',
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Basic info card
              _buildBasicInfoCard(curWeight, heightMeters, targetWeight, bmi),

              const SizedBox(height: 14),

              // Session stats (month total + overall)
              FutureBuilder<List<int>?>(
                future: _loadCheckinCountsForMonth(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final counts = snap.data;
                  int monthCount = 0;
                  if (counts != null)
                    monthCount = counts.fold(0, (p, e) => p + e);
                  else
                    monthCount = monthDaysFromDoc;
                  return _buildSessionStatsCard(
                    monthDaysCount: monthCount,
                    totalDaysCount: totalDaysFromDoc,
                  );
                },
              ),

              const SizedBox(height: 12),

              // Detailed line chart according to detail filter
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _weightHistoryStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  final items = docs
                      .map((d) {
                        final m = d.data();
                        final ts = m['createdAt'] is Timestamp
                            ? (m['createdAt'] as Timestamp).toDate()
                            : null;
                        final w = _parseDouble(m['weight']);
                        return {'date': ts, 'weight': w};
                      })
                      .where((e) => e['date'] != null && e['weight'] != null)
                      .toList();

                  if (items.isEmpty) return const SizedBox();

                  DateTime? cutoff;
                  if (_detailFilter == WeightRangeFilter.last7)
                    cutoff = DateTime.now().subtract(const Duration(days: 7));
                  else if (_detailFilter == WeightRangeFilter.last30)
                    cutoff = DateTime.now().subtract(const Duration(days: 30));
                  final filtered = (cutoff != null)
                      ? items
                            .where(
                              (e) => (e['date'] as DateTime).isAfter(cutoff!),
                            )
                            .toList()
                      : items;

                  if (filtered.isEmpty) return const SizedBox();

                  final points = <FlSpot>[];
                  final labels = <String>[];
                  for (var i = 0; i < filtered.length; i++) {
                    final item = filtered[i];
                    final w = item['weight'] as double;
                    points.add(FlSpot(i.toDouble(), w));
                    labels.add(
                      DateFormat('dd/MM').format(item['date'] as DateTime),
                    );
                  }

                  final minY = points.map((e) => e.y).reduce(min) - 2.0;
                  final maxY = points.map((e) => e.y).reduce(max) + 2.0;

                  return SizedBox(height: 0);
                },
              ),

              const SizedBox(height: 16),

              // Recent history lists
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lịch sử cân nặng (mới nhất)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('customers')
                            .doc(uid)
                            .collection('weightHistory')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('Chưa có dữ liệu cân nặng.'),
                            );
                          }
                          return Column(
                            children: docs.take(12).map((d) {
                              final map = d.data();
                              final weight = _parseDouble(map['weight']);
                              final createdAt = map['createdAt'] is Timestamp
                                  ? (map['createdAt'] as Timestamp).toDate()
                                  : null;
                              final dateStr = createdAt != null
                                  ? DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(createdAt)
                                  : '';
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.monitor_weight_rounded,
                                ),
                                title: Text(
                                  '${weight != null ? weight.toStringAsFixed(1) : '-'} kg',
                                ),
                                subtitle: Text(dateStr),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// Small enum reused locally for filters
enum WeightRangeFilter { last7, last30, all }
