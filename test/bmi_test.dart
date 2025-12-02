import 'package:flutter_test/flutter_test.dart';

double calculateBMI(double weight, double heightCm) {
  final heightM = heightCm / 100;
  return double.parse((weight / (heightM * heightM)).toStringAsFixed(2));
}

void main() {
  test("Tính BMI đúng với dữ liệu đầu vào", () {
    final bmi = calculateBMI(70, 170);
    expect(bmi, 24.22);
  });
}
