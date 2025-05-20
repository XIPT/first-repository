import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '/state/keypoints_state.dart';

import '/utils/enums.dart';
import '/utils/geometry.dart';
import '/utils/linedrawing.dart';
import '/utils/textdrawing.dart';

import '/state/measurement_state_helper.dart';

class CervicalAnglePage extends StatefulWidget {
  const CervicalAnglePage({super.key});

  @override
  State<CervicalAnglePage> createState() => _CervicalAnglePage();
}

class _CervicalAnglePage extends State<CervicalAnglePage> {

  // 원본 이미지 크기를 저장할 변수
  Size? originalImageSize;
  Size? displaySize;

  // 확대/축소 컨트롤러
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  // 각 분절별 정상 각도 범위 정의 (전만 양수 기준)
  final Map<String, Map<String, double>> _normalRanges = {
    'C2-C3': {'min': 0.4, 'max': 5.0},
    'C3-C4': {'min': 1.3, 'max': 6.3},
    'C4-C5': {'min': 1.7, 'max': 7.7},
    'C5-C6': {'min': 2.0, 'max': 8.4},
    'C6-C7': {'min': 1.6, 'max': 7.8},
    'C2-C7': {'min': 13.9, 'max': 26.2},
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

  // 각도에 따른 상태 확인 함수 (정상, 경미한 이상, 심한 이상)
  StatusLevel _getAngleStatus(String segmentName, double angle) {
    if (_normalRanges.containsKey(segmentName)) {
      final range = _normalRanges[segmentName]!;
      if (angle >= range['min']! && angle <= range['max']!) {
        return StatusLevel.normal;
      } else if (angle < range['min']! - 3.0 || angle > range['max']! + 3.0) {
        return StatusLevel.severe;
      } else {
        return StatusLevel.mild;
      }
    }
    return StatusLevel.normal; // 기본값
  }

  Widget _buildCervicalAngleanalysis(List<Map<String, dynamic>>? keypoints) {
    if (keypoints == null || keypoints.isEmpty || keypoints.length < 23) {
      return Center(
        child: Text(
          '분석 데이터가 없습니다',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // C2-C7 각도 계산 - 전만일 때 양수로 변경
    double c2c7Angle = Geometry.spineBetweenLinesLordosisPositive(
        Offset(keypoints[0]['x']!, keypoints[0]['y']!),
        Offset(keypoints[1]['x']!, keypoints[1]['y']!),
        Offset(keypoints[2]['x']!, keypoints[2]['y']!),
        Offset(keypoints[3]['x']!, keypoints[3]['y']!)
    );

    // 각 분절 각도는 전만일 때 양수로 계산
    final linePairs = [
      [[keypoints[0], keypoints[1]], [keypoints[6], keypoints[5]]], // C2-C3
      [[keypoints[8], keypoints[7]], [keypoints[10], keypoints[9]]], // C3-C4
      [[keypoints[12], keypoints[11]], [keypoints[14], keypoints[13]]], // C4-C5
      [[keypoints[16], keypoints[15]], [keypoints[18], keypoints[17]]], // C5-C6
      [[keypoints[20], keypoints[19]], [keypoints[22], keypoints[21]]], // C6-C7
    ];

    List<double> segmentAngles = linePairs.map((pair) {
      final firstLine = pair[0];
      final secondLine = pair[1];
      return Geometry.spineBetweenLinesLordosisPositive(
          Offset(firstLine[0]['x']!, firstLine[0]['y']!),
          Offset(firstLine[1]['x']!, firstLine[1]['y']!),
          Offset(secondLine[0]['x']!, secondLine[0]['y']!),
          Offset(secondLine[1]['x']!, secondLine[1]['y']!)
      );
    }).toList();

    // C2-C7 각도의 상태 확인
    final c2c7Status = _getAngleStatus('C2-C7', c2c7Angle);
    final c2c7StatusColor = Textdrawing.getColorForStatus(c2c7Status);

    return ListView(
      children: [
        Text(
          '경추 전만 분석 결과',
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),

        // C2-C7 각도 표시
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Textdrawing.getBackgroundColorForStatus(c2c7Status),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                  'C2-C7 각도',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )
              ),
              SizedBox(height: 8),
              Text(
                  '${c2c7Angle.toStringAsFixed(1)}°',
                  style: TextStyle(
                    color: c2c7StatusColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  )
              ),
              SizedBox(height: 4),
              Text(
                  '정상 범위: ${_normalRanges['C2-C7']!['min']}° ~ ${_normalRanges['C2-C7']!['max']}°',
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
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: ' 정상±3°: ',
                    ),
                    TextSpan(
                      text: 'mild',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: ' 정상±3°이상: ',
                    ),
                    TextSpan(
                      text: 'severe',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: ')',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        Text(
          '분절별 각도',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(height: 8),

        // 각 분절 각도 표시
        for (int i = 0; i < segmentAngles.length; i++)
          _buildSegmentAngleRow(i, segmentAngles[i]),

        Divider(color: Colors.grey),

        // 해석 정보 추가
        Text(
          '기울기 해석',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
        ),
        SizedBox(height: 8),

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
                'C2-C7 경추각도는 건강한 목뼈 곡선을 평가하는 대표지표로 거북목,일자목,역C자목을 알수있습니다.',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                '분절별 각도는 어디서 문제가 더 세세히 발생되었는지를 보고 더 정밀한 치료를 할때 보조지표가 됩니다.',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                '목디스크, 경추척수병, 수술전후 평가지표, 도수치료의 경과 관찰지표가 될수있습니다.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentAngleRow(int index, double angle) {
    final segmentName = _getSegmentLabel(index);
    final segmentKey = segmentName.split(' ')[0]; // 'C2-C3 각도'에서 'C2-C3' 추출
    final status = _getAngleStatus(segmentKey, angle);
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
                  '$segmentName:',
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
              '정상 범위: ${_normalRanges[segmentKey]!['min']}° ~ ${_normalRanges[segmentKey]!['max']}°',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              )
          ),
        ],
      ),
    );
  }

  String _getSegmentLabel(int index) {
    switch (index) {
      case 0: return 'C2-C3 각도';
      case 1: return 'C3-C4 각도';
      case 2: return 'C4-C5 각도';
      case 3: return 'C5-C6 각도';
      case 4: return 'C6-C7 각도';
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
        title: const Text("경추 전만 각도", style: TextStyle(color: Colors.white)),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      onInteractionUpdate: _onScaleChanged,
                      minScale: 0.5,
                      maxScale: 2.5,
                      constrained: true,
                      boundaryMargin: EdgeInsets.all(20.0),
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
                                    painter: CervicalAnglePainter(
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
                  );
                },
              ),
            ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[900],
              padding: EdgeInsets.all(16.0),
              child: _buildCervicalAngleanalysis(cervicalLaKeypoints),
            ),
          ),
        ],
      ),
    );
  }
}

