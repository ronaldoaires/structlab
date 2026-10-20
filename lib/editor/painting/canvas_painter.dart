import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/painting/dimension_painter.dart';
import 'package:structlab/editor/painting/grid_painter.dart';
import 'package:structlab/editor/painting/load_painter.dart';
import 'package:structlab/editor/painting/member_painter.dart';
import 'package:structlab/editor/painting/paint_context.dart';
import 'package:structlab/editor/painting/preview_painter.dart';
import 'package:structlab/editor/painting/support_painter.dart';

/// Draws the whole editor canvas by calling the specialized painters.
class StructuralCanvasPainter extends CustomPainter {
  StructuralCanvasPainter({
    required this.model,
    required this.selectedType,
    required this.selectedId,
    required this.pendingStart,
    required this.previewEnd,
    required this.pendingLoadNodeId,
    required this.modelToScreen,
    this.flaggedNodeIds = const {},
    this.flaggedMemberIds = const {},
  });

  final StructuralModel model;
  final SelectedType selectedType;
  final int? selectedId;
  final Offset? pendingStart;
  final Offset? previewEnd;
  final int? pendingLoadNodeId;
  final Offset Function(Offset) modelToScreen;
  final Set<int> flaggedNodeIds;
  final Set<int> flaggedMemberIds;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = canvasBackground);

    final ctx = PaintContext(
      model: model,
      toScreen: modelToScreen,
      selectedType: selectedType,
      selectedId: selectedId,
      flaggedNodeIds: flaggedNodeIds,
      flaggedMemberIds: flaggedMemberIds,
    );

    // Where the model origin is on screen and how many px a meter takes.
    final origin = modelToScreen(Offset.zero);
    final scale = modelToScreen(const Offset(1, 0)).dx - origin.dx;

    drawGrid(canvas, size, origin, scale);
    drawAxes(canvas, size, origin);
    drawMembers(canvas, ctx);
    drawSupports(canvas, ctx);
    drawLoads(canvas, ctx);
    drawNodes(canvas, ctx);
    drawDimensions(canvas, ctx);
    drawBeamPreview(canvas, ctx, pendingStart, previewEnd);
    drawPendingStart(canvas, ctx, pendingStart);
    drawPendingLoad(canvas, ctx, pendingLoadNodeId);
  }

  @override
  bool shouldRepaint(covariant StructuralCanvasPainter oldDelegate) => true;
}