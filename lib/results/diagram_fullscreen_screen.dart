import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:structlab/analysis/internal_forces/internal_forces_model.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/l10n/strings_internal_forces_pt.dart';
import 'package:structlab/results/widgets/force_diagram.dart';
import 'package:structlab/results/widgets/diagram_legend.dart';

/// One diagram (V, M or N) on a full screen, with pinch zoom, pan and
/// tap-to-read, like the drawing canvas.
class DiagramFullScreen extends StatefulWidget {
  const DiagramFullScreen({
    super.key,
    required this.model,
    required this.result,
    required this.kind,
    required this.labels,
  });

  final StructuralModel model;
  final InternalForcesResult result;
  final InternalForceKind kind;
  final ModelLabels labels;

  @override
  State<DiagramFullScreen> createState() => _DiagramFullScreenState();
}

class _DiagramFullScreenState extends State<DiagramFullScreen> {
  static const double _minZoom = 0.5;
  static const double _maxZoom = 8.0;
  static const double _maxOrdinatePx = 80;

  double _zoom = 1;
  Offset _pan = Offset.zero;
  Size _size = Size.zero;
  DiagramSelection? _selection;

  // Gesture start state.
  double _startZoom = 1;
  Offset _startPan = Offset.zero;
  Offset _startFocal = Offset.zero;

  Offset get _center => Offset(_size.width / 2, _size.height / 2);

  DiagramGeometry _geometry() => DiagramGeometry(
        model: widget.model,
        size: _size,
        kind: widget.kind,
        maxAbs: widget.result.maxAbs(widget.kind),
        zoom: _zoom,
        pan: _pan,
        maxOrdinatePx: _maxOrdinatePx,
      );

  void _onScaleStart(ScaleStartDetails d) {
    _startZoom = _zoom;
    _startPan = _pan;
    _startFocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final anchor = (_startFocal - _center - _startPan) / _startZoom;
    final zoom = (_startZoom * d.scale).clamp(_minZoom, _maxZoom).toDouble();
    setState(() {
      _zoom = zoom;
      _pan = d.localFocalPoint - _center - anchor * zoom;
    });
  }

  void _onSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final anchor = (e.localPosition - _center - _pan) / _zoom;
    final zoom = (_zoom * math.exp(-e.scrollDelta.dy / 300))
        .clamp(_minZoom, _maxZoom)
        .toDouble();
    setState(() {
      _zoom = zoom;
      _pan = e.localPosition - _center - anchor * zoom;
    });
  }

  void _fit() => setState(() {
        _zoom = 1;
        _pan = Offset.zero;
      });

  void _pick(Offset position) {
    final hit = _geometry().hitTest(widget.result, position);
    if (hit == null) return;
    setState(() => _selection = hit);
  }

  String _reading() {
    final s = _selection;
    final f = s == null ? null : widget.result.forMember(s.memberId);
    if (s == null || f == null) return diagramZoomHint;
    return diagramReading(
      widget.labels.member(s.memberId),
      s.x,
      widget.kind,
      f.valueAt(widget.kind, s.x),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(forceKindTitle(widget.kind)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: diagramFitTooltip,
            onPressed: _fit,
            icon: const Icon(Icons.center_focus_strong_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _size = Size(constraints.maxWidth, constraints.maxHeight);
                  final geometry = _geometry();
                  return ClipRect(
                    child: Listener(
                      onPointerSignal: _onSignal,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                        onTapUp: (d) => _pick(d.localPosition),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: ForceDiagramPainter(
                            geometry: geometry,
                            result: widget.result,
                            labels: widget.labels,
                            samples: const {},
                            selection: _selection,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: lineColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DiagramLegend(kind: widget.kind),
                  const SizedBox(height: 8),
                  Text(
                    _reading(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: brandBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}