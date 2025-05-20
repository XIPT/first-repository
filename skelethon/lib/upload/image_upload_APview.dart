import 'dart:math' as Math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image/image.dart' as img;

import '/utils/enums.dart';
import '/utils/region_crop.dart';

class FileUploadAPView extends StatefulWidget {
  final UploadMode? initialMode;

  const FileUploadAPView({
    super.key,
    this.initialMode,
  });

  @override
  State<FileUploadAPView> createState() => _FileUploadAPViewState();
}

class _FileUploadAPViewState extends State<FileUploadAPView> {
  Uint8List? selectedBytes;
  String? fileName;
  String? selectedFilePath;
  bool isFlipped = false;

  // 업로드 모드 상태 추가
  late UploadMode uploadMode;

  // 선택된 부위 (부분 모드일 때만 사용)
  String? selectedRegion;

  // 크롭 관련 상태 추가
  Rect? cropRect;
  bool isCropping = false;
  final cropKey = GlobalKey();
  Offset? cropStart;
  Offset? cropEnd;

  // 초기 크롭 설정 여부를 추적하는 플래그 추가
  bool isInitialCropSet = false;

  // 크롭 조절 핸들 관련 변수
  bool isDraggingHandle = false;
  int selectedHandle = -1; // 0: top-left, 1: top-right, 2: bottom-right, 3: bottom-left, 4: entire
  final double handleSize = 20.0;

  // 이미지 스케일 계산용
  double imageScale = 1.0;

  // 이미지 표시 영역 정보
  double? imageLeft;
  double? imageTop;
  double? imageRight;
  double? imageBottom;
  double? imageWidth;
  double? imageHeight;

  // 현재 크롭 작업이 가능한지 여부
  bool canCrop = false;

  // 부위별 비율 정보는 이제 유틸 클래스에서 가져옵니다.
  Map<String, Map<String, dynamic>> get regionSettings => RegionCropUtil.regionSettings;

  @override
  void initState() {
    super.initState();
    // 초기 모드 설정
    uploadMode = widget.initialMode == UploadMode.cropRegion
        ? UploadMode.cropRegion
        : UploadMode.fullBody;
  }

  // 이미지 영역 계산 함수
  void _calculateImageDisplayRect() {
    if (selectedBytes == null || cropKey.currentContext == null) return;

    try {
      final renderBox = cropKey.currentContext!.findRenderObject() as RenderBox;
      final result = RegionCropUtil.calculateImageDisplayRect(
        imageBytes: selectedBytes!,
        renderBox: renderBox,
      );

      setState(() {
        imageScale = result['imageScale']!;
        imageLeft = result['imageLeft']!;
        imageTop = result['imageTop']!;
        imageRight = result['imageRight']!;
        imageBottom = result['imageBottom']!;
        imageWidth = result['imageWidth']!;
        imageHeight = result['imageHeight']!;
      });

      print('이미지 표시 영역: left=$imageLeft, top=$imageTop, right=$imageRight, bottom=$imageBottom');
    } catch (e) {
      print('❌ 이미지 영역 계산 오류: $e');
    }
  }

  // 부위별 초기 크롭 영역 설정 메서드
  void _setupInitialCropRectForRegion() {
    if (selectedBytes == null || selectedRegion == null || cropKey.currentContext == null) return;

    // 이미지 표시 영역 계산
    _calculateImageDisplayRect();
    if (imageLeft == null || imageTop == null || imageWidth == null || imageHeight == null) return;

    try {
      final initialCropRect = RegionCropUtil.calculateInitialCropRect(
        region: selectedRegion!,
        imageScale: imageScale,
        imageLeft: imageLeft!,
        imageTop: imageTop!,
        imageRight: imageRight!,
        imageBottom: imageBottom!,
        imageWidth: imageWidth!,
        imageHeight: imageHeight!,
      );

      setState(() {
        cropRect = initialCropRect;
        cropStart = initialCropRect.topLeft;
        cropEnd = initialCropRect.bottomRight;
        isInitialCropSet = true;
      });

      print('부위별 초기 크롭 설정 간소화: $selectedRegion, 크기=${initialCropRect.width}x${initialCropRect.height}');
    } catch (e) {
      print('❌ 부위별 크롭 초기화 에러: $e');
    }
  }

