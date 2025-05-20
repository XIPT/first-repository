import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

/// 기하학 계산 유틸리티 클래스
/// 두 점 사이의 관계, 각도, 거리 등을 계산하는 정적 메서드들
class Geometry {
  // 유틸리티 클래스이므로 인스턴스화 방지
  Geometry._();

  /// 두 점 사이 거리 계산
  static double distanceBetweenPoints(Offset p1, Offset p2) {
    return (p2 - p1).distance;
  }

  /// X축 절대값 거리 계산
  static double xDistancabs(Offset p1, Offset p2) {
    return (p2.dx - p1.dx).abs();
  }

  /// Y축 절대값 거리 계산
  static double yDistanceabs(Offset p1, Offset p2) {
    return (p2.dy - p1.dy).abs();
  }

  /// X축 거리 계산
  static double xDistance(Offset p1, Offset p2) {
    return (p2.dx - p1.dx);
  }

  /// Y축 거리 계산
  static double yDistance(Offset p1, Offset p2) {
    return (p2.dy - p1.dy);
  }


  /// 두 점을 지나는 선의 각도(라디안)
  static double angleBetweenPoints(Offset p1, Offset p2) {
    return atan2(p2.dy - p1.dy, p2.dx - p1.dx);
  }

  /// 두 점을 지나는 선의 각도(도)
  static double degreesBetweenPoints(Offset p1, Offset p2) {
    return angleBetweenPoints(p1, p2) * 180 / pi;
  }

  /// 두 선 사이의 각도(라디안) - 개선된 버전
  static double angleBetweenLines(Offset line1P1, Offset line1P2, Offset line2P1, Offset line2P2) {
    // 각 선분의 방향 벡터 계산
    final vector1 = Offset(line1P2.dx - line1P1.dx, line1P2.dy - line1P1.dy);
    final vector2 = Offset(line2P2.dx - line2P1.dx, line2P2.dy - line2P1.dy);

    // 두 벡터 사이의 각도 계산
    final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
    final magnitude1 = vector1.distance;
    final magnitude2 = vector2.distance;

    if (magnitude1 == 0 || magnitude2 == 0) return 0.0;

    final cosAngle = dotProduct / (magnitude1 * magnitude2);

    // 각도가 발산하는 것을 방지하기 위한 clamp
    final clampedCosAngle = cosAngle.clamp(-1.0, 1.0);

    // 각도 계산 (0° ~ 180°)
    final angle = acos(clampedCosAngle);

    // 크로스 프로덕트의 부호로 방향 결정 (시계 또는 반시계)
    // 근데 척추 각도에서는 방향이 크게 중요하지 않을 수 있음
    return angle;
  }

  /// 1. 해부학적으로 의미 있는 척추 각도(도) - 양수/음수 차이 없이
  static double spineBetweenLines(Offset line1P1, Offset line1P2, Offset line2P1, Offset line2P2) {
    // 기존 각도 계산
    double angle = angleBetweenLines(line1P1, line1P2, line2P1, line2P2);
    double anatomicalAngle = angle * 180.0 / pi;

    return anatomicalAngle;
  }

  /// 2. 척추 각도(도) - 전만일 때 양수 (왼쪽이 convex일 때)
  static double spineBetweenLinesKyphosisPositive(Offset line1P1, Offset line1P2, Offset line2P1, Offset line2P2) {
    // 각 선분의 방향 벡터 계산
    final vector1 = Offset(line1P2.dx - line1P1.dx, line1P2.dy - line1P1.dy);
    final vector2 = Offset(line2P2.dx - line2P1.dx, line2P2.dy - line2P1.dy);

    // 두 벡터 사이의 각도 계산
    final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
    final magnitude1 = vector1.distance;
    final magnitude2 = vector2.distance;

    if (magnitude1 == 0 || magnitude2 == 0) return 0.0;

    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final clampedCosAngle = cosAngle.clamp(-1.0, 1.0);
    final angle = acos(clampedCosAngle);

    // 크로스 프로덕트로 방향 결정
    final crossProduct = vector1.dx * vector2.dy - vector1.dy * vector2.dx;

    // 왼쪽이 convex(전만)일 때 양수, 오른쪽이 convex(후만)일 때 음수
    // 화면에서는 Y축이 아래로 증가하므로, crossProduct의 부호가 반대로 해석됨
    final signedAngle = crossProduct >= 0 ? angle : -angle;

    return signedAngle * 180.0 / pi;
  }

  /// 3. 척추 각도(도) - 후만일 때 양수 (오른쪽이 convex일 때)
  static double spineBetweenLinesLordosisPositive(Offset line1P1, Offset line1P2, Offset line2P1, Offset line2P2) {
    // 각 선분의 방향 벡터 계산
    final vector1 = Offset(line1P2.dx - line1P1.dx, line1P2.dy - line1P1.dy);
    final vector2 = Offset(line2P2.dx - line2P1.dx, line2P2.dy - line2P1.dy);

    // 두 벡터 사이의 각도 계산
    final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
    final magnitude1 = vector1.distance;
    final magnitude2 = vector2.distance;

    if (magnitude1 == 0 || magnitude2 == 0) return 0.0;

    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final clampedCosAngle = cosAngle.clamp(-1.0, 1.0);
    final angle = acos(clampedCosAngle);

    // 크로스 프로덕트로 방향 결정
    final crossProduct = vector1.dx * vector2.dy - vector1.dy * vector2.dx;

    // 왼쪽이 convex(전만)일 때 음수, 오른쪽이 convex(후만)일 때 양수
    // 화면에서는 Y축이 아래로 증가하므로, crossProduct의 부호가 반대로 해석됨
    final signedAngle = crossProduct >= 0 ? -angle : angle;

    return signedAngle * 180.0 / pi;
  }

