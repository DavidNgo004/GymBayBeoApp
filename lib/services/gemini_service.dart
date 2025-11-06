import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final String apiKey = dotenv.env['GEMINI_API_KEY']!;

  Future<String> sendMessage(String prompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text ?? 'Không có phản hồi từ Gemini.';
    } else {
      final err = jsonDecode(response.body);
      final msg = err['error']?['message'] ?? 'Lỗi không xác định.';
      print('Gemini API error: $msg');
      return 'Lỗi khi kết nối với Gemini API: $msg (${response.statusCode})';
    }
  }
}
