import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Number of radial control points sampled around the shape.
/// 72 is the primary resolution; can be reduced to 48 if lower-end device performance requires it.
const int kDefaultRadialPoints = 72;
const double kTau = math.pi * 2;

enum ShapeName { blob, ring, burst, cluster, shield }

const List<ShapeName> kShapeNames = [
  ShapeName.blob,
  ShapeName.ring,
  ShapeName.burst,
  ShapeName.cluster,
  ShapeName.shield,
];

/// Calculates the normalized radius r(θ) for a given shape at angle [a] in radians.
double radiusFor(ShapeName shape, double a) {
  switch (shape) {
    case ShapeName.blob:
      return 1.0 + 0.095 * math.sin(3 * a + 0.4) + 0.06 * math.cos(2 * a + 1.1);
    case ShapeName.ring:
      return 1.0;
    case ShapeName.burst:
      const spikes = 6;
      final t = math.cos(spikes * a);
      final sharp = t.sign * math.pow(t.abs(), 0.55);
      return 0.72 + 0.34 * sharp;
    case ShapeName.cluster:
      const lobes = 5;
      final t = math.cos(lobes * (a + math.pi / 2));
      final soft = t.sign * math.pow(t.abs(), 0.85);
      return 0.86 + 0.20 * soft;
    case ShapeName.shield:
      // Padlock silhouette
      final cosA = math.cos(a);
      final sinA = math.sin(a);
      final n = 8.0;
      
      if (sinA >= 0) {
        // Bottom body: w = 0.75, h = 0.6
        return 1.0 / math.pow(math.pow(cosA.abs() / 0.75, n) + math.pow(sinA.abs() / 0.6, n), 1.0 / n);
      } else {
        // Top half: body shoulders (w = 0.75, h = 0.4) + shackle (w = 0.4, h = 0.9)
        final rBody = 1.0 / math.pow(math.pow(cosA.abs() / 0.75, n) + math.pow(sinA.abs() / 0.4, n), 1.0 / n);
        final rShackle = 1.0 / math.pow(math.pow(cosA.abs() / 0.4, 4.0) + math.pow(sinA.abs() / 0.9, 4.0), 1.0 / 4.0); 
        return math.max(rBody, rShackle);
      }
  }
}

/// Inner hole radius fraction per shape (0.0 = solid, >0.0 = ring/donut).
double innerScaleFor(ShapeName shape) {
  switch (shape) {
    case ShapeName.blob:
      return 0.0;
    case ShapeName.ring:
      return 0.62;
    case ShapeName.burst:
      return 0.26;
    case ShapeName.cluster:
      return 0.34;
    case ShapeName.shield:
      return 0.15;
  }
}

/// Pre-samples radial control points for all 5 shapes at resolution [n].
Map<ShapeName, List<double>> generateRadiiTable([int n = kDefaultRadialPoints]) {
  final map = <ShapeName, List<double>>{};
  for (final shape in kShapeNames) {
    map[shape] = List<double>.generate(n, (i) => radiusFor(shape, (i / n) * kTau));
  }
  return map;
}

final Map<ShapeName, List<double>> kRadii72 = generateRadiiTable(72);
final Map<ShapeName, List<double>> kRadii48 = generateRadiiTable(48);

/// Constructs a closed [Path] passing smoothly through [pts] using Catmull-Rom cubic Beziers.
Path catmullRomClosed(List<Offset> pts) {
  final path = Path();
  final n = pts.length;
  if (n == 0) return path;

  path.moveTo(pts[0].dx, pts[0].dy);
  for (int i = 0; i < n; i++) {
    final p0 = pts[(i - 1 + n) % n];
    final p1 = pts[i];
    final p2 = pts[(i + 1) % n];
    final p3 = pts[(i + 2) % n];

    final c1 = Offset(
      p1.dx + (p2.dx - p0.dx) / 6.0,
      p1.dy + (p2.dy - p0.dy) / 6.0,
    );
    final c2 = Offset(
      p2.dx - (p3.dx - p1.dx) / 6.0,
      p2.dy - (p3.dy - p1.dy) / 6.0,
    );

    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  path.close();
  return path;
}

/// Constructs an open [Path] passing smoothly through [pts] using Catmull-Rom cubic Beziers.
Path catmullRomOpen(List<Offset> pts) {
  final path = Path();
  final n = pts.length;
  if (n < 2) return path;

  path.moveTo(pts[0].dx, pts[0].dy);
  for (int i = 0; i < n - 1; i++) {
    final p0 = pts[math.max(0, i - 1)];
    final p1 = pts[i];
    final p2 = pts[i + 1];
    final p3 = pts[math.min(n - 1, i + 2)];

    final c1 = Offset(
      p1.dx + (p2.dx - p0.dx) / 6.0,
      p1.dy + (p2.dy - p0.dy) / 6.0,
    );
    final c2 = Offset(
      p2.dx - (p3.dx - p1.dx) / 6.0,
      p2.dy - (p3.dy - p1.dy) / 6.0,
    );

    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path;
}

/// Builds the morphed closed outline [Path] at continuous fractional shape index [index].
/// E.g. index = 1.37 represents 37% lerp from ring (1) to burst (2).
Path buildMorphedPath(
  double index, {
  required Offset center,
  required double radius,
  int pointCount = 72,
}) {
  final clamped = index.clamp(0.0, (kShapeNames.length - 1).toDouble());
  final i0 = clamped.floor();
  final i1 = math.min(kShapeNames.length - 1, i0 + 1);
  final t = clamped - i0;

  final shape0 = kShapeNames[i0];
  final shape1 = kShapeNames[i1];

  final radiiTable = pointCount == 48 ? kRadii48 : kRadii72;
  final a = radiiTable[shape0]!;
  final b = radiiTable[shape1]!;

  final inner0 = innerScaleFor(shape0);
  final inner1 = innerScaleFor(shape1);

  final lerpedOuterRadii = List<double>.generate(
    pointCount,
    (i) => a[i] + (b[i] - a[i]) * t,
  );
  final lerpedInnerScale = inner0 + (inner1 - inner0) * t;

  final outerPts = List<Offset>.generate(pointCount, (i) {
    final angle = (i / pointCount) * kTau;
    final r = lerpedOuterRadii[i] * radius;
    return Offset(center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r);
  });

  final path = catmullRomClosed(outerPts);

  if (lerpedInnerScale > 0.02) {
    // Reverse inner loop for even-odd hole rendering
    final innerPts = List<Offset>.generate(pointCount, (i) {
      final revIndex = pointCount - 1 - i;
      final angle = (revIndex / pointCount) * kTau;
      final r = lerpedOuterRadii[revIndex] * lerpedInnerScale * radius;
      return Offset(center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r);
    });

    final innerPath = catmullRomClosed(innerPts);
    path.fillType = PathFillType.evenOdd;
    path.addPath(innerPath, Offset.zero);
  }

  return path;
}
