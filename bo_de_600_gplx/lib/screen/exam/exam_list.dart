import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/services/exam_service.dart';
import 'package:bo_de_600_gplx/models/exam.dart';
import 'package:bo_de_600_gplx/router/app_router.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  late Future<List<ExamItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ExamService.fetchExams();
  }

  Future<void> _reload() async {
    setState(() {
      _future = ExamService.fetchExams();
    });
  }

  Future<void> _createNewExam() async {
    // Hộp thoại confirm (tránh bấm nhầm)
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo đề thi mới'),
        content: const Text(
            'Hệ thống sẽ sinh ngẫu nhiên 25 câu theo cơ cấu 8-1-1-1-8-6.\nBạn có chắc muốn tạo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tạo')),
        ],
      ),
    );
    if (ok != true) return;

    // Overlay loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Gợi ý tên: tăng số thứ tự theo số lượng hiện có
      final current = await _future.catchError((_) => <ExamItem>[]);
      final nextIndex = (current is List ? current.length : 0) + 1;
      final newName = 'Đề ${nextIndex.toString().padLeft(2, '0')}';

      // Gọi API tạo đề
      final newId =
          await ExamService.createExam(name: newName, timeLimit: 1140);

      if (!mounted) return;
      Navigator.pop(context); // tắt loading

      // Thông báo + reload danh sách
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tạo "$newName" (id: $newId)')),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // tắt loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo đề thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // nền xám nhạt
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 41, 84, 112),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.15),
        title: const Text('Danh sách đề thi'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _createNewExam, icon: const Icon(Icons.add)),
        ],
      ),
      body: FutureBuilder<List<ExamItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }

          // Ẩn đề rỗng (khuyến nghị: backend nên trả "total" thật bằng cách đếm exam_questions)
          final items = (snap.data ?? []).where((e) => e.total > 0).toList();

          if (items.isEmpty) {
            return const Center(child: Text('Chưa có đề thi'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final e = items[i];

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.examDetail,
                    arguments: {'id': e.id, 'name': e.name},
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // Ô tròn / vuông nhỏ hiển thị số đề
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3ECFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E4DB7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Thông tin chính
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên đề
                            Text(
                              e.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Dòng: Số câu + Thời gian
                            Row(
                              children: [
                                const Icon(Icons.help_outline,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text(
                                  'Số câu: ${e.total}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.timer_outlined,
                                    size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text(
                                  '${e.timeLimit ~/ 60} phút',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),

                      const SizedBox(width: 4),

                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
