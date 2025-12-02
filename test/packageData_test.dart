import 'package:flutter_test/flutter_test.dart';

class PackageService {
  Future<List<String>> getPackages() async {
    return ["Gói 1 tháng", "Gói 3 tháng"];
  }
}

class FakePackageService extends PackageService {
  @override
  Future<List<String>> getPackages() async {
    return ["Gói 1 tháng", "Gói 3 tháng", "Gói 12 tháng"];
  }
}

void main() {
  test("Lấy danh sách gói tập", () async {
    final service = FakePackageService();

    final result = await service.getPackages();

    expect(result.length, 3);
    expect(result.contains("Gói 12 tháng"), true);
  });
}
