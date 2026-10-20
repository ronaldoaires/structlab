import 'package:flutter/material.dart';

/// Single drawing of the fixed support (engaste), shared by the canvas and
/// the toolbar/menu icon so both always look the same.
///
/// [origin] is the node point (top of the stem). The shape grows downward
/// (support "below" the node) and is scaled by [unit] (1 = canvas pixels).
void drawFixedSupportShape(
  Canvas canvas,
  Offset origin,
  double unit,
  Paint stroke,
) {
  const stem = 16.0; // node -> base line
  const half = 13.0; // half width of the base line
  const hatchDx = -6.0;
  const hatchDy = 9.0;

  Offset p(double x, double y) => origin + Offset(x * unit, y * unit);

  // Stem (the "tail") from the node down to the base line.
  canvas.drawLine(p(0, 0), p(0, stem), stroke);
  // Base line.
  canvas.drawLine(p(-half, stem), p(half, stem), stroke);
  // 4 hatch marks.
  for (final x in const [-9.0, -3.0, 3.0, 9.0]) {
    canvas.drawLine(p(x, stem), p(x + hatchDx, stem + hatchDy), stroke);
  }
}