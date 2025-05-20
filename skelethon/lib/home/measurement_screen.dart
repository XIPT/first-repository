import 'package:flutter/material.dart';
import 'dart:typed_data';

import '/utils/geometry.dart';
import '/utils/enums.dart';

class XrayMeasurementScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const XrayMeasurementScreen({
    Key? key,
    required this.imageBytes,
  }) : super(key: key);

  @override
  _XrayMeasurementScreenState createState() => _XrayMeasurementScreenState();
}

class _XrayMeasurementScreenState extends State<XrayMeasurementScreen> with WidgetsBindingObserver {
  // 측정 관련 상태 변수
  MeasurementMode _currentMode = MeasurementMode.none;
  bool _isDragging = false;
  bool _hasCompletedDrag = false;
  Offset? _startPoint;
  Offset? _endPoint;
  double _pixelDistance = 0.0;
  double _realMmDistance = 0.0;
  double _calculatedPixelToMm = 0.0;

  // 이미지 크기 관련 변수
  bool _isImageSizeLoaded = false;
  int _originalWidth = 0;
  int _originalHeight = 0;
  double _displayedImageWidth = 0;
  double _displayedImageHeight = 0;
  double _horizontalRatio = 1.0;
  double _verticalRatio = 1.0;
  Rect? _imageRect;

  // 동적 보정 관련 변수
  double _renderingCorrectionFactor = 1.0;
  bool _isCorrectionFactorCalculated = false;

  // 컨트롤러 및 키
  final TextEditingController _mmController = TextEditingController();
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mmController.text = '';
    _loadImageInfo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateImageSize();

