import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/painting/paint_context.dart';
import 'package:structlab/editor/painting/support_shapes.dart';

void drawSupports(Canvas canvas, PaintContext ctx) {
  for (final support in ctx.model.supports) {
    final node = ctx.model.nodeById(support.nodeId);
    if (node == null) continue;
    final origin = ctx.toScreen(node.position);
    final selected = ctx.isSelected(SelectedType.support, support.id);
    final paint = Paint()
      ..color = selected ? const Color(0xFFB42318) : const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    final fill = Paint()
      ..color = selected ? const Color(0xFFFFE4E1) : const Color(0xFFE2E8F0);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(support.rotationDegrees * math.pi / 180);
    const point = Offset.zero;

    if (support.type == SupportType.fixed) {
      drawFixedSupportShape(canvas, point, 1, paint);
    } else if (support.type == SupportType.pin) {
      drawPinSupportShape(canvas, point, 1, paint, fill: fill);
    } else {
      // Roller.
      final path = Path()
        ..moveTo(point.dx, point.dy + 2)
        ..lineTo(point.dx - 12, point.dy + 20)
        ..lineTo(point.dx + 12, point.dy + 20)
        ..close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, paint);
      canvas.drawCircle(point + const Offset(-5, 23), 2.5, paint);
      canvas.drawCircle(point + const Offset(5, 23), 2.5, paint);
      canvas.drawLine(
        point + const Offset(-15, 27),
        point + const Offset(15, 27),
        paint,
      );
    }
    canvas.restore();
  }
}
