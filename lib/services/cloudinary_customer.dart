import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String cloudName = 'drzg13ngi';
  static const String uploadPreset = 'DavidNgo_upload';
  static const String apiKey = '833449183238323';
  static const String apiSecret = 'mWOB_OltltkFqT6lvmlElNkXbkI';

  ///  Upload ảnh lên Cloudinary
  static Future<String?> uploadImage(String filePath) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        print(' Upload thành công: ${data['secure_url']}');
        return data['secure_url'];
      } else {
        print(' Upload thất bại: ${response.statusCode} → $body');
      }
    } catch (e) {
      print(' Lỗi upload: $e');
    }
    return null;
  }

  /// - Nếu truyền URL, sẽ tự tách public_id để xóa.
  static Future<bool> deleteImage(String imageUrlOrPublicId) async {
    try {
      String publicId = extractPublicId(imageUrlOrPublicId);
      if (publicId.isEmpty) {
        print(" Không thể lấy public_id từ URL.");
        return false;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature(publicId, timestamp);

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/destroy",
      );

      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'api_key': apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      final data = jsonDecode(response.body);
      if (data['result'] == 'ok') {
        print("Đã xóa ảnh: $publicId");
        return true;
      } else {
        print("Xóa thất bại: ${data['result']}");
        return false;
      }
    } catch (e) {
      print("⚠️ Lỗi khi xóa ảnh: $e");
      return false;
    }
  }

  /// 🧩 Hàm tạo signature (Cloudinary yêu cầu khi xóa ảnh)
  static String _generateSignature(String publicId, int timestamp) {
    final raw = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    return sha1.convert(utf8.encode(raw)).toString();
  }

  /// 📸 Tách public_id từ link Cloudinary
  static String extractPublicId(String imageUrl) {
    try {
      if (!imageUrl.contains('/upload/')) return imageUrl;
      final parts = imageUrl.split('/upload/');
      if (parts.length < 2) return '';
      final pathPart = parts[1];
      // Bỏ phần version v... và phần đuôi .jpg/.png
      final noVersion = pathPart.replaceAll(RegExp(r'v[0-9]+/'), '');
      final publicId = noVersion.split('.').first;
      return publicId;
    } catch (e) {
      print("Lỗi tách public_id: $e");
      return '';
    }
  }
}
