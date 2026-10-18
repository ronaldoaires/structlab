import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:structlab/core/geometry.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/painting/load_geometry.dart';
import 'package:structlab/editor/painting/paint_context.dart';
import 'package:structlab/editor/painting/paint_utils.dart';

/// Default distance (px) between a member and its dimension line.
const double _baseOffset = 36;

/// Normal that points down on screen (to the right for a vertical member).
Offset _dimensionNormal(Offset dir) {
  var normal = Offset(-dir.dy, dir.dx);
  if (normal.dy < -1e-6 || (normal.dy.abs() <= 1e-6 && normal.dx < 0)) {
    normal = -normal;
  }
  return normal;
}

/// Dimensions (distance between nodes) drawn below each member, in technical
/// drawing style: offset parallel line, tick marks at the ends and the value
/// aligned with the member.
void drawDimensions(Canvas canvas, PaintContext ctx) {
  for (final member in ctx.model.members) {
    final startNode = ctx.model.nodeById(member.startNodeId);
    final endNode = ctx.model.nodeById(member.endNodeId);
    if (startNode == null || endNode == null) continue;
    final selected = ctx.isSelected(SelectedType.member, member.id);
    final length = (endNode.position - startNode.position).distance;
    final a = ctx.toScreen(startNode.position);
    final b = ctx.toScreen(endNode.position);
    _drawDimension(
      canvas,
      a,
      b,
      '${length.toStringAsFixed(2)} m',
      selected ? brandBlue : const Color(0xFF64748B),
      _dimensionOffset(ctx, member, a, b),
    );
  }
}

/// How far the dimension line must be from the member so it does not collide
/// with loads (arrows and their labels) drawn on the same side.
double _dimensionOffset(
    PaintContext ctx, StructuralMember member, Offset a, Offset b) {
  final delta = b - a;
  final dist = delta.distance;
  if (dist < 1) return _baseOffset;
  final dir = delta / dist;
  final normal = _dimensionNormal(dir);
  final loads = ctx.model.loads;
  var need = 0.0;

  for (final load in loads) {
    // Tails (and labels) are on the opposite side of the load direction.
    final side = dot2(-loadScreenDir(load), normal);
    if (side <= 0.05) continue;

    if (load.kind == LoadKind.concentrated) {
      if (load.nodeId != member.startNodeId &&
          load.nodeId != member.endNodeId) {
        continue;
      }
      final clearance =
          concentratedClearancePx(load, loads, ctx.model.nodeById);
      final reach = (clearance > 0 ? clearance + 8 : 5) + 33 + 18;
      need = math.max(need, side * reach);
      continue;
    }

    final endId = load.endNodeId;
    if (endId == null) continue;
    final nA = ctx.model.nodeById(load.nodeId);
    final nB = ctx.model.nodeById(endId);
    if (nA == null || nB == null) continue;
    final la = ctx.toScreen(nA.position);
    final lb = ctx.toScreen(nB.position);

    // The load must lie on this member's line and overlap its span.
    if (cross2(dir, la - a).abs() > 2 || cross2(dir, lb - a).abs() > 2) {
      continue;
    }
    final t1 = dot2(la - a, dir);
    final t2 = dot2(lb - a, dir);
    final overlap =
        math.min(math.max(t1, t2), dist) - math.max(math.min(t1, t2), 0.0);
    if (overlap <= 1) continue;

    final arrow = math.max(
      loadArrowLengthPx(load, load.q1),
      loadArrowLengthPx(load, load.q2),
    );
    // Arrow + head gap + label height and spacing.
    need = math.max(need, side * (arrow + 3 + 18));
  }

  return math.max(_baseOffset, need + 10);
}

void _drawDimension(Canvas canvas, Offset a, Offset b, String text,
    Color color, double offset) {
  final delta = b - a;
  final dist = delta.distance;
  if (dist < 1) return;
  final dir = delta / dist;
  final normal = _dimensionNormal(dir);

  final a2 = a + normal * offset;
  final b2 = b + normal * offset;

  final paint = Paint()
    ..color = color
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;

  // Dimension line.
  canvas.drawLine(a2, b2, paint);
  // Extension lines at the ends.
  canvas.drawLine(a + normal * (offset - 6), a2 + normal * 4, paint);
  canvas.drawLine(b + normal * (offset - 6), b2 + normal * 4, paint);
  // Oblique tick marks.
  final tick = unitVec(dir + normal) * 4;
  final tickPaint = Paint()
    ..color = color
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(a2 - tick, a2 + tick, tickPaint);
  canvas.drawLine(b2 - tick, b2 + tick, tickPaint);

  // Text aligned with the member, always readable.
  drawLabel(
    canvas,
    text,
    Offset((a2.dx + b2.dx) / 2, (a2.dy + b2.dy) / 2),
    color: color,
    angle: readableAngle(math.atan2(dir.dy, dir.dx)),
    background: canvasBackground,
  );
}