  // 특정 핸들이 클릭되었는지 확인하는 함수
  int _getHandleAtPosition(Offset position) {
    if (cropRect == null) return -1;

    return RegionCropUtil.getHandleAtPosition(position, cropRect!, handleSize);
  }

  // 크롭 영역 제약 조건 적용
  Rect _constrainCropRect(Rect rect) {
    if (cropKey.currentContext == null || selectedBytes == null || selectedRegion == null) return rect;

    // 이미지 표시 영역이 계산되지 않았으면 계산
    if (imageLeft == null || imageTop == null) {
      _calculateImageDisplayRect();
    }

    // 이미지 영역 정보가 없을 경우 기본 처리
    if (imageLeft == null || imageTop == null || imageRight == null || imageBottom == null) {
      return rect;
    }

    return RegionCropUtil.constrainCropRect(
      rect: rect,
      region: selectedRegion!,
      imageScale: imageScale,
      imageLeft: imageLeft!,
      imageTop: imageTop!,
      imageRight: imageRight!,
      imageBottom: imageBottom!,
      imageWidth: imageWidth!,
      imageHeight: imageHeight!,
      selectedHandle: selectedHandle,
      isCropping: isCropping,
      cropStart: cropStart,
      cropEnd: cropEnd,
    );
  }

  // 이미지 처리 함수
  Uint8List? getProcessedBytes() {
    if (selectedBytes == null) return null;

    if (uploadMode == UploadMode.fullBody) {
      // 전신 모드: 좌우반전만 적용
      return RegionCropUtil.processImage(
        imageBytes: selectedBytes!,
        isFlipped: isFlipped,
        selectedRegion: null,
        cropRect: null,
        imageLeft: null,
        imageTop: null,
        imageScale: imageScale,
      );
    } else if (cropRect != null && cropKey.currentContext != null) {
      // 크롭 모드: 크롭 영역 적용
      // 이미지 영역 정보가 없으면 계산
      if (imageLeft == null || imageTop == null) {
        _calculateImageDisplayRect();
      }

      if (imageLeft == null || imageTop == null) {
        print('❌ 이미지 영역을 계산할 수 없습니다.');
        return selectedBytes;
      }

      return RegionCropUtil.processImage(
        imageBytes: selectedBytes!,
        isFlipped: isFlipped,
        selectedRegion: selectedRegion,
        cropRect: cropRect,
        imageLeft: imageLeft,
        imageTop: imageTop,
        imageScale: imageScale,
      );
    } else {
      // 크롭 영역이 없거나 컨텍스트가 없으면 원본 반환
      return selectedBytes;
    }
  }

  // 이미지 선택 함수
  Future<void> _selectImage() async {
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']),
        ],
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          selectedBytes = bytes;
          fileName = file.name;
          selectedFilePath = file.path;
          isFlipped = false;
          // 파일 변경 시 크롭 정보 초기화
          cropRect = null;
          cropStart = null;
          cropEnd = null;
          isInitialCropSet = false; // 파일 변경 시 초기 크롭 설정 플래그 초기화
          canCrop = false; // 크롭 가능 상태 초기화

          // 이미지 영역 정보 초기화
          imageLeft = null;
          imageTop = null;
          imageRight = null;
          imageBottom = null;
          imageWidth = null;
          imageHeight = null;

