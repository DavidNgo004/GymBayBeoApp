import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatisticsChart extends StatefulWidget {
  final CollectionReference paymentsRef;
  final NumberFormat moneyFmt;

  const AdminStatisticsChart({
    super.key,
    required this.paymentsRef,
    required this.moneyFmt,
  });

  @override
  State<AdminStatisticsChart> createState() => _AdminStatisticsChartState();
}

class _AdminStatisticsChartState extends State<AdminStatisticsChart> {
  String filterType = 'day'; // day, month
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> payments = [];
  double totalRevenue = 0;

  List<BarChartGroupData> barGroups = [];
  List<String> xLabels = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    QuerySnapshot snapshot = await widget.paymentsRef
        .where('status', isEqualTo: 'success')
        .get();

    List<Map<String, dynamic>> all = snapshot.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      data['id'] = d.id;
      return data;
    }).toList();

    DateTime start, end;
    if (filterType == 'day') {
      start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      end = start.add(const Duration(days: 1));
    } else {
      start = DateTime(selectedDate.year, selectedDate.month);
      end = DateTime(selectedDate.year, selectedDate.month + 1);
    }

    List<Map<String, dynamic>> filtered = all.where((p) {
      Timestamp createdAt = p['createdAt'];
      DateTime date = createdAt.toDate();
      return !date.isBefore(start) && date.isBefore(end);
    }).toList();

    totalRevenue = filtered.fold(
      0,
      (sum, p) => sum + (p['amount'] ?? 0).toDouble(),
    );

    _generateChartData(filtered);

    setState(() {
      payments = filtered;
    });
  }

  void _generateChartData(List<Map<String, dynamic>> data) {
    Map<int, double> groupedRevenue = {};
    xLabels.clear();

    if (filterType == 'day') {
      for (int i = 0; i < 6; i++) {
        groupedRevenue[i] = 0;
        xLabels.add('Ca ${i + 1}');
      }

      for (var p in data) {
        DateTime time = (p['createdAt'] as Timestamp).toDate();
        int shiftIndex = time.hour ~/ 4;
        groupedRevenue[shiftIndex] =
            (groupedRevenue[shiftIndex] ?? 0) + (p['amount'] ?? 0);
      }
    } else {
      for (int i = 1; i <= 4; i++) {
        groupedRevenue[i] = 0;
        xLabels.add('Tuần $i');
      }

      for (var p in data) {
        DateTime time = (p['createdAt'] as Timestamp).toDate();
        int week = ((time.day - 1) ~/ 7) + 1;
        if (week > 4) week = 4;

        groupedRevenue[week] = (groupedRevenue[week] ?? 0) + (p['amount'] ?? 0);
      }
    }

    barGroups = groupedRevenue.entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value,
            width: 14,
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    }).toList();
  }

  Future<void> _pickDate() async {
    final rootContext = Navigator.of(context).overlay!.context;

    if (filterType == 'day') {
      DateTime? picked = await showDatePicker(
        context: rootContext,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() => selectedDate = picked);
        _fetchData();
      }
    } else {
      DateTime? picked = await showMonthPicker(
        context: rootContext,
        initialDate: selectedDate,
      );
      if (picked != null) {
        setState(() => selectedDate = picked);
        _fetchData();
      }
    }
  }

  Widget _buildBarChart() {
    if (barGroups.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Text(
                    '${(value / 1000).round()}k',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = barGroups.indexWhere((g) => g.x == value.toInt());
                  if (index < 0 || index >= xLabels.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      xLabels[index],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: filterType,
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Theo ngày')),
                    DropdownMenuItem(value: 'month', child: Text('Theo tháng')),
                  ],
                  onChanged: (v) {
                    setState(() => filterType = v!);
                    _pickDate();
                  },
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    filterType == 'day'
                        ? DateFormat('dd/MM/yyyy').format(selectedDate)
                        : DateFormat('MM/yyyy').format(selectedDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tổng doanh thu: ${widget.moneyFmt.format(totalRevenue)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            _buildBarChart(),
            const Divider(height: 30),
            Text(
              'Chi tiết doanh thu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            if (payments.isEmpty)
              const Text('Không có dữ liệu')
            else
              Column(
                children: payments.map((p) {
                  final createdAt = (p['createdAt'] as Timestamp).toDate();
                  final userId = p['userId'] ?? '';
                  final packageId = p['packageId'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('customers')
                        .doc(userId)
                        .get(),
                    builder: (context, userSnap) {
                      String name = 'Không xác định';
                      String email = '';
                      String img = '';

                      if (userSnap.hasData &&
                          userSnap.data != null &&
                          userSnap.data!.exists) {
                        final userData =
                            userSnap.data!.data() as Map<String, dynamic>;
                        name = userData['name'] ?? 'Khách hàng';
                        email = userData['email'] ?? '';
                        img = userData['imageUrl'] ?? '';
                      }

                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('memberships')
                            .where('packageId', isEqualTo: packageId)
                            .limit(1)
                            .get(),
                        builder: (context, packSnap) {
                          String packageName = 'Không rõ gói';
                          if (packSnap.hasData &&
                              packSnap.data!.docs.isNotEmpty) {
                            final packData =
                                packSnap.data!.docs.first.data()
                                    as Map<String, dynamic>;
                            packageName = packData['packageName'];
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            color: Colors.deepPurple.shade50.withOpacity(0.6),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Avatar
                                  img.isNotEmpty
                                      ? CircleAvatar(
                                          radius: 25,
                                          backgroundImage: NetworkImage(img),
                                        )
                                      : const CircleAvatar(
                                          radius: 25,
                                          backgroundColor: Colors.deepPurple,
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                        ),

                                  const SizedBox(width: 14),

                                  // Thông tin
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          packageName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$name\n${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Giá tiền
                                  Text(
                                    widget.moneyFmt.format(p['amount'] ?? 0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                      fontSize: 15,
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
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
