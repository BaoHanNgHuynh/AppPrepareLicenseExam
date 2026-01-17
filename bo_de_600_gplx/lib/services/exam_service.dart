import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exam.dart';

class ExamService { static const String _baseUrl = 'http://10.0.2.2:8080/api';
 

  /// Tạo & lưu đề (server sẽ generate theo cơ cấu 8-1-1-1-8-6)
  static Future<String> createExam({
    String name = 'Đề mới',
    int timeLimit = 1140,
    int? seed,
  }) async {
    final uri = Uri.parse('$_baseUrl/exams');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'timeLimit': timeLimit,
        if (seed != null) 'seed': seed,
      }),
    );
    if (resp.statusCode != 201) {
      throw Exception('Tạo đề thất bại (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['id'] as String;
  }

  /// Danh sách đề (cho Exam List)
  static Future<List<ExamItem>> fetchExams() async {
    final uri = Uri.parse('$_baseUrl/exams');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Không lấy được danh sách đề (${resp.statusCode})');
    }
    final decoded = jsonDecode(resp.body);
    final List list =
        decoded is List ? decoded : (decoded['data'] as List? ?? const []);
    return list.map((e) => ExamItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Chi tiết 1 đề (full=1 trả về đủ 25 câu theo đúng thứ tự)
  static Future<ExamDetail> fetchExamDetail(String id) async {
    final uri = Uri.parse('$_baseUrl/exams/$id?full=1');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Không lấy được chi tiết đề (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return ExamDetail.fromJson(data);
  }
}
