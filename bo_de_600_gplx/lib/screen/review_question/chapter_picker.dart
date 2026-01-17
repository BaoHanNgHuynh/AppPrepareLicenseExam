import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/services/learn_service.dart';
import 'package:bo_de_600_gplx/router/app_router.dart';

// Mở chọn chương và mini quiz
Future<void> openChapterPicker(BuildContext context) async {
  List<Map<String, dynamic>> chapters = [];
  try {
    chapters = await LearnService.getChaptersFull();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải chương: $e')),
      );
    }
    return;
  }
  final selected = await showModalBottomSheet<Map<String, String>>(
    context: context,
    showDragHandle: true,
    builder: (_) {
      return SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: chapters.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final c = chapters[i];
            return ListTile(
              leading: const Icon(Icons.menu_book),
              title: Text((c['title'] ?? 'Chương').toString()),
              subtitle: Text((c['chapter_tag'] ?? '').toString()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop<Map<String, String>>(
                context,
                {
                  'chapterId': (c['id']).toString(),
                  'title': (c['title'] ?? 'Chương').toString(),
                },
              ),
            );
          },
        ),
      );
    },
  );

  if (selected == null) return;

  if (context.mounted) {
    Navigator.pushNamed(
      context,
      AppRouter.reviewQuiz,
      arguments: {
        'chapterId': selected['chapterId'],
        'title': 'Ôn tập: ${selected['title']}',
      },
    );
  }
}
