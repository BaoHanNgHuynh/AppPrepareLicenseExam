// lib/services/practice_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bo_de_600_gplx/services/auth_service.dart';

class PracticeService {
  /// source: 'random' | 'chapter' | 'critical'
  static Future<void> recordAttempt({
    required String questionId,
    required String chapterId,  // relation ID (= chapter_tag trong PocketBase)
    required bool isCorrect,
    required String source,
  }) async {
    final uri = Uri.parse('${AuthService.baseUrl}/practice/attempt');

    final resp = await http.post(
      uri,
      headers: await AuthService.authHeaders(), // Bearer token
      body: jsonEncode({
        'questionId': questionId,
        'chapterTag': chapterId, // backend cần field này
        'isCorrect': isCorrect,
        'source': source,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('recordAttempt failed: ${resp.body}');
    }
  }
}
