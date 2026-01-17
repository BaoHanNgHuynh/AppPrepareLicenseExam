import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bo_de_600_gplx/services/auth_service.dart';
import 'package:bo_de_600_gplx/models/question.dart';

class WrongService {
  static Future<List<Question>> fetchWrongQuestions({
    String? source, // 'random' | 'chapter' | 'critical'
    String? chapterTag, // ví dụ 'baoHieu', 'saHinh', ...
  }) async {
    final headers = await AuthService.authHeaders();

    
    final uri =
        Uri.parse('${AuthService.baseUrl}/wrong${_query(source, chapterTag)}');

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Lỗi tải câu sai: ${resp.body}');
    }

    final root = jsonDecode(resp.body);

    // Backend trả { ok: true, items: [...], page, perPage, totalItems, ... }
    final items = (root['items'] as List?) ?? [];

    // Mỗi item có expand.question_id (đã là object Question)
    final result = <Question>[];
    for (final it in items) {
      final q = it['expand']?['question_id'];
      if (q != null) result.add(Question.fromJson(q));
    }
    return result;
  }
    static Future<bool> clearWrong({
    String? source,
    String? chapterTag,
  }) async {
    // headers có token + thêm Content-Type
    final headers = {
      ...await AuthService.authHeaders(),
      'Content-Type': 'application/json',
    };

    final body = <String, dynamic>{};
    if (source != null) body['source'] = source;
    if (chapterTag != null) body['chapterTag'] = chapterTag;

    final resp = await http.post(
         Uri.parse('${AuthService.baseUrl}/wrong/clear'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
     
      throw Exception('Lỗi xoá câu sai: ${resp.body}');
    }

    final json = jsonDecode(resp.body);
    return json['ok'] == true;
  }


  static String _query(String? source, String? chapterTag) {
    if (source == null && chapterTag == null) return '';
    final params = <String>[];
    if (source != null) params.add('source=$source');
    if (chapterTag != null) params.add('chapterTag=$chapterTag');
    return '?${params.join('&')}';
  }
}
