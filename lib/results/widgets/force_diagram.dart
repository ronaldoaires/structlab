import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:structlab/analysis/internal_forces/internal_forces_model.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/core/format_number.dart';
import 'package:structlab/core/geometry.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/editor/painting/paint_utils.dart';
import 'package:structlab/l10n/strings_internal_forces_pt.dart';

/// Longest ordinate of the diagram, in px.
const double _maxOrdinatePx = 52;

/// Point of the diagram picked by the user.
class DiagramSelection {
  const DiagramSelection(this.memberId, this.x);

  final int memberId;
  final double x;
}

/// Converts model coordinates to the canvas and members/values to diagram
/// points. Shared by the painter and the touch handling.
class DiagramGeometry {
  DiagramGeometry({
    required this.model,
    required Size size,
    required this.kind,
    required double maxAbs,
  }) {
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final n in model.nodes) {
      minX = math.min(minX, n.position.dx);
      maxX = math.max(maxX, n.position.dx);
      minY = math.min(minY, n.position.dy);
      maxY = math.max(maxY, n.position.dy);
    }
    if (model.nodes.isEmpty) {
      minX = maxX = minY = maxY = 0;
    }
    const margin = 64.0;
    final w = math.max(maxX - minX, 0.5);
    final h = math.max(maxY - minY, 0.5);
    final availW = math.max(40.0, size.width - 2 * margin);
    final availH = math.max(40.0, size.height - 2 * margin);
    scale = math.min(math.min(availW / w, availH / h), 90.0);
    _mid = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    _center = Offset(size.width / 2, size.height / 2);
    pxPerUnit = maxAbs > 1e-9 ? _maxOrdinatePx / maxAbs : 0;
  }

  final StructuralModel model;
  final InternalForceKind kind;

  /// Pixels per meter of the structure.
  late final double scale;

  /// Pixels per kN (or kN·m) of the diagram.
  late final double pxPerUnit;

  late final Offset _mid;
  late final Offset _center;

  /// Moments are drawn on the tensioned side (opposite to n).
  double get side => kind == InternalForceKind.moment ? -1 : 1;

  Offset toScreen(Offset p) => Offset(
        _center.dx + (p.dx - _mid.dx) * scale,
        _center.dy - (p.dy - _mid.dy) * scale,
      );

  double _rad(MemberInternalForces f) => f.angleDegrees * math.pi / 180;

  /// Point of the member axis at distance [x] from its start.
  Offset basePoint(MemberInternalForces f, double x) {
    final left = model.nodeById(f.startNodeId)!.position;
    final r = _rad(f);
    return toScreen(left + Offset(math.cos(r), math.sin(r)) * x);
  }

  /// n (left of the member direction) in screen coordinates.
  Offset normalScreen(MemberInternalForces f) {
    final r = _rad(f);
    return Offset(-math.sin(r), -math.cos(r));
  }

  Offset ordinatePoint(MemberInternalForces f, double x) =>
      basePoint(f, x) +
      normalScreen(f) * (f.valueAt(kind, x) * pxPerUnit * side);

  /// Direction pointing away from the member, on the side of the ordinate.
  Offset outward(MemberInternalForces f, double value) =>
      normalScreen(f) * (side * (value >= 0 ? 1 : -1));

  /// The point of the diagram closest to [p] (null when too far).
  DiagramSelection? hitTest(InternalForcesResult result, Offset p) {
    DiagramSelection? best;
    var bestDistance = 40.0;
    for (final f in result.members) {
      final a = basePoint(f, 0);
      final b = basePoint(f, f.length);
      final axis = b - a;
      final len2 = axis.dx * axis.dx + axis.dy * axis.dy;
      if (len2 < 1e-9) continue;
      final t = (dot2(p - a, axis) / len2).clamp(0.0, 1.0).toDouble();
      final x = f.length * t;
      final d = distanceToSegment(p, basePoint(f, x), ordinatePoint(f, x));
      if (d < bestDistance) {
        bestDistance = d;
        best = DiagramSelection(f.memberId, x);
      }
    }
    return best;
  }
}

class ForceDiagramPainter extends CustomPainter {
  ForceDiagramPainter({
    required this.geometry,
    required this.result,
    required this.labels,
    required this.samples,
    required this.selection,
  });

  final DiagramGeometry geometry;
  final InternalForcesResult result;
  final ModelLabels labels;

  /// Points chosen by the user, by member id.
  final Map<int, List<double>> samples;
  final DiagramSelection? selection;

  static const Color _diagramColor = brandBlue;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    canvas.drawRect(Offset.zero & size, Paint()..color = canvasBackground);

