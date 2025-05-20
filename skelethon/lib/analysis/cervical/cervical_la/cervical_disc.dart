import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '/state/keypoints_state.dart';

import '/utils/enums.dart';
import '/utils/geometry.dart';
import '/utils/linedrawing.dart';
import '/utils/textdrawing.dart';

import '/state/measurement_state_helper.dart';


class CervicalDiscPage extends StatefulWidget {
  const CervicalDiscPage({super.key});

  @override
  State<CervicalDiscPage> createState() => _CervicalDiscPageState();
}

class _CervicalDiscPageState extends State<CervicalDiscPage> {

  // 원본 이미지 크기를 저장할 변수
  Size? originalImageSize;
  Size? displaySize;

  // 확대/축소 컨트롤러
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  // 디스크 측정값을 저장할 변수들
  List<double> anteriorDistances = [];
  List<double> posteriorDistances = [];
  List<double> midDistances = [];
  List<double> ratios = [];

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

  // 이미지 크기를 가져오는 함수
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

  // 디스크 거리 계산 (using geometry utilities)
  double calculateDiskDistance(Map<String, double> upperDiskBottom, Map<String, double> lowerDiskTop) {
    final p1 = Offset(upperDiskBottom['x']!, upperDiskBottom['y']!);
    final p2 = Offset(lowerDiskTop['x']!, lowerDiskTop['y']!);
    return Geometry.distanceBetweenPoints(p1, p2) * getCurrentPixelToMm();
  }

  // 두 점의 중간 좌표 반환 (using geometry utilities)
  Map<String, double> getMidpoint(Map<String, dynamic> p1, Map<String, dynamic> p2) {
    final mid = Geometry.midpoint(Offset(p1['x']!, p1['y']!), Offset(p2['x']!, p2['y']!));
    return {'x': mid.dx, 'y': mid.dy};
  }

