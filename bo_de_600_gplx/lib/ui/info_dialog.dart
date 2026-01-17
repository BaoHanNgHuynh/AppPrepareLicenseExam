import 'package:flutter/material.dart';

class InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const InfoLine({
    super.key,
    this.icon = Icons.info_outline,
    this.text = '',
    this.iconColor = Colors.blueGrey,
  });

  const InfoLine.item(
    this.icon,
    this.text, {
    super.key,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                letterSpacing: 0.2, // 👈 đỡ dính chữ
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