      // 지연 후 실제 이미지 크기 확인 및 보정 계수 계산
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _updateRenderingCorrectionFactor();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mmController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _updateImageSize();
        _updateRenderingCorrectionFactor();
      });
    }
  }

  // 이미지 원본 크기 정보 로드
  void _loadImageInfo() {
    final image = Image.memory(widget.imageBytes);
    image.image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) {
          setState(() {
            _originalWidth = info.image.width;
            _originalHeight = info.image.height;
            _isImageSizeLoaded = true;
          });
          _updateImageSize();
        })
    );
  }

  // 이미지 크기 및 위치 계산
  void _updateImageSize() {
    if (!mounted || !_isImageSizeLoaded) return;

    try {
      final screenSize = MediaQuery
          .of(context)
          .size;
      final safeArea = MediaQuery
          .of(context)
          .padding;
      final appBarHeight = 56.0;

      final containerWidth = screenSize.width - 32;
      final containerHeight = screenSize.height - safeArea.top -
          safeArea.bottom - appBarHeight - 220;
      final containerSize = Size(containerWidth, containerHeight);

      final double imageAspectRatio = _originalWidth / _originalHeight;

      double width, height;
      if (containerSize.width / containerSize.height > imageAspectRatio) {
        height = containerSize.height;
        width = height * imageAspectRatio;
      } else {
        width = containerSize.width;
        height = width / imageAspectRatio;
      }

      final double left = (containerSize.width - width) / 2;
      final double top = (containerSize.height - height) / 2;

      setState(() {
        _displayedImageWidth = width;
        _displayedImageHeight = height;
        _imageRect = Rect.fromLTWH(left, top, width, height);
        _horizontalRatio = _originalWidth / width;
        _verticalRatio = _originalHeight / height;
      });

      // 이미지 정보 업데이트 후 보정 계수 재계산
      _updateRenderingCorrectionFactor();
    } catch (e) {
      print('이미지 크기 업데이트 중 오류: $e');
    }
  }

  // 실제 렌더링된 이미지 크기 확인 및 보정 계수 계산
  void _updateRenderingCorrectionFactor() {
    if (_imageKey.currentContext != null) {
      final RenderBox renderBox = _imageKey.currentContext!
          .findRenderObject() as RenderBox;
      final Size actualSize = renderBox.size;

      // 실제 렌더링 비율 계산
      final actualHRatio = _originalWidth / actualSize.width;
      final actualVRatio = _originalHeight / actualSize.height;

      // 계산된 비율과 실제 비율의 차이로 보정 계수 계산
      final hCorrection = actualHRatio / _horizontalRatio;
      final vCorrection = actualVRatio / _verticalRatio;

      // 가로 세로 보정 계수의 평균 사용 (일반적으로 비슷한 값이어야 함)
      setState(() {
        _renderingCorrectionFactor = (hCorrection + vCorrection) / 2;
        _isCorrectionFactorCalculated = true;
      });

      print('동적 보정 계수 계산: $_renderingCorrectionFactor');
    }
  }

  // 측정 모드 설정
  void _setMeasurementMode(MeasurementMode mode) {
    if (_currentMode == mode) {
      setState(() {
        _currentMode = MeasurementMode.none;
      });
    } else {
      setState(() {
        _currentMode = mode;
        _startPoint = null;
        _endPoint = null;
        _pixelDistance = 0;
        _hasCompletedDrag = false;
      });
    }
  }

  // 화면 좌표를 원본 이미지 좌표로 변환
  Offset _convertToOriginalCoordinates(Offset screenPosition) {
    if (_imageRect == null || !_isImageSizeLoaded) {
      return screenPosition;
    }

    final relativeX = (screenPosition.dx - _imageRect!.left) /
        _imageRect!.width;
    final relativeY = (screenPosition.dy - _imageRect!.top) /
        _imageRect!.height;

    final clampedRelativeX = relativeX.clamp(0.0, 1.0);
    final clampedRelativeY = relativeY.clamp(0.0, 1.0);

    final originalX = clampedRelativeX * _originalWidth;
    final originalY = clampedRelativeY * _originalHeight;

    return Offset(originalX, originalY);
  }

  // 원본 이미지 좌표를 화면 좌표로 변환
  Offset _convertToScreenCoordinates(Offset originalPosition) {
    if (_imageRect == null || !_isImageSizeLoaded) {
      return originalPosition;
    }

    final relativeX = originalPosition.dx / _originalWidth;
    final relativeY = originalPosition.dy / _originalHeight;

    final screenX = _imageRect!.left + relativeX * _imageRect!.width;
    final screenY = _imageRect!.top + relativeY * _imageRect!.height;

    return Offset(screenX, screenY);
  }

  // 픽셀 거리 계산 - 원본 이미지 기준
  void _calculatePixelDistance() {
    if (_startPoint == null || _endPoint == null) return;

    // 원본 좌표에서 직접 거리 계산
    double rawDistance;
    if (_currentMode == MeasurementMode.horizontal) {
      rawDistance = (_endPoint!.dx - _startPoint!.dx).abs();
    } else {
      rawDistance = (_endPoint!.dy - _startPoint!.dy).abs();
    }

    // 동적 보정 계수 적용
    if (_isCorrectionFactorCalculated) {
      _pixelDistance = rawDistance * _renderingCorrectionFactor;
    } else {
      // 아직 보정 계수가 계산되지 않았으면 기본값 사용
      _pixelDistance = rawDistance;
    }
  }

  // 픽셀당 mm 변환 비율 계산
  void _calculatePixelToMm() {
    if (_pixelDistance <= 0 || _realMmDistance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('유효한 측정값이 필요합니다. 선을 그리고 실제 거리를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _calculatedPixelToMm = _realMmDistance / _pixelDistance;
      MeasurementConstants.updatePixelToMm(_calculatedPixelToMm);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '설정 완료: 1 픽셀 = ${_calculatedPixelToMm.toStringAsFixed(6)} mm'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 드래그 시작
  void _onDragStart(DragStartDetails details) {
    if (_currentMode == MeasurementMode.none) return;
    if (_imageRect == null || !_isImageSizeLoaded) return;

    final screenPosition = details.localPosition;
    final containerRect = Rect.fromLTWH(0, 0, MediaQuery
        .of(context)
        .size
        .width, MediaQuery
        .of(context)
        .size
        .height);
    if (!containerRect.contains(screenPosition)) return;

    final originalPosition = _convertToOriginalCoordinates(screenPosition);

    setState(() {
      _isDragging = true;
      _hasCompletedDrag = false;
      _startPoint = originalPosition;
      _endPoint = originalPosition;
    });
  }

  // 드래그 업데이트
  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _currentMode == MeasurementMode.none) return;

    final screenPosition = details.localPosition;
    final originalPosition = _convertToOriginalCoordinates(screenPosition);

    Offset newEndPoint;
    if (_currentMode == MeasurementMode.horizontal) {
      newEndPoint = Offset(originalPosition.dx, _startPoint!.dy);
    } else {
      newEndPoint = Offset(_startPoint!.dx, originalPosition.dy);
    }

    setState(() {
      _endPoint = newEndPoint;
      _calculatePixelDistance();
    });
  }

  // 드래그 종료
  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging || _currentMode == MeasurementMode.none) return;

    setState(() {
      _isDragging = false;
      _hasCompletedDrag = true;
      _calculatePixelDistance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('거리 측정', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildMeasurementControls(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageView(),
              ),
            ),
          ),
          _buildMeasurementInfoArea(),
        ],
      ),
    );
  }

  // 측정 컨트롤 UI
  Widget _buildMeasurementControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.straighten, size: 18),
            label: const Text('가로'),
            onPressed: () => _setMeasurementMode(MeasurementMode.horizontal),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentMode == MeasurementMode.horizontal
                  ? Colors.blue
                  : Colors.grey[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.height, size: 18),
            label: const Text('세로'),
            onPressed: () => _setMeasurementMode(MeasurementMode.vertical),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentMode == MeasurementMode.vertical ? Colors
                  .orange : Colors.grey[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // 이미지 뷰
  Widget _buildImageView() {
    return Stack(
      children: [
        Center(
          child: Image.memory(
            widget.imageBytes,
            key: _imageKey,
            fit: BoxFit.contain,
          ),
        ),
        if (_startPoint != null && _endPoint != null &&
            _currentMode != MeasurementMode.none)
          CustomPaint(
            size: Size.infinite,
            painter: LinePainter(
              start: _startPoint!,
              end: _endPoint!,
              isHorizontal: _currentMode == MeasurementMode.horizontal,
              color: _hasCompletedDrag ? Colors.green : Colors.blue,
              calculatedDistance: _pixelDistance,
              convertToScreen: _convertToScreenCoordinates,
            ),
          ),
        if (_currentMode != MeasurementMode.none)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: _onDragStart,
              onPanUpdate: _onDragUpdate,
              onPanEnd: _onDragEnd,
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }

  // 측정 정보 영역
  // 측정 정보 영역
  Widget _buildMeasurementInfoArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'X-ray 사이즈 : ',
                  style: const TextStyle(
                    color: Colors.orange, // X-ray 크기: 부분만 파란색으로 강조
                    fontSize: 14,
                    fontWeight: FontWeight.bold, // 굵게 표시
                  ),
                ),
                TextSpan(
                  text: _isImageSizeLoaded
                      ? '$_originalWidth × $_originalHeight px'
                      : '로딩 중...',
                  style: const TextStyle(
                    color: Colors.white70, // 나머지 텍스트는 원래 색상 유지
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Colors.grey),

          // 측정 거리 정보 - 항상 고정된 높이로 표시하도록 수정
          Container(
            height: 44,
            // 고정된 높이 설정
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _pixelDistance > 0 ? Colors.blue.withOpacity(0.2) : Colors
                  .transparent,
              borderRadius: BorderRadius.circular(4),
              border: _pixelDistance > 0
                  ? Border.all(color: Colors.blue.withOpacity(0.5))
                  : null,
            ),
            alignment: Alignment.centerLeft,
            // 내용 중앙 정렬
            child: _pixelDistance > 0
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('측정된 거리:', style: TextStyle(color: Colors.white)),
                Text(
                  '${_pixelDistance.toStringAsFixed(1)} 픽셀',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            )
                : const Text(
              '측정선을 그려 거리를 측정하세요',
              style: TextStyle(
                  color: Colors.white70, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mmController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '실제 거리 (mm)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue)),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _realMmDistance = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _pixelDistance > 0 ? _calculatePixelToMm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                child: const Text('계산'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 계산 결과 영역 - 항상 일정한 공간 확보
          Container(
            height: _calculatedPixelToMm > 0 ? 60 : 0, // 내용이 있을 때만 높이 할당
            padding: _calculatedPixelToMm > 0
                ? const EdgeInsets.all(12)
                : EdgeInsets.zero,
            decoration: _calculatedPixelToMm > 0
                ? BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            )
                : null,
            child: _calculatedPixelToMm > 0
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                    '계산된 픽셀당 mm:', style: TextStyle(color: Colors.white)),
                Text(
                  '${_calculatedPixelToMm.toStringAsFixed(6)} mm/px',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            )
                : null,
          ),

          const SizedBox(height: 4),

          ValueListenableBuilder<double>(
            valueListenable: MeasurementConstants.pixelToMmNotifier,
            builder: (context, value, child) {
              return Text(
                '현재 적용값: 1 픽셀 = ${value.toStringAsFixed(6)} mm',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 선을 그리는 클래스
class LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final bool isHorizontal;
  final Color color;
  final double calculatedDistance;
  final Function(Offset) convertToScreen;

  LinePainter({
    required this.start,
    required this.end,
    required this.isHorizontal,
    required this.color,
    required this.calculatedDistance,
    required this.convertToScreen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final screenStart = convertToScreen(start);
      final screenEnd = convertToScreen(end);

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.butt;

      final markerPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.butt;

      canvas.drawLine(screenStart, screenEnd, linePaint);

      final double markerLength = 10.0;

      if (isHorizontal) {
        canvas.drawLine(
          Offset(screenStart.dx, screenStart.dy - markerLength / 2),
          Offset(screenStart.dx, screenStart.dy + markerLength / 2),
          markerPaint,
        );
        canvas.drawLine(
          Offset(screenEnd.dx, screenEnd.dy - markerLength / 2),
          Offset(screenEnd.dx, screenEnd.dy + markerLength / 2),
          markerPaint,
        );
      } else {
        canvas.drawLine(
          Offset(screenStart.dx - markerLength / 2, screenStart.dy),
          Offset(screenStart.dx + markerLength / 2, screenStart.dy),
          markerPaint,
        );
        canvas.drawLine(
          Offset(screenEnd.dx - markerLength / 2, screenEnd.dy),
          Offset(screenEnd.dx + markerLength / 2, screenEnd.dy),
          markerPaint,
        );
      }

      final textSpan = TextSpan(
        text: '${calculatedDistance.toStringAsFixed(1)} px',
        style: const TextStyle(
          color: Colors.white,
          backgroundColor: Colors.black54,
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final textPosition = isHorizontal
          ? Offset((screenStart.dx + screenEnd.dx) / 2 - textPainter.width / 2, screenStart.dy - 20)
          : Offset(screenStart.dx + 10, (screenStart.dy + screenEnd.dy) / 2 - textPainter.height / 2);

      final backgroundRect = Rect.fromLTWH(
        textPosition.dx - 4,
        textPosition.dy - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRect(backgroundRect, Paint()..color = Colors.black54);

      textPainter.paint(canvas, textPosition);
    } catch (e) {
      print('선 그리기 오류: $e');
    }
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.isHorizontal != isHorizontal ||
        oldDelegate.color != color ||
        oldDelegate.calculatedDistance != calculatedDistance;
  }
}