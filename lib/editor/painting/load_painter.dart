import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:structlab/core/geometry.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/painting/load_geometry.dart';
import 'package:structlab/editor/painting/paint_context.dart';
import 'package:structlab/editor/painting/paint_utils.dart';

String _fmt(double v) => v.toStringAsFixed(1);

void drawLoads(Canvas canvas, PaintContext ctx) {
  final loads = ctx.model.loads;
  // Distributed first; concentrated on top.
  final ordered = [
    ...loads.where((l) => l.kind != LoadKind.concentrated),
    ...loads.where((l) => l.kind == LoadKind.concentrated),
  ];
  for (final load in ordered) {
    final nodeA = ctx.model.nodeById(load.nodeId);
    if (nodeA == null) continue;
    final selected = ctx.isSelected(SelectedType.load, load.id);
    final color = selected ? const Color(0xFFB42318) : const Color(0xFFD9485F);
    final dir = loadScreenDir(load);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    if (load.kind == LoadKind.concentrated) {
      _drawConcentrated(canvas, ctx, load, nodeA, dir, color, paint);
    } else {
      _drawDistributed(canvas, ctx, load, nodeA, dir, color, paint);
    }
  }
}

void _drawConcentrated(
  Canvas canvas,
  PaintContext ctx,
  StructuralLoad load,
  StructuralNode node,
  Offset dir,
  Color color,
  Paint paint,
) {
  final point = ctx.toScreen(node.position);
  final clearance =
      concentratedClearancePx(load, ctx.model.loads, ctx.model.nodeById);
  final end = point - dir * (clearance > 0 ? clearance + 8 : 5);
  final start = end - dir * 33;

  // Distributed load underneath: thin dashed line down to the node.
  if (clearance > 0) {
    final leader = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 1;
    final total = (end - point).distance;
    final u = (end - point) / total;
    var d = 0.0;
    while (d < total) {
      canvas.drawLine(
        point + u * d,
        point + u * math.min(d + 4, total),
        leader,
      );
      d += 7;
    }
  }

  canvas.drawLine(start, end, paint);
  drawArrowHead(canvas, end, dir, color, 10);

  // Horizontal label placed beyond the arrow tail, along the arrow direction.
  final text = '${_fmt(load.q1)} kN';
  final box = labelSize(text, 10);
  final extent = dir.dx.abs() * box.width / 2 + dir.dy.abs() * box.height / 2 + 3;
  drawLabel(
    canvas,
    text,
    start - dir * extent,
    color: color,
    background: canvasBackground,
  );
}

void _drawDistributed(
  Canvas canvas,
  PaintContext ctx,
  StructuralLoad load,
  StructuralNode nodeA,
  Offset dir,
  Color color,
  Paint paint,
) {
  final endId = load.endNodeId;
  final nodeB = endId == null ? null : ctx.model.nodeById(endId);
  if (nodeB == null) return;
  final a = ctx.toScreen(nodeA.position);
  final b = ctx.toScreen(nodeB.position);
  final delta = b - a;
  final dist = delta.distance;
  if (dist < 1) return;

  final lenA = loadArrowLengthPx(load, load.q1);
  final lenB = loadArrowLengthPx(load, load.q2);
  final headA = a - dir * 3;
  final headB = b - dir * 3;
  final tailA = headA - dir * lenA;
  final tailB = headB - dir * lenB;

  canvas.drawPath(
    Path()
      ..moveTo(headA.dx, headA.dy)
      ..lineTo(headB.dx, headB.dy)
      ..lineTo(tailB.dx, tailB.dy)
      ..lineTo(tailA.dx, tailA.dy)
      ..close(),
    Paint()..color = color.withValues(alpha: 0.10),
  );
  canvas.drawLine(tailA, tailB, paint);

  final count = math.max(2, (dist / 18).round());
  for (var i = 0; i <= count; i++) {
    final t = i / count;
    final len = lenA + (lenB - lenA) * t;
    if (len < 6) continue;
    final head = Offset.lerp(headA, headB, t)!;
    final tail = head - dir * len;
    canvas.drawLine(tail, head, paint);
    drawArrowHead(canvas, head, dir, color, 8);
  }

  // Label position along the span: avoid concentrated loads at nodes.
  var labelT = 0.5;
  for (final t in const [0.5, 0.25, 0.75]) {
    final p = Offset.lerp(a, b, t)!;
    final conflict = ctx.model.loads.any((o) {
      if (o.kind != LoadKind.concentrated) return false;
      final on = ctx.model.nodeById(o.nodeId);
      return on != null && (ctx.toScreen(on.position) - p).distance < 34;
    });
    if (!conflict) {
      labelT = t;
      break;
    }
  }

  final text = switch (load.kind) {
    LoadKind.uniform => '${_fmt(load.q1)} kN/m',
    LoadKind.triangular => '${_fmt(math.max(load.q1, load.q2))} kN/m',
    _ => '${_fmt(load.q1)} – ${_fmt(load.q2)} kN/m',
  };
  final box = labelSize(text, 10);

  // Outer side of the load (where the arrow tails are), perpendicular to the
  // member.
  final beamDir = delta / dist;
  var normal = Offset(-beamDir.dy, beamDir.dx);
  if (dot2(normal, -dir) < 0) normal = -normal;
  final outward = math.max(0.0, dot2(-dir, normal));

  // Tallest arrow under the label (sloped loads), so the text clears the
  // tail line along its whole width.
  double lenAt(double t) =>
      lenA + (lenB - lenA) * t.clamp(0.0, 1.0).toDouble();
  final half = (box.width / 2) / dist;
  final lenMax = math.max(
    lenAt(labelT),
    math.max(lenAt(labelT - half), lenAt(labelT + half)),
  );

  final headMid = Offset.lerp(headA, headB, labelT)!;
  final center = headMid + normal * (lenMax * outward + 11);

  // Text follows the member inclination and is never upside down.
  drawLabel(
    canvas,
    text,
    center,
    color: color,
    angle: readableAngle(math.atan2(delta.dy, delta.dx)),
    background: canvasBackground,
  );
}