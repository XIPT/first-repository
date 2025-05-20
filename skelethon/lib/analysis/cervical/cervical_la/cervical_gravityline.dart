import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '/state/keypoints_state.dart';

import '/utils/enums.dart';
import '/utils/geometry.dart';
import '/utils/linedrawing.dart';
import '/utils/textdrawing.dart';

import '/state/measurement_state_helper.dart';


class CervicalGravityLinePage extends StatefulWidget {
  const CervicalGravityLinePage({super.key});

  @override
  State<CervicalGravityLinePage> createState() => _CervicalGravityLinePage();
}

class _CervicalGravityLinePage extends State<CervicalGravityLinePage> {

  // 원본 이미지 크기를 저장할 변수
  Size? originalImageSize;
  Size? displaySize;

  // 확대/축소 컨트롤러
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  // 교점까지의 거리를 저장할 변수
  double? intersectionDistance;

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

  // 교점까지의 거리를 계산하는 함수
  double? calculateIntersectionDistance(List<Map<String, dynamic>> points) {
    if (points.isEmpty || points.length < 23) {
      return null;
    }

    // 두 선 사이의 교점 찾기
    final Offset p1 = Offset(points[2]['x']!, points[2]['y']!);
    final Offset p2 = Offset(points[21]['x']!, points[21]['y']!);
    final Offset p3 = Offset(points[3]['x']!, points[3]['y']!);
    final Offset p4 = Offset(points[22]['x']!, points[22]['y']!);

    // 교점 계산
    final Offset? intersectionPoint = Geometry.intersection(p1, p2, p3, p4);

    if (intersectionPoint != null) {
      // points[4]의 x좌표 (노란선의 x좌표) 가져오기
      final double yellowLineX = points[4]['x']!;

      // 거리 계산 (X축 방향으로)
      final double distanceX = (intersectionPoint.dx - yellowLineX);

      // 픽셀을 mm로 변환
      return distanceX * getCurrentPixelToMm();
    }

    return null;
  }

  Widget _buildGravityLineAnalysis(List<Map<String, dynamic>>? keypoints) {
    if (keypoints == null || keypoints.isEmpty || keypoints.length < 23) {
      return Center(
        child: Text(
          '분석 데이터가 없습니다',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // 교점까지의 거리 계산
    final distance = calculateIntersectionDistance(keypoints);
    if (distance == null) {
      return Center(
        child: Text(
          '교점을 찾을 수 없습니다',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // 거리에 따른 상태 결정
    String status;
    Color statusColor;

    if (distance >= 0 && distance <= 3.0) {
      status = '정상';
      statusColor = Colors.green;
    } else if (distance > -2.0 && distance <= 5.0) {
      status = '경미한 변위';
      statusColor = Colors.yellow;
    } else {
      status = '심각한 변위';
      statusColor = Colors.red;
    }

    return ListView(
      children: [
        Text(
          '경추 중력선 분석 결과',
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),

        // 거리 표시
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                  'C7 추체 중심까지의 거리',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )
              ),
              SizedBox(height: 8),
              Text(
                  '${distance.toStringAsFixed(2)} mm',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  )
              ),
              SizedBox(height: 4),
              Text(
                  '상태: $status',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )
              ),
            ],
          ),
        ),

        Divider(color: Colors.grey),

        Text(
          '중력선 편차 해석',
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
                '정상 범위: 0 ~ 3.0 mm',
                style: TextStyle(color: Colors.green),
              ),
              SizedBox(height: 4),
              Text(
                '경미한 변위: 정상범위 ±3.0 mm',
                style: TextStyle(color: Colors.yellow),
              ),
              SizedBox(height: 4),
              Text(
                '심각한 변위: 정상범위 ± 5.0 mm 이상',
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 8),
              Text(
                '중력선 편차가 클수록 경추부의 불균형이 심하며, 장기간 지속 시 경추 만곡 변화와 근골격계 증상이 발생할 수 있습니다.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // 추가 정보
        Text(
          '측정 방법',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(height: 8),
        Text(
          'C2 중심점으로부터 수직으로 그은 직선에 C7 척추의 중심점까지의 가로축 거리를 측정합니다.',
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 4),
        Text(
          'C7중심점 앞쪽을 통과하면서 척추에 선이 닿아있으면 정상입니다.',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
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
        title: const Text("경추 중력선", style: TextStyle(color: Colors.white)),
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
                                        painter: GravityLinePainter(
                                          cervicalLaKeypoints: cervicalLaKeypoints,
                                          pixelToMm: getCurrentPixelToMm(),
                                          scale: _currentScale,
                                          onDistanceCalculated: (distance) {
                                            if (intersectionDistance != distance) {
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                setState(() {
                                                  intersectionDistance = distance;
                                                });
                                              });
                                            }
                                          },
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
              child: _buildGravityLineAnalysis(cervicalLaKeypoints),
            ),
          ),
        ],
      ),
    );
  }
}

class GravityLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> cervicalLaKeypoints;
  final double pixelToMm;
  final double scale;
  final Function(double)? onDistanceCalculated;

  GravityLinePainter({
    required this.cervicalLaKeypoints,
    required this.pixelToMm,
    this.scale = 1.0,
    this.onDistanceCalculated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final fontSize = 14.0 / scale;

    // 1. 노란색 직선
    _drawGravityLine(canvas, size, cervicalLaKeypoints, Colors.yellow);

    // 2. 초록색 거리기반 선
    _drawC7centerLine(canvas, size, cervicalLaKeypoints, Colors.yellow, fontSize);

    canvas.restore();
  }

  void _drawGravityLine(Canvas canvas, Size size, List<Map<String, dynamic>> points, Color color) {
    if (points.isEmpty || points.length < 22) {
      print('경고: cervicalLaKeypoints 배열이 비어있거나 부족합니다');
      return;
    }

    final double startX = points[4]['x']!;
    final double startY = points[4]['y']!;

    // y축 방향으로 위로 끝까지 그리고 아래로 끝까지
    final Offset topPoint = Offset(startX, 0);
    final Offset bottomPoint = Offset(startX, size.height);

    // 직선 그리기 (Linedrawing utility 사용)
    Linedrawing.drawLine(canvas, topPoint, bottomPoint, color: color, strokeWidth: 2.0 / scale);
  }

  void _drawC7centerLine(Canvas canvas, Size size, List<Map<String, dynamic>> points, Color color, double fontSize) {
    if (points.isEmpty || points.length < 23) {
      print('경고: cervicalLaKeypoints 배열이 비어있거나 부족합니다');
      return;
    }

    // 선을 그리기 위한 Paint 객체 생성
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2 / scale;

    // points[2], points[3]와 points[21], points[22] 사이의 선 그리기
    final lines = [
      [points[2], points[21]],
      [points[3], points[22]]
    ];

    // 두 선 사이의 교점 찾기
    final Offset p1 = Offset(points[2]['x']!, points[2]['y']!);
    final Offset p2 = Offset(points[21]['x']!, points[21]['y']!);
    final Offset p3 = Offset(points[3]['x']!, points[3]['y']!);
    final Offset p4 = Offset(points[22]['x']!, points[22]['y']!);

    // geometry.dart에서 정의된 intersection 함수를 사용하여 교점 계산
    final Offset? intersectionPoint = Geometry.intersection(p1, p2, p3, p4);

    // 원래 선들 그리기
    for (final line in lines) {
      Linedrawing.drawLine(
        canvas,
        Offset(line[0]['x']!, line[0]['y']!),
        Offset(line[1]['x']!, line[1]['y']!),
        color: color,
        strokeWidth: 2.0 / scale,
      );
    }

    if (intersectionPoint != null) {
      // 교점 시각화 (원 모양으로 빨간색 점)
      final circlePaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      // 원 그리기
      canvas.drawCircle(intersectionPoint, 4.0 / scale, circlePaint);

      // points[4]의 x좌표 (노란선의 x좌표) 가져오기
      final double yellowLineX = points[4]['x']!;
      final double startY = intersectionPoint.dy;

      // 교점에서 노란색 세로선까지 초록색 보조선 그리기
      final helperLinePaint = Paint()
        ..color = Colors.green
        ..strokeWidth = 2 / scale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // 교점에서 노란색 세로선까지 수평선 그리기
      canvas.drawLine(
          Offset(intersectionPoint.dx, startY),
          Offset(yellowLineX, startY),
          helperLinePaint
      );

      // 거리 계산 (X축 방향으로)
      final double distanceX = (intersectionPoint.dx - yellowLineX).abs();

      // 픽셀을 mm로 변환
      final double distanceMm = distanceX * pixelToMm;

      // 콜백 호출로 거리 전달
      if (onDistanceCalculated != null) {
        onDistanceCalculated!(distanceMm);
      }

      // 거리에 따른 색상 결정
      Color textColor;
      if (distanceMm >= 0 && distanceMm <= 3.0) {
        textColor = Colors.white;
      } else if (distanceMm > -2.0 && distanceMm <= 5.0) {
        textColor = Colors.yellow;
      } else {
        textColor = Colors.red;
      }

      // 텍스트 위치 계산 (중간 지점)
      final Offset mid = Offset(
          (intersectionPoint.dx + yellowLineX) / 2,
          startY - 10
      );

      // Textdrawing 유틸리티 사용하여 텍스트 표시
      Textdrawing.drawTextWithAlignment(
        canvas,
        '${distanceMm.toStringAsFixed(2)} mm',
        mid,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        alignment: TextAlignment.top,
        margin: 8.0,
        scale: 1.0,
      );
    } else {
      print('교점을 찾을 수 없습니다');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}