import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:structlab/editor/painting/paint_context.dart';
import 'package:structlab/editor/painting/paint_utils.dart';

const Color _previewColor = Color(0xFFD9485F);

/// Ring on the start point of the beam being drawn.
void drawPendingStart(Canvas canvas, PaintContext ctx, Offset? pendingStart) {
  if (pendingStart == null) return;
  final point = ctx.toScreen(pendingStart);
  canvas.drawCircle(
    point,
    8,
    Paint()
      ..color = _previewColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  canvas.drawCircle(point, 3, Paint()..color = _previewColor);
}

/// Ring on the first node picked for a distributed load.
void drawPendingLoad(Canvas canvas, PaintContext ctx, int? pendingNodeId) {
  if (pendingNodeId == null) return;
  final node = ctx.model.nodeById(pendingNodeId);
  if (node == null) return;
  canvas.drawCircle(
    ctx.toScreen(node.position),
    10,
    Paint()
      ..color = const Color(0xFF2447B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2,
  );
}

/// Dashed preview line of the beam being drawn, with length and angle.
void drawBeamPreview(
  Canvas canvas,
  PaintContext ctx,
  Offset? startModel,
  Offset? endModel,
) {
  if (startModel == null || endModel == null) return;

  final a = ctx.toScreen(startModel);
  final b = ctx.toScreen(endModel);
  final delta = b - a;
  final dist = delta.distance;
  if (dist < 1) return;
  final dir = delta / dist;

  final linePaint = Paint()
    ..color = _previewColor
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  double d = 0;
  while (d < dist) {
    final e = math.min(d + 8, dist);
    canvas.drawLine(a + dir * d, a + dir * e, linePaint);
    d += 14;
  }

  canvas.drawCircle(
    b,
    6,
    Paint()
      ..color = _previewColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );

  final vec = endModel - startModel;
  final angle = math.atan2(vec.dy, vec.dx) * 180 / math.pi;
  final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  drawLabel(
    canvas,
    '${vec.distance.toStringAsFixed(2)} m · ${angle.toStringAsFixed(1)}°',
    mid + const Offset(0, -22),
    color: _previewColor,
    fontSize: 11,
    background: Colors.white,
  );
}