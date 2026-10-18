import 'package:flutter/material.dart';
import 'package:structlab/core/constants.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/painting/canvas_painter.dart';

/// The drawing area. Converts touches to model coordinates and forwards them
/// to the controller. Zoom and pan will be added here later.
class EditorCanvas extends StatelessWidget {
  const EditorCanvas({super.key, required this.controller});

  final EditorController controller;

  Offset _screenToModel(Offset point, Size size) => Offset(
        (point.dx - size.width / 2) / pixelsPerMeter,
        (size.height / 2 - point.dy) / pixelsPerMeter,
      );

  Offset _modelToScreen(Offset point, Size size) => Offset(
        size.width / 2 + point.dx * pixelsPerMeter,
        size.height / 2 - point.dy * pixelsPerMeter,
      );

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => c.pointerDown(
                  e.localPosition, _screenToModel(e.localPosition, size)),
              onPointerMove: (e) => c.pointerMove(
                  e.localPosition, _screenToModel(e.localPosition, size)),
              onPointerUp: (e) => c.pointerUp(
                  e.localPosition, _screenToModel(e.localPosition, size)),
              onPointerCancel: (_) => c.pointerCancel(),
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
        ),
      ),
    );
  }
}