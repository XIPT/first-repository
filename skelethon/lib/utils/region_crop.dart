// /utils/region_crop.dart
import 'dart:math' as Math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class RegionCropUtil {
  // 부위별 비율 정보 저장 변수
  static final Map<String, Map<String, dynamic>> regionSettings = {
    'cervical': {
      'aspectRatio': 1.0,  // 경추 - 정사각형(1:1)
      'minSize': 160.0,    // 최소 크기
      'maxSize': 960.0,    // 최대 크기
    },
    'thoracic': {
      'aspectRatio': 0.5,  // 흉추 - 세로:가로 = 2:1
      'minSize': 160.0,    // 최소 가로 크기
      'maxSize': 960.0,    // 최대 가로 크기
    },
    'lumbar': {
      'aspectRatio': 1.0,  // 요추 - 정사각형(1:1)
      'minSize': 160.0,    // 최소 크기
      'maxSize': 960.0,    // 최대 크기
    },
    'pelvic': {
      'aspectRatio': 1.0,  // 골반 - 정사각형(1:1)
      'minSize': 160.0,    // 최소 크기
      'maxSize': 960.0,    // 최대 크기
    },
  };

  // 이미지 표시 영역 계산 함수
  static Map<String, double> calculateImageDisplayRect({
    required Uint8List imageBytes,
    required RenderBox renderBox,
  }) {
    final result = <String, double>{};

    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        throw Exception('이미지 디코딩 실패');
      }

      final size = renderBox.size;

      // 이미지와 화면의 비율 계산 (보다 안정적인 방식으로)
      double displayScale;
      double displayedImageWidth;
      double displayedImageHeight;

      // 이미지 비율과 화면 비율 비교
      double imageRatio = decoded.width / decoded.height;
      double screenRatio = size.width / size.height;

      if (imageRatio > screenRatio) {
        // 이미지가 화면보다 가로로 더 넓은 경우
        displayedImageWidth = size.width;
        displayedImageHeight = size.width / imageRatio;
        displayScale = size.width / decoded.width;
      } else {
        // 이미지가 화면보다 세로로 더 긴 경우
        displayedImageHeight = size.height;
        displayedImageWidth = size.height * imageRatio;
        displayScale = size.height / decoded.height;
      }

      // 이미지가 화면에서 표시되는 영역 계산
      final imageLeft = (size.width - displayedImageWidth) / 2;
      final imageTop = (size.height - displayedImageHeight) / 2;
      final imageRight = imageLeft + displayedImageWidth;
      final imageBottom = imageTop + displayedImageHeight;

      // 결과 반환
      result['imageScale'] = displayScale;
      result['imageLeft'] = imageLeft;
      result['imageTop'] = imageTop;
      result['imageRight'] = imageRight;
      result['imageBottom'] = imageBottom;
      result['imageWidth'] = displayedImageWidth;
      result['imageHeight'] = displayedImageHeight;

      print('계산된 이미지 표시 영역: left=$imageLeft, top=$imageTop, right=$imageRight, bottom=$imageBottom, scale=$displayScale');

      return result;
    } catch (e) {
      print('❌ 이미지 영역 계산 오류: $e');

      // 오류 발생 시 기본값 반환 (최소한의 화면 크기 사용)
      final defaultSize = renderBox.size;
      result['imageScale'] = 1.0;
      result['imageLeft'] = 0;
      result['imageTop'] = 0;
      result['imageRight'] = defaultSize.width;
      result['imageBottom'] = defaultSize.height;
      result['imageWidth'] = defaultSize.width;
      result['imageHeight'] = defaultSize.height;

      return result;
    }
  }

  // 부위별 초기 크롭 영역 계산
  static Rect calculateInitialCropRect({
    required String region,
    required double imageScale,
    required double imageLeft,
    required double imageTop,
    required double imageRight,
    required double imageBottom,
    required double imageWidth,
    required double imageHeight,
  }) {
    // 선택된 부위의 설정 가져오기
    final settings = regionSettings[region];
    if (settings == null) {
      throw Exception('선택된 부위의 설정을 찾을 수 없습니다.');
    }

    final aspectRatio = settings['aspectRatio'] as double;
    final minSize = settings['minSize'] as double;

    // 최소 크기에 맞춰 초기 크롭 크기 계산 (화면 스케일 적용)
    double cropWidth = minSize * imageScale;
    double cropHeight;

    if (region == 'thoracic') {
      // 흉추는 세로:가로 = 2:1 비율
      cropHeight = cropWidth * 2;

      // 이미지 높이를 벗어나는지 확인
      if (cropHeight > imageHeight) {
        cropHeight = imageHeight * 0.9; // 이미지 높이의 90%로 제한
        cropWidth = cropHeight / 2;      // 비율 유지
      }
    } else {
      // 다른 부위는 정사각형 (1:1)
      cropHeight = cropWidth;

      // 이미지 범위를 벗어나는지 확인
      if (cropWidth > imageWidth || cropHeight > imageHeight) {
        double maxDimension = Math.min(imageWidth, imageHeight);
        cropWidth = maxDimension * 0.9;  // 이미지 크기의 90%로 제한
        cropHeight = cropWidth;          // 정사각형 유지
      }
    }

    // 크롭 영역의 중심은 이미지 중심
    final centerX = (imageLeft + imageRight) / 2;
    final centerY = (imageTop + imageBottom) / 2;

    // 크롭 영역 좌표 계산 (중앙 배치)
    double left = centerX - cropWidth / 2;
    double top = centerY - cropHeight / 2;

    // 이미지 영역을 벗어나지 않도록 조정
    if (left < imageLeft) left = imageLeft;
    if (top < imageTop) top = imageTop;
    if (left + cropWidth > imageRight) left = imageRight - cropWidth;
    if (top + cropHeight > imageBottom) top = imageBottom - cropHeight;

    return Rect.fromLTWH(left, top, cropWidth, cropHeight);
  }

  // 특정 핸들이 클릭되었는지 확인하는 함수
  static int getHandleAtPosition(Offset position, Rect cropRect, double handleSize) {
    final handles = [
      Rect.fromCenter(center: cropRect.topLeft, width: handleSize, height: handleSize),
      Rect.fromCenter(center: cropRect.topRight, width: handleSize, height: handleSize),
      Rect.fromCenter(center: cropRect.bottomRight, width: handleSize, height: handleSize),
      Rect.fromCenter(center: cropRect.bottomLeft, width: handleSize, height: handleSize),
    ];

    for (int i = 0; i < handles.length; i++) {
      if (handles[i].contains(position)) {
        return i;
      }
    }

    // 핸들이 없으면 전체 크롭 영역이 클릭되었는지 확인
    if (cropRect.contains(position)) {
      return 4; // 전체 크롭 영역 선택
    }

    return -1; // 아무것도 선택되지 않음
  }

  // 크롭 영역 제약 조건 적용
  static Rect constrainCropRect({
    required Rect rect,
    required String region,
    required double imageScale,
    required double imageLeft,
    required double imageTop,
    required double imageRight,
    required double imageBottom,
    required double imageWidth,
    required double imageHeight,
    required int selectedHandle,
    required bool isCropping,
    required Offset? cropStart,
    required Offset? cropEnd,
  }) {
    // 드래그 방향 정보 저장
    bool isLeftToRight = true;
    bool isTopToBottom = true;

    // 드래그 방향 결정 (새 영역 생성 중 또는 핸들 드래그 중)
    if (cropStart != null && cropEnd != null) {
      isLeftToRight = cropStart.dx <= cropEnd.dx;
      isTopToBottom = cropStart.dy <= cropEnd.dy;
    }

    // 기본 좌표값
    double left = rect.left;
    double top = rect.top;
    double right = rect.right;
    double bottom = rect.bottom;

    // 이미지 영역 내로 제한
    left = left.clamp(imageLeft, imageRight);
    top = top.clamp(imageTop, imageBottom);
    right = right.clamp(imageLeft, imageRight);
    bottom = bottom.clamp(imageTop, imageBottom);

    // 현재 이미지에 맞게 최소/최대 크기 조정 (화면 스케일 적용)
    final settings = regionSettings[region]!;
    double scaledMinWidth = settings['minSize'] * imageScale;
    double scaledMaxWidth = Math.min(settings['maxSize'] * imageScale, imageWidth);

    // 부위별 비율에 따른 높이 제약 계산
    double scaledMinHeight, scaledMaxHeight;

    if (region == 'thoracic') {
      // 흉추는 세로:가로 = 2:1
      scaledMinHeight = scaledMinWidth * 2;
      scaledMaxHeight = scaledMaxWidth * 2;

      // 높이가 이미지를 벗어나지 않도록 최대 높이 조정
      if (scaledMaxHeight > imageHeight) {
        scaledMaxHeight = imageHeight;
        scaledMaxWidth = scaledMaxHeight / 2;
      }
    } else {
      // 다른 부위는 정사각형 (1:1)
      scaledMinHeight = scaledMinWidth;
      scaledMaxHeight = scaledMaxWidth;

      // 정사각형 제약으로 최대 크기 제한
      scaledMaxWidth = Math.min(scaledMaxWidth, imageHeight);
      scaledMaxHeight = scaledMaxWidth;
    }

    // 현재 너비와 높이 계산 (절대값 사용)
    double width = (right - left).abs();
    double height = (bottom - top).abs();

    // 핸들 또는 드래그 작업에 따른 크기 조정 로직
    if (region == 'thoracic') {
      // 흉추: 세로:가로 = 2:1
      if (selectedHandle >= 0 && selectedHandle <= 3) {
        // 핸들 드래그 중에는 핸들 유형에 따라 조정
        width = Math.max(width, scaledMinWidth);
        width = Math.min(width, scaledMaxWidth);
        height = width * 2;

        // 원래 드래그 방향 유지
        if (isLeftToRight) {
          right = left + width;
        } else {
          left = right - width;
        }

        if (isTopToBottom) {
          bottom = top + height;
        } else {
          top = bottom - height;
        }
      } else if (isCropping) {
        // 새로 그릴 때 비율 유지
        width = Math.max(width, scaledMinWidth);
        width = Math.min(width, scaledMaxWidth);
        height = width * 2;

        // 드래그 방향에 따라 적절히 조정
        if (isLeftToRight) {
          right = left + width;
        } else {
          left = right - width;
        }

        if (isTopToBottom) {
          bottom = top + height;
        } else {
          top = bottom - height;
        }
      }
    } else {
      // 다른 부위: 정사각형 (1:1)
      if (selectedHandle >= 0 && selectedHandle <= 3) {
        // 정사각형 유지
        double size = Math.max(width, height);
        size = Math.max(size, scaledMinWidth);
        size = Math.min(size, scaledMaxWidth);

        // 원래 드래그 방향 유지
        if (isLeftToRight) {
          right = left + size;
        } else {
          left = right - size;
        }

        if (isTopToBottom) {
          bottom = top + size;
        } else {
          top = bottom - size;
        }
      } else if (isCropping) {
        // 새로 그릴 때 정사각형 유지
        double size = Math.max(width, height);
        size = Math.max(size, scaledMinWidth);
        size = Math.min(size, scaledMaxWidth);

        // 드래그 방향에 따라 적절히 조정
        if (isLeftToRight) {
          right = left + size;
        } else {
          left = right - size;
        }

        if (isTopToBottom) {
          bottom = top + size;
        } else {
          top = bottom - size;
        }
      }
    }

    // 이미지 경계 초과 재확인 및 조정
    if (left < imageLeft) {
      double adjust = imageLeft - left;
      left = imageLeft;
      // 전체 이동이면 right도 같이 이동
      if (selectedHandle == 4) {
        right += adjust;
      }
    }

    if (top < imageTop) {
      double adjust = imageTop - top;
      top = imageTop;
      // 전체 이동이면 bottom도 같이 이동
      if (selectedHandle == 4) {
        bottom += adjust;
      }
    }

    if (right > imageRight) {
      double adjust = right - imageRight;
      right = imageRight;
      // 전체 이동이면 left도 같이 이동
      if (selectedHandle == 4) {
        left -= adjust;
      }
    }

    if (bottom > imageBottom) {
      double adjust = bottom - imageBottom;
      bottom = imageBottom;
      // 전체 이동이면 top도 같이 이동
      if (selectedHandle == 4) {
        top -= adjust;
      }
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  // 이미지 내 크롭 영역 계산
  static Map<String, double> calculateCropInImage({
    required Rect cropRect,
    required double imageLeft,
    required double imageTop,
    required double imageScale,
    required int imageWidth,
    required int imageHeight,
    required String region,
  }) {
    try {
      // 결과 맵 초기화
      final result = <String, double>{};

      // 크롭 영역의 이미지 내 좌표 계산
      double cropLeftInImage = (cropRect.left - imageLeft) / imageScale;
      double cropTopInImage = (cropRect.top - imageTop) / imageScale;
      double cropWidthInImage = cropRect.width / imageScale;
      double cropHeightInImage = cropRect.height / imageScale;

      // 좌표가 유효한지 검사
      cropLeftInImage = _sanitizeValue(cropLeftInImage, 0.0, imageWidth - 1.0);
      cropTopInImage = _sanitizeValue(cropTopInImage, 0.0, imageHeight - 1.0);

      // 이미지 경계를 넘어가지 않도록 크기 조정
      if (cropLeftInImage + cropWidthInImage > imageWidth) {
        cropWidthInImage = imageWidth - cropLeftInImage;
      }
      if (cropTopInImage + cropHeightInImage > imageHeight) {
        cropHeightInImage = imageHeight - cropTopInImage;
      }

      // 최소 크기 보장 (1픽셀 미만이 되지 않도록)
      cropWidthInImage = Math.max(1.0, cropWidthInImage);
      cropHeightInImage = Math.max(1.0, cropHeightInImage);

      // 결과 반환
      result['left'] = cropLeftInImage;
      result['top'] = cropTopInImage;
      result['width'] = cropWidthInImage;
      result['height'] = cropHeightInImage;

      return result;
    } catch (e) {
      print('❌ 크롭 영역 계산 예외 발생: $e');

      // 예외 발생 시 기본값 반환 (이미지의 중앙 부분)
      final defaultSize = Math.min(100.0, Math.min(imageWidth / 2, imageHeight / 2));
      final left = (imageWidth - defaultSize) / 2;
      final top = (imageHeight - defaultSize) / 2;

      return {
        'left': left,
        'top': top,
        'width': defaultSize,
        'height': defaultSize,
      };
    }
  }

  // NaN, Infinity, 범위 밖 값을 처리하기 위한 헬퍼 함수
  static double _sanitizeValue(double value, double min, double max) {
    if (value.isNaN || value.isInfinite) {
      return min;
    }
    return Math.max(min, Math.min(value, max));
  }

  // 이미지 처리 함수
  static Uint8List? processImage({
    required Uint8List imageBytes,
    required bool isFlipped,
    String? selectedRegion,
    Rect? cropRect,
    double? imageLeft,
    double? imageTop,
    required double imageScale,
  }) {
    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        throw Exception('이미지 디코딩 실패');
      }

      // 처리된 이미지
      img.Image processed;

      // 전신 모드 또는 크롭 파라미터 부족 시
      if (selectedRegion == null || cropRect == null || imageLeft == null || imageTop == null) {
        // 좌우반전만 적용
        processed = isFlipped ? img.flipHorizontal(decoded) : decoded;
      } else {
        try {
          // 크롭 영역 계산 및 적용
          final cropParams = calculateCropInImage(
            cropRect: cropRect,
            imageLeft: imageLeft,
            imageTop: imageTop,
            imageScale: imageScale,
            imageWidth: decoded.width,
            imageHeight: decoded.height,
            region: selectedRegion,
          );

          // 좌우반전 여부에 따라 원본 이미지 결정
          final sourcedImage = isFlipped ? img.flipHorizontal(decoded) : decoded;

          // 크롭 적용
          processed = img.copyCrop(
            sourcedImage,
            x: cropParams['left']!.toInt(),
            y: cropParams['top']!.toInt(),
            width: cropParams['width']!.toInt(),
            height: cropParams['height']!.toInt(),
          );
        } catch (e) {
          print('❌ 크롭 처리 중 오류 발생: $e');
          // 오류 발생 시 좌우반전만 적용
          processed = isFlipped ? img.flipHorizontal(decoded) : decoded;
        }
      }

      // JPG 형식으로 인코딩하여 반환
      return Uint8List.fromList(img.encodeJpg(processed, quality: 90));
    } catch (e) {
      print('❌ 이미지 처리 오류: $e');
      // 오류 발생 시 원본 바이트 반환
      return imageBytes;
    }
  }

  // 크롭 핸들 위젯 생성
  static Widget buildCropHandle(int handleIndex, double handleSize) {
    return Container(
      width: handleSize,
      height: handleSize,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.orange, width: 2),
        shape: BoxShape.circle,
      ),
    );
  }
}