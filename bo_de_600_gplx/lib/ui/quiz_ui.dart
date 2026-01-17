import 'package:flutter/material.dart';
import 'package:bo_de_600_gplx/ui/tts_page.dart';

class QuizTopBar extends StatelessWidget {
  const QuizTopBar({
    super.key,
    required this.current,
    required this.total,
    required this.isDiemLiet,
    this.trailing,
  });
  final int current;
  final int total;
  final bool isDiemLiet;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: const Color.fromARGB(255, 214, 209, 209),
          border: Border.all(
            color: Colors.transparent,
            width: 0,
          ),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Text(
            'Câu $current/$total',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          if (isDiemLiet)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Điểm liệt',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w600)),
            ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class QuizBottomBar extends StatelessWidget {
  const QuizBottomBar({
    super.key,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    this.nextLabel = 'Câu tiếp',
  });

  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: canPrev ? onPrev : null,
                    child: const Text('Câu trước'))),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
                    onPressed: canNext ? onNext : null,
                    child: Text(nextLabel))),
          ],
        ),
      ),
    );
  }
}

class QuizAnswerList extends StatelessWidget {
  const QuizAnswerList({
    super.key,
    required this.answers,
    required this.correctIndex,
    required this.groupValue,
    required this.onChanged,
    this.showResult = false,

    // ✅ thêm tts để đọc từng đáp án
    this.tts,
  });

  final List<String> answers;
  final int correctIndex;
  final int? groupValue;
  final ValueChanged<int>? onChanged;
  final bool showResult;

  // ✅
  final TtsHelper? tts;

  bool get _answered => showResult && groupValue != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(answers.length, (i) {
        final isRight = i == correctIndex;
        final isChosen = groupValue == i;

        Color bgColor = Colors.white;
        Color borderColor = const Color(0xFFE5E5E5);
        Color textColor = Colors.black;

        if (_answered) {
          if (isRight && isChosen) {
            // đáp án đúng và đang chọn
            bgColor = const Color.fromARGB(255, 129, 244, 133);
          } else if (isRight) {
            // đáp án đúng nhưng không chọn
            bgColor = const Color.fromARGB(255, 173, 240, 174);
          } else if (isChosen && !isRight) {
            // đáp án sai và đang chọn
            bgColor = const Color.fromARGB(255, 246, 120, 120);
          }
        } else {
          if (isChosen) {
            bgColor = const Color(0xFFD7E3FC); // xanh nhạt highlight
            borderColor = const Color(0xFF1A73E8); // xanh đậm
            textColor = Colors.black;
          }
        }
        return _AnswerItem(
          label: answers[i],
          isSelected: isChosen,
          background: bgColor,
          borderColor: borderColor,
          textColor: textColor,
          onTap: onChanged == null ? null : () => onChanged!(i),
          // ✅ truyền tts + key riêng từng đáp án
          tts: tts,
          ttsKey: "a$i",
        );
      }),
    );
  }
}

class _AnswerItem extends StatefulWidget {
  const _AnswerItem({
    required this.label,
    required this.isSelected,
    required this.background,
    required this.borderColor,
    required this.textColor,
    required this.onTap,

    // ✅ thêm để đọc
    this.tts,
    this.ttsKey,
  });

  final String label;
  final bool isSelected;
  final Color background;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onTap;

  // ✅
  final TtsHelper? tts;
  final String? ttsKey;

  @override
  State<_AnswerItem> createState() => _AnswerItemState();
}

class _AnswerItemState extends State<_AnswerItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          scale: _pressed ? 0.98 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: widget.background, // trắng mặc định
              borderRadius: radius,
              border: Border.all(
                color: widget.isSelected
                    ? const Color.fromARGB(255, 16, 16, 16).withOpacity(0.5)
                    : widget.borderColor,
                width: widget.isSelected ? 1.5 : 1,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  child: Icon(
                    widget.isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: widget.isSelected ? Colors.black : Colors.blueGrey,
                  ),
                ),
                // nội dung
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: widget.textColor,
                      ),
                    ),
                  ),
                ),

                // ✅ nút loa đọc đáp án (bên phải)
                if (widget.tts != null && widget.ttsKey != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: widget.tts!.buildSpeakButton(
                      text: widget.label,
                      key: widget.ttsKey!,
                      tooltip: "Đọc đáp án",
                      icon: Icons.volume_up,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuizExplanation extends StatefulWidget {
  const QuizExplanation({
    super.key,
    required this.text,
    this.initiallyExpanded = false,
  });

  final String text;
  final bool initiallyExpanded;

  @override
  State<QuizExplanation> createState() => _QuizExplanationState();
}

class _QuizExplanationState extends State<QuizExplanation> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyExpanded;
  }

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Material(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _toggle,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.help_outline,
                        color: Color(0xFFEF6C00), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Giải thích',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEF6C00),
                        ),
                      ),
                    ),
                    Text(
                      _open ? 'Ẩn' : 'Xem',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  crossFadeState: _open
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 180),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🕒 Badge thời gian – chỉ dùng cho Đề ngẫu nhiên / Bộ đề
class QuizTimerBadge extends StatelessWidget {
  const QuizTimerBadge({super.key, required this.timeText});
  final String timeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 163, 214, 251),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer,
              size: 20, color: Color.fromARGB(255, 35, 34, 34)),
          const SizedBox(width: 6),
          Text(timeText,
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// 🧩 Hiển thị câu hỏi (dùng chung)
class QuizQuestionText extends StatelessWidget {
  final String text;
  const QuizQuestionText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color.fromARGB(255, 29, 47, 240),
            height: 1.3),
      ),
    );
  }
}
