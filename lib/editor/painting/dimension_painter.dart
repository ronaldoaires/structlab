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

/// Tolerance (meters) to treat a member as horizontal or vertical.
const double _axisTol = 1e-6;

/// Distance (px) of the horizontal leg below the node level.
const double _legOffsetBelow = 44;

/// Distance (px) of the vertical leg from its column.
const double _legOffsetSide = 36;

/// Same, when there are members on both sides of the column.
const double _legOffsetBothSides = 24;

const Color _dimColor = Color(0xFF64748B);

bool _isInclined(Offset a, Offset b) =>
    (b.dx - a.dx).abs() > _axisTol && (b.dy - a.dy).abs() > _axisTol;

/// Rounds a coordinate to millimeters so it can be used as a map key.
int _key(double v) => (v * 1000).round();

/// A range of a leg (model coordinates) that belongs to one member.
class _Span {
  const _Span(this.from, this.to, this.selected);

  final double from;
  final double to;
  final bool selected;
}

/// All legs on the same line: a horizontal level (y) or a vertical column (x).
class _Group {
  _Group(this.at);

  final double at;
  final List<_Span> spans = [];

  /// Vertical groups only: > 0 when the members lie to the right of the
  /// column, < 0 to the left, 0 when on both sides.
  double side = 0;
}

typedef _Segment = ({double from, double to, bool selected});

/// Splits the spans of a group at every breakpoint, so overlapping legs
/// become a chain that only shows the difference (e.g. 2 m + 1 m).
List<_Segment> _chain(List<_Span> spans) {
  final points = <double>{
    for (final s in spans) ...[s.from, s.to],
  }.toList()..sort();
  final result = <_Segment>[];
  for (var i = 0; i < points.length - 1; i++) {
    final lo = points[i];
    final hi = points[i + 1];
    if (hi - lo < _axisTol) continue;
    final mid = (lo + hi) / 2;
    final covering = spans.where((s) => s.from <= mid && mid <= s.to);
    if (covering.isEmpty) continue;
    result.add((from: lo, to: hi, selected: covering.any((s) => s.selected)));
  }
  return result;
}

/// Normal that points down on screen (to the right for a vertical member).
Offset _dimensionNormal(Offset dir) {
  var normal = Offset(-dir.dy, dir.dx);
  if (normal.dy < -1e-6 || (normal.dy.abs() <= 1e-6 && normal.dx < 0)) {
    normal = -normal;
  }
  return normal;
}

/// Dimensions drawn in technical drawing style.
/// - Horizontal or vertical member: one dimension parallel to the member.
/// - Inclined member: two legs (horizontal at the lower node level, vertical
///   at the column of the higher node). Legs on the same line are chained,
///   so only the differences are shown.
void drawDimensions(Canvas canvas, PaintContext ctx) {
  final horizontal = <int, _Group>{};
  final vertical = <int, _Group>{};

  for (final member in ctx.model.members) {
    final startNode = ctx.model.nodeById(member.startNodeId);
    final endNode = ctx.model.nodeById(member.endNodeId);
    if (startNode == null || endNode == null) continue;
    final pa = startNode.position;
    final pb = endNode.position;
    final selected = ctx.isSelected(SelectedType.member, member.id);

    if (!_isInclined(pa, pb) ||
        member.dimensionStyle == DimensionStyle.length) {
      final length = (pb - pa).distance;
      final a = ctx.toScreen(pa);
      final b = ctx.toScreen(pb);
      _drawDimension(
        canvas,
        a,
        b,
        '${length.toStringAsFixed(2)} m',
        selected ? brandBlue : _dimColor,
        _dimensionOffset(ctx, member, a, b),
      );
      continue;
    }

    final aIsLow = pa.dy < pb.dy;
    final low = aIsLow ? pa : pb;
    final high = aIsLow ? pb : pa;

    final h = horizontal.putIfAbsent(_key(low.dy), () => _Group(low.dy));
    h.spans.add(
      _Span(math.min(pa.dx, pb.dx), math.max(pa.dx, pb.dx), selected),
    );

    final v = vertical.putIfAbsent(_key(high.dx), () => _Group(high.dx));
    v.spans.add(_Span(low.dy, high.dy, selected));
    v.side += (low.dx - high.dx).sign;
  }

  _drawLegs(canvas, ctx, horizontal, vertical);
}

void _drawLegs(
  Canvas canvas,
  PaintContext ctx,
  Map<int, _Group> horizontal,
  Map<int, _Group> vertical,
) {
  Color colorOf(bool selected) => selected ? brandBlue : _dimColor;

  for (final g in horizontal.values) {
    for (final s in _chain(g.spans)) {
      _drawDimension(
        canvas,
        ctx.toScreen(Offset(s.from, g.at)),
        ctx.toScreen(Offset(s.to, g.at)),
        '${(s.to - s.from).toStringAsFixed(2)} m',
        colorOf(s.selected),
        _legOffsetBelow,
      );
    }
  }

  for (final g in vertical.values) {
    // The line goes on the side with no members (left when on both sides).
    final normal = g.side < 0 ? const Offset(1, 0) : const Offset(-1, 0);
    final offset = g.side == 0 ? _legOffsetBothSides : _legOffsetSide;
    for (final s in _chain(g.spans)) {
      _drawDimension(
        canvas,
        ctx.toScreen(Offset(g.at, s.from)),
        ctx.toScreen(Offset(g.at, s.to)),
        '${(s.to - s.from).toStringAsFixed(2)} m',
        colorOf(s.selected),
        offset,
        normalOverride: normal,
      );
    }
  }
}

/// How far the dimension line must be from the member so it does not collide
/// with loads (arrows and their labels) drawn on the same side.
double _dimensionOffset(
  PaintContext ctx,
  StructuralMember member,
  Offset a,
  Offset b,
) {
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
      final clearance = concentratedClearancePx(
        load,
        loads,
        ctx.model.nodeById,
      );
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

void _drawDimension(
  Canvas canvas,
  Offset a,
  Offset b,
  String text,
  Color color,
  double offset, {
  Offset? normalOverride,
}) {
  final delta = b - a;
  final dist = delta.distance;
  if (dist < 1) return;
  final dir = delta / dist;
  final normal = normalOverride ?? _dimensionNormal(dir);

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

  // Text aligned with the dimension line, always readable.
  drawLabel(
    canvas,
    text,
    Offset((a2.dx + b2.dx) / 2, (a2.dy + b2.dy) / 2),
    color: color,
    angle: readableAngle(math.atan2(dir.dy, dir.dx)),
    background: canvasBackground,
  );
}
