import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:file_selector/file_selector.dart'; // 파일 선택기 패키지 추가

import '/home/measurement_screen.dart';

/// 이미지 측정 관련 유틸리티 클래스
/// 이미지 크롭 및 측정 화면으로 이동하는 기능을 제공합니다.
class ImageUploadMeasurement {
  /// 파일 선택 후 이미지 크롭 다이얼로그를 표시하고 측정 화면으로 이동합니다.
  ///
  /// [context]: 현재 BuildContext
  static Future<void> selectAndMeasure({
    required BuildContext context,
  }) async {
    // 파일 선택
    final Uint8List? imageBytes = await selectImage(context);
    if (imageBytes == null) return; // 파일 선택 취소 또는 오류

    // 크롭 다이얼로그 표시
    showCropDialog(
      context: context,
      imageBytes: imageBytes,
      onImageSelected: (processedBytes) {
        // 측정 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => XrayMeasurementScreen(imageBytes: processedBytes),
          ),
        );
      },
    );
  }

  /// 파일 선택 후 크롭 과정 없이 바로 측정 화면으로 이동합니다.
  ///
  /// [context]: 현재 BuildContext
  static Future<void> selectAndDirectMeasure({
    required BuildContext context,
  }) async {
    // 파일 선택
    final Uint8List? imageBytes = await selectImage(context);
    if (imageBytes == null) return; // 파일 선택 취소 또는 오류

    // 바로 측정 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => XrayMeasurementScreen(imageBytes: imageBytes),
      ),
    );
  }

  /// 파일 선택기를 통해 이미지를 선택합니다.
  ///
  /// 선택된 이미지 바이트를 반환하거나, 선택 취소/오류 시 null을 반환합니다.
  static Future<Uint8List?> selectImage(BuildContext context) async {
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']),
        ],
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        return bytes;
      }
    } catch (e) {
      print('❌ 파일 선택 에러: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 선택 오류: $e')),
        );
      }
    }

    return null; // 파일 선택 취소 또는 오류
  }

  /// 이미지 크롭 다이얼로그를 표시하고 측정 화면으로 이동합니다.
  ///
  /// [context]: 현재 BuildContext
  /// [imageBytes]: 처리할 이미지 바이트 데이터
  static void showMeasurementDialog({
    required BuildContext context,
    required Uint8List imageBytes,
  }) {
    // 크롭 다이얼로그 표시
    showCropDialog(
      context: context,
      imageBytes: imageBytes,
      onImageSelected: (processedBytes) {
        // 측정 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => XrayMeasurementScreen(imageBytes: processedBytes),
          ),
        );
      },
    );
  }

  /// 크롭 과정 없이 바로 측정 화면으로 이동합니다.
  ///
  /// [context]: 현재 BuildContext
  /// [imageBytes]: 처리할 이미지 바이트 데이터
  static void directMeasurement({
    required BuildContext context,
    required Uint8List imageBytes,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => XrayMeasurementScreen(imageBytes: imageBytes),
      ),
    );
  }

  // showCropDialog 메소드는 그대로 유지
  static void showCropDialog({
    required BuildContext context,
    required Uint8List imageBytes,
    required void Function(Uint8List processedImageBytes) onImageSelected,
  }) {
    // 크롭 관련 변수
    Rect? cropRect;
    bool isCropping = false;
    Offset? startPoint;
    Offset? endPoint;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // 이미지 크롭 함수
          Future<void> _cropAndUseImage() async {
            if (cropRect == null) {
              // 크롭 없이 원본 이미지 사용
              onImageSelected(imageBytes);
              Navigator.pop(context);
              return;
            }

            try {
              // 이미지 디코딩
              final decoded = img.decodeImage(imageBytes);
              if (decoded == null) {
                onImageSelected(imageBytes);
                Navigator.pop(context);
                return;
              }

              // 이미지 크기 정보 (이미지 뷰 크기 기준)
              final containerWidth = MediaQuery.of(context).size.width * 0.7;
              final containerHeight = MediaQuery.of(context).size.height * 0.5;

              // 이미지 디스플레이 크기 계산
              final imageRatio = decoded.width / decoded.height;
              final displayRatio = containerWidth / containerHeight;

              double displayWidth, displayHeight;
              double imageX, imageY;

              if (imageRatio > displayRatio) {
                // 화면에 맞게 가로 기준으로 조정
                displayWidth = containerWidth;
                displayHeight = containerWidth / imageRatio;
                imageX = 0;
                imageY = (containerHeight - displayHeight) / 2;
              } else {
                // 화면에 맞게 세로 기준으로 조정
                displayHeight = containerHeight;
                displayWidth = containerHeight * imageRatio;
                imageX = (containerWidth - displayWidth) / 2;
                imageY = 0;
              }

              // 크롭 영역을 원본 이미지 좌표로 변환
              final scaleX = decoded.width / displayWidth;
              final scaleY = decoded.height / displayHeight;

              int cropX = ((cropRect!.left - imageX) * scaleX).round();
              int cropY = ((cropRect!.top - imageY) * scaleY).round();
              int cropWidth = (cropRect!.width * scaleX).round();
              int cropHeight = (cropRect!.height * scaleY).round();

              // 범위 체크
              cropX = cropX.clamp(0, decoded.width - 1);
              cropY = cropY.clamp(0, decoded.height - 1);
              cropWidth = cropWidth.clamp(1, decoded.width - cropX);
              cropHeight = cropHeight.clamp(1, decoded.height - cropY);

              // 크롭 수행
              final cropped = img.copyCrop(
                decoded,
                x: cropX,
                y: cropY,
                width: cropWidth,
                height: cropHeight,
              );

              // 크롭된 이미지 인코딩
              final croppedBytes = Uint8List.fromList(img.encodeJpg(cropped));

              // 콜백 호출 및 다이얼로그 닫기
              Navigator.pop(context);
              onImageSelected(croppedBytes);
            } catch (e) {
              print('크롭 오류: $e');
              // 오류 발생 시 원본 이미지 사용
              Navigator.pop(context);
              onImageSelected(imageBytes);
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              margin: const EdgeInsets.all(6.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 타이틀
                  Text(
                    '측정할 영역 선택',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 이미지 컨테이너
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Stack(
                        children: [
                          // 이미지
                          Center(
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.contain,
                            ),
                          ),

                          // 크롭 영역 제스처 감지
                          Positioned.fill(
                            child: GestureDetector(
                              onPanStart: (details) {
                                setState(() {
                                  isCropping = true;
                                  startPoint = details.localPosition;
                                  endPoint = details.localPosition;
                                  cropRect = Rect.fromPoints(startPoint!, endPoint!);
                                });
                              },
                              onPanUpdate: (details) {
                                if (isCropping) {
                                  setState(() {
                                    endPoint = details.localPosition;
                                    cropRect = Rect.fromPoints(startPoint!, endPoint!);
                                  });
                                }
                              },
                              onPanEnd: (details) {
                                setState(() {
                                  isCropping = false;
                                });
                              },
                            ),
                          ),

                          // 크롭 영역 표시
                          if (cropRect != null)
                            Positioned.fromRect(
                              rect: cropRect!,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 버튼 영역
                  Column(
                    children: [
                      // 선택 영역 사용 버튼 (맨 위에 배치)
                      ElevatedButton.icon(
                        icon: Icon(
                          Icons.crop,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          '선택 영역 사용',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[850]?.withOpacity(0.5),
                          disabledForegroundColor: Colors.white.withOpacity(0.5),
                        ),
                        onPressed: cropRect != null ? () => _cropAndUseImage() : null,
                      ),

                      const SizedBox(height: 16),

                      // 취소와 전체 사용 버튼을 양끝에 배치
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 취소 버튼 (네모 모양)
                          TextButton(
                            child: Text(
                              '취소',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // 네모 모양으로 변경
                                side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),

                          // 전체 사용 버튼 (네모 모양)
                          TextButton(
                            child: Text(
                              '전체 사용',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // 네모 모양으로 변경
                                side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
                              ),
                            ),
                            onPressed: () {
                              // 크롭 없이 전체 이미지 사용
                              Navigator.pop(context);
                              onImageSelected(imageBytes);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}