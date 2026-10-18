import 'package:flutter/material.dart';

/// One-line (up to two) status text under the canvas.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
      color: const Color(0xFFF8FAFC),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
      ),
    );
  }
}