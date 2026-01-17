import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://10.0.2.2:8080'; // emulator Android

class ExamHistoryItem {
  final String id;
  final String examId;
  final String examName;
  final int totalQuestion;
  final int correct;
  final int diemLietWrong;
  final bool passed;
  final int time; // giây hoặc phút tùy bạn
  final DateTime created;
  final List<dynamic> questionsJson;
  final List<dynamic> selectionsJson;

  ExamHistoryItem({
    required this.id,
    required this.examId,
    required this.examName,
    required this.totalQuestion,
    required this.correct,
    required this.diemLietWrong,
    required this.passed,
    required this.time,
    required this.created,
    required this.questionsJson,
    required this.selectionsJson,
  });

  double get percent =>
      totalQuestion == 0 ? 0 : correct * 100.0 / totalQuestion;

  factory ExamHistoryItem.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v, [int def = 0]) {
      if (v == null) return def;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? def;
    }

    String _toString(dynamic v, [String def = '']) {
      if (v == null) return def;
      return v.toString();
    }

    final createdStr = json['created']?.toString();

    List<dynamic> _toList(dynamic v) {
      if (v is List) return v;
      return const [];
    }

    final questionsJson =
        _toList(json['questionsJson'] ?? json['questions_json']);
    final selectionsJson =
        _toList(json['selectionsJson'] ?? json['selections_json']);

    return ExamHistoryItem(
      id: _toString(json['id']), // nếu null -> ''
      examId: _toString(json['examId']), // nếu null -> ''
      examName: _toString(json['examName'], 'Đề thi'),
      totalQuestion: _toInt(json['totalQuestion']),
      correct: _toInt(json['correct']),
      diemLietWrong: _toInt(json['diemLietWrong']),
      passed: json['passed'] == true, // chỉ true khi đúng true
      time: _toInt(json['time']),
      created: createdStr != null
          ? DateTime.parse(createdStr)
          : DateTime.now(), // phòng trường hợp null
      questionsJson: _toList(json['questions']),
      selectionsJson: _toList(json['selections']),
    );
  }
}

class HistoryService {
  const HistoryService();

  /// gọi POST /api/exam-results để lưu 1 lần thi
  Future<bool> saveExamResult({
    required String token,
    required String examId,
    required int totalQuestion,
    required int correct,
    required int diemLietWrong,
    required bool passed,
    required int time,
    Map<String, dynamic>? chapterResult,

  }) async {
    final url = Uri.parse('$baseUrl/api/exam-results');
    final body = {
      'examId': examId,
      'totalQuestion': totalQuestion,
      'correct': correct,
      'diemLietWrong': diemLietWrong,
      'passed': passed,
      'time': time,
       if (chapterResult != null) 'chapterResult': chapterResult,
    };

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return res.statusCode >= 200 && res.statusCode < 300;
  }

  /// GET /api/exam-results – lấy lịch sử thi theo bộ đề
  Future<List<ExamHistoryItem>> fetchExamHistory({
    required String token,
    int page = 1,
    int perPage = 50,
  }) async {
    final url =
        Uri.parse('$baseUrl/api/exam-results?page=$page&perPage=$perPage');

    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Không lấy được lịch sử thi');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    print("RAW HISTORY JSON: $data");
    final itemsJson = data['items'] as List<dynamic>;
    for (final e in itemsJson) {
      print("ITEM JSON: $e");
    }
    return itemsJson
        .map((e) => ExamHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