    final axis = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final f in result.members) {
      canvas.drawLine(g.basePoint(f, 0), g.basePoint(f, f.length), axis);
    }

    if (g.pxPerUnit > 0) {
      for (final f in result.members) {
        _drawMember(canvas, f);
      }
    }

    for (final n in g.model.nodes) {
      final p = g.toScreen(n.position);
      canvas.drawCircle(p, 3.5, Paint()..color = inkMuted);
      drawLabel(
        canvas,
        labels.node(n.id),
        p + const Offset(-10, -10),
        color: inkMuted,
        fontSize: 10,
      );
    }

    _drawSelection(canvas);
  }

  void _drawMember(Canvas canvas, MemberInternalForces f) {
    final g = geometry;
    const steps = 40;
    final points = [
      for (var i = 0; i <= steps; i++)
        g.ordinatePoint(f, f.length * i / steps),
    ];
    final start = g.basePoint(f, 0);
    final end = g.basePoint(f, f.length);

    final fill = Path()..moveTo(start.dx, start.dy);
    final outline = Path()..moveTo(start.dx, start.dy);
    for (final p in points) {
      fill.lineTo(p.dx, p.dy);
      outline.lineTo(p.dx, p.dy);
    }
    fill
      ..lineTo(end.dx, end.dy)
      ..close();
    outline.lineTo(end.dx, end.dy);

    canvas.drawPath(fill, Paint()..color = _diagramColor.withValues(alpha: 0.12));
    canvas.drawPath(
      outline,
      Paint()
        ..color = _diagramColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // Value labels: both ends and the extreme in the middle, when it stands out.
    void label(double x) {
      final v = f.valueAt(geometry.kind, x);
      if (v.abs() < 1e-6) return;
      drawLabel(
        canvas,
        formatNumber(v),
        g.ordinatePoint(f, x) + g.outward(f, v) * 12,
        color: _diagramColor,
        fontSize: 10,
        background: canvasBackground,
      );
    }

    label(0);
    label(f.length);
    var extremeIndex = 0;
    var extreme = 0.0;
    for (var i = 1; i < steps; i++) {
      final v = f.valueAt(geometry.kind, f.length * i / steps).abs();
      if (v > extreme) {
        extreme = v;
        extremeIndex = i;
      }
    }
    final endMax = math.max(
      f.valueAt(geometry.kind, 0).abs(),
      f.valueAt(geometry.kind, f.length).abs(),
    );
    if (extremeIndex > 0 && extreme > endMax * 1.05 + 1e-6) {
      label(f.length * extremeIndex / steps);
    }

    // Points of the table.
    for (final x in samples[f.memberId] ?? const <double>[]) {
      final p = g.ordinatePoint(f, x);
      canvas.drawCircle(p, 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        3.5,
        Paint()
          ..color = _diagramColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  void _drawSelection(Canvas canvas) {
    final s = selection;
    if (s == null) return;
    final f = result.forMember(s.memberId);
    if (f == null) return;
    final base = geometry.basePoint(f, s.x);
    final tip = geometry.ordinatePoint(f, s.x);
    canvas.drawLine(
      base,
      tip,
      Paint()
        ..color = const Color(0xFFD9485F)
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(tip, 5, Paint()..color = const Color(0xFFD9485F));
    canvas.drawCircle(base, 3, Paint()..color = const Color(0xFFD9485F));
  }

  @override
  bool shouldRepaint(covariant ForceDiagramPainter oldDelegate) => true;
}

/// The diagram plus the reading of the touched point.
class ForceDiagramView extends StatefulWidget {
  const ForceDiagramView({
    super.key,
    required this.model,
    required this.result,
    required this.kind,
    required this.labels,
    required this.samples,
  });

  final StructuralModel model;
  final InternalForcesResult result;
  final InternalForceKind kind;
  final ModelLabels labels;
  final Map<int, List<double>> samples;

  @override
  State<ForceDiagramView> createState() => _ForceDiagramViewState();
}

class _ForceDiagramViewState extends State<ForceDiagramView> {
  DiagramSelection? _selection;

  void _pick(DiagramGeometry geometry, Offset position) {
    final hit = geometry.hitTest(widget.result, position);
    if (hit == null) return;
    setState(() => _selection = hit);
  }

  String _reading() {
    final s = _selection;
    final f = s == null ? null : widget.result.forMember(s.memberId);
    if (s == null || f == null) return diagramHint;
    return diagramReading(
      widget.labels.member(s.memberId),
      s.x,
      widget.kind,
      f.valueAt(widget.kind, s.x),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final geometry = DiagramGeometry(
                  model: widget.model,
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  kind: widget.kind,
                  maxAbs: widget.result.maxAbs(widget.kind),
                );
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _pick(geometry, d.localPosition),
                  onPanUpdate: (d) => _pick(geometry, d.localPosition),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: ForceDiagramPainter(
                      geometry: geometry,
                      result: widget.result,
                      labels: widget.labels,
                      samples: widget.samples,
                      selection: _selection,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _reading(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: brandBlue,
          ),
        ),
      ],
    );
  }
}