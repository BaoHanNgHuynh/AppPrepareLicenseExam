import 'package:flutter/material.dart';

class QuizAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onFinish;
  final List<Widget>? actions;

  const QuizAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onFinish,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF3D708C),
      elevation: 2,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        ...(actions ?? []),
        if (onFinish != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: onFinish,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: const Color(0xFF90CAF9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Kết thúc',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// DIALOG XÁC NHẬN "KẾT THÚC BÀI LÀM?"

Future<bool> showConfirmFinishDialog(
  BuildContext context, {
  required int answered,
  required int total,
  String? title,
  String? message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title ?? 'Kết thúc?'),
      content: Text(
        message ??
            'Bạn đã trả lời $answered/$total câu.\n'
                'Bạn muốn kết thúc và xem kết quả?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Kết thúc'),
        ),
      ],
    ),
  );

  return ok == true;
}