class CervicalAnglePainter extends CustomPainter {
  final List<Map<String, dynamic>> cervicalLaKeypoints;
  final double pixelToMm;
  final double scale;

  CervicalAnglePainter({
    required this.cervicalLaKeypoints,
    required this.pixelToMm,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 캔버스 상태 저장
    canvas.save();

    // 1. 빨간색 점선 (더 길게 연장)
    _drawC2C7Lines(canvas, cervicalLaKeypoints, Colors.red, extendFactor: 6.0);

    // 2. 노란색 직선 (extendFactor는 함수 내부에서 지정)
    _drawCervicalAngleLines(canvas, cervicalLaKeypoints, Colors.yellow, extendFactor: 2.0);

    // 캔버스 상태 복원
    canvas.restore();
  }

  void _drawC2C7Lines(Canvas canvas, List<Map<String, dynamic>> points, Color color, {required double extendFactor}) {
    if (points.isEmpty || points.length < 23) {
      print('경고: points 배열이 비어있거나 부족합니다');
      return;
    }

    final lines = [
      [points[0], points[1]],
      [points[2], points[3]],
    ];

    final lineStrokeWidth = 2.0 / scale;
    final fontSize = 20.0 / scale; // C2-C7 각도는 기본 크게 유지

    // 1. 점선 스타일로 연장된 선 그리기
    for (var line in lines) {
      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);

      // 연장된 점선 그리기
      Linedrawing.drawExtendedDashedLine(
        canvas,
        p1,
        p2,
        color: color,
        strokeWidth: lineStrokeWidth,
        extendFactor: extendFactor,
        dashLength: 5.0 / scale,
        gapLength: 3.0 / scale,
      );
    }

    // 2. 짝을 이루는 선들 사이의 각도 계산 및 표시
    final linePairs = [
      [lines[0], lines[1]], // [0,1]과 [2,3] 사이 각도
    ];

    for (var pair in linePairs) {
      final firstLine = pair[0];
      final secondLine = pair[1];

      // 첫 번째 선의 포인트들
      final line1P1 = Offset(firstLine[0]['x']!, firstLine[0]['y']!);
      final line1P2 = Offset(firstLine[1]['x']!, firstLine[1]['y']!);

      // 두 번째 선의 포인트들
      final line2P1 = Offset(secondLine[0]['x']!, secondLine[0]['y']!);
      final line2P2 = Offset(secondLine[1]['x']!, secondLine[1]['y']!);

      // 두 선 사이의 각도 계산 - 전만일 때 양수
      double angleDegrees = Geometry.spineBetweenLinesLordosisPositive(line1P1, line1P2, line2P1, line2P2);

      // 각도 텍스트 표시 위치 (두 선의 중간 지점)
      final midPoint1 = Geometry.midpoint(line1P1, line1P2);
      final midPoint2 = Geometry.midpoint(line2P1, line2P2);
      final textPosition = Geometry.midpoint(midPoint1, midPoint2);

      // 각도 텍스트 그리기 (스케일에 따라 크기 조정)
      Textdrawing.drawTextWithAlignment(
        canvas,
        'C2-C7: ${angleDegrees.toStringAsFixed(1)}°',
        textPosition,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize, // 스케일에 반비례하여 텍스트 크기 조정
          fontWeight: FontWeight.bold,
        ),
        alignment: TextAlignment.left,
        margin: 50.0 / scale, // 마진도 스케일에 따라 조정
        scale: 1.0,
      );
    }
  }

  void _drawCervicalAngleLines(Canvas canvas, List<Map<String, dynamic>> points, Color color, {required double extendFactor}) {
    if (points.isEmpty || points.length < 23) {
      print('경고: points 배열이 비어있거나 부족합니다');
      return;
    }

    final lines = [
      [points[0], points[1]],
      [points[6], points[5]],
      [points[8], points[7]],
      [points[10], points[9]],
      [points[12], points[11]],
      [points[14], points[13]],
      [points[16], points[15]],
      [points[18], points[17]],
      [points[20], points[19]],
      [points[22], points[21]],
    ];

    final lineStrokeWidth = 2.0 / scale;
    final fontSize = 14.0 / scale; // 분절별 각도는 이 크기로 통일

    // 1. 먼저 모든 선 그리기
    for (var line in lines) {
      final p1 = Offset(line[0]['x']!, line[0]['y']!);
      final p2 = Offset(line[1]['x']!, line[1]['y']!);

      final extendedLine = Geometry.extendLine(p1, p2, extendFactor: extendFactor);
      final extendedStart = extendedLine.item1;
      final extendedEnd = extendedLine.item2;

      Linedrawing.drawLine(
        canvas,
        extendedStart,
        extendedEnd,
        color: color,
        strokeWidth: lineStrokeWidth,
      );
    }

    // 2. 짝을 이루는 선들 사이의 각도 계산 및 표시
    final linePairs = [
      [lines[0], lines[1]], // [0,1]과 [5,6] 사이 각도
      [lines[2], lines[3]], // [7,8]과 [9,10] 사이 각도
      [lines[4], lines[5]], // [11,12]와 [13,14] 사이 각도
      [lines[6], lines[7]], // [15,16]과 [17,18] 사이 각도
      [lines[8], lines[9]], // [19,20]과 [21,22] 사이 각도
    ];

    for (var pair in linePairs) {
      final firstLine = pair[0];
      final secondLine = pair[1];

      // 첫 번째 선의 포인트들
      final line1P1 = Offset(firstLine[0]['x']!, firstLine[0]['y']!);
      final line1P2 = Offset(firstLine[1]['x']!, firstLine[1]['y']!);

      // 두 번째 선의 포인트들
      final line2P1 = Offset(secondLine[0]['x']!, secondLine[0]['y']!);
      final line2P2 = Offset(secondLine[1]['x']!, secondLine[1]['y']!);

      // 두 선 사이의 각도 계산 - 전만일 때 양수
      double angleDegrees = Geometry.spineBetweenLinesLordosisPositive(line1P1, line1P2, line2P1, line2P2);

      // 각도 텍스트 표시 위치 (두 선의 중간 지점)
      final midPoint1 = Geometry.midpoint(line1P1, line1P2);
      final midPoint2 = Geometry.midpoint(line2P1, line2P2);
      final textPosition = Geometry.midpoint(midPoint1, midPoint2);

      // 각도 텍스트 그리기 (스케일에 따라 크기 조정)
      Textdrawing.drawTextWithAlignment(
        canvas,
        '${angleDegrees.toStringAsFixed(1)}°',
        textPosition,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize, // 스케일에 반비례하여 텍스트 크기 조정
          fontWeight: FontWeight.bold,
        ),
        alignment: TextAlignment.left,
        margin: 20.0 / scale, // 마진도 스케일에 따라 조정
        scale: 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}