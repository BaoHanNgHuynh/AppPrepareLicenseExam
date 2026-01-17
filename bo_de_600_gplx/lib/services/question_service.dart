import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class QuestionService {
  static const String _baseUrl = 'http://10.0.2.2:8080/api';

  /// Ôn tập theo chương (mini quiz)
  static Future<List<Question>> getPracticeByChapter(
    String chapterId, {
    int? limit,
  }) async {
    final query = <String, String>{
      'chapterId': chapterId,
    };

    if (limit != null) {
      query['limit'] = '$limit';
    }

    final uri = Uri.parse('$_baseUrl/questions').replace(
      queryParameters: query,
    );

    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Không lấy được câu hỏi ôn tập (${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body);
    final List data =
        decoded is List ? decoded : (decoded['data'] as List? ?? const []);

    return data
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy ngẫu nhiên X câu hỏi (mặc định 25)
  static Future<List<Question>> fetchRandomExam() async {
    final uri = Uri.parse('$_baseUrl/exams/random');
    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Không thể tạo đề thi ngẫu nhiên (${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body);
    final List data = decoded['questions'] as List;

    return data
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy danh sách câu hỏi "điểm liệt" (mặc định 20)
  static Future<List<Question>> fetchDiemLietQuestions({int limit = 20}) async {
    final uri = Uri.parse('$_baseUrl/questions/diem-liet?limit=$limit');
    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Không thể lấy câu hỏi điểm liệt (${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body);
    final List data =
        decoded is List ? decoded : (decoded['data'] as List? ?? const []);

    return data
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
