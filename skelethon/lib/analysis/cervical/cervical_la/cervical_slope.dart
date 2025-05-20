import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '/state/keypoints_state.dart';

import '/utils/enums.dart';
import '/utils/geometry.dart';
import '/utils/linedrawing.dart';
import '/utils/textdrawing.dart';

import '/state/measurement_state_helper.dart';


class CervicalSlopePage extends StatefulWidget {
  const CervicalSlopePage({super.key});

  @override
  State<CervicalSlopePage> createState() => _CervicalSlopePage();
}

class _CervicalSlopePage extends State<CervicalSlopePage> {

  // 원본 이미지 크기를 저장할 변수
  Size? originalImageSize;
  Size? displaySize;

  // 확대/축소 컨트롤러
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  // 각도 값을 저장할 변수
  List<double> angles = [];

  // 각 경추별 정상 기울기 범위 정의 (양수: 상방 기울기, 음수: 하방 기울기)
  final Map<String, Map<String, double>> _normalRanges = {
    'C2 하판': {'min': 0.0, 'max': 10.0},
    'C7 상판': {'min': 11.6, 'max': 21.8},
    'C7 하판': {'min': 12.9, 'max': 21.9},
  };

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

  // 각도 계산 함수 - 양수/음수 구분 (양수: 상방 기울기, 음수: 하방 기울기)
  List<double> calculateAngles(List<Map<String, dynamic>> points) {
    if (points.isEmpty || points.length < 23) {
      return [];
    }

    // slope endplate 선들 정의
    final lines = [
      [points[0], points[1]],   // C2 하판
      [points[22], points[21]], // C7 상판
      [points[2], points[3]],   // C7 하판
    ];

    List<double> result = [];

    // 각 하판과 수평선 사이의 각도 계산
    for (var endplateLine in lines) {
      final p1 = Offset(endplateLine[0]['x']!, endplateLine[0]['y']!);
      final p2 = Offset(endplateLine[1]['x']!, endplateLine[1]['y']!);

      // 같은 높이에 있는 수평선 생성
      final horizontalP1 = Offset(p1.dx - 100, p1.dy);
      final horizontalP2 = Offset(p1.dx + 100, p1.dy);

      // 두 선 사이의 각도 계산 - 방향성 고려
      double angleDegrees = Geometry.spineBetweenLinesKyphosisPositive(p1, p2, horizontalP1, horizontalP2);
      result.add(angleDegrees);
    }

    return result;
  }

  // 각도에 따른 상태 확인 함수 (정상, 경미한 이상, 심한 이상)
  StatusLevel _getAngleStatus(String vertebra, double angle) {
    if (_normalRanges.containsKey(vertebra)) {
      final range = _normalRanges[vertebra]!;
      if (angle >= range['min']! && angle <= range['max']!) {
        return StatusLevel.normal;
      } else if (angle < range['min']! - 5.0 || angle > range['max']! + 5.0) {
        return StatusLevel.severe;
      } else {
        return StatusLevel.mild;
      }
    }
    return StatusLevel.normal; // 기본값
  }

