import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Dùng chung baseUrl + header có Bearer token
class _HttpAuth {
  static const String baseUrl = "http://10.0.2.2:8080/api"; // đổi khi build device thật

  static Future<Map<String, String>> headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }
}


class ProgressService {
  ProgressService._();

  /// Gửi 1 lượt làm câu hỏi (tạo history + backend cache progress)
  ///
  /// [questionId]  id của câu hỏi
  /// [chapterTag]  tag chương đúng với `questions.chapter_tag`
  /// [isCorrect]   true/false
  /// [source]      (optional) "review" | "random" | "exam:<id>"
  static Future<Map<String, dynamic>> sendAttempt({
    required String questionId,
    required String chapterTag,
    required bool isCorrect,
    String? source,
  }) async {
    try {
      final h = await _HttpAuth.headers();
      final uri = Uri.parse('${_HttpAuth.baseUrl}/practice/attempt');

      final res = await http.post(
        uri,
        headers: h,
        body: jsonEncode({
          'questionId': questionId,
          'chapterTag': chapterTag,
          'isCorrect': isCorrect,
          if (source != null) 'source': source,
        }),
      );

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {
          "ok": true,
          "progress": body["progress"], // object chapter_progress hiện tại
        };
      }
      return {"ok": false, "error": body["message"] ?? body["error"] ?? "Gửi attempt thất bại"};
    } catch (e) {
      return {"ok": false, "error": "Lỗi kết nối: $e"};
    }
  }

  /// Lấy tiến trình của 1 chương
  /// Trả kèm % hoàn thành & % chính xác để UI dùng luôn
  static Future<Map<String, dynamic>> getChapterProgress(String chapterTag) async {
    try {
      final h = await _HttpAuth.headers();
      final uri = Uri.parse('${_HttpAuth.baseUrl}/progress/$chapterTag');

      final res = await http.get(uri, headers: h);
      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final attempted = (body["questions_attempted"] ?? 0) as num;
        final correct   = (body["questions_correct"] ?? 0) as num;
        final total     = (body["total_questions"] ?? 0) as num;

        final accuracy   = attempted > 0 ? (correct / attempted * 100) : 0.0;
        final completion = total > 0 ? (attempted / total * 100) : 0.0;

        return {
          "ok": true,
          "data": body,           // raw chapter_progress
          "accuracy": accuracy,   // %
          "completion": completion, // %
        };
      }
      return {"ok": false, "error": body["message"] ?? body["error"] ?? "Không lấy được tiến trình chương"};
    } catch (e) {
      return {"ok": false, "error": "Lỗi kết nối: $e"};
    }
  }

  ///Lấy tiến trình tất cả các chương để vẽ dashboard
  static Future<Map<String, dynamic>> getAllProgress() async {
    try {
      final h = await _HttpAuth.headers();
      final uri = Uri.parse('${_HttpAuth.baseUrl}/progress');

      final res = await http.get(uri, headers: h);
      final body = jsonDecode(res.body);

      if (res.statusCode == 200 && body is List) {
        // Tính thêm % cho từng item
        final items = body.map<Map<String, dynamic>>((it) {
          final attempted = (it["questions_attempted"] ?? 0) as num;
          final correct   = (it["questions_correct"] ?? 0) as num;
          final total     = (it["total_questions"] ?? 0) as num;

          final accuracy   = attempted > 0 ? (correct / attempted * 100) : 0.0;
          final completion = total > 0 ? (attempted / total * 100) : 0.0;

          return {
            ...it,
            "accuracy": accuracy,
            "completion": completion,
          };
        }).toList();

        return {"ok": true, "items": items};
      }
      return {"ok": false, "error": (body is Map) ? (body["message"] ?? body["error"]) : "Không lấy được tiến trình"};
    } catch (e) {
      return {"ok": false, "error": "Lỗi kết nối: $e"};
    }
  }
}
