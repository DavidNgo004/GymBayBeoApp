import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Cloudinary Service — hỗ trợ upload và xóa ảnh.
///
/// ⚠️ Không nên public API secret khi release app.
/// Dùng tạm trong môi trường dev/offline.
class CloudinaryService {
  static const String _cloudName = "drzg13ngi";
  static const String _apiKey = "125755137594278";
  static const String _apiSecret = "mWOB_OltltkFqT6lvmlElNkXbkI";
  static const String _uploadPreset = "DavidNgo_upload";

  /// 🟢 Upload ảnh lên Cloudinary
  /// Trả về [secure_url] của ảnh
  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      final resData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(resData.body);
        return data["secure_url"]; // ✅ Trả về URL ảnh
      } else {
        print("❌ Upload thất bại: ${resData.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Lỗi khi upload ảnh: $e");
      return null;
    }
  }

  /// 🔴 Xóa ảnh theo URL (hoặc public_id)
  ///
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
        "https://api.cloudinary.com/v1_1/$_cloudName/image/destroy",
      );

      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      final data = jsonDecode(response.body);
      if (data['result'] == 'ok') {
        print("✅ Đã xóa ảnh: $publicId");
        return true;
      } else {
        print("❌ Xóa thất bại: ${data['result']}");
        return false;
      }
    } catch (e) {
      print("⚠️ Lỗi khi xóa ảnh: $e");
      return false;
    }
  }

  /// 🧩 Hàm tạo signature (Cloudinary yêu cầu khi xóa ảnh)
  static String _generateSignature(String publicId, int timestamp) {
    final raw = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
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
      print("⚠️ Lỗi tách public_id: $e");
      return '';
    }
  }

  // ✅ THÊM NHẸ: hàm helper check ảnh có tồn tại không
  static Future<bool> checkImageExists(String imageUrl) async {
    try {
      final response = await http.head(Uri.parse(imageUrl));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