  Widget _buildCervicalSlopeAnalysis(List<Map<String, dynamic>>? keypoints) {
    if (keypoints == null || keypoints.isEmpty || keypoints.length < 23) {
      return Center(
        child: Text(
          '분석 데이터가 없습니다',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // 각도 계산
    angles = calculateAngles(keypoints);
    if (angles.isEmpty) {
      return Center(
        child: Text(
          '각도를 계산할 수 없습니다',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // C7 하판 각도 및 상태
    double c7InferiorAngle = angles[2]; // C7 하판 각도 (인덱스 2)
    StatusLevel c7InferiorStatus = _getAngleStatus('C7 하판', c7InferiorAngle);

    return ListView(
      children: [
        Text(
          '경추 경사 각도 분석 결과',
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),

        // C7 하판 각도 표시
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Textdrawing.getBackgroundColorForStatus(c7InferiorStatus),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                  'C7 하판 기울기 각도',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )
              ),
              SizedBox(height: 8),
              Text(
                  '${c7InferiorAngle.toStringAsFixed(1)}°',
                  style: TextStyle(
                    color: Textdrawing.getColorForStatus(c7InferiorStatus),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  )
              ),
              SizedBox(height: 4),
              Text(
                  '정상 범위: ${_normalRanges['C7 하판']!['min']}° ~ ${_normalRanges['C7 하판']!['max']}°',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  )
              ),
              SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  text: '(정상범위: ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: 'normal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold, // 굵게
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: ' 정상±5°: ', // 부호 수정
                    ),
                    TextSpan(
                      text: 'mild',
                      style: TextStyle(
                        color: Colors.amber, // 노란색 계열 좀 더 보기 좋게
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: ' 정상±5°이상: ',
                    ),
                    TextSpan(
                      text: 'severe',
                      style: TextStyle(
                        color: Colors.redAccent, // 빨강 좀 더 선명하게
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: ')',
                    ),
                  ],
                ),
              )
            ],
          ),
        ),

        SizedBox(height: 16),

        Text(
          '분절별 기울기',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(height: 8),

        // 분절별 각도 표시
        for (int i = 0; i < angles.length; i++)
          _buildVertebraRow(i, angles[i]),

        Divider(color: Colors.grey),

        Text(
          '기울기 해석',
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
                '경추 기울기는 거북목의 심한정도, 경추 정렬의 이상평가, 수술 전후 교정평가에 사용되어집니다',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                'C2 기울기는 거북목이나 목디스크 평가에 사용되고 경사가 감소되면 과도한 전만, 경사가 증가되면 거북목이 의심을 할수있습니다.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 4),
              Text(
                'C7 하판 기울기는 T1 기울기 대신 볼수있는 지표로 경사가 감소하면 편평등 경사가 증가하면 굽은등을 예측하는 지표가 됩니다',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVertebraRow(int index, double angle) {
    final vertebraLabel = _getVertebralLabel(index);
    final vertebraKey = index == 0 ? 'C2 하판' : (index == 1 ? 'C7 상판' : 'C7 하판');
    final status = _getAngleStatus(vertebraKey, angle);
    final textColor = Textdrawing.getColorForStatus(status);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      margin: EdgeInsets.only(bottom: 4.0),
      decoration: BoxDecoration(
        color: Textdrawing.getBackgroundColorForStatus(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '$vertebraLabel:',
                  style: TextStyle(color: Colors.white)
              ),
              Text(
                  '${angle.toStringAsFixed(1)}°',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold
                  )
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
              '정상 범위: ${_normalRanges[vertebraKey]!['min']}° ~ ${_normalRanges[vertebraKey]!['max']}°',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              )
          ),
        ],
      ),
    );
  }

  // 전체 평균 각도에 대한 상태 확인
  StatusLevel _getOverallStatus(double avgAngle) {
    final absAngle = avgAngle.abs();
    if (absAngle <= 3.0) {
      return StatusLevel.normal;
    } else if (absAngle <= 8.0) {
      return StatusLevel.mild;
    } else {
      return StatusLevel.severe;
    }
  }

  String _getVertebralLabel(int index) {
    switch (index) {
      case 0: return 'C2 하판 기울기';
      case 1: return 'C7 상판 기울기';
      case 2: return 'C7 하판 기울기';
      default: return '알 수 없는 추체';
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
        title: const Text("경추 기울기", style: TextStyle(color: Colors.white)),
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
                                        painter: CervicalSlopePainter(
                                          cervicalLaKeypoints: cervicalLaKeypoints,
                                          pixelToMm: getCurrentPixelToMm(),
                                          scale: _currentScale,
                                          onAnglesCalculated: (calculatedAngles) {
                                            if (angles != calculatedAngles) {
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                setState(() {
                                                  angles = calculatedAngles;
                                                });
                                              });
                                            }
                                          },
                                          getStatusForAngle: _getAngleStatus,
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
              child: _buildCervicalSlopeAnalysis(cervicalLaKeypoints),
            ),
          ),
        ],
      ),
    );
  }
}

class CervicalSlopePainter extends CustomPainter {
  final List<Map<String, dynamic>> cervicalLaKeypoints;
  final double pixelToMm;
  final double scale;
  final Function(List<double>)? onAnglesCalculated;
  final Function(String, double)? getStatusForAngle;

