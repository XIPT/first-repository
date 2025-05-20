import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

import 'geometry.dart';

class Linedrawing {
  /// 점 그리기
  static void drawPoint(Canvas canvas, Offset point,
      {Color color = Colors.red, double radius = 5.0}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, radius, paint);
  }

  /// 선 그리기
  static void drawLine(Canvas canvas, Offset p1, Offset p2,
      {Color color = Colors.blue, double strokeWidth = 2.0}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p1, p2, paint);
  }

  /// 연장된 선 그리기
  static void drawExtendedLine(Canvas canvas, Offset p1, Offset p2,
      {Color color = Colors.blue, double strokeWidth = 2.0, double extendFactor = 2.0}) {
    final extendedLine = Geometry.extendLine(p1, p2, extendFactor: extendFactor);
    drawLine(canvas, extendedLine.item1, extendedLine.item2,
        color: color, strokeWidth: strokeWidth);
  }

  /// 점선 그리기
  static void drawDashedLine(Canvas canvas, Offset p1, Offset p2,
      {Color color = Colors.blue, double strokeWidth = 2.0, double dashLength = 5.0, double gapLength = 3.0}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 시작점과 끝점 사이의 총 거리
    final distance = (p2 - p1).distance;

    // 방향 벡터
    final direction = Offset((p2.dx - p1.dx) / distance, (p2.dy - p1.dy) / distance);

    // 점선 그리기
    double currentDistance = 0.0;
    bool isDrawing = true;

    while (currentDistance < distance) {
      final remainingDistance = distance - currentDistance;
      final segmentLength = isDrawing
          ? (remainingDistance < dashLength ? remainingDistance : dashLength)
          : (remainingDistance < gapLength ? remainingDistance : gapLength);

      final currentPoint = Offset(
        p1.dx + direction.dx * currentDistance,
        p1.dy + direction.dy * currentDistance,
      );

      final endPoint = Offset(
        currentPoint.dx + direction.dx * segmentLength,
        currentPoint.dy + direction.dy * segmentLength,
      );

      if (isDrawing) {
        canvas.drawLine(currentPoint, endPoint, paint);
      }

      currentDistance += segmentLength;
      isDrawing = !isDrawing;
    }
  }

  /// 연장된 점선 그리기
  static void drawExtendedDashedLine(Canvas canvas, Offset p1, Offset p2,
      {Color color = Colors.blue, double strokeWidth = 2.0, double extendFactor = 2.0,
        double dashLength = 5.0, double gapLength = 3.0}) {
    final extendedLine = Geometry.extendLine(p1, p2, extendFactor: extendFactor);
    drawDashedLine(canvas, extendedLine.item1, extendedLine.item2,
        color: color, strokeWidth: strokeWidth, dashLength: dashLength, gapLength: gapLength);
  }

  /// 선분의 중점에 점 그리기
  static void drawMidpoint(Canvas canvas, Offset p1, Offset p2,
      {Color color = Colors.green, double radius = 5.0}) {
    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    drawPoint(canvas, mid, color: color, radius: radius);
  }

  /// 각도 표시(호, 라벨)
  static void drawAngle(Canvas canvas, Offset a, Offset b, Offset c,
      {Color color = Colors.orange,
        double arcRadius = 30,
        String? label,
        TextStyle textStyle = const TextStyle(color: Colors.black, fontSize: 14)}) {
    final angle = Geometry.angleAtPoint(a, b, c); // 사용자가 만든 함수
    final startAngle = Geometry.angleBetweenPoints(b, a); // b->a
    canvas.drawArc(
      Rect.fromCircle(center: b, radius: arcRadius),
      startAngle,
      angle,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    if (label != null) {
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      // 각의 중앙으로 텍스트 위치 계산
      final middleAngle = startAngle + (angle / 2);
      final textOffset = Offset(
        b.dx + arcRadius * cos(middleAngle) - textPainter.width / 2,
        b.dy + arcRadius * sin(middleAngle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  /// 호(arc) 그리기
  static void drawArc(Canvas canvas, Offset center, double radius, double startAngle, double sweepAngle,
      {Color color = Colors.purple, double strokeWidth = 2.0}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }
}