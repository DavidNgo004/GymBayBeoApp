import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:gym_bay_beo/conf/app_colors.dart';
import 'admin_statistics_chart.dart';

class StatisticsPage extends StatelessWidget {
  final CollectionReference membershipsRef = FirebaseFirestore.instance
      .collection('memberships');
  final NumberFormat moneyFmt = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Thống kê'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminStatisticsChart(
              membershipsRef: membershipsRef,
              moneyFmt: moneyFmt,
            ),
          ],
        ),
      ),
    );
  }
}
