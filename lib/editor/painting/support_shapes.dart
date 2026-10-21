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

/// Single drawing of the pin support (apoio de segundo gênero), in the
/// FTool style: triangle sitting on a base line with hatch marks below.
///
/// [origin] is the node point (apex). The shape grows downward and is scaled
/// by [unit] (1 = canvas pixels). When [fill] is given, the triangle is
/// filled before being stroked.
void drawPinSupportShape(
  Canvas canvas,
  Offset origin,
  double unit,
  Paint stroke, {
  Paint? fill,
}) {
  const apexGap = 2.0; // small gap between the node and the apex
  const height = 20.0; // node -> base line
  const triHalf = 12.0; // half width of the triangle base
  const lineHalf = 15.0; // half width of the base line
  const hatchDx = -4.0;
  const hatchDy = 7.0;

  Offset p(double x, double y) => origin + Offset(x * unit, y * unit);

  final triangle = Path()
    ..moveTo(p(0, apexGap).dx, p(0, apexGap).dy)
    ..lineTo(p(-triHalf, height).dx, p(-triHalf, height).dy)
    ..lineTo(p(triHalf, height).dx, p(triHalf, height).dy)
    ..close();
  if (fill != null) canvas.drawPath(triangle, fill);
  canvas.drawPath(triangle, stroke);

  // Base line.
  canvas.drawLine(p(-lineHalf, height), p(lineHalf, height), stroke);
  // 5 hatch marks.
  for (final x in const [-12.0, -6.0, 0.0, 6.0, 12.0]) {
    canvas.drawLine(p(x, height), p(x + hatchDx, height + hatchDy), stroke);
  }
}