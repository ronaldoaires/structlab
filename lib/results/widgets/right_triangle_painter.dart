import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/editor/painting/paint_utils.dart';

/// Small right triangle used to explain Pythagoras: horizontal leg Δx,
/// vertical leg Δy and the member as the hypotenuse L. It is a sketch, not
/// to scale: the leg ratio is clamped so flat or steep members stay readable.
class RightTrianglePainter extends CustomPainter {
  RightTrianglePainter({
    required this.legRatio,
    required this.risesToRight,
    required this.horizontalLabel,
    required this.verticalLabel,
    required this.hypotenuseLabel,
  });

  /// Δy / Δx of the real member.
  final double legRatio;

  /// True when the right end of the member is the higher one.
  final bool risesToRight;

  final String horizontalLabel;
  final String verticalLabel;
  final String hypotenuseLabel;

  @override
  void paint(Canvas canvas, Size size) {
    const padSide = 22.0, padTop = 8.0, padBottom = 22.0;
    final ratio = legRatio.clamp(0.35, 1.1).toDouble();
    final availW = size.width - 2 * padSide;
    final availH = size.height - padTop - padBottom;
    final w = math.min(availW, availH / ratio);
    final h = w * ratio;
    final left = (size.width - w) / 2;
    final bottom = padTop + (availH + h) / 2;

    // Corner with the right angle is always at the bottom, under the high end.
    final Offset low, corner, high;
    if (risesToRight) {
      low = Offset(left, bottom);
      corner = Offset(left + w, bottom);
      high = Offset(left + w, bottom - h);
    } else {
      high = Offset(left, bottom - h);
      corner = Offset(left, bottom);
      low = Offset(left + w, bottom);
    }

    final legPaint = Paint()
      ..color = inkMuted
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(low, corner, legPaint);
    canvas.drawLine(corner, high, legPaint);

    // Right-angle mark.
    const m = 8.0;
    final inward = risesToRight ? -1.0 : 1.0;
    canvas.drawPath(
      Path()
        ..moveTo(corner.dx + inward * m, corner.dy)
        ..lineTo(corner.dx + inward * m, corner.dy - m)
        ..lineTo(corner.dx, corner.dy - m),
      Paint()
        ..color = inkMuted
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    // Hypotenuse = the member.
    canvas.drawLine(
      low,
      high,
      Paint()
        ..color = brandBlue
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (final p in [low, high]) {
      canvas.drawCircle(p, 3.5, Paint()..color = brandBlue);
    }

    // Labels.
    drawLabel(
      canvas,
      horizontalLabel,
      Offset((low.dx + corner.dx) / 2, bottom + 12),
      color: ink,
      fontSize: 11,
    );
    drawLabel(
      canvas,
      verticalLabel,
      Offset(corner.dx - inward * 11, bottom - h / 2),
      color: ink,
      fontSize: 11,
      angle: -math.pi / 2,
    );

    final mid = (low + high) / 2;
    final away = mid - corner;
    final unit = away / away.distance;
    final along = high - low;
    drawLabel(
      canvas,
      hypotenuseLabel,
      mid + unit * 11,
      color: brandBlue,
      fontSize: 13,
      angle: readableAngle(math.atan2(along.dy, along.dx)),
    );
  }

  @override
  bool shouldRepaint(covariant RightTrianglePainter old) =>
      old.legRatio != legRatio ||
      old.risesToRight != risesToRight ||
      old.horizontalLabel != horizontalLabel ||
      old.verticalLabel != verticalLabel ||
      old.hypotenuseLabel != hypotenuseLabel;
}
