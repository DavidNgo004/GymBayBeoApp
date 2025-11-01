import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatisticsChart extends StatefulWidget {
  final CollectionReference membershipsRef;
  final NumberFormat moneyFmt;

  const AdminStatisticsChart({
    super.key,
    required this.membershipsRef,
    required this.moneyFmt,
  });

  @override
  State<AdminStatisticsChart> createState() => _AdminStatisticsChartState();
}

class _AdminStatisticsChartState extends State<AdminStatisticsChart> {
  String filterType = 'day'; // day, month, year
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> memberships = [];
  double totalRevenue = 0;
  List<BarChartGroupData> barGroups = [];
  List<String> xLabels = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    QuerySnapshot snapshot = await widget.membershipsRef.get();
    List<Map<String, dynamic>> all = snapshot.docs.map((d) {
      var data = d.data() as Map<String, dynamic>;
      data['id'] = d.id;
      return data;
    }).toList();

    DateTime start, end;
    if (filterType == 'day') {
      start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      end = start.add(const Duration(days: 1));
    } else if (filterType == 'month') {
      start = DateTime(selectedDate.year, selectedDate.month);
      end = DateTime(selectedDate.year, selectedDate.month + 1);
    } else {
      start = DateTime(selectedDate.year, 1, 1);
      end = DateTime(selectedDate.year + 1, 1, 1);
    }

    List<Map<String, dynamic>> filtered = all.where((m) {
      Timestamp createdAt = m['createdAt'];
      DateTime date = createdAt.toDate();
      // Bao gồm cả ngày bắt đầu
      return !date.isBefore(start) && date.isBefore(end);
    }).toList();

    totalRevenue = filtered.fold(
      0,
      (sum, m) => sum + (m['pricePaid'] ?? 0).toDouble(),
    );

    _generateChartData(filtered);
    setState(() {
      memberships = filtered;
    });
  }

  void _generateChartData(List<Map<String, dynamic>> data) {
    Map<int, double> groupedRevenue = {};
    xLabels.clear();

    if (filterType == 'day') {
      // Theo từng ca 4 tiếng
      for (int i = 0; i < 6; i++) {
        groupedRevenue[i] = 0;
        xLabels.add('Ca ${i + 1}');
      }
      for (var m in data) {
        DateTime time = (m['createdAt'] as Timestamp).toDate();
        int shiftIndex = time.hour ~/ 4;
        groupedRevenue[shiftIndex] =
            (groupedRevenue[shiftIndex] ?? 0) + (m['pricePaid'] ?? 0);
      }
    } else if (filterType == 'month') {
      // Theo 4 tuần
      for (int i = 1; i <= 4; i++) {
        groupedRevenue[i] = 0;
        xLabels.add('Tuần $i');
      }
      for (var m in data) {
        DateTime time = (m['createdAt'] as Timestamp).toDate();
        int week = ((time.day - 1) ~/ 7) + 1;
        if (week > 4) week = 4;
        groupedRevenue[week] =
            (groupedRevenue[week] ?? 0) + (m['pricePaid'] ?? 0);
      }
    } else {
      // Theo 4 quý trong năm
      for (int q = 1; q <= 4; q++) {
        groupedRevenue[q] = 0;
        xLabels.add('Q$q');
      }

      for (var item in data) {
        DateTime time = (item['createdAt'] as Timestamp).toDate();
        int quarter = ((time.month - 1) ~/ 3) + 1;
        groupedRevenue[quarter] =
            (groupedRevenue[quarter] ?? 0) + (item['pricePaid'] ?? 0);
      }
    }

    barGroups = groupedRevenue.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
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
    // Lấy root context để hiển thị dialog không bị mờ đen
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
    } else if (filterType == 'month') {
      DateTime? picked = await showMonthPicker(
        context: rootContext,
        initialDate: selectedDate,
      );
      if (picked != null) {
        setState(() => selectedDate = picked);
        _fetchData();
      }
    } else {
      // ✅ FIX chọn năm – hoạt động trên mọi context
      int selectedYear = selectedDate.year;
      int? pickedYear = await showDialog<int>(
        context: rootContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Chọn năm"),
            content: SizedBox(
              height: 250,
              child: YearPicker(
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                selectedDate: DateTime(selectedYear),
                onChanged: (DateTime dateTime) {
                  selectedYear = dateTime.year;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, selectedYear),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );

      if (pickedYear != null) {
        setState(() => selectedDate = DateTime(pickedYear, 1, 1));
        _fetchData();
      }
    }
  }

  Widget _buildBarChart() {
    if (barGroups.isEmpty) {
      return const Center(child: Text("Không có dữ liệu"));
    }

    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          gridData: FlGridData(show: true, drawHorizontalLine: true),
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
                  int index = barGroups.indexWhere((g) => g.x == value);
                  if (index == -1 || index >= xLabels.length) {
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
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bộ lọc
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: filterType,
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Theo ngày')),
                    DropdownMenuItem(value: 'month', child: Text('Theo tháng')),
                    DropdownMenuItem(value: 'year', child: Text('Theo năm')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      filterType = value!;
                    });
                    _pickDate();
                  },
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    filterType == 'day'
                        ? DateFormat('dd/MM/yyyy').format(selectedDate)
                        : filterType == 'month'
                        ? DateFormat('MM/yyyy').format(selectedDate)
                        : DateFormat('yyyy').format(selectedDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tổng doanh thu: ${widget.moneyFmt.format(totalRevenue)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            _buildBarChart(),
            const SizedBox(height: 16),

            //chú thích cho trục X
            if (filterType == 'day')
              const Text(
                'Chú thích: Ca 1 (0–4h), Ca 2 (4–8h), Ca 3 (8–12h), Ca 4 (12–16h), Ca 5 (16–20h), Ca 6 (20–24h)',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              )
            else if (filterType == 'month')
              const Text(
                'Chú thích: Tuần 1–4 tương ứng 4 tuần trong tháng',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              )
            else
              const Text(
                'Chú thích: Q1 (Tháng 1–3), Q2 (Tháng 4–6), Q3 (Tháng 7–9), Q4 (Tháng 10–12)',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),

            const Divider(height: 30),

            const Divider(height: 30),
            Text(
              'Danh sách gói tập',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (memberships.isEmpty)
              const Text('Không có dữ liệu cho thời gian này.')
            else
              Column(
                children: memberships.map((m) {
                  final createdAt = (m['createdAt'] as Timestamp).toDate();
                  return ListTile(
                    leading: const Icon(
                      Icons.fitness_center,
                      color: Colors.deepPurple,
                    ),
                    title: Text(m['packageName'] ?? ''),
                    subtitle: Text(
                      'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                    ),
                    trailing: Text(
                      widget.moneyFmt.format(m['pricePaid'] ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
