import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/models/question.dart';
import 'package:bo_de_600_gplx/router/app_router.dart';
import 'package:bo_de_600_gplx/ui/quiz_review_page.dart';

class ResultPage extends StatelessWidget {
  final int correctCount;
  final int totalQuestions;
  final Duration duration;
  final List<bool?> answerResults;
  final List<bool> isDiemLietList;

  // Dùng cho "Xem lại bài làm"
  final List<Question>? questions;
  final List<int?>? selections;
  final String? reviewTitle;

  const ResultPage({
    super.key,
    required this.correctCount,
    required this.totalQuestions,
    required this.duration,
    required this.answerResults,
    required this.isDiemLietList,
    this.questions,
    this.selections,
    this.reviewTitle,
  });

  bool get hasDiemLiet {
    for (int i = 0;
        i < answerResults.length && i < isDiemLietList.length;
        i++) {
      if (isDiemLietList[i] && answerResults[i] == false) return true;
    }
    return false;
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final incorrect = answerResults.where((e) => e == false).length;

    // đủ dữ liệu để xem lại bài làm?
    final bool canReview = questions != null &&
        selections != null &&
        questions!.length == selections!.length &&
        questions!.length == answerResults.length;

    // Biến để chứa kết quả
    String message;
    Color textColor;
    Color bannerColor;

    if (hasDiemLiet) {
      message = 'KHÔNG ĐẠT: SAI CÂU ĐIỂM LIỆT!';
      textColor = Colors.red;
      bannerColor = Colors.red.shade100;
    } else if (correctCount >= 21) {
      message = 'ĐẠT: CHÚC MỪNG BẠN!';
      textColor = Colors.green;
      bannerColor = Colors.green.shade100;
    } else {
      message = 'KHÔNG ĐẠT: CHƯA ĐỦ SỐ CÂU ĐÚNG';
      textColor = Colors.red;
      bannerColor = Colors.red.shade100;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF90CAF9),
        // ✅ back về Home luôn
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          tooltip: 'Về trang chủ',
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
        title: const Text(
          'Kết quả đề thi',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Về trang chủ',
            icon: const Icon(Icons.home, color: Colors.black),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === Banner trạng thái ===
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // === 3 chip thống kê ===
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _StatChip(
                  icon: Icons.timer,
                  label: '',
                  value: formatDuration(duration),
                  color: const Color(0xFF1E88E5),
                ),
                _StatChip(
                  icon: Icons.check_circle,
                  label: 'Đúng',
                  value: '$correctCount',
                  color: const Color(0xFF0F9D58),
                ),
                _StatChip(
                  icon: Icons.cancel,
                  label: 'Sai',
                  value: '$incorrect',
                  color: const Color(0xFFD93025),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // === Lưới trạng thái từng câu ===
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalQuestions,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final result = answerResults[index];
                Color bg;
                IconData icon;
                Color iconColor;

                if (result == true) {
                  bg = const Color(0xFFE7F6EC);
                  icon = Icons.check;
                  iconColor = const Color(0xFF0F9D58);
                } else if (result == false) {
                  bg = const Color(0xFFFFE8E9);
                  icon = Icons.close;
                  iconColor = const Color(0xFFD93025);
                } else {
                  bg = const Color(0xFFF1F3F4);
                  icon = Icons.help_outline;
                  iconColor = const Color(0xFF757575);
                }

                return Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Câu ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Icon(icon, size: 22, color: iconColor),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // === Nút hành động ===
            Column(
              children: [
                // Xem câu sai
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.wrongQuestions,
                      );
                    },
                    icon: const Icon(Icons.error_outline),
                    label: const Text(
                      'Xem câu sai',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE3F2FD),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                      elevation: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Xem lại bài làm
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: canReview
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizReviewPage(
                                  title: reviewTitle ?? 'Xem lại bài làm',
                                  questions: questions!,
                                  selections: selections!,
                                  answerResults: answerResults,
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.visibility),
                    label: const Text(
                      'Xem lại bài làm',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(
                        color: Color(0xFF1E88E5),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Chip hiển thị số liệu =====
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
