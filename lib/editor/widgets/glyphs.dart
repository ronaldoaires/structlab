import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/editor/painting/support_shapes.dart';

/// Small drawn icon of a support type.
class SupportGlyph extends StatelessWidget {
  const SupportGlyph({
    super.key,
    required this.type,
    this.color = brandBlue,
    this.size = 26,
  });

  final SupportType type;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SupportGlyphPainter(type, color),
    );
  }
}

class _SupportGlyphPainter extends CustomPainter {
  _SupportGlyphPainter(this.type, this.color);

  final SupportType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case SupportType.pin:
        drawPinSupportShape(
          canvas,
          Offset(w * 0.5, h * 0.1),
          w / 34,
          stroke,
        );
        break;
      case SupportType.roller:
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.5, h * 0.10)
            ..lineTo(w * 0.27, h * 0.58)
            ..lineTo(w * 0.73, h * 0.58)
            ..close(),
          stroke,
        );
        canvas.drawCircle(Offset(w * 0.37, h * 0.70), w * 0.07, stroke);
        canvas.drawCircle(Offset(w * 0.63, h * 0.70), w * 0.07, stroke);
        canvas.drawLine(
          Offset(w * 0.12, h * 0.86),
          Offset(w * 0.88, h * 0.86),
          stroke,
        );
        break;
      case SupportType.fixed:
        drawFixedSupportShape(
          canvas,
          Offset(w * 0.5, h * 0.12),
          w / 30,
          stroke,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SupportGlyphPainter old) =>
      old.type != type || old.color != color;
}

/// Small drawn icon of a load kind.
class LoadGlyph extends StatelessWidget {
  const LoadGlyph({
    super.key,
    required this.kind,
    this.color = brandBlue,
    this.size = 26,
  });

  final LoadKind kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LoadGlyphPainter(kind, color),
    );
  }
}

class _LoadGlyphPainter extends CustomPainter {
  _LoadGlyphPainter(this.kind, this.color);

  final LoadKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final baseY = h * 0.86;

    void arrow(double x, double tailY, double headY) {
      canvas.drawLine(Offset(x, tailY), Offset(x, headY), stroke);
      canvas.drawLine(
        Offset(x, headY),
        Offset(x - w * 0.07, headY - h * 0.10),
        stroke,
      );
      canvas.drawLine(
        Offset(x, headY),
        Offset(x + w * 0.07, headY - h * 0.10),
        stroke,
      );
    }

        if (kind == LoadKind.moment) {
      final center = Offset(w * 0.5, h * 0.5);
      final r = w * 0.34;
      const a0 = math.pi * 0.25;
      const sweep = -1.5 * math.pi;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: r), a0, sweep, false, stroke);
      const end = a0 + sweep;
      final tip = center + Offset(math.cos(end), math.sin(end)) * r;
      final dir = Offset(math.sin(end), -math.cos(end));
      final perp = Offset(-dir.dy, dir.dx);
      final s = w * 0.16;
      canvas.drawLine(tip, tip - dir * s + perp * s * 0.5, stroke);
      canvas.drawLine(tip, tip - dir * s - perp * s * 0.5, stroke);
      return;
    }

    canvas.drawLine(Offset(w * 0.08, baseY), Offset(w * 0.92, baseY), stroke);

    if (kind == LoadKind.concentrated) {
      arrow(w * 0.5, h * 0.08, baseY - h * 0.02);
      return;
    }

    final (h0, h1) = switch (kind) {
      LoadKind.uniform => (h * 0.58, h * 0.58),
      LoadKind.triangular => (0.0, h * 0.66),
      _ => (h * 0.28, h * 0.66),
    };
    const n = 4;
    final x0 = w * 0.12;
    final x1 = w * 0.88;
    canvas.drawLine(Offset(x0, baseY - h0), Offset(x1, baseY - h1), stroke);
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final x = x0 + (x1 - x0) * t;
      final height = h0 + (h1 - h0) * t;
      if (height > h * 0.14) {
        arrow(x, baseY - height, baseY - h * 0.02);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoadGlyphPainter old) =>
      old.kind != kind || old.color != color;
}
