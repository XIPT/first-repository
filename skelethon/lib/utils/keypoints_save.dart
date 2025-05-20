import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:math';
import 'package:provider/provider.dart';
import '../state/keypoints_state.dart';

// Firebase 관련 import 추가
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/utils/keypoints_viewer.dart';
import '/utils/encryption.dart';


class KeypointsOverlay extends StatefulWidget {
  final Uint8List imageBytes; // 원본 이미지 바이트
  final List<Map<String, dynamic>> keypoints; // 찍은 키포인트들 좌표 목록
  final VoidCallback? onClose; // 닫기 버튼 눌렀을 때 콜백
  final String imageId; // 이미지 고유 ID
  final String region; // 신체 부위 예: 'Cervical'
  final String view; // 뷰 타입 예: 'Lateral'
  final double originalWidth; // 원본 이미지 mm 단위 폭
  final double originalHeight; // 원본 이미지 mm 단위 높이
  // 키포인트 예측 모델 함수 추가
  final Future<List<Map<String, dynamic>>> Function(Uint8List)?
  predictKeypoints;

  const KeypointsOverlay({
    super.key,
    required this.imageBytes,
    required this.keypoints,
    this.onClose,
    required this.imageId,
    required this.region,
    required this.view,
    required this.originalWidth,
    required this.originalHeight,
    this.predictKeypoints, // 키포인트 예측 함수 추가
  });

  @override
  State<KeypointsOverlay> createState() => _KeypointsOverlayState();
}

class _KeypointsOverlayState extends State<KeypointsOverlay> {
  // 현재 작업 중인 키포인트 목록
  late List<Map<String, dynamic>> currentKeypoints;

  // 원본 키포인트 (작업 취소 시 복원용)
  late List<Map<String, dynamic>> originalKeypoints;

  // 정밀 예측 진행 중 상태
  bool isRefiningPrediction = false;

  @override
  void initState() {
    super.initState();
    // 초기값 설정
    originalKeypoints = List<Map<String, dynamic>>.from(widget.keypoints);
    currentKeypoints = List<Map<String, dynamic>>.from(widget.keypoints);
  }

  List<Map<String, dynamic>> _convertToOriginalCoordinates(
      List<Map<String, dynamic>> pixelCoordinates,
      double imageWidth,
      double imageHeight,
      double originalWidth,
      double originalHeight,
      ) {
    return pixelCoordinates.map((point) {
      final x = point['x'] as double;
      final y = point['y'] as double;

      // 이미지 픽셀 좌표에서 원본 mm 단위 좌표로 변환
      final originalX = (x / imageWidth) * originalWidth;
      final originalY = (y / imageHeight) * originalHeight;

      // 원본 좌표를 복사하고 x, y만 변환된 값으로 업데이트
      return {
        ...point, // 기존 속성 모두 유지 (label 등)
        'x': originalX,
        'y': originalY,
      };
    }).toList();
  }

