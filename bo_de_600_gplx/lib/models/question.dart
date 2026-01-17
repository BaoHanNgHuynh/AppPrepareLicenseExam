class Question {
  final String id;
  final int? indexNumber;
  final String questionText;
  final List<String> answers;
  final int correctAnswerIndex;
  final bool isDiemLiet;
  final String? imageUrl; // link ảnh từ backend
  final String? explain; // giải thích
  final String? chapterTag;
  final String? chapterTitle;

  Question({
    required this.id,
    required this.indexNumber,
    required this.questionText,
    required this.answers,
    required this.correctAnswerIndex,
    required this.isDiemLiet,
    this.imageUrl,
    this.explain,
    this.chapterTag,
    this.chapterTitle,
  });

  // Chuyển JSON -> Question
  factory Question.fromJson(Map<String, dynamic> json) {
    final titleFromFlat = json['chapter_title'] as String?;
    final expand = json['expand']?['chapter_tag'];
    final titleFromExpand = expand is Map<String, dynamic>
        ? (expand['tag'] as String? ?? expand['title'] as String?)
        : null;

    final title = titleFromFlat ?? titleFromExpand;
    return Question(
      id: json['id'] as String,
      indexNumber: json['indexNumber'] is int
          ? json['indexNumber']
          : int.tryParse(json['indexNumber']?.toString() ?? ''),
      questionText: (json['questionText'] ?? '') as String,
      answers: List<String>.from((json['answers'] ?? []) as List),
      correctAnswerIndex: (json['correctAnswerIndex'] ?? 0) as int,
      isDiemLiet: json['isDiemLiet'] == true,
      imageUrl: json['image'] as String?,
      explain: json['explain'] as String?,
      chapterTag: json['chapter_tag'] as String?,
      chapterTitle: title,
    );
  }

// Chuyển Question -> JSON (để lưu SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'indexNumber': indexNumber,
      'questionText': questionText,
      'answers': answers,
      'correctAnswerIndex': correctAnswerIndex,
      'isDiemLiet': isDiemLiet,
      'image': imageUrl, // giữ lại cùng tên field với backend
      'explain': explain,
      'chapter_tag': chapterTag,
      if (chapterTitle != null) 'chapterTitle': chapterTitle,
    };
  }
}
