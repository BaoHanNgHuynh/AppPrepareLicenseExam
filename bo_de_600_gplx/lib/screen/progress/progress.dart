import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/services/progress_service.dart';

String formatDate(String? raw) {
  if (raw == null) return "";
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;

  return "${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
}

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await ProgressService.getAllProgress();
    if (!mounted) return;
    if (r["ok"] == true) {
      final items = (r["items"] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList()
        ..sort((a, b) => (a["chapter_tag"] ?? "")
            .toString()
            .compareTo((b["chapter_tag"] ?? "").toString()));

      setState(() {
        _items = items;
        _loading = false;
      });
    } else {
      setState(() {
        _error = r["error"]?.toString() ?? "Không lấy được tiến trình";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: _buildBody(context),
        ),
      ),
    );
  }

  num _avgOf(String key) {
    if (_items.isEmpty) return 0;
    num sum = 0;
    for (final it in _items) {
      sum += (it[key] ?? 0) as num;
    }
    return sum / _items.length;
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const SizedBox(height: 40),
          const _ProgressHeaderEmpty(),
          const SizedBox(height: 40),
          Icon(Icons.error_outline, size: 48, color: Colors.redAccent.shade200),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
              label: const Text("Thử lại"),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: const [
          _ProgressHeaderEmpty(),
          SizedBox(height: 40),
          Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 10),
          Center(
            child: Text(
              "Chưa có dữ liệu tiến trình.\nHãy làm thử vài câu nhé!",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    final avgCompletion = _avgOf("completion");
    final avgAccuracy = _avgOf("accuracy");

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length + 1, // +1 cho header
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _ProgressHeader(
            avgCompletion: avgCompletion,
            avgAccuracy: avgAccuracy,
            totalChapters: _items.length,
          );
        }
        final it = _items[index - 1];
        return _ProgressTile(
          chapterId: (it["chapter_id"] ?? "").toString(),
          chapterName: (it["chapter_tag"] ?? "Chương ?").toString(),
          attempted: (it["questions_attempted"] ?? 0) as num,
          correct: (it["questions_correct"] ?? 0) as num,
          total: (it["total_questions"] ?? 0) as num,
          accuracy: (it["accuracy"] ?? 0.0) as num,
          completion: (it["completion"] ?? 0.0) as num,
          recent: (it["recent_result"] ?? []) as List?,
          lastUpdated: (it["last_updated"] ?? it["updated"] ?? it["created"])
              ?.toString(),
          onTap: () {},
        );
      },
    );
  }
}

// ================= HEADER TỔNG QUAN =================

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.avgCompletion,
    required this.avgAccuracy,
    required this.totalChapters,
  });

  final num avgCompletion;
  final num avgAccuracy;
  final int totalChapters;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.timeline, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Tiến trình học",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Theo dõi tiến độ học và mức độ chính xác của từng chương mà bạn đã luyện tập.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeaderStat(
                label: "Hoàn thành TB",
                value: "${avgCompletion.toStringAsFixed(0)}%",
              ),
              const SizedBox(width: 10),
              _HeaderStat(
                label: "Chính xác TB",
                value: "${avgAccuracy.toStringAsFixed(0)}%",
              ),
              const SizedBox(width: 10),
              _HeaderStat(
                label: "Số chương",
                value: "$totalChapters",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressHeaderEmpty extends StatelessWidget {
  const _ProgressHeaderEmpty();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          Icon(Icons.timeline, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "Tiến trình học",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= TILE CHI TIẾT MỖI CHƯƠNG =================

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.chapterId,
    required this.chapterName,
    required this.attempted,
    required this.correct,
    required this.total,
    required this.accuracy,
    required this.completion,
    this.recent,
    this.lastUpdated,
    this.onTap,
  });

  final String chapterId;
  final String chapterName;
  final num attempted;
  final num correct;
  final num total;
  final num accuracy; // %
  final num completion; // %
  final List? recent;
  final String? lastUpdated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconCircle(color: c.primary, icon: Icons.description_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    chapterName.isEmpty ? "Chương" : chapterName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                ),
                _Badge(
                  label: "Độ chính xác",
                  value: "${accuracy.toStringAsFixed(0)}%",
                  color: _accuracyColor(context, accuracy),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2 vòng tròn
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CircleStat(
                  label: "Hoàn thành",
                  value: (completion.toDouble() / 100).clamp(0.0, 1.0),
                  color: const Color(0xFF005A9C),
                ),
                _CircleStat(
                  label: "Chính xác",
                  value: (accuracy.toDouble() / 100).clamp(0.0, 1.0),
                  color: const Color(0xFFFF6B6B),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 3 chip thống kê
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _StatChip(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  text: "Đúng: $correct",
                ),
                _StatChip(
                  icon: Icons.help_outline,
                  color: Colors.orange,
                  text: "Đã làm: $attempted",
                ),
                _StatChip(
                  icon: Icons.list_alt_outlined,
                  color: const Color(0xFF6EA8FF),
                  text: "Tổng: $total",
                ),
              ],
            ),

            if (recent != null && recent!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _RecentDots(recent: recent!),
            ],

            if (lastUpdated != null) ...[
              const SizedBox(height: 6),
              Text(
                "Cập nhật: ${formatDate(lastUpdated)}",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _accuracyColor(BuildContext context, num accuracy) {
    if (accuracy >= 80) return Color(0xFF2ECC71);
    if (accuracy >= 60) return Color(0xFFF5A623);

    return const Color(0xFFE74C3C);
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color.withOpacity(0.12); // nền mềm
    final iconColor = color.withOpacity(0.85); // icon đậm hơn

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.show_chart,
            size: 18,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= VÒNG TRÒN HOÀN THÀNH / CHÍNH XÁC =================

class _CircleStat extends StatelessWidget {
  final String label;
  final double value; // 0.0 – 1.0
  final Color color;

  const _CircleStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: value.isNaN ? 0 : value,
                strokeWidth: 7,
                valueColor: AlwaysStoppedAnimation(color),
                backgroundColor: color.withOpacity(0.18),
              ),
            ),
            Text(
              "${(value * 100).toStringAsFixed(0)}%",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ================= CHIP & LỊCH SỬ GẦN ĐÂY =================

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      side: BorderSide(color: color.withOpacity(0.3)),
      backgroundColor: color.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _RecentDots extends StatelessWidget {
  const _RecentDots({required this.recent});
  final List recent;

  @override
  Widget build(BuildContext context) {
    final int count = recent.length > 8 ? 8 : recent.length;

    int correctCount = 0;
    for (int i = 0; i < count; i++) {
      final ok = (recent[i]["correct"] ?? false) == true;
      if (ok) correctCount++;
    }

    return Row(
      children: [
        const Text(
          "Gần đây:",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 6),
        Wrap(
          spacing: 4,
          children: List.generate(count, (i) {
            final ok = (recent[i]["correct"] ?? false) == true;
            final base = ok
                ? const Color.fromARGB(255, 22, 158, 29)
                : const Color.fromARGB(255, 245, 19, 15);

            return Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: base.withOpacity(0.14),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: base.withOpacity(0.7),
                  width: 1,
                ),
              ),
              child: Icon(
                ok ? Icons.check : Icons.close,
                color: base,
                size: 13,
              ),
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          "$correctCount/$count đúng",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
