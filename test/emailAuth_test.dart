import 'package:flutter_test/flutter_test.dart';

bool isValidEmail(String email) {
  final regex = RegExp(r"^[\w\-\.]+@([\w\-]+\.)+[\w]{2,4}$");
  return regex.hasMatch(email);
}

void main() {
  test("Email hợp lệ", () {
    expect(isValidEmail("test@gmail.com"), true);
  });

  test("Email không hợp lệ", () {
    expect(isValidEmail("abc@.com"), false);
  });
}
