import 'dart:ui';

Offset unitVec(Offset v) {
  final d = v.distance;
  return d == 0 ? Offset.zero : v / d;
}

double cross2(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;

double dot2(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

bool pointInPolygon(Offset p, List<Offset> poly) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i];
    final b = poly[j];
    final crosses = (a.dy > p.dy) != (b.dy > p.dy) &&
        p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx;
    if (crosses) inside = !inside;
  }
  return inside;
}

double distanceToSegment(Offset point, Offset start, Offset end) {
  final segment = end - start;
  final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
  if (lengthSquared == 0) return (point - start).distance;
  final pointVector = point - start;
  final t = ((pointVector.dx * segment.dx + pointVector.dy * segment.dy) /
          lengthSquared)
      .clamp(0.0, 1.0)
      .toDouble();
  final projection = Offset(
    start.dx + segment.dx * t,
    start.dy + segment.dy * t,
  );
  return (point - projection).distance;
}