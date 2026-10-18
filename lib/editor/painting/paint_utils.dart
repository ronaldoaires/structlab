import 'dart:math' as math;

import 'package:flutter/material.dart';

TextPainter _layoutText(String text, Color color, double fontSize) {
  return TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
}

/// Size of a label box (text plus padding) drawn by [drawLabel].
Size labelSize(String text, double fontSize) {
  final p = _layoutText(text, const Color(0xFF000000), fontSize);
  return Size(p.width + 8, p.height + 4);
}

/// Rotates [angle] (radians) by 180 degrees when needed so text is never
/// upside down.
double readableAngle(double angle) {
  if (angle > math.pi / 2) return angle - math.pi;
  if (angle < -math.pi / 2) return angle + math.pi;
  return angle;
}

/// Draws [text] centered at [center], rotated by [angle] (radians), over an
/// optional rounded background.
void drawLabel(
  Canvas canvas,
  String text,
  Offset center, {
  required Color color,
  double fontSize = 10,
  double angle = 0,
  Color? background,
}) {
  final painter = _layoutText(text, color, fontSize);
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);
  if (background != null) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: painter.width + 8,
          height: painter.height + 4,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = background.withValues(alpha: 0.9),
    );
  }
  painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  canvas.restore();
}

void drawArrowHead(
    Canvas canvas, Offset tip, Offset dir, Color color, double size) {
  final perp = Offset(-dir.dy, dir.dx);
  final path = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(
      tip.dx - dir.dx * size + perp.dx * size * 0.5,
      tip.dy - dir.dy * size + perp.dy * size * 0.5,
    )
    ..lineTo(
      tip.dx - dir.dx * size - perp.dx * size * 0.5,
      tip.dy - dir.dy * size - perp.dy * size * 0.5,
    )
    ..close();
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.fill,
  );
}