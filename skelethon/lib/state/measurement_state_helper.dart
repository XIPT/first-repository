import 'package:flutter/material.dart';
import '../utils/geometry.dart';


/// 현재 pixelToMm 값을 쉽게 가져오는 함수
double getCurrentPixelToMm() {
  // 전역 변수로 접근
  return MeasurementConstants.pixelToMm;
}

/// 픽셀 거리를 실제 mm 거리로 변환
double pixelToRealDistance(double pixelDistance) {
  return pixelDistance * MeasurementConstants.pixelToMm;
}

/// 실제 mm 거리를 픽셀 거리로 변환
double realToPixelDistance(double mmDistance) {
  return mmDistance / MeasurementConstants.pixelToMm;
}

/// UI에서 pixelToMmNotifier를 사용하기 위한 위젯
class PixelToMmValue extends StatelessWidget {
  final Widget Function(BuildContext, double, Widget?) builder;

  const PixelToMmValue({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: MeasurementConstants.pixelToMmNotifier,
      builder: builder,
    );
  }
}