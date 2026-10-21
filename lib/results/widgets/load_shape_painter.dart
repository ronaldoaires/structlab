import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/editor/painting/paint_utils.dart';

const Color _loadColor = Color(0xFFD9485F);

/// Draws a distributed load (rectangle, triangle or trapezoid) with arrows,
/// height labels, the resultant R at the CG, the two spans split at the CG
/// and the total length L.
class LoadShapePainter extends CustomPainter {
  LoadShapePainter({
    required this.q1,
    required this.q2,
    required this.cgFraction,
    this.labelLeft,
    this.labelRight,
    this.leftSpanLabel,
    this.rightSpanLabel,
    this.startLabel,
    this.endLabel,
    this.resultantLabel,
    this.lengthLabel,
  });

  /// Height at the start node (kN/m).
  final double q1;

  /// Height at the end node (kN/m).
  final double q2;

  /// CG position along the span, 0..1 from the start node.
  final double cgFraction;

  final String? labelLeft;
  final String? labelRight;

  /// Dimension labels of the two segments, split at the CG line.
  final String? leftSpanLabel;
  final String? rightSpanLabel;
  final String? startLabel;
  final String? endLabel;

  /// Text next to the resultant arrow (e.g. "R = 40 kN").
  final String? resultantLabel;

  /// Text under the total length line (e.g. "L = 4 m").
  final String? lengthLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final maxQ = q1 > q2 ? q1 : q2;
    if (maxQ <= 0) return;
    const padX = 28.0, top = 58.0, bottomSpace = 84.0;
    final x0 = padX, x1 = size.width - padX;
    final base = size.height - bottomSpace;
    final maxH = base - top;
    final h1 = q1 / maxQ * maxH;
    final h2 = q2 / maxQ * maxH;

    final cx = x0 + (x1 - x0) * cgFraction;
    final topY = base - (h1 + (h2 - h1) * cgFraction);

    final stroke = Paint()
      ..color = _loadColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Filled shape.
    canvas.drawPath(
      Path()
        ..moveTo(x0, base)
        ..lineTo(x1, base)
        ..lineTo(x1, base - h2)
        ..lineTo(x0, base - h1)
        ..close(),
      Paint()..color = _loadColor.withValues(alpha: 0.12),
    );
    // Top edge and the two vertical sides.
    canvas.drawLine(Offset(x0, base - h1), Offset(x1, base - h2), stroke);
    if (h1 > 0) {
      canvas.drawLine(Offset(x0, base), Offset(x0, base - h1), stroke);
    }
    if (h2 > 0) {
      canvas.drawLine(Offset(x1, base), Offset(x1, base - h2), stroke);
    }

    // Arrows pointing down to the beam.
    const n = 5;
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final h = h1 + (h2 - h1) * t;
      if (h < 10) continue;
      final x = x0 + (x1 - x0) * t;
      canvas.drawLine(Offset(x, base - h), Offset(x, base - 2), stroke);
      drawArrowHead(canvas, Offset(x, base), const Offset(0, 1), _loadColor, 6);
    }

    // Beam.
    canvas.drawLine(
      Offset(x0 - 8, base),
      Offset(x1 + 8, base),
      Paint()
        ..color = brandBlue
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Height labels, aligned with the edges of the shape.
    final isRectangle = (q1 - q2).abs() < 1e-9;
    void heightLabel(String text, double centerX, double height) {
      drawLabel(
        canvas,
        text,
        Offset(centerX, base - height - 11),
        color: _loadColor,
        fontSize: 11,
        background: canvasBackground,
      );
    }

    if (isRectangle) {
      if (labelLeft != null) heightLabel(labelLeft!, (x0 + x1) / 2, h1);
    } else {
      if (labelLeft != null && h1 > 0) {
        final w = labelSize(labelLeft!, 11).width;
        heightLabel(labelLeft!, x0 + w / 2, h1);
      }
      if (labelRight != null && h2 > 0) {
        final w = labelSize(labelRight!, 11).width;
        heightLabel(labelRight!, x1 - w / 2, h2);
      }
    }

    // Resultant: blue arrow from above the load down to its surface at the CG.
    const arrowTop = 14.0;
    final resultantPaint = Paint()
      ..color = brandBlue
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, arrowTop), Offset(cx, topY - 2), resultantPaint);
    drawArrowHead(canvas, Offset(cx, topY), const Offset(0, 1), brandBlue, 9);
    if (resultantLabel != null) {
      final w = labelSize(resultantLabel!, 13).width;
      final fitsRight = cx + 8 + w <= size.width;
      drawLabel(
        canvas,
        resultantLabel!,
        Offset(fitsRight ? cx + 8 + w / 2 : cx - 8 - w / 2, arrowTop + 6),
        color: brandBlue,
        fontSize: 13,
      );
    }

    // CG: dashed line from the load surface down to the beam.
    final dash = Paint()
      ..color = brandBlue
      ..strokeWidth = 1.4;
    for (var y = topY; y < base; y += 7) {
      canvas.drawLine(
        Offset(cx, y),
        Offset(cx, (y + 4).clamp(0.0, base).toDouble()),
        dash,
      );
    }
    canvas.drawCircle(Offset(cx, base), 4.5, Paint()..color = brandBlue);
    drawLabel(
      canvas,
      'CG',
      Offset(cx + 14, base - 12),
      color: brandBlue,
      fontSize: 12,
    );

    // Node names under the beam ends.
    if (startLabel != null) {
      drawLabel(canvas, startLabel!, Offset(x0, base + 12),
          color: ink, fontSize: 12);
    }
    if (endLabel != null) {
      drawLabel(canvas, endLabel!, Offset(x1, base + 12),
          color: ink, fontSize: 12);
    }

    // Dimension line split at the CG: one segment on each side.
    final dim = Paint()
      ..color = inkMuted
      ..strokeWidth = 1;
    if (leftSpanLabel != null && rightSpanLabel != null) {
      final y = base + 32;
      canvas.drawLine(Offset(x0, y), Offset(x1, y), dim);
      for (final x in [x0, cx, x1]) {
        canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), dim);
      }
      drawLabel(canvas, leftSpanLabel!, Offset((x0 + cx) / 2, y),
          color: inkMuted, fontSize: 11, background: Colors.white);
      drawLabel(canvas, rightSpanLabel!, Offset((cx + x1) / 2, y),
          color: inkMuted, fontSize: 11, background: Colors.white);
    }

    // Total length L, with its label under the line.
    if (lengthLabel != null) {
      final y = base + 54;
      final lengthPaint = Paint()
        ..color = ink
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(x0, y), Offset(x1, y), lengthPaint);
      for (final x in [x0, x1]) {
        canvas.drawLine(Offset(x, y - 6), Offset(x, y + 6), lengthPaint);
      }
      drawLabel(canvas, lengthLabel!, Offset((x0 + x1) / 2, y + 16),
          color: _loadColor, fontSize: 12);
    }
  }

  @override
  bool shouldRepaint(covariant LoadShapePainter old) =>
      old.q1 != q1 ||
      old.q2 != q2 ||
      old.cgFraction != cgFraction ||
      old.labelLeft != labelLeft ||
      old.labelRight != labelRight ||
      old.leftSpanLabel != leftSpanLabel ||
      old.rightSpanLabel != rightSpanLabel ||
      old.startLabel != startLabel ||
      old.endLabel != endLabel ||
      old.resultantLabel != resultantLabel ||
      old.lengthLabel != lengthLabel;
}