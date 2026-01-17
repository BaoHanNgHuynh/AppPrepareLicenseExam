import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/services/learn_service.dart';

class LessonDetailPage extends StatefulWidget {
  const LessonDetailPage({super.key, required this.lesson});
  final Map<String, dynamic> lesson;

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  List<dynamic> lessonContents = [];
  bool isLoading = true;

  // Flashcard state
  final Set<int> _expandedIndexes = {};

  @override
  void initState() {
    super.initState();
    _fetchLessonContents();
  }

  Future<void> _fetchLessonContents() async {
    try {
      final data =
          await LearnService.getLessonContentsByLessonId(widget.lesson["id"]);
      if (!mounted) return;
      setState(() {
        lessonContents = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.lesson["title"] ?? "Chi tiết bài học";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5D84),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : (lessonContents.isEmpty
                ? const Center(child: Text("Chưa có nội dung cho bài học này"))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: lessonContents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = lessonContents[index];

                      final titleText = (item["title"] ?? "").toString().trim();
                      final contentText =
                          (item["content"] ?? "").toString().trim();
                      final imageUrl = (item["image"] ?? "").toString().trim();

                      final hasTitle = titleText.isNotEmpty;
                      final hasContent = contentText.isNotEmpty;
                      final hasImage = imageUrl.isNotEmpty;

                      final isExpanded = _expandedIndexes.contains(index);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedIndexes.remove(index);
                            } else {
                              _expandedIndexes.add(index);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            // 🎨 Màu card
                            color: isExpanded
                                ? const Color(0xFFF2F8FF) // xanh nhạt khi mở
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isExpanded
                                  ? const Color(0xFF90CAF9)
                                  : const Color(0xFFE5E7EB),
                              width: isExpanded ? 1.2 : 1,
                            ),

                            // 🌫 Shadow theo trạng thái
                            boxShadow: isExpanded
                                ? const [
                                    BoxShadow(
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                      color: Color(0x14000000),
                                    ),
                                  ]
                                : const [
                                    BoxShadow(
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                      color: Color(0x10000000),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasImage)
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: double.infinity,
                                      color: Colors.white,
                                      padding: const EdgeInsets.all(8),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.contain,
                                        height: 200,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(child: Text("❌")),
                                      ),
                                    ),
                                  ),
                                ),

                              if (hasImage) const SizedBox(height: 12),

                              // ===== 2. TITLE =====
                              if (hasTitle)
                                Text(
                                  titleText,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),

                              // ===== 3. HINT =====
                              if (!isExpanded)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    "Học ngay",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color.fromARGB(221, 5, 80, 210),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),

                              // ===== 4. Ý NGHĨA (FLASHCARD) =====
                              if (isExpanded && hasContent) ...[
                                const SizedBox(height: 12),
                                Text(
                                  contentText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.65,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF263238),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  )),
      ),
    );
  }
}
