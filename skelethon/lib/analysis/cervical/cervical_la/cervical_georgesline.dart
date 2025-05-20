import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '/state/keypoints_state.dart';

import '/utils/enums.dart';
import '/utils/linedrawing.dart';
import '/utils/textdrawing.dart';

import '/state/measurement_state_helper.dart';

class GeorgesLinePage extends StatefulWidget {
  const GeorgesLinePage({super.key});

  @override
  State<GeorgesLinePage> createState() => _GeorgesLinePageState();
}

class _GeorgesLinePageState extends State<GeorgesLinePage> {

  // 원본 이미지 크기를 저장할 변수
  Size? originalImageSize;
  Size? displaySize;

  // 확대/축소 컨트롤러
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getImageSize();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _getImageSize() async {
    final keypointsState = Provider.of<KeypointsState>(context, listen: false);
    final originalImage = keypointsState.getOriginalImage('cervical', 'LA');

    if (originalImage != null) {
      final image = await decodeImageFromList(originalImage);
      setState(() {
        originalImageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
    }
  }

  double georgeslineDistance(Map<String, dynamic> upperDiskBottom,
      Map<String, dynamic> lowerDiskTop) {
    final x1 = upperDiskBottom['x'] as double;
    final x2 = lowerDiskTop['x'] as double;
    return (x1 - x2).abs() * getCurrentPixelToMm();
  }

  void _onScaleChanged(ScaleUpdateDetails details) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale != _currentScale) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _resetPosition() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
    });
  }

  Widget _buildGeorgesLineAnalysis(List<Map<String, dynamic>>? keypoints) {
    if (keypoints == null || keypoints.isEmpty || keypoints.length < 22) {
      return Center(
        child: Text(
          '분석 데이터가 없습니다',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // 조지스 라인 간 거리 계산 (mm 단위)
    final distances = [
      georgeslineDistance(keypoints[7], keypoints[9]),     // C3-C4
      georgeslineDistance(keypoints[11], keypoints[13]),   // C4-C5
      georgeslineDistance(keypoints[15], keypoints[17]),   // C5-C6
      georgeslineDistance(keypoints[19], keypoints[21]),   // C6-C7
    ];

    // 가장 큰 거리와 해당 인덱스 찾기
    double maxDistance = 0;
    int maxIndex = 0;

    for (int i = 0; i < distances.length; i++) {
      if (distances[i] > maxDistance) {
        maxDistance = distances[i];
        maxIndex = i;
      }
    }

    return ListView(
      children: [
        Text(
          '조지스 라인 분석 결과',
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),

        // 가장 큰 거리 표시
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                  '가장 큰 변위',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )
              ),
              SizedBox(height: 8),
              Text(
                  '${_getSegmentLabel(maxIndex)}: ${maxDistance.toStringAsFixed(2)} mm',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        Text(
          '부위별 측정값',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(height: 8),

        // 각 분절 거리 표시
        for (int i = 0; i < distances.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${_getSegmentLabel(i)}:',
                    style: TextStyle(color: Colors.white)
                ),
                Text(
                    '${distances[i].toStringAsFixed(2)} mm',
                    style: TextStyle(
                        color: i == maxIndex ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold
                    )
                ),
              ],
            ),
          ),

        Divider(color: Colors.grey),

        Text(
          '조지스라인 설명',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(height: 8),

        // 해석 정보
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '측정방법 : 상부경추 하단 뒤쪽과 하부경추 상단 뒤쪽의 가로축 거리의 차이를 잼',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                '해석 : 가장 차이가 큰 쪽의 상부경추가 틀어짐의 원인이 되는곳으로 교정 point로 사용',
                style: TextStyle(color: Colors.yellowAccent),
              ),
            ],
          ),
        ),

      ],
    );
  }

  String _getSegmentLabel(int index) {
    switch (index) {
      case 0: return 'C3-C4 변위';
      case 1: return 'C4-C5 변위';
      case 2: return 'C5-C6 변위';
      case 3: return 'C6-C7 변위';
      default: return '알 수 없는 분절';
    }
  }

  @override
  Widget build(BuildContext context) {
    final keypointsState = Provider.of<KeypointsState>(context);
    final cervicalLaKeypoints = keypointsState.getOriginalKeypoints('cervical', 'LA');
    final originalImage = keypointsState.getOriginalImage('cervical', 'LA');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("조지스 라인", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Text(
              '${(_currentScale * 100).toInt()}%',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetPosition,
          ),
        ],
      ),
      body: Column(
        children: [
          if (originalImage != null)
            Expanded(
              flex: 1,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        InteractiveViewer(
                          transformationController: _transformationController,
                          onInteractionUpdate: _onScaleChanged,
                          minScale: 0.5,
                          maxScale: 2.5,
                          constrained: true,
                          boundaryMargin: EdgeInsets.all(20.0),
                          onInteractionEnd: (details) {
                            setState(() {
                              _currentScale = _transformationController.value.getMaxScaleOnAxis();
                            });
                          },
                          child: originalImageSize != null
                              ? FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: originalImageSize!.width,
                              height: originalImageSize!.height,
                              child: Stack(
                                children: [
                                  Image.memory(originalImage),
                                  if (cervicalLaKeypoints != null)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: GeorgesLinePainter(
                                          cervicalLaKeypoints: cervicalLaKeypoints,
                                          pixelToMm: getCurrentPixelToMm(),
                                          scale: _currentScale,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                              : CircularProgressIndicator(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[900],
              padding: EdgeInsets.all(16.0),
              child: _buildGeorgesLineAnalysis(cervicalLaKeypoints),
            ),
          ),
        ],
      ),
    );
  }
}

class GeorgesLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> cervicalLaKeypoints;
  final double pixelToMm;
  final double scale;

  GeorgesLinePainter({
    required this.cervicalLaKeypoints,
    required this.pixelToMm,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final fontSize = 14.0 / scale;

    // 1. 노란색 직선
    _drawGeorgesLines(canvas, cervicalLaKeypoints, Colors.yellow);

    // 2. 초록색 거리기반 선 및 가장 큰 차이는 빨간색으로
    _drawSupportLines(canvas, cervicalLaKeypoints, Colors.green, fontSize);

    canvas.restore();
  }

  void _drawGeorgesLines(Canvas canvas, List<Map<String, dynamic>> points, Color color) {
    if (points.isEmpty || points.length < 22) {
      print('경고: cervicalLaKeypoints 배열이 비어있거나 부족합니다');
      return;
    }

    final lines = [
      [points[5], points[7]],
      [points[9], points[11]],
      [points[13], points[15]],
      [points[17], points[19]],
      [points[21], points[3]],
    ];

    for (var line in lines) {
      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);

      Linedrawing.drawLine(
        canvas,
        p1,
        p2,
        color: color,
        strokeWidth: 2.0 / scale,
      );
    }
  }

  void _drawSupportLines(Canvas canvas, List<Map<String, dynamic>> points, Color color, double fontSize) {
    if (points.isEmpty || points.length < 22) {
      print('경고: cervicalLaKeypoints 배열이 비어있거나 부족합니다');
      return;
    }

    final lines = [
      [points[7], points[9]],
      [points[11], points[13]],
      [points[15], points[17]],
      [points[19], points[21]],
    ];

    // 가장 큰 거리 계산
    double maxDistance = 0;
    int maxIndex = 0;

    for (int i = 0; i < lines.length; i++) {
      final p1 = Offset(lines[i][0]['x']!, lines[i][0]['y']!);
      final p2 = Offset(lines[i][1]['x']!, lines[i][1]['y']!);

      // 거리 (mm 단위로 계산)
      final distancePx = (p2.dx - p1.dx).abs();
      final distanceMm = distancePx * pixelToMm;

      if (distanceMm > maxDistance) {
        maxDistance = distanceMm;
        maxIndex = i;
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final p1 = Offset(lines[i][0]['x']!, lines[i][0]['y']!);
      final p2 = Offset(lines[i][1]['x']!, lines[i][1]['y']!);

      // 왼쪽 기준점 (x가 작은 점)
      final leftPoint = (p1.dx < p2.dx) ? p1 : p2;
      final rightPoint = (p1.dx < p2.dx) ? p2 : p1;

      // 거리 (mm 단위로 계산)
      final distancePx = (rightPoint.dx - leftPoint.dx).abs();
      final distanceMm = distancePx * pixelToMm;

      // 초록 선 그릴 끝점 (왼쪽 점 + 거리만큼 오른쪽으로)
      final lineEnd = Offset(leftPoint.dx + distancePx, leftPoint.dy);

      // 선 색상 (가장 큰 거리일 경우 빨간색)
      final lineColor = (i == maxIndex) ? Colors.red : color;

      // 초록/빨간 선 그리기
      Linedrawing.drawLine(
        canvas,
        leftPoint,
        lineEnd,
        color: lineColor,
        strokeWidth: 2.0 / scale,
      );

      // 거리(mm) 텍스트 표시 (선 중간 위치)
      final mid = Offset(
        (leftPoint.dx + lineEnd.dx) / 2,
        (leftPoint.dy + lineEnd.dy) / 2,
      );

      Textdrawing.drawTextWithAlignment(
        canvas,
        '${distanceMm.toStringAsFixed(2)} mm',
        mid,
        style: TextStyle(
          color: (i == maxIndex) ? Colors.red : Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        alignment: TextAlignment.left,
        margin: 8.0,
        scale: 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}