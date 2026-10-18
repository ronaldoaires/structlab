import 'package:flutter/material.dart';
import 'package:structlab/core/constants.dart';

void drawGrid(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = const Color(0xFFE8EDF4)
    ..strokeWidth = 0.7;
  const spacing = pixelsPerMeter / 2;
  for (double x = size.width / 2 % spacing; x < size.width; x += spacing) {
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }
  for (double y = size.height / 2 % spacing; y < size.height; y += spacing) {
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
}

void drawAxes(Canvas canvas, Size size) {
  final paint = Paint()
    ..color = const Color(0xFFD5DDE8)
    ..strokeWidth = 1;
  canvas.drawLine(
    Offset(0, size.height / 2),
    Offset(size.width, size.height / 2),
    paint,
  );
  canvas.drawLine(
    Offset(size.width / 2, 0),
    Offset(size.width / 2, size.height),
    paint,
  );
}