  CervicalSlopePainter({
    required this.cervicalLaKeypoints,
    required this.pixelToMm,
    this.scale = 1.0,
    this.onAnglesCalculated,
    this.getStatusForAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // 1. 노란색 선 - 하판 그리기
    final angles = _drawEndplateLines(canvas, cervicalLaKeypoints, Colors.yellow);

    // 콜백으로 각도 전달
    if (onAnglesCalculated != null && angles.isNotEmpty) {
      onAnglesCalculated!(angles);
    }

    // 2. 노란색 점선 - 수평 기준선
    _drawHorizontalLines(canvas, cervicalLaKeypoints, Colors.yellow);

    canvas.restore();
  }

  List<double> _drawEndplateLines(Canvas canvas, List<Map<String, dynamic>> points, Color color) {
    if (points.isEmpty || points.length < 23) {
      print('경고: points 배열이 비어있거나 부족합니다');
      return [];
    }

    final lineStrokeWidth = 2.0 / scale;
    final fontSize = 14.0 / scale;

    // 하판 선들 정의
    final lines = [
      [points[0], points[1]],   // C2 하판
      [points[22], points[21]], // C7 상판
      [points[2], points[3]],   // C7 하판
    ];

    // 각 라인에 대응하는 추체 이름
    final vertebraNames = ['C2', 'C7 상판', 'C7 하판'];

    List<double> angles = [];

    // 1. 각 하판 선 그리기
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);

      // 실선으로 하판 그리기
      Linedrawing.drawLine(
        canvas,
        p1,
        p2,
        color: color,
        strokeWidth: lineStrokeWidth,
      );
    }

    // 2. 각 하판과 수평선 사이의 각도 계산
    for (var i = 0; i < lines.length; i++) {
      final endplateLine = lines[i];
      final vertebraName = vertebraNames[i];

      // 하판 선의 포인트들
      final p1 = Offset(endplateLine[0]['x']!, endplateLine[0]['y']!);
      final p2 = Offset(endplateLine[1]['x']!, endplateLine[1]['y']!);

      // 같은 높이에 있는 수평선 생성
      final horizontalP1 = Offset(p1.dx - 100 / scale, p1.dy);
      final horizontalP2 = Offset(p1.dx + 100 / scale, p1.dy);

      // 두 선 사이의 각도 계산 - 방향 포함
      double angleDegrees = Geometry.spineBetweenLinesKyphosisPositive(p1, p2, horizontalP1, horizontalP2);
      angles.add(angleDegrees);

      // 상태 확인 및 색상 결정
      Color textColor = Colors.white;
      if (getStatusForAngle != null) {
        final status = getStatusForAngle!(vertebraName, angleDegrees);
        textColor = Textdrawing.getColorForStatus(status);
      } else {
        // 기본 색상 로직
        if (angleDegrees.abs() <= 3.0) {
          textColor = Colors.white;
        } else if (angleDegrees.abs() <= 8.0) {
          textColor = Colors.yellow;
        } else {
          textColor = Colors.red;
        }
      }

      // 각도 텍스트 위치 (하판 오른쪽)
      final midPoint = Geometry.midpoint(p1, p2);
      final textPosition = Offset(midPoint.dx + 50 / scale, midPoint.dy);

      // 각도 텍스트 그리기
      Textdrawing.drawTextWithAlignment(
        canvas,
        '${_getTextLabel(i)}: ${angleDegrees.toStringAsFixed(1)}°',
        textPosition,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        alignment: TextAlignment.left,
        margin: 5.0,
        scale: 1.0,
      );
    }

    return angles;
  }

  String _getTextLabel(int index) {
    switch (index) {
      case 0: return 'C2 하판';
      case 1: return 'C7 상판';
      case 2: return 'C7 하판';
      default: return '?';
    }
  }

  void _drawHorizontalLines(Canvas canvas, List<Map<String, dynamic>> points, Color color) {
    if (points.isEmpty || points.length < 23) {
      print('경고: points 배열이 비어있거나 부족합니다');
      return;
    }

    final lineStrokeWidth = 2.0 / scale;

    // 하판 선들 정의 (동일)
    final lines = [
      [points[0], points[1]],   // C2 하판
      [points[22], points[21]], // C7 상판
      [points[2], points[3]],   // C7 하판
    ];

    // 각 하판 높이에 수평선 그리기
    for (var line in lines) {
      // 하판의 두 점 가져오기
      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);

      // 수평선의 y 좌표는 하판의 두번째 점의 y 좌표
      final y = p1.dy;

      // 수평선 시작점은 하판의 첫번째 점
      final startX = p1.dx;

      // 수평선의 길이 계산 (하판 길이의 약 2배만큼 왼쪽으로)
      final endplateDx = p1.dx - p2.dx; // 하판의 x 방향 길이
      final endX = p1.dx - (endplateDx * 1.5); // 하판 길이의 2배만큼 왼쪽으로

      // 수평선 좌표
      final horizontalP1 = Offset(startX, y);
      final horizontalP2 = Offset(endX, y);

      // 점선으로 수평선 그리기
      Linedrawing.drawDashedLine(
        canvas,
        horizontalP1,
        horizontalP2,
        color: color,
        strokeWidth: lineStrokeWidth,
        dashLength: 5.0 / scale,
        gapLength: 3.0 / scale,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}