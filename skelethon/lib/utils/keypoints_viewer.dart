import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class KeypointsViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final List<Map<String, dynamic>> keypoints;
  final Color pointColor;
  final Color lineColor;
  final double minScale;
  final double maxScale;
  final bool connectPoints;

  const KeypointsViewer({
    Key? key,
    required this.imageBytes,
    required this.keypoints,
    this.pointColor = Colors.red,
    this.lineColor = Colors.blue,
    this.minScale = 0.5,
    this.maxScale = 2.5,
    this.connectPoints = false,
  }) : super(key: key);

  @override
  KeypointsViewerState createState() => KeypointsViewerState();
}

class KeypointsViewerState extends State<KeypointsViewer> {
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  ui.Image? _image;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(KeypointsViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageBytes != oldWidget.imageBytes) {
      _resetAndReload();
    }
  }

  void _resetAndReload() {
    _transformationController.value = Matrix4.identity();
    _currentScale = 1.0;
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final image = await decodeImageFromList(widget.imageBytes);
      if (mounted) {
        setState(() {
          _image = image;
        });
      }
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  void _onScaleChanged(ScaleUpdateDetails details) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale != _currentScale && mounted) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          // 사이즈가 변경되면 기록
          _lastSize = Size(constraints.maxWidth, constraints.maxHeight);

          if (_image == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: InteractiveViewer(
              transformationController: _transformationController,
              onInteractionUpdate: _onScaleChanged,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              boundaryMargin: const EdgeInsets.all(8),
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 이미지
                    Center(
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // 키포인트 오버레이
                    if (_image != null)
                      CustomPaint(
                        painter: _KeypointsPainter(
                          image: _image!,
                          keypoints: widget.keypoints,
                          currentScale: _currentScale,
                          containerSize: _lastSize!,
                          pointColor: widget.pointColor,
                          lineColor: widget.lineColor,
                          connectPoints: widget.connectPoints,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}

class _KeypointsPainter extends CustomPainter {
  final ui.Image image;
  final List<Map<String, dynamic>> keypoints;
  final double currentScale;
  final Size containerSize;
  final Color pointColor;
  final Color lineColor;
  final bool connectPoints;

  static const double BASE_POINT_SIZE = 2.0;

  _KeypointsPainter({
    required this.image,
    required this.keypoints,
    required this.currentScale,
    required this.containerSize,
    required this.pointColor,
    required this.lineColor,
    required this.connectPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (keypoints.isEmpty) return;

    // 이미지 크기와 화면 크기의 비율 계산
    final imageRatio = image.width / image.height;
    final containerRatio = containerSize.width / containerSize.height;

    double renderWidth, renderHeight;
    double offsetX = 0, offsetY = 0;

    // 이미지가 화면에 맞춰진 실제 렌더링 크기 계산
    if (imageRatio > containerRatio) {
      // 이미지가 가로로 더 넓은 경우
      renderWidth = containerSize.width;
      renderHeight = containerSize.width / imageRatio;
      offsetY = (containerSize.height - renderHeight) / 2;
    } else {
      // 이미지가 세로로 더 높은 경우
      renderHeight = containerSize.height;
      renderWidth = containerSize.height * imageRatio;
      offsetX = (containerSize.width - renderWidth) / 2;
    }

    // 원본 이미지 좌표에서 화면 좌표로 변환하는 비율
    final scaleX = renderWidth / image.width;
    final scaleY = renderHeight / image.height;

    // 점 그리기 스타일
    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    // 선 그리기 스타일
    final linePaint = Paint()
      ..color = lineColor.withOpacity(0.7)
      ..strokeWidth = 2 / currentScale
      ..style = PaintingStyle.stroke;

    // 모든 포인트의 변환된 좌표 저장
    final List<Offset> transformedPoints = [];

    // 포인트 그리기
    for (var point in keypoints) {
      if (point['x'] != null && point['y'] != null) {
        // 이미지 내 좌표를 화면 좌표로 변환
        final x = point['x'] * scaleX + offsetX;
        final y = point['y'] * scaleY + offsetY;

        final transformedPoint = Offset(x, y);
        transformedPoints.add(transformedPoint);

        // 확대/축소에 따라 포인트 크기 조정
        final adjustedSize = BASE_POINT_SIZE / currentScale;

        // 원 그리기
        canvas.drawCircle(transformedPoint, adjustedSize, pointPaint);
      }
    }

    // 선 그리기 (옵션)
    if (connectPoints && transformedPoints.length > 1) {
      for (int i = 0; i < transformedPoints.length - 1; i++) {
        canvas.drawLine(
          transformedPoints[i],
          transformedPoints[i + 1],
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KeypointsPainter oldDelegate) =>
      oldDelegate.image != image ||
          oldDelegate.keypoints != keypoints ||
          oldDelegate.currentScale != currentScale ||
          oldDelegate.containerSize != containerSize;
}