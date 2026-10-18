import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/painting/paint_context.dart';

void drawMembers(Canvas canvas, PaintContext ctx) {
  for (final member in ctx.model.members) {
    final startNode = ctx.model.nodeById(member.startNodeId);
    final endNode = ctx.model.nodeById(member.endNodeId);
    if (startNode == null || endNode == null) continue;
    final start = ctx.toScreen(startNode.position);
    final end = ctx.toScreen(endNode.position);
    final selected = ctx.isSelected(SelectedType.member, member.id);
    if (selected) {
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFFB8C8FF)
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = selected ? brandBlue : const Color(0xFF3155C6)
        ..strokeWidth = selected ? 4 : 3
        ..strokeCap = StrokeCap.round,
    );
  }
}

void drawNodes(Canvas canvas, PaintContext ctx) {
  for (final node in ctx.model.nodes) {
    final point = ctx.toScreen(node.position);
    final selected = ctx.isSelected(SelectedType.node, node.id);
    canvas.drawCircle(
      point,
      selected ? 6 : 4.5,
      Paint()..color = selected ? const Color(0xFFD9485F) : brandBlue,
    );
    canvas.drawCircle(
      point,
      selected ? 8 : 6.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }
}