  // 키포인트 저장 처리
  Future<void> _saveKeypoints() async {
    final keypointsState = context.read<KeypointsState>();

    // 원본 이미지 상태에 저장 (원본 바이트 그대로)
    keypointsState.setOriginalImage(
      widget.region,
      widget.view,
      widget.imageBytes,
    );

    // 이미지 디코딩 (image 패키지 사용)
    final image = img.decodeImage(widget.imageBytes);
    if (image == null) {
      throw Exception("이미지 디코딩 실패");
    }

    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    // // overlay 이미지 생성 (Canvas에 그리기)
    // final recorder = ui.PictureRecorder();
    // final canvas = Canvas(recorder);
    //
    // // 플러터 캔버스는 y축이 아래로 향하니까 상하 반전해줘야 원본처럼 보임
    // canvas.scale(1, -1);
    // canvas.translate(0, -newHeight);
    //
    // // 이미지 캔버스에 그리기
    // canvas.drawImage(
    //   await decodeImageFromList(widget.imageBytes),
    //   Offset.zero,
    //   Paint(),
    // );
    //
    // // 빨간색 점 스타일
    // final pointPaint =
    // Paint()
    //   ..color = Colors.red
    //   ..style = PaintingStyle.fill;
    //
    // // Keypoints (좌표들) 그리기
    // for (var point in currentKeypoints) {
    //   final x = point['x'] as double;
    //   final y = point['y'] as double;
    //   canvas.drawCircle(Offset(x, y), 2.0, pointPaint);
    // }
    //
    // // 그린 그림 → 이미지로 변환
    // final picture = recorder.endRecording();
    // final imageWithKeypoints = await picture.toImage(image.height, image.width);
    // final byteData = await imageWithKeypoints.toByteData(
    //   format: ui.ImageByteFormat.png,
    // );
    //
    // // overlay 이미지 바이트로 변환 후 상태에 저장
    // if (byteData != null) {
    //   final overlayedBytes = byteData.buffer.asUint8List();
    //   keypointsState.setOverlayedImage(
    //     widget.region,
    //     widget.view,
    //     overlayedBytes,
    //   );
    // }

    // // overlayedKeypoints 좌표도 상태에 저장
    // if (currentKeypoints.isNotEmpty) {
    //   keypointsState.setOverlayedKeypoints(
    //     widget.region,
    //     widget.view,
    //     currentKeypoints,
    //     imageId: widget.imageId,
    //   );
    // }

    // 키포인트를 mm로 변환하여 저장
    final transformedKeypoints = _convertToOriginalCoordinates(
        currentKeypoints,
        imageWidth,
        imageHeight,
        widget.originalWidth,
        widget.originalHeight
    );

    // 변환된 좌표 저장
    keypointsState.setOriginalKeypoints(
      widget.region,
      widget.view,
      transformedKeypoints,
    );
    // 닫기 (콜백이 있으면 콜백 실행, 없으면 그냥 Navigator.pop)
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.pop(context);
    }
  }

  // 정밀 예측 실행
  Future<void> _performRefinedPrediction() async {
    if (widget.predictKeypoints == null || currentKeypoints.isEmpty) return;

    setState(() {
      isRefiningPrediction = true;
    });

    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 이미지 디코딩
      final image = img.decodeImage(widget.imageBytes);
      if (image == null) {
        throw Exception("이미지 디코딩 실패");
      }

      // 키포인트 중심점 계산
      double sumX = 0,
          sumY = 0;
      for (var point in currentKeypoints) {
        sumX += point['x'] as double;
        sumY += point['y'] as double;
      }
      final centerX = sumX / currentKeypoints.length;
      final centerY = sumY / currentKeypoints.length;

      // 키포인트 범위 계산
      double minX = double.infinity,
          maxX = 0;
      double minY = double.infinity,
          maxY = 0;

      for (var point in currentKeypoints) {
        final x = point['x'] as double;
        final y = point['y'] as double;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }

      // 정사각형 crop 사이즈 계산 (최대변 + padding)
      final padding = 0.5; // 50% 여유
      final cropSize = max(maxX - minX, maxY - minY) * (1 + padding);

      // 중심 기준으로 정사각형 크롭 영역 설정
      int x1 = (centerX - cropSize / 2).round();
      int y1 = (centerY - cropSize / 2).round();
      int x2 = (centerX + cropSize / 2).round();
      int y2 = (centerY + cropSize / 2).round();

      // 이미지 범위를 벗어나지 않도록 보정
      x1 = x1.clamp(0, image.width - 1);
      y1 = y1.clamp(0, image.height - 1);
      x2 = x2.clamp(0, image.width - 1);
      y2 = y2.clamp(0, image.height - 1);

      // 크롭 실행
      final croppedImage = img.copyCrop(
        image,
        x: x1,
        y: y1,
        width: x2 - x1,
        height: y2 - y1,
      );

      // Uint8List 변환
      final croppedBytes = Uint8List.fromList(img.encodePng(croppedImage));

      // 키포인트 예측
      List<Map<String, dynamic>> refinedKeypoints = await widget.predictKeypoints!(croppedBytes);

      // 예측된 키포인트를 원본 이미지 픽셀 좌표로 보정
      List<Map<String, dynamic>> adjustedKeypoints = refinedKeypoints.map((point) {
        final x = (point['x'] as double) + x1;
        final y = (point['y'] as double) + y1;
        return {'x': x, 'y': y};
      }).toList();

      // 로딩 닫기
      Navigator.pop(context);

      setState(() {
        currentKeypoints = adjustedKeypoints;
      });

    } catch (e) {
      // 에러 발생 시 로딩 닫고 에러 메시지 표시
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정밀 예측 실패: $e'))
      );
    } finally {
      setState(() {
        isRefiningPrediction = false;
      });
    }
  }


  // firebase로 날짜별 저장
  Future<void> _saveSelectedKeypoints() async {
    try {
      // 💡 위젯이 마운트 해제되었는지 확인
      if (!mounted) {
        print('위젯이 마운트 해제됨 - 저장 작업 취소');
        return;
      }

      final keypointsState = context.read<KeypointsState>();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {  // 마운트 확인 추가
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그인이 필요합니다')),
          );
        }
        return;
      }

      // 이미지 디코딩 추가 - 좌표 변환을 위해 필요
      final image = img.decodeImage(widget.imageBytes);
      if (image == null) {
        throw Exception("이미지 디코딩 실패");
      }
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();

      // 좌표 변환 (픽셀 -> mm 단위)
      final transformedKeypoints = _convertToOriginalCoordinates(
          currentKeypoints,
          imageWidth,
          imageHeight,
          widget.originalWidth,
          widget.originalHeight
      );

      // 라벨 정의
      const List<String> KEYPOINT_LABEL_NAMES = [
        "C2 bottom left", "C2 bottom right",
        "C7 bottom left", "C7 bottom right",
        "C2 centroid",
        "C3 top left", "C3 top right", "C3 bottom left", "C3 bottom right",
        "C4 top left", "C4 top right", "C4 bottom left", "C4 bottom right",
        "C5 top left", "C5 top right", "C5 bottom left", "C5 bottom right",
        "C6 top left", "C6 top right", "C6 bottom left", "C6 bottom right",
        "C7 top left", "C7 top right"
      ];

      // 현재 날짜 가져오기
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      // 이미지를 Firebase Storage에 업로드
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('images')
          .child('$dateStr')
          .child('${widget.region}_${widget.view}_$timeStr.jpg');

      // 💡 각 비동기 작업 후 마운트 상태 확인
      await storageRef.putData(widget.imageBytes);
      if (!mounted) return;  // 마운트 확인 추가

      final imageUrl = await storageRef.getDownloadURL();
      if (!mounted) return;  // 마운트 확인 추가

      // 변환된 좌표에 라벨 추가 (currentKeypoints 대신 transformedKeypoints 사용)
      final keypointsWithLabels = transformedKeypoints.asMap().map((index, point) {
        String label = index < KEYPOINT_LABEL_NAMES.length
            ? KEYPOINT_LABEL_NAMES[index]
            : "Unknown ${index}";
        return MapEntry(
            index,
            {
              'x': point['x'],
              'y': point['y'],
              'id': index,
              'label': label,
            }
        );
      }).values.toList();

      // 암호화 - 키포인트 좌표만 암호화
      final encryptedCoordinates = EncryptionUtil.encryptData(keypointsWithLabels);

      // Firestore에 데이터 저장 (민감한 좌표 데이터만 암호화)
      final keypointsDoc = await FirebaseFirestore.instance.collection('keypoints').add({
        'userId': user.uid,
        'region': widget.region,
        'view': widget.view,
        'date': dateStr,
        'timestamp': FieldValue
            .serverTimestamp(),
        'imageUrl': imageUrl,
        'encryptedCoordinates': encryptedCoordinates, // 암호화된 좌표 데이터
        'keypointCount': keypointsWithLabels.length,   // 일반 텍스트 메타데이터
        'keypointLabels': keypointsWithLabels.map((kp) => kp['label']).toList(), // 라벨은 일반 텍스트로 저장 (검색용)
      });
      if (!mounted) return;

      // 이미지 컬렉션에도 참조 추가
      await FirebaseFirestore.instance.collection('images').add({
        'userId': user.uid,
        'keypointsId': keypointsDoc.id,
        'region': widget.region,
        'view': widget.view,
        'date': dateStr,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      });
      if (!mounted) return;

      // 로컬에도 저장
      keypointsState.setOriginalImage(
        widget.region,
        widget.view,
        widget.imageBytes,
      );

      // 변환된 좌표 저장 (로컬에도 동일한 좌표 체계 사용)
      keypointsState.setOriginalKeypoints(
          widget.region,
          widget.view,
          transformedKeypoints
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지와 키포인트가 저장되었습니다')),
      );

    } catch (e) {
      print('저장 오류: $e');
      if (e is FirebaseException) {
        print('Firebase 오류 코드: ${e.code}, 메시지: ${e.message}');
      }
      if (mounted) {  // 마운트 확인 추가
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 타이틀 및 모드 전환 버튼
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Center(
              child: Text(
                '키포인트 미리보기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // 이미지와 키포인트 표시 영역
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: KeypointsViewer(
                  imageBytes: widget.imageBytes,
                  keypoints: currentKeypoints,
                ),
              ),
            ),
          ),

          // 버튼 영역
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                // 상단 버튼 행 (원래대로, 정밀 예측)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // firebase에 기록 저장
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // 저장이 완료될 때까지 기다린 후 화면 닫기
                          try {
                            await _saveSelectedKeypoints();
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            print('저장 실패: $e');
                            // 오류 처리는 _saveSelectedKeypoints 내부에서 이미 수행
                          }
                        },
                        icon: Icon(
                          Icons.save,
                          color: Colors.orange,
                        ),
                        label: Text(
                          '기록 저장',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.5), width: 1),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[850]
                              ?.withOpacity(0.5),
                          disabledForegroundColor: Colors.white.withOpacity(
                              0.5),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          // 통합된 단일 버튼
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: isRefiningPrediction
                                  ? null
                                  : ListEquals(currentKeypoints, originalKeypoints)
                                  ? _performRefinedPrediction   // 현재 원본 상태라면 정밀 예측 실행
                                  : () {                        // 정밀 예측 상태라면 원래대로 복원
                                setState(() {
                                  currentKeypoints = List<Map<String, dynamic>>.from(
                                    originalKeypoints,
                                  );
                                });
                              },
                              icon: isRefiningPrediction
                                  ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Icon(
                                ListEquals(currentKeypoints, originalKeypoints)
                                    ? Icons.auto_fix_high   // 원본 상태일 때 정밀 예측 아이콘
                                    : Icons.restore,        // 변경된 상태일 때 원래대로 아이콘
                                color: Colors.orange,
                                size: 18,
                              ),
                              label: Text(
                                isRefiningPrediction
                                    ? '처리 중...'
                                    : ListEquals(currentKeypoints, originalKeypoints)
                                    ? '정밀 예측'    // 원본 상태일 때 정밀 예측 텍스트
                                    : '원래대로',    // 변경된 상태일 때 원래대로 텍스트
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: Colors.grey[850]?.withOpacity(0.5),
                                disabledForegroundColor: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 12),

                // 하단 버튼 행 (취소, 저장) - spaceBetween 스타일 적용
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 취소 버튼
                    TextButton(
                      onPressed: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: Colors.white.withOpacity(0.5), width: 1),
                        ),
                      ),
                    ),


                    // 저장 버튼
                    ElevatedButton(
                      onPressed: _saveKeypoints,
                      child: Text(
                        '확인',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: Colors.white.withOpacity(0.5), width: 1),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey[850]?.withOpacity(
                            0.4),
                        disabledForegroundColor: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 리스트 비교 함수
bool ListEquals(List<Map<String, dynamic>> list1,
    List<Map<String, dynamic>> list2,) {
  if (list1.length != list2.length) return false;

  for (int i = 0; i < list1.length; i++) {
    if (list1[i]['x'] != list2[i]['x'] || list1[i]['y'] != list2[i]['y']) {
      return false;
    }
  }

  return true;
}
