import 'dart:ui';

import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/editor/editor_types.dart';

/// Everything a sub-painter needs to draw the current frame.
class PaintContext {
  const PaintContext({
    required this.model,
    required this.toScreen,
    required this.selectedType,
    required this.selectedId,
  });

  final StructuralModel model;

  /// Converts model coordinates (meters) to screen coordinates (px).
  final Offset Function(Offset) toScreen;
  final SelectedType selectedType;
  final int? selectedId;

  bool isSelected(SelectedType type, int id) =>
      selectedType == type && selectedId == id;
}