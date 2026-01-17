import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/services/learn_service.dart';
import 'package:bo_de_600_gplx/router/app_router.dart';

class LessonsPage extends StatefulWidget {
  const LessonsPage({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
  });

  final String chapterId;
  final String chapterTitle;

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  List<dynamic> lessons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    try {
      final data = await LearnService.getLessonsByChapter(widget.chapterId);
      if (!mounted) return;
      setState(() {
        lessons = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  void _openLesson(Map<String, dynamic> lesson) {
    Navigator.pushNamed(
      context,
      AppRouter.lessonDetail,
      arguments: {'lesson': lesson},
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color top1 = Color(0xFF2C5C7C);
    const Color top2 = Color(0xFF3D708C);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          widget.chapterTitle,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [top1, top2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF6F7FB),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: isLoading
                      ? const _SkeletonGrid()
                      : RefreshIndicator(
                          onRefresh: _fetchLessons,
                          child: lessons.isEmpty
                              ? ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 40, 20, 100),
                                  children: const [_EmptyState()],
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final cross =
                                        constraints.maxWidth > 380 ? 2 : 1;
                                    return GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 16, 16, 110),
                                      itemCount: lessons.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cross,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        // vuông kiểu hình 1
                                        childAspectRatio:
                                            cross == 1 ? 1.05 : 0.95,
                                      ),
                                      itemBuilder: (_, index) {
                                        final lesson = lessons[index]
                                            as Map<String, dynamic>;
                                        final title = (lesson["title"] ??
                                                "Bài học không tên")
                                            .toString();
                                        return _LessonCard(
                                          index: index + 1,
                                          title: title,
                                          subtitle: "",
                                          onTap: () => _openLesson(lesson),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Mini quiz: giữ màu cũ
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _MiniQuizPill(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.reviewQuiz,
            arguments: {
              'chapterId': widget.chapterId,
              'title': 'Ôn tập: ${widget.chapterTitle}',
              'limit': 10,
            },
          );
        },
      ),
    );
  }
}

/// --------- CARD VUÔNG + GestureDetector ----------
class _LessonCard extends StatefulWidget {
  const _LessonCard({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final int index;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = [
      Colors.indigo,
      Colors.green,
      Colors.orange,
      const Color.fromARGB(255, 127, 11, 159),
      Colors.red,
      Colors.blue,
    ];
    final color = palette[widget.index % palette.length];

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF7F9FC)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EDF6)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 12,
                  offset: Offset(0, 6))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // icon bo tròn
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_rounded, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.2,
                    color: Colors.black.withOpacity(0.58)),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("Bài ${widget.index}",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                  const Spacer(),
                  const Icon(Icons.more_horiz_rounded,
                      size: 22, color: Colors.black54),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --------- Mini quiz: giữ màu cũ ----------
class _MiniQuizPill extends StatelessWidget {
  const _MiniQuizPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.quiz, color: Colors.blue, size: 22),
              SizedBox(width: 8),
              Text('Mini quiz',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

/// --------- Skeleton: tỉ lệ vuông ----------
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cross = c.maxWidth > 380 ? 2 : 1;
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: 6,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cross,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: cross == 1 ? 1.05 : 0.95,
        ),
        itemBuilder: (_, __) {
          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF7F9FC)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8EDF6)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE9ECF3),
                        borderRadius: BorderRadius.circular(12))),
                const SizedBox(height: 12),
                Container(
                    height: 18,
                    width: double.infinity,
                    color: const Color(0xFFE9ECF3)),
                const SizedBox(height: 8),
                Container(
                    height: 14, width: 120, color: const Color(0xFFE9ECF3)),
                const Spacer(),
                Container(
                    height: 24,
                    width: 90,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE9ECF3),
                        borderRadius: BorderRadius.circular(10))),
              ],
            ),
          );
        },
      );
    });
  }
}

/// --------- Empty state ----------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Icon(Icons.article_outlined, size: 56, color: primary),
        const SizedBox(height: 12),
        const Text("Chưa có bài học",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          "Kéo xuống để làm mới hoặc quay lại chọn chương khác.",
          style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