  /// 세 점에서 중간점 각도(내부 각도)
  static double angleAtPoint(Offset a, Offset b, Offset c) {
    final ab = b - a;
    final cb = b - c;
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final magAb = ab.distance;
    final magCb = cb.distance;
    return acos(dot / (magAb * magCb));
  }

  /// 세 점에서 중간점 각도(도)
  static double degreesAtPoint(Offset a, Offset b, Offset c) {
    return angleAtPoint(a, b, c) * 180 / pi;
  }

  /// 선분의 중점 구하기
  static Offset midpoint(Offset p1, Offset p2) {
    return Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
  }

  /// 선분 위의 비율만큼 떨어진 점 구하기
  static Offset pointOnLine(Offset p1, Offset p2, double t) {
    // t: 0이면 p1, 1이면 p2
    return Offset(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
  }

  /// 두 직선의 교점 구하기
  static Offset? intersection(Offset p1, Offset p2, Offset p3, Offset p4) {
    final denominator = (p1.dx - p2.dx) * (p3.dy - p4.dy) -
        (p1.dy - p2.dy) * (p3.dx - p4.dx);
    if (denominator == 0) return null; // 평행

    final x = ((p1.dx * p2.dy - p1.dy * p2.dx) * (p3.dx - p4.dx) -
        (p1.dx - p2.dx) * (p3.dx * p4.dy - p3.dy * p4.dx)) /
        denominator;
    final y = ((p1.dx * p2.dy - p1.dy * p2.dx) * (p3.dy - p4.dy) -
        (p1.dy - p2.dy) * (p3.dx * p4.dy - p3.dy * p4.dx)) /
        denominator;
    return Offset(x, y);
  }

  /// 원의 호 길이 계산 (반지름 r, 각도 theta 라디안 단위)
  static double arcLength(double radius, double theta) {
    return radius * theta;
  }

  /// 점과 두 점을 지나는 직선의 거리
  static double distancePointToLine(Offset pt, Offset a, Offset b) {
    final numerator = ((b.dy - a.dy) * pt.dx - (b.dx - a.dx) * pt.dy + b.dx * a.dy - b.dy * a.dx).abs();
    final denominator = sqrt(pow(b.dy - a.dy, 2) + pow(b.dx - a.dx, 2));
    if (denominator == 0) return 0.0; // 중복점 예외처리
    return numerator / denominator;
  }

  /// 기준점(center)를 중심으로 point를 angle 라디안 만큼 회전
  static Offset rotatePoint(Offset point, Offset center, double angle) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Offset(
      center.dx + dx * cosA - dy * sinA,
      center.dy + dx * sinA + dy * cosA,
    );
  }

  /// 선분의 연장선상에서 특정 거리만큼 떨어진 점 구하기
  static Offset pointOnLineWithDistance(Offset p1, Offset p2, double distance) {
    final totalDistance = (p2 - p1).distance;
    if (totalDistance == 0) return p1;
    final ratio = distance / totalDistance;
    return pointOnLine(p1, p2, ratio);
  }

  /// 두 점 사이의 선을 지정된 비율로 양쪽으로 연장하기
  /// extendFactor: 전체 길이의 확장 비율 (2.0이면 원래 길이의 2배로 연장)
  static Tuple2<Offset, Offset> extendLine(Offset p1, Offset p2, {double extendFactor = 2.0}) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;

    // 중점 기준으로 양쪽으로 연장
    final start = Offset(p1.dx - dx * (extendFactor - 1) / 2, p1.dy - dy * (extendFactor - 1) / 2);
    final end = Offset(p2.dx + dx * (extendFactor - 1) / 2, p2.dy + dy * (extendFactor - 1) / 2);

    return Tuple2(start, end);
  }
}

/// 두 값을 담을 수 있는 간단한 Tuple 클래스
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);
}

/// 픽셀과 실제 mm 간의 변환 관리를 위한 싱글톤 클래스
/// 앱 전체에서 공통으로 사용되는 측정 관련 상수와 유틸리티를 제공합니다.
class MeasurementConstants {
  // 싱글톤 패턴 구현
  static final MeasurementConstants _instance = MeasurementConstants._internal();

  factory MeasurementConstants() {
    return _instance;
  }

  MeasurementConstants._internal();

  // 기본값 설정 (초기 픽셀당 mm 값)
  static double pixelToMm = 0.264583;

  // ChangeNotifier를 사용해 값 변경 시 리스너에게 알림
  static final ValueNotifier<double> pixelToMmNotifier = ValueNotifier<double>(pixelToMm);

  // 값 업데이트 메서드
  static void updatePixelToMm(double newValue) {
    pixelToMm = newValue;
    pixelToMmNotifier.value = newValue;
  }

  // 픽셀 값을 mm로 변환
  static double pixelsToMm(double pixels) {
    return pixels * pixelToMm;
  }

  // mm 값을 픽셀로 변환
  static double mmToPixels(double mm) {
    return mm / pixelToMm;
  }
}