  // 확대/축소 비율 계산
  void _onScaleChanged(ScaleUpdateDetails details) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale != _currentScale) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  // 기본 위치로 리셋
  void _resetPosition() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
    });
  }

  // 디스크 거리 계산
  void calculateAllDistances(List<Map<String, dynamic>> points) {
    if (points.isEmpty || points.length < 23) {
      return;
    }

    // 앞쪽 디스크 사이 거리 계산
    List<double> anterior = [];
    final anteriorLines = [
      [points[0], points[6]],
      [points[8], points[10]],
      [points[12], points[14]],
      [points[16], points[18]],
      [points[20], points[22]],
    ];

    for (var line in anteriorLines) {
      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);
      anterior.add(Geometry.yDistanceabs(p1, p2) * getCurrentPixelToMm());
    }

    // 뒤쪽 디스크 사이 거리 계산
    List<double> posterior = [];
    final posteriorLines = [
      [points[1], points[5]],
      [points[7], points[9]],
      [points[11], points[13]],
      [points[15], points[17]],
      [points[19], points[21]],
    ];

    for (var line in posteriorLines) {
      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);
      posterior.add(Geometry.yDistanceabs(p1, p2) * getCurrentPixelToMm());
    }

    // 중간 디스크 사이 거리 계산
    List<Map<String, double>> midPoints = [
      getMidpoint(points[0], points[1]),
      getMidpoint(points[5], points[6]),
      getMidpoint(points[7], points[8]),
      getMidpoint(points[9], points[10]),
      getMidpoint(points[11], points[12]),
      getMidpoint(points[13], points[14]),
      getMidpoint(points[15], points[16]),
      getMidpoint(points[17], points[18]),
      getMidpoint(points[19], points[20]),
      getMidpoint(points[21], points[22]),
    ];

    List<double> middle = [];
    final midLines = [
      [midPoints[0], midPoints[1]],
      [midPoints[2], midPoints[3]],
      [midPoints[4], midPoints[5]],
      [midPoints[6], midPoints[7]],
      [midPoints[8], midPoints[9]],
    ];

    for (var line in midLines) {
      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);
      middle.add(Geometry.distanceBetweenPoints(p1, p2) * getCurrentPixelToMm());
    }

    // 비율 계산 (앞/뒤)
    List<double> ratioList = [];
    for (int i = 0; i < anterior.length; i++) {
      if (posterior[i] != 0) {
        ratioList.add(anterior[i] / posterior[i]);
      } else {
        ratioList.add(0);
      }
    }

    setState(() {
      anteriorDistances = anterior;
      posteriorDistances = posterior;
      midDistances = middle;
      ratios = ratioList;
    });
  }

  Widget _buildDiscAnalysis(List<Map<String, dynamic>>? keypoints) {
    if (keypoints == null || keypoints.isEmpty || keypoints.length < 23) {
      return Center(
        child: Text(
          '분석 데이터가 없습니다',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // 거리 계산
    if (anteriorDistances.isEmpty || posteriorDistances.isEmpty) {
      calculateAllDistances(keypoints);
    }

    if (anteriorDistances.isEmpty || posteriorDistances.isEmpty) {
      return Center(
        child: Text(
          '거리를 계산할 수 없습니다',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // 평균 비율 계산
    double avgRatio = ratios.reduce((a, b) => a + b) / ratios.length;

    // 정상 비율 범위
    const double normalLower = 0.9;
    const double normalUpper = 1.2;

    // 비율 상태 결정
    String ratioStatus;
    Color ratioColor;

    if (avgRatio >= normalLower && avgRatio <= normalUpper) {
      ratioStatus = '정상';
      ratioColor = Colors.green;
    } else if (avgRatio < normalLower) {
      ratioStatus = '전방 디스크 높이 감소';
      ratioColor = Colors.red;
    } else {
      ratioStatus = '후방 디스크 높이 감소';
      ratioColor = Colors.red;
    }

    return ListView(
      children: [
        Text(
          '디스크 간격 분석 결과',
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),

        // 평균 비율 표시
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ratioColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                  '앞/뒤 디스크 높이 비율',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )
              ),
              SizedBox(height: 8),
              Text(
                  '${avgRatio.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: ratioColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  )
              ),
              SizedBox(height: 4),
              Text(
                  '상태: $ratioStatus',
                  style: TextStyle(
                    color: ratioColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  )
              ),
              SizedBox(height: 2),
              Text(
                  '정상 범위: $normalLower ~ $normalUpper',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  )
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        Text(
          '디스크 간격 세부 측정',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(height: 8),

        // 각 디스크별 측정값 표시 (표 형식)
        Table(
          border: TableBorder.all(
            color: Colors.grey,
            width: 0.5,
          ),
          columnWidths: {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(1.5),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey[800],
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('디스크 위치', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('전방 (mm)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('후방 (mm)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('중간 (mm)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('비율 (앞/뒤)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            // 각 디스크 행 추가
            for (int i = 0; i < anteriorDistances.length; i++)
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(_getDiscLabel(i), style: TextStyle(color: Colors.white)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(anteriorDistances[i].toStringAsFixed(2),
                        style: TextStyle(color: Colors.green)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(posteriorDistances[i].toStringAsFixed(2),
                        style: TextStyle(color: Colors.green)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(midDistances[i].toStringAsFixed(2),
                        style: TextStyle(color: Colors.green)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(ratios[i].toStringAsFixed(2),
                        style: TextStyle(
                            color: (ratios[i] >= normalLower && ratios[i] <= normalUpper)
                                ? Colors.blue : Colors.red
                        )),
                  ),
                ],
              ),
          ],
        ),

        SizedBox(height: 16),

        Text(
          '디스크 비율 해석',
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
                '정상 비율: 0.9 ~ 1.2',
                style: TextStyle(color: Colors.green),
              ),
              SizedBox(height: 4),
              Text(
                '전방 디스크 높이 감소: < 0.9',
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 4),
              Text(
                '후방 디스크 높이 감소: > 1.2',
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 8),
              Text(
                '디스크 높이의 전후방 비율은 경추 만곡과 디스크 변성의 지표입니다. 불균형한 비율은 근육 긴장, 디스크 탈출 또는 돌출, 관절염 등의 병리적 상태를 나타낼 수 있습니다.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDiscLabel(int index) {
    switch (index) {
      case 0: return 'C2-C3 디스크';
      case 1: return 'C3-C4 디스크';
      case 2: return 'C4-C5 디스크';
      case 3: return 'C5-C6 디스크';
      case 4: return 'C6-C7 디스크';
      default: return '알 수 없는 디스크';
    }
  }

  @override
  Widget build(BuildContext context) {
    final keypointsState = Provider.of<KeypointsState>(context);
    final cervicalLaKeypoints = keypointsState.getOriginalKeypoints('cervical', 'LA');
    final originalImage = keypointsState.getOriginalImage('cervical', 'LA');

    // midPoints 초기화
    List<Map<String, double>> midPoints = [];

    if (cervicalLaKeypoints != null && cervicalLaKeypoints.length >= 23) {
      midPoints = [
        getMidpoint(cervicalLaKeypoints[0], cervicalLaKeypoints[1]),
        getMidpoint(cervicalLaKeypoints[5], cervicalLaKeypoints[6]),
        getMidpoint(cervicalLaKeypoints[7], cervicalLaKeypoints[8]),
        getMidpoint(cervicalLaKeypoints[9], cervicalLaKeypoints[10]),
        getMidpoint(cervicalLaKeypoints[11], cervicalLaKeypoints[12]),
        getMidpoint(cervicalLaKeypoints[13], cervicalLaKeypoints[14]),
        getMidpoint(cervicalLaKeypoints[15], cervicalLaKeypoints[16]),
        getMidpoint(cervicalLaKeypoints[17], cervicalLaKeypoints[18]),
        getMidpoint(cervicalLaKeypoints[19], cervicalLaKeypoints[20]),
        getMidpoint(cervicalLaKeypoints[21], cervicalLaKeypoints[22]),
      ];
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('디스크 간격 분석', style: TextStyle(color: Colors.white)),
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
                                        painter: DistanceLinePainter(
                                          midPoints: midPoints,
                                          cervicalLaKeypoints: cervicalLaKeypoints,
                                          pixelToMm: getCurrentPixelToMm(),
                                          scale: _currentScale,
                                          onMeasurementsCalculated: (anterior, posterior, mid, diskRatios) {
                                            if (anteriorDistances != anterior ||
                                                posteriorDistances != posterior ||
                                                midDistances != mid ||
                                                ratios != diskRatios) {
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                setState(() {
                                                  anteriorDistances = anterior;
                                                  posteriorDistances = posterior;
                                                  midDistances = mid;
                                                  ratios = diskRatios;
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
              child: _buildDiscAnalysis(cervicalLaKeypoints),
            ),
          ),
        ],
      ),
    );
  }
}

class DistanceLinePainter extends CustomPainter {
  final List<Map<String, double>> midPoints;
  final List<Map<String, dynamic>> cervicalLaKeypoints;
  final double pixelToMm;
  final double scale;
  final Function(List<double>, List<double>, List<double>, List<double>)? onMeasurementsCalculated;

  DistanceLinePainter({
    required this.midPoints,
    required this.cervicalLaKeypoints,
    required this.pixelToMm,
    this.scale = 1.0,
    this.onMeasurementsCalculated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final lineStrokeWidth = 2.0 / scale;
    final pointRadius = 4.0 / scale;
    final fontSize = 14.0 / scale;

    // 1. 노란색 직선 (두 keypoints의 거리보다 약간 더 길게)
    _drawYellowLines(canvas, cervicalLaKeypoints, Colors.yellow, lineStrokeWidth, pointRadius);

    // 모든 거리 측정
    final List<double> anteriorDistances = _drawAntLines(canvas, cervicalLaKeypoints, Colors.green, fontSize);
    final List<double> posteriorDistances = _drawPostLines(canvas, cervicalLaKeypoints, Colors.green, fontSize);
    final List<double> midDistances = _drawMidLines(canvas, cervicalLaKeypoints, Colors.green, fontSize);

    // 비율 계산
    List<double> ratios = [];
    for (int i = 0; i < anteriorDistances.length; i++) {
      if (posteriorDistances[i] != 0) {
        ratios.add(anteriorDistances[i] / posteriorDistances[i]);
      } else {
        ratios.add(0);
      }
    }

    // 콜백으로 측정값 전달
    if (onMeasurementsCalculated != null) {
      onMeasurementsCalculated!(anteriorDistances, posteriorDistances, midDistances, ratios);
    }

    canvas.restore();
  }

  // 1. 노란색 직선 그리기 (두 keypoints를 잇는 직선)
  void _drawYellowLines(Canvas canvas, List<Map<String, dynamic>> points, Color color, double strokeWidth, double pointRadius, {double extendFactor = 2.0}) {
    final lines = [
      [points[0], points[1]],
      [points[5], points[6]],
      [points[7], points[8]],
      [points[9], points[10]],
      [points[11], points[12]],
      [points[13], points[14]],
      [points[15], points[16]],
      [points[17], points[18]],
      [points[19], points[20]],
      [points[21], points[22]],
    ];

    for (var line in lines) {
      final x1 = line[0]['x']!;
      final y1 = line[0]['y']!;
      final x2 = line[1]['x']!;
      final y2 = line[1]['y']!;

      final dx = x2 - x1;
      final dy = y2 - y1;

      // 중점 기준으로 양쪽으로 연장
      final start = Offset(x1 - dx * (extendFactor - 1) / 2, y1 - dy * (extendFactor - 1) / 2);
      final end = Offset(x2 + dx * (extendFactor - 1) / 2, y2 + dy * (extendFactor - 1) / 2);

      // 선 그리기
      Linedrawing.drawLine(canvas, start, end, color: color, strokeWidth: strokeWidth);
    }
  }

  // 2. 앞쪽 디스크 사이 직선 그리기
  List<double> _drawAntLines(
      Canvas canvas,
      List<Map<String, dynamic>> points,
      Color color,
      double fontSize,
      ) {
    // 배열 검증
    if (points.isEmpty || points.length < 22) {
      print('경고: cervicalLaKeypoints 배열이 비어있거나 충분한 요소가 없습니다');
      return [];
    }

    final lines = [
      [points[0], points[6]],
      [points[8], points[10]],
      [points[12], points[14]],
      [points[16], points[18]],
      [points[20], points[22]],
    ];

    List<double> distances = [];

    // 모든 선 먼저 그리기
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // null 체크
      if (line[0]['x'] == null || line[0]['y'] == null ||
          line[1]['x'] == null || line[1]['y'] == null) {
        distances.add(0);
        continue;
      }

      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);

      // 선 그리기
      Linedrawing.drawLine(canvas, p1, p2, color: color, strokeWidth: 2.0 / scale);

      // 거리 계산 (y축 거리로 변경)
      final distance = Geometry.yDistanceabs(p1, p2) * pixelToMm;
      distances.add(distance);
    }

    // 그 다음 텍스트 그리기
    for (int i = 0; i < lines.length; i++) {
      if (distances[i] == 0) continue;

      final line = lines[i];
      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);
      final mid = Geometry.midpoint(p1, p2);

      // 거리 텍스트 그리기
      Textdrawing.drawTextWithAlignment(
        canvas,
        '${distances[i].toStringAsFixed(2)} mm',
        mid, // 중간 위치
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        alignment: TextAlignment.right,
        margin: 10.0,
        scale: 1.0,
      );
    }

    return distances;
  }

  // 3. 뒤쪽 디스크 사이 직선 그리기
  List<double> _drawPostLines(
      Canvas canvas,
      List<Map<String, dynamic>> points,
      Color color,
      double fontSize,
      ) {
    // 배열 검증
    if (points.isEmpty || points.length < 23) {
      print('경고: points 배열이 비어있거나 충분한 요소가 없습니다');
      return [];
    }

    final lines = [
      [points[1], points[5]],
      [points[7], points[9]],
      [points[11], points[13]],
      [points[15], points[17]],
      [points[19], points[21]],
    ];

    List<double> distances = [];

    // 모든 선 먼저 그리기
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // null 체크
      if (line[0]['x'] == null || line[0]['y'] == null ||
          line[1]['x'] == null || line[1]['y'] == null) {
        distances.add(0);
        continue;
      }

      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);

      // 선 그리기
      Linedrawing.drawLine(canvas, p1, p2, color: color, strokeWidth: 2.0 / scale);

      // 거리 계산 (y축 거리로 변경)
      final distance = Geometry.yDistanceabs(p1, p2) * pixelToMm;
      distances.add(distance);
    }

    // 그 다음 텍스트 그리기
    for (int i = 0; i < lines.length; i++) {
      if (distances[i] == 0) continue;

      final line = lines[i];
      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);
      final mid = Geometry.midpoint(p1, p2);

      // 거리 텍스트 그리기
      Textdrawing.drawTextWithAlignment(
          canvas,
          '${distances[i].toStringAsFixed(2)} mm',
    mid, // 중간 위치
    style: TextStyle(
    color: Colors.white,
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    ),
    alignment: TextAlignment.left,
    margin: 10.0,scale: 1.0,
      );
    }

    return distances;
  }

  // 4. 중간 디스크 사이 직선 그리기
  List<double> _drawMidLines(
      Canvas canvas,
      List<Map<String, dynamic>> points,
      Color color,
      double fontSize,
      ) {
    // 배열 검증
    if (points.isEmpty || points.length < 23 || midPoints.isEmpty || midPoints.length < 10) {
      print('경고: points 배열이나 midPoints 배열이 비어있거나 충분한 요소가 없습니다');
      return [];
    }

    final lines = [
      [midPoints[0], midPoints[1]], // C2-C3 사이 중간점
      [midPoints[2], midPoints[3]], // C3-C4 사이 중간점
      [midPoints[4], midPoints[5]], // C4-C5 사이 중간점
      [midPoints[6], midPoints[7]], // C5-C6 사이 중간점
      [midPoints[8], midPoints[9]], // C6-C7 사이 중간점
    ];

    List<double> distances = [];

    // 모든 선 먼저 그리기
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // null 체크
      if (line[0]['x'] == null || line[0]['y'] == null ||
          line[1]['x'] == null || line[1]['y'] == null) {
        distances.add(0);
        continue;
      }

      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);

      // 선 그리기
      Linedrawing.drawLine(canvas, p1, p2, color: color, strokeWidth: 2.0 / scale);

      // 직선 거리 계산 (비스듬한 거리 측정)
      final distance = Geometry.distanceBetweenPoints(p1, p2) * pixelToMm;
      distances.add(distance);
    }

    // 그 다음 텍스트 그리기
    for (int i = 0; i < lines.length; i++) {
      if (distances[i] == 0) continue;

      final line = lines[i];
      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);
      final mid = Geometry.midpoint(p1, p2);

      // 거리 텍스트 그리기 (중앙 정렬)
      Textdrawing.drawTextWithAlignment(
        canvas,
        '${distances[i].toStringAsFixed(2)} mm',
        mid, // 중간 위치
        style: TextStyle(
          color: Colors.white, // 다른 측정과 구분하기 위해 색상 변경
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        alignment: TextAlignment.top, // 중앙 정렬
        margin: 5.0,
        scale: 1.0,
      );
    }

    return distances;
  }

  @override
  bool shouldRepaint(covariant DistanceLinePainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.midPoints != midPoints ||
        oldDelegate.cervicalLaKeypoints != cervicalLaKeypoints;
  }
}