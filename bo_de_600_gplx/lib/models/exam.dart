import 'package:bo_de_600_gplx/models/question.dart';

class ExamItem {
  final String id;
  final String name;
  final int total;
  final int timeLimit;
  final String created;

  ExamItem({
    required this.id,
    required this.name,
    required this.total,
    required this.timeLimit,
    required this.created,
  });

  factory ExamItem.fromJson(Map<String, dynamic> j) => ExamItem(
        id: j['id'] as String,
        name: j['name'] as String,
        total: (j['total'] ?? 0) as int,
        timeLimit: (j['timeLimit'] ?? 1140) as int,
        created: j['created'] as String,
      );
}

class ExamDetail {
  final String id;
  final String name;
  final int timeLimit;
  final int total;
  final List<Question> questions;

  ExamDetail({
    required this.id,
    required this.name,
    required this.timeLimit,
    required this.total,
    required this.questions,
  });

  factory ExamDetail.fromJson(Map<String, dynamic> j) => ExamDetail(
        id: j['id'] as String,
        name: j['name'] as String,
        timeLimit: (j['timeLimit'] ?? 1140) as int,
        total: (j['total'] ?? 0) as int,
        questions: (j['questions'] as List? ?? const [])
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
