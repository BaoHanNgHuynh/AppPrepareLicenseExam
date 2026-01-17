import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';

class TtsService {
  /// Gửi text lên API /tts, trả về audio bytes (WAV)
  ///
  static final http.Client _client = http.Client();
  static Future<Uint8List?> synthesize(String text) async {
    if (text.trim().isEmpty) return null;

    final url = Uri.parse(AppConfig.ttsUrl);

    try {
      final res = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"text": text}),
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) {
        print("TTS error status: ${res.statusCode} - ${res.body}");
        return null;
      }
      // ✅ WAV bytes trực tiếp
      return res.bodyBytes;
    } catch (e) {
      print("TTS exception: $e");
      return null;
    }
  }
}
