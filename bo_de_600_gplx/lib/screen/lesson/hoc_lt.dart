import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/services/learn_service.dart';
import 'package:bo_de_600_gplx/router/app_router.dart';

class TheoryPage extends StatefulWidget {
  const TheoryPage({super.key});

  @override
  State<TheoryPage> createState() => _TheoryPageState();
}

class _TheoryPageState extends State<TheoryPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> chapters = [];
  List<dynamic> filtered = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChapters();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchChapters() async {
    try {
      setState(() => isLoading = true);
      final data = await LearnService.getChapters();
      setState(() {
        chapters = data;
        filtered = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e")),
        );
      }
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => filtered = List.from(chapters));
      return;
    }
    setState(() {
      filtered = chapters.where((it) {
        final title = (it["title"] ?? "").toString().toLowerCase();
        return title.contains(q);
      }).toList();
    });
  }

  void _openLessons(Map<String, dynamic> chapter) {
    Navigator.pushNamed(
      context,
      AppRouter.lessons,
      arguments: {
        'chapterId': chapter["id"],
        'chapterTitle': chapter["title"] ?? "Chương",
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "Học lý thuyết",
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.95), primary.withOpacity(0.70)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SearchField(controller: _searchCtrl),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF6F7FB),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: isLoading
                      ? const _SkeletonList()
                      : RefreshIndicator(
                          onRefresh: fetchChapters,
                          child: filtered.isEmpty
                              ? _EmptyState(onClear: () {
                                  _searchCtrl.clear();
                                  _onSearchChanged();
                                })
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final chapter = filtered[index];
                                    final title = chapter["title"] ??
                                        "Chương ${index + 1}";
                                    return _ChapterCard(
                                      index: index,
                                      title: title.toString(),
                                      onTap: () => _openLessons(chapter),
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
    );
  }
}

/// Search field – gọn, có icon & clear
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: "Tìm kiếm",
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: "Xóa",
              onPressed: controller.clear,
              icon: const Icon(Icons.close_rounded),
            );
          },
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Card item cho mỗi chương – bo tròn, bóng nhẹ, badge số chương
class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.index,
    required this.title,
    required this.onTap,
  });

  final int index;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            constraints: const BoxConstraints(minHeight: 92),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔸 Icon yêu thích thay cho badge số chương
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12), // nền nhẹ màu cam
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Tiêu đề + phụ đề
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        softWrap: true,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),

                // Nút/chevron
                const SizedBox(
                  width: 24,
                  child: Icon(Icons.chevron_right_rounded,
                      size: 26, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton loading – không cần thêm package
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    Widget bone([double h = 18, double w = double.infinity]) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: const Color(0xFFE9ECF3),
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9ECF3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bone(),
                      const SizedBox(height: 8),
                      bone(14, 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Trạng thái rỗng khi không khớp tìm kiếm
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: primary),
            const SizedBox(height: 12),
            const Text(
              "Không tìm thấy chương phù hợp",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "Tìm từ khóa khác.",
              style:
                  TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
