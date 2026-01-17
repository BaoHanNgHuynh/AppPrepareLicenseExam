import 'package:bo_de_600_gplx/models/exam.dart';
import 'package:flutter/material.dart';

// import các màn hình
import 'package:bo_de_600_gplx/splash/splash.dart';
import 'package:bo_de_600_gplx/screen/auth/login.dart';
import 'package:bo_de_600_gplx/screen/auth/register.dart';
import 'package:bo_de_600_gplx/screen/home/home_page.dart';
import 'package:bo_de_600_gplx/screen/lesson/hoc_lt.dart';
import 'package:bo_de_600_gplx/screen/lesson/lesson_page.dart';
import 'package:bo_de_600_gplx/screen/lesson/lesson_detail_page.dart';
import 'package:bo_de_600_gplx/screen/question/20_questions.dart';

import 'package:bo_de_600_gplx/screen/question/random_question.dart';
import 'package:bo_de_600_gplx/screen/question/wrong_questions.dart';
import 'package:bo_de_600_gplx/screen/result/result_page.dart';
import 'package:bo_de_600_gplx/screen/settings/setting_page.dart';
import 'package:bo_de_600_gplx/screen/tip/tip_page.dart';
import 'package:bo_de_600_gplx/screen/review_question/mini_quiz.dart';
import 'package:bo_de_600_gplx/screen/result/history_page.dart';
import 'package:bo_de_600_gplx/screen/exam/exam_list.dart';
import 'package:bo_de_600_gplx/screen/exam/exam_screen.dart';
import 'package:bo_de_600_gplx/screen/exam/exam_result.dart';
import 'package:bo_de_600_gplx/screen/progress/progress.dart';
import 'package:bo_de_600_gplx/screen/traffic_sign/traffic_sign_page.dart';

class AppRouter {
  //dùng Navigator.pushNamed
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const settings = '/settings';
  static const tips = '/tips';
  static const diemLiet = '/diem-liet';
  static const randomQuestions = '/random-questions';
  static const wrongQuestions = '/wrong-questions';
  static const history = '/history';
  static const theory = '/theory';
  static const trafficSigns = '/traffic-signs';
  static const lessonDetail = '/lesson-detail';
  static const progress = '/progress';
  static const examList = '/exam-list';
  static const examDetail = '/exam-deatail';
  static const examResult = '/exam-result';
  // các routes cần arg
  static const reviewQuiz = '/review-quiz';
  static const result = '/result';
  static const lessons = '/lessons';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashPage(),
        login: (_) => const LoginPage(),
        register: (_) => const RegisterPage(),
        home: (_) => const MyHomePage(title: 'DrivePrep'),
        settings: (_) => const SettingsPage(),
        tips: (_) => TipsScreen(),
        diemLiet: (_) => const DiemLietPage(),
        randomQuestions: (_) => const CauHoiNgauNhienPage(),
        wrongQuestions: (_) => const IncorrectQuestionsPage(),
        theory: (_) => const TheoryPage(),
        progress: (_) => const ProgressPage(),
        history: (_) => const HistoryPage(),
        examList: (_) => const ExamListScreen(),
        trafficSigns: (_) => const TrafficSignsScreen(),
      };

  // ---- Dynamic routes (cần truyền args qua Navigator.pushNamed) ----
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case reviewQuiz:
        // arguments: { 'chapterId': String, 'title': String?, 'limit': int? }
        final args = (settings.arguments as Map?) ?? {};
        int? limit;
        final rawLimit = args['limit'];
        if (rawLimit is int) {
          limit = rawLimit;
        } else if (rawLimit is String) {
          limit = int.tryParse(rawLimit);
        }
        final chapterId = args['chapterId']?.toString() ?? '';
        final title = args['title']?.toString() ?? 'Ôn tập câu hỏi';
        return MaterialPageRoute(
          builder: (_) => ReviewQuizPage(
            chapterId: chapterId,
            title: title,
            limit: limit,
          ),
        );

      case result:
        // arguments: {
        //   'correctCount': int,
        //   'totalQuestions': int,
        //   'duration': Duration,
        //   'answerResults': List<bool?>,
        //   'isDiemLietList': List<bool>,
        // }
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => ResultPage(
            correctCount: args['correctCount'] ?? 0,
            totalQuestions: args['totalQuestions'] ?? 0,
            duration: args['duration'] ?? const Duration(seconds: 0),
            answerResults:
                (args['answerResults'] as List<bool?>?) ?? const <bool?>[],
            isDiemLietList:
                (args['isDiemLietList'] as List<bool>?) ?? const <bool>[],
            questions: args['questions'],
            selections: args['selections'],
            reviewTitle: args['reviewTitle'],
          ),
        );

      case lessons:
        // arguments: { 'chapterId': String, 'chapterTitle': String }
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => LessonsPage(
            chapterId: args['chapterId'] ?? '',
            chapterTitle: args['chapterTitle'] ?? 'Chương',
          ),
        );

      case lessonDetail:
        // arguments: { 'lesson': Map }
        final args = (settings.arguments as Map?) ?? {};
        final lesson = (args['lesson'] as Map<String, dynamic>?);
        if (lesson == null) {
          //nếu thiếu arg, trả về trang thông báo nhẹ
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Thiếu dữ liệu bài học')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => LessonDetailPage(lesson: lesson),
        );

      case examDetail:
        // arguments: { "id": String, "name": String }
        final args = (settings.arguments ?? {}) as Map;
        final String examId = args['id'] as String;
        final String examName = (args['name'] as String?) ?? 'Đề thi';
        return MaterialPageRoute(
          builder: (_) => ExamScreen(examId: examId, examName: examName),
          settings: settings,
        );

      case examResult:
        // arguments: {
        //   'examId': String,
        //   'examName': String,
        //   'totalQuestion': int,
        //   'correct': int,
        //   'diemLietWrong': int,
        //   'usedSeconds': int,
        // }
        final args = (settings.arguments ?? {}) as Map;
        return MaterialPageRoute(
          builder: (_) => ExamResultPage(
            examId: args['examId'] as String,
            examName: args['examName'] as String,
            totalQuestion: args['totalQuestion'] as int,
            correct: args['correct'] as int,
            diemLietWrong: args['diemLietWrong'] as int,
            usedSeconds: args['usedSeconds'] as int,
            chapterResult: args['chapterResult'],
          ),
        );
    }
    return null;
  }
}
