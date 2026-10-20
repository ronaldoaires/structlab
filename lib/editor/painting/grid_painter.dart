import 'package:flutter/material.dart';

/// Grid every 0.5 m. [origin] is where model (0,0) is on screen and [scale]
/// is the pixels per meter at the current zoom.
void drawGrid(Canvas canvas, Size size, Offset origin, double scale) {
  final spacing = scale / 2;
  if (spacing < 6) return; // too dense to be useful
  final paint = Paint()
    ..color = const Color(0xFFE8EDF4)
    ..strokeWidth = 0.7;
  for (double x = origin.dx % spacing; x < size.width; x += spacing) {
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }
  for (double y = origin.dy % spacing; y < size.height; y += spacing) {
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
}

void drawAxes(Canvas canvas, Size size, Offset origin) {
  final paint = Paint()
    ..color = const Color(0xFFD5DDE8)
    ..strokeWidth = 1;
  canvas.drawLine(
    Offset(0, origin.dy),
    Offset(size.width, origin.dy),
    paint,
  );
  canvas.drawLine(
    Offset(origin.dx, 0),
    Offset(origin.dx, size.height),
    paint,
  );
}