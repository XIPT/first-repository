import 'package:flutter/material.dart';
import 'dart:ui';
import 'enums.dart';


class Textdrawing {
  static void drawTextWithAlignment(
      Canvas canvas,
      String text,
      Offset position, {
        TextStyle style = const TextStyle(color: Colors.black, fontSize: 14),
        TextAlignment alignment = TextAlignment.center,
        double margin = 4.0,
        double scale = 1.0, // 스케일 파라미터 추가
      }) {
    // 중요: 폰트 크기에 스케일을 적용하지 않도록 변경
    // 이렇게 하면 화면이 확대/축소되어도 글씨 크기는 동일하게 유지됩니다
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: 2,
    )..layout();

    // 여기서는 마진만 스케일 조정 (위치 계산용)
    final scaledMargin = margin;

    Offset offset;
    switch (alignment) {
      case TextAlignment.center:
        offset = position - Offset(textPainter.width / 2, textPainter.height / 2);
        break;
      case TextAlignment.left:
      // 왼쪽 정렬은 텍스트의 왼쪽 경계를 기준점에 맞추고,
      // 기준점으로부터 오른쪽으로 margin만큼 이동
        offset = position + Offset(scaledMargin, -textPainter.height / 2);
        break;
      case TextAlignment.right:
      // 오른쪽 정렬은 텍스트의 오른쪽 경계를 기준점에 맞추고,
      // 기준점으로부터 왼쪽으로 margin만큼 이동
        offset = position - Offset(textPainter.width + scaledMargin, textPainter.height / 2);
        break;
      case TextAlignment.top:
        offset = position - Offset(textPainter.width / 2, textPainter.height + scaledMargin);
        break;
      case TextAlignment.bottom:
        offset = position + Offset(-textPainter.width / 2, scaledMargin);
        break;
    }

    textPainter.paint(canvas, offset);
  }

  /// 상태에 따른 텍스트 색상 반환
  static Color getColorForStatus(StatusLevel status) {
    switch (status) {
      case StatusLevel.normal:
        return Colors.white;
      case StatusLevel.mild:
        return Colors.yellow;
      case StatusLevel.severe:
        return Colors.red;
    }
  }

  /// 상태에 따른 배경색 반환
  static Color getBackgroundColorForStatus(StatusLevel status) {
    switch (status) {
      case StatusLevel.normal:
        return Colors.green.withOpacity(0.2);
      case StatusLevel.mild:
        return Colors.yellow.withOpacity(0.2);
      case StatusLevel.severe:
        return Colors.red.withOpacity(0.2);
    }
  }
}