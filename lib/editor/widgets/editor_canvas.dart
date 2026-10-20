import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/painting/canvas_painter.dart';

/// The drawing area. One finger goes to the active tool; two fingers (or the
/// mouse wheel) zoom and pan the view.
class EditorCanvas extends StatefulWidget {
  const EditorCanvas({super.key, required this.controller});

  final EditorController controller;

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  final Map<int, Offset> _pointers = {};
  bool _navigating = false;

  EditorController get _c => widget.controller;

  Offset _screenToModel(Offset p, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final v = (p - center - _c.pan) / _c.pxPerMeter;
    return Offset(v.dx, -v.dy);
  }

  Offset _modelToScreen(Offset m, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    return center + _c.pan + Offset(m.dx, -m.dy) * _c.pxPerMeter;
  }

  /// Center and distance of the first two fingers.
  ({Offset focal, double dist}) _pair() {
    final pts = _pointers.values.take(2).toList();
    return (focal: (pts[0] + pts[1]) / 2, dist: (pts[0] - pts[1]).distance);
  }

  void _down(PointerDownEvent e, Size size) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 1 && !_navigating) {
      _c.pointerDown(e.localPosition, _screenToModel(e.localPosition, size));
    } else if (_pointers.length >= 2 && !_navigating) {
      // A second finger turns the gesture into navigation.
      _navigating = true;
      _c.pointerCancel();
    }
  }

  void _move(PointerMoveEvent e, Size size) {
    if (!_pointers.containsKey(e.pointer)) return;
    if (_navigating) {
      if (_pointers.length < 2) {
        _pointers[e.pointer] = e.localPosition;
        return;
      }
      final before = _pair();
      _pointers[e.pointer] = e.localPosition;
      final after = _pair();
      if (before.dist > 0) {
        _c.navigate(
          prevFocal: before.focal,
          focal: after.focal,
          scaleFactor: after.dist / before.dist,
          size: size,
        );
      }
      return;
    }
    _pointers[e.pointer] = e.localPosition;
    _c.pointerMove(e.localPosition, _screenToModel(e.localPosition, size));
  }

  void _up(PointerUpEvent e, Size size) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers.remove(e.pointer);
    if (!_navigating) {
      _c.pointerUp(e.localPosition, _screenToModel(e.localPosition, size));
    }
    if (_pointers.isEmpty) _navigating = false;
  }

  void _cancel(PointerCancelEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers.remove(e.pointer);
    if (!_navigating) _c.pointerCancel();
    if (_pointers.isEmpty) _navigating = false;
  }

  void _signal(PointerSignalEvent e, Size size) {
    if (e is PointerScrollEvent) {
      _c.navigate(
        prevFocal: e.localPosition,
        focal: e.localPosition,
        scaleFactor: math.exp(-e.scrollDelta.dy / 300),
        size: size,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _down(e, size),
          onPointerMove: (e) => _move(e, size),
          onPointerUp: (e) => _up(e, size),
          onPointerCancel: _cancel,
          onPointerSignal: (e) => _signal(e, size),
          child: CustomPaint(
            size: Size.infinite,
            painter: StructuralCanvasPainter(
              model: c.model,
              selectedType: c.selectedType,
              selectedId: c.selectedId,
              pendingStart: c.pendingBeamStart,
              previewEnd: c.previewEnd,
              pendingLoadNodeId: c.pendingLoadNodeId,
              modelToScreen: (point) => _modelToScreen(point, size),
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}