          // 선택된 부위 초기화
          selectedRegion = null;
        });

        // 이미지 로드된 후 이미지 표시 영역 계산 (기본 설정)
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            _calculateImageDisplayRect();
          }
        });
      }
    } catch (e) {
      print('❌ 파일 선택 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 선택 오류: $e')),
        );
      }
    }
  }

  // 부위 선택 버튼 위젯 - 세로형 (이미지 옆에 배치용)
  Widget _buildRegionSelectionButtonsVertical() {
    // 부분 모드에서만 표시
    if (uploadMode != UploadMode.cropRegion || selectedBytes == null) {
      return SizedBox.shrink();
    }

    // 부위 선택 버튼 정의
    final regions = [
      {'id': 'cervical', 'label': '경추'},
      {'id': 'thoracic', 'label': '흉추'},
      {'id': 'lumbar', 'label': '요추'},
      {'id': 'pelvic', 'label': '골반'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 부위 선택 버튼들
          for (final region in regions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: _buildRegionButton(region),
            ),
        ],
      ),
    );
  }

  // 개별 부위 선택 버튼 위젯
  Widget _buildRegionButton(Map<String, String> region) {
    final isSelected = selectedRegion == region['id'];
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedRegion = region['id'];
            // 부위 선택 시 크롭 가능 상태로 변경
            canCrop = true;

            // 부위 변경 시 기존 크롭 영역 초기화
            cropRect = null;
            cropStart = null;
            cropEnd = null;
            isInitialCropSet = false;

            // 부위에 맞게 초기 크롭 영역 설정
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _calculateImageDisplayRect();
                _setupInitialCropRectForRegion();
              }
            });
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Colors.orange,
          backgroundColor: isSelected ? Colors.orange : Colors.black,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: Colors.orange,
              width: isSelected ? 1 : 1,
            ),
          ),
          elevation: isSelected ? 3 : 0,
        ),
        child: Text(
          region['label']!,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  // 이미지 미리보기 위젯
  Widget _buildImagePreview() {
    if (selectedBytes == null) {
      return const Center(
        child: Text(
          '이미지가 없습니다',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    return GestureDetector(
      key: cropKey,
      // 부분 모드에서만 제스처 활성화 + 부위 선택 후에만 활성화
      onPanStart: (uploadMode == UploadMode.cropRegion && canCrop)
          ? (details) {
        // 어떤 핸들이 터치되었는지 확인
        final handle = _getHandleAtPosition(details.localPosition);
        setState(() {
          selectedHandle = handle;
          if (handle == -1) {
            // 새로운 크롭 영역 시작
            isCropping = true;
            cropStart = details.localPosition;
            cropEnd = details.localPosition;
            cropRect = Rect.fromPoints(cropStart!, cropEnd!);
          }
        });
      }
          : null,
      // 이미지 미리보기 위젯의 onPanUpdate 부분
      onPanUpdate: (uploadMode == UploadMode.cropRegion && canCrop)
          ? (details) {
        if (selectedHandle >= 0) {
          // 핸들 또는 전체 영역 드래그
          if (cropRect != null) {
            setState(() {
              Rect newRect;

              switch (selectedHandle) {
                case 0: // 좌상단
                  newRect = Rect.fromLTRB(
                      details.localPosition.dx,
                      details.localPosition.dy,
                      cropRect!.right,
                      cropRect!.bottom);
                  break;
                case 1: // 우상단
                  newRect = Rect.fromLTRB(
                      cropRect!.left,
                      details.localPosition.dy,
                      details.localPosition.dx,
                      cropRect!.bottom);
                  break;
                case 2: // 우하단
                  newRect = Rect.fromLTRB(
                      cropRect!.left,
                      cropRect!.top,
                      details.localPosition.dx,
                      details.localPosition.dy);
                  break;
                case 3: // 좌하단
                  newRect = Rect.fromLTRB(
                      details.localPosition.dx,
                      cropRect!.top,
                      cropRect!.right,
                      details.localPosition.dy);
                  break;
                case 4: // 전체 영역 이동
                // 이동 시에는 크기/비율 변화가 없어야 함
                  final dx = details.delta.dx;
                  final dy = details.delta.dy;

                  // 이동 범위 제한 계산
                  double newLeft = cropRect!.left + dx;
                  double newTop = cropRect!.top + dy;
                  double newRight = cropRect!.right + dx;
                  double newBottom = cropRect!.bottom + dy;

                  // 이미지 영역을 벗어나는지 확인하고 조정
                  if (newLeft < imageLeft!) {
                    double adjust = imageLeft! - newLeft;
                    newLeft += adjust;
                    newRight += adjust;
                  }

                  if (newTop < imageTop!) {
                    double adjust = imageTop! - newTop;
                    newTop += adjust;
                    newBottom += adjust;
                  }

                  if (newRight > imageRight!) {
                    double adjust = newRight - imageRight!;
                    newLeft -= adjust;
                    newRight -= adjust;
                  }

                  if (newBottom > imageBottom!) {
                    double adjust = newBottom - imageBottom!;
                    newTop -= adjust;
                    newBottom -= adjust;
                  }

                  newRect = Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
                  break;
                default:
                  newRect = cropRect!;
                  break;
              }

              // 제약 조건 적용
              cropRect = _constrainCropRect(newRect);

              // 시작점과 종료점 업데이트
              cropStart = cropRect!.topLeft;
              cropEnd = cropRect!.bottomRight;
            });
          }
        } else if (isCropping) {
          // 새 크롭 영역 생성 중
          setState(() {
            cropEnd = details.localPosition;
            Rect preConstraintRect = Rect.fromPoints(cropStart!, cropEnd!);

            // 제약 조건 적용
            cropRect = _constrainCropRect(preConstraintRect);

            // 제약 적용 후의 끝점 업데이트 (방향 유지를 위해)
            if (cropStart!.dx < cropEnd!.dx) {
              if (cropStart!.dy < cropEnd!.dy) {
                // 오른쪽 아래로 드래그
                cropEnd = cropRect!.bottomRight;
              } else {
                // 오른쪽 위로 드래그
                cropEnd = Offset(cropRect!.right, cropRect!.top);
              }
            } else {
              if (cropStart!.dy < cropEnd!.dy) {
                // 왼쪽 아래로 드래그
                cropEnd = Offset(cropRect!.left, cropRect!.bottom);
              } else {
                // 왼쪽 위로 드래그
                cropEnd = cropRect!.topLeft;
              }
            }
          });
        }
      }
          : null,
      onPanEnd: (uploadMode == UploadMode.cropRegion && canCrop)
          ? (details) {
        setState(() {
          isCropping = false;
          selectedHandle = -1;
        });
      }
          : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경을 어둡게 설정하여 이미지가 더 잘 보이도록 함
          Container(color: Colors.black),

          // 이미지 표시
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(isFlipped ? 3.14159 : 0),
                child: Image.memory(
                  selectedBytes!,
                  fit: BoxFit.contain, // 항상 contain으로 설정하여 이미지 전체가 보이도록
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),

          // 부위 선택 안내 메시지 (부위 선택 전에만 표시)
          if (uploadMode == UploadMode.cropRegion && !canCrop)
            Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '👆 위에서 크롭할 부위를 먼저 선택해주세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 크롭 모드이고 크롭 영역이 있을 때 크롭 영역 표시
          if (uploadMode == UploadMode.cropRegion && cropRect != null && canCrop)
            Positioned.fromRect(
              rect: cropRect!,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.orange,
                    width: 2,
                  ),
                  color: Colors.orange.withOpacity(0.1),
                ),
              ),
            ),

          // 크롭 핸들 표시
          if (uploadMode == UploadMode.cropRegion && cropRect != null && canCrop)
            ...[
              // 네 모서리에 핸들 표시
              Positioned(
                left: cropRect!.left - handleSize / 2,
                top: cropRect!.top - handleSize / 2,
                child: RegionCropUtil.buildCropHandle(0, handleSize),
              ),
              Positioned(
                left: cropRect!.right - handleSize / 2,
                top: cropRect!.top - handleSize / 2,
                child: RegionCropUtil.buildCropHandle(1, handleSize),
              ),
              Positioned(
                left: cropRect!.right - handleSize / 2,
                top: cropRect!.bottom - handleSize / 2,
                child: RegionCropUtil.buildCropHandle(2, handleSize),
              ),
              Positioned(
                left: cropRect!.left - handleSize / 2,
                top: cropRect!.bottom - handleSize / 2,
                child: RegionCropUtil.buildCropHandle(3, handleSize),
              ),
            ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          margin: const EdgeInsets.all(6.0),
          padding: const EdgeInsets.all(10.0),
          height: MediaQuery.of(context).size.height * 0.8,
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
            children: [
            // 업로드 모드 헤더
            Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              uploadMode == UploadMode.fullBody ? '전신 업로드 정면뷰 모드' : '부위 업로드 정면뷰 모드',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 이미지 미리보기 영역과 부위 선택 버튼을 가로로 배치
          Expanded(
            flex: 6, // 전체 높이의 대부분을 차지
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 이미지 미리보기 (왼쪽)
                Expanded(
                  flex: 8, // 이미지가 더 넓은 공간 차지
                  child: Container(
                    margin: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: _buildImagePreview(),
                  ),
                ),

                // 부위 선택 버튼 (오른쪽)
                if (uploadMode == UploadMode.cropRegion && selectedBytes != null)
                  Expanded(
                    flex: 2, // 부위 선택 버튼은 더 좁은 공간
                    child: Container(
                      margin: const EdgeInsets.only(left: 4.0),
                      child: _buildRegionSelectionButtonsVertical(),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 파일 선택 및 기타 버튼을 나란히 배치
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 파일 선택 버튼
              ElevatedButton.icon(
                onPressed: _selectImage,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.orange,
                  size: 20,
                ),
                label: Text(
                  '파일선택',
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
                ),
              ),
              const SizedBox(width: 12),

              // 좌우반전 버튼
              ElevatedButton.icon(
                onPressed: selectedBytes != null
                    ? () {
                  setState(() {
                    isFlipped = !isFlipped;
                  });
                }
                    : null,
                icon: Icon(
                  Icons.flip,
                  color: Colors.orange,
                  size: 18,
                ),
                label: Text(
                  isFlipped ? '원래대로' : '좌우반전',
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
            ],
          ),
          const SizedBox(height: 10),

          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              // 취소 버튼
              TextButton(
              onPressed: () => Navigator.pop(context),
      child: Text(
        '취소',
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
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
        ),
      ),
    ),

    // 저장 버튼
    ElevatedButton(
    onPressed: selectedBytes != null &&
    (uploadMode == UploadMode.fullBody ||
    (uploadMode == UploadMode.cropRegion &&
    cropRect != null &&
    // 부분 모드에서는 부위 선택도 필수
    (uploadMode != UploadMode.cropRegion || selectedRegion != null)))
    ? () {
    try {
    final processed = getProcessedBytes();
    if (processed != null) {
    Navigator.pop(context, {
    'bytes': processed,
    'name': fileName,
    'path': selectedFilePath,
    'uploadMode': uploadMode.toString(),
    // 부분 모드에서 선택된 부위 정보 추가
    'selectedRegion': selectedRegion,
    });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 처리 중 오류가 발생했습니다.')),
      );
    }
    } catch (e) {
      print('❌ 저장 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 오류: $e')),
      );
    }
    }
        : null,
      child: Text(
        '저장',
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
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        elevation: 0,
        disabledBackgroundColor: Colors.grey[850]?.withOpacity(0.4),
        disabledForegroundColor: Colors.white.withOpacity(0.4),
      ),
    ),
              ],
          ),
            ],
          ),
      ),
    );
  }
}