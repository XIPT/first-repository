// lib/state/measurement_state.dart

import 'package:flutter/material.dart';
import '../utils/geometry.dart';

/// MeasurementState 클래스는 앱의 측정 관련 상태를 관리합니다.
/// 이전에 직접 MeasurementConstants를 정의했던 것을 utils/measurement_constants.dart로 이동했습니다.
class MeasurementState extends ChangeNotifier {
  // 현재 사용중인 측정 상수 객체 참조
  final MeasurementConstants _constants = MeasurementConstants();

  // 최근 측정 이력을 저장하는 리스트
  final List<MeasurementRecord> _measurementHistory = [];

  // 측정 이력 접근자
  List<MeasurementRecord> get measurementHistory => List.unmodifiable(_measurementHistory);

  // 현재 픽셀당 mm 값 접근자
  double get pixelToMm => MeasurementConstants.pixelToMm;

  // 픽셀당 mm 값 변경 리스너
  ValueNotifier<double> get pixelToMmNotifier => MeasurementConstants.pixelToMmNotifier;

  // 측정 이력에 새 기록 추가
  void addMeasurementRecord(MeasurementRecord record) {
    _measurementHistory.add(record);
    notifyListeners();
  }

  // 측정 이력 초기화
  void clearMeasurementHistory() {
    _measurementHistory.clear();
    notifyListeners();
  }

  // 픽셀당 mm 값 업데이트
  void updatePixelToMm(double newValue) {
    MeasurementConstants.updatePixelToMm(newValue);
    // MeasurementConstants는 자체적으로 ValueNotifier를 통해 알림을 보내므로
    // 여기서는 추가 notifyListeners 호출이 필요 없음
  }
}

/// 측정 기록을 저장하는 클래스
class MeasurementRecord {
  final double pixelDistance; // 픽셀 단위 거리
  final double realDistance; // 실제 mm 단위 거리
  final double pixelToMmRatio; // 계산된 픽셀당 mm 비율

  MeasurementRecord({
    required this.pixelDistance,
    required this.realDistance,
    required this.pixelToMmRatio,
  });

  // 측정 기록을 문자열로 반환
  @override
  String toString() {
    return '${pixelDistance.toStringAsFixed(1)} px = ${realDistance.toStringAsFixed(2)} mm (${pixelToMmRatio.toStringAsFixed(6)} mm/px)';
  }
}
