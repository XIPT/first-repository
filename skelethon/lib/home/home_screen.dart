import 'package:flutter/material.dart';
import '../main.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

import '../upload/image_upload_APview.dart';
import '../upload/image_upload_LAview.dart';
import '../upload/image_upload_measurement.dart';

import '../state/xray_state.dart';
import '../state/xray_crop_state.dart';
import '../state/user_state.dart';
import '../state/measurement_state.dart';

import '../services/api_service.dart';

import '../utils/enums.dart';
import '../utils/geometry.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 부분 모드에서 선택된 부위 저장 (AP, LA 각각)
  String? apSelectedRegion;
  String? laSelectedRegion;

  // SnackBar 표시 제어용
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  _snackBarController;

  // 측정도구 표시 제어용
  bool _isMeasureToolExpanded = false;

  // 추가: QuestionMark 위젯 참조를 위한 GlobalKey
  final GlobalKey<_BouncingQuestionMarkState> _questionMarkKey = GlobalKey<_BouncingQuestionMarkState>();

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final userId = userState.userId ?? 'unknown';
    final xrayState = context.watch<XrayState>();
    final apFileName = xrayState.apFileName;
    final laFileName = xrayState.laFileName;

    // 현재 분석 모드 상태를 UserState에서 가져오기
    final analysisMode = userState.analysisMode;

    // uploadMode 표시 상태 가져오기
    final apUploadMode = xrayState.apUploadMode;
    final laUploadMode = xrayState.laUploadMode;

    // 모드 설명을 SnackBar로 표시하는 함수
    void showModeChangedSnackBar() {
      // 이전에 표시된 모든 SnackBar 제거
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 컨트롤러 변수 해제
      _snackBarController = null;

      // 모드 설명을 SnackBar로 표시
      _snackBarController = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                analysisMode == UploadMode.fullBody
                    ? Icons.crop
                    : Icons.person_outline,
                color:
                analysisMode == UploadMode.fullBody
                    ? Colors.orange
                    : Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  analysisMode == UploadMode.fullBody
                      ? '부분 모드: 업로드 시 직접 분석할 부위를 선택'
                      : '전신 모드: 전신 X-ray를  부위별로 알아서 분석',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.black.withOpacity(0.9),
          duration: const Duration(seconds: 3),
          onVisible: () {
            // SnackBar가 표시될 때 로그 추가
            print('SnackBar 표시됨: ${analysisMode.toString()}');
          },
        ),
      );
    }

    // 모드 변경 함수를 UserState를 사용하도록 수정
    void toggleAnalysisMode() {
      // UserState를 통해 모드 변경
      userState.toggleAnalysisMode();

      // 이미지가 있는 경우 확인 다이얼로그 표시
      if (apFileName != null || laFileName != null) {
        // 현재 표시된 SnackBar 닫기
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // 확인 다이얼로그 표시
        showDialog(
          context: context,
          barrierDismissible: false, // 외부 클릭으로 닫히지 않도록 설정
          builder:
              (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              '모드 변경',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              '모드가 변경되어 업로드된 이미지를 초기화합니다.\n이미지를 다시 올려주시기 바랍니다.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                child: Text('확인', style: TextStyle(color: Colors.orange)),
                onPressed: () {
                  // 이미지 초기화
                  xrayState.clearAll();

                  // 선택된 부위 정보도 초기화
                  setState(() {
                    apSelectedRegion = null;
                    laSelectedRegion = null;
                  });

                  // 다이얼로그 닫기
                  Navigator.of(context).pop();

                  // 모드 변경이 완료된 후 약간의 딜레이 추가 (UI 업데이트 완료를 위해)
                  Future.delayed(Duration(milliseconds: 100), () {
                    // 스낵바 표시
                    showModeChangedSnackBar();
                  });
                },
              ),
            ],
          ),
        );
      } else {
        // 이미지가 없는 경우 바로 스낵바 표시
        // 약간의 딜레이 추가 (setState가 완료되고 UI가 업데이트된 후 실행)
        Future.delayed(Duration(milliseconds: 100), () {
          showModeChangedSnackBar();
        });
      }
    }

    Widget _buildInfoCard() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade900.withOpacity(0.9),
              Colors.grey.shade800.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 끝으로 배치
              children: [
                const Text(
                  'Auto X‑line이란?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // key를 추가하여 참조할 수 있도록 변경
                BouncingQuestionMark(
                  key: _questionMarkKey,
                  onTap: () {
                    launchUrl(Uri.parse('https://www.youtube.com'));
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '🧾 AI가 정면·측면 X‑ray를 분석해 척추 각도·변형 리포트를 생성\n'
                  '🏥가까운 전문병원을 추천해 주는 스마트 척추케어 서비스 입니다.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),

          // 거리측정용
            // 상단 영역: 버튼과 픽셀/mm 비율을 양쪽 정렬
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
              child: Row(
                children: [
                  // 왼쪽: 단위측정 버튼 - Flexible로 감싸서 너비 비율 고정
                  Flexible(
                    flex: 2,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isMeasureToolExpanded = !_isMeasureToolExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isMeasureToolExpanded ? Colors.orange : Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _isMeasureToolExpanded ? Colors.orange.shade300 : Colors.grey[600]!,
                          ),
                        ),
                        // 여기가 변경된 부분: Wrap을 사용하고 mainAxisSize 제거
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            // mainAxisSize: MainAxisSize.min 제거
                            children: [
                              Icon(
                                Icons.straighten,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '단위 측정',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: _isMeasureToolExpanded ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                _isMeasureToolExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 14,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12), // 간격 동일하게 추가

                  // 오른쪽: 픽셀/mm 비율 표시 - Flexible로 감싸서 너비 비율 고정
                  Flexible(
                    flex: 3,
                    child: ValueListenableBuilder<double>(
                      valueListenable: MeasurementConstants.pixelToMmNotifier,
                      builder: (context, value, _) {
                        return Text(
                          '1px당 실제거리 : ${value.toStringAsFixed(4)}mm',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

// 확장된 패널
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isMeasureToolExpanded ? 60 : 0,
              child: AnimatedOpacity(
                opacity: _isMeasureToolExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      // 왼쪽: 버튼 - 상단과 동일한 flex 비율
                      Flexible(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 36), // 너비 최대로 설정
                          ),
                          onPressed: () {
                            ImageUploadMeasurement.selectAndMeasure(context: context);
                            setState(() {
                              _isMeasureToolExpanded = false;
                            });
                          },
                          child: const Text(
                            '이미지 선택 및 측정하기',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12), // 상단과 동일한 간격

                      // 오른쪽: 설명 텍스트 - 상단과 동일한 flex 비율
                      Flexible(
                        flex: 3,
                        child: const Text(
                          '1px당 단위를 측정하여 X-ray와 실제 거리를 매칭시켜줍니다.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ]
        ),
      );
    };


    // 업로드 이미지
    Widget _buildUploadArea({
      required String label,
      required String? fileName,
      required VoidCallback onTap,
      String? uploadMode,
      String? selectedRegion,
    }) {
      // 모드에 따른 색상 설정
      final bool isCropMode =
      uploadMode != null && uploadMode.contains('cropRegion');
      final Color modeColor = isCropMode ? Colors.orange : Colors.blue;
      final String modeText = isCropMode ? '부분' : '전신';

      // 선택된 부위 표시 텍스트 생성
      String? regionText;
      if (isCropMode && selectedRegion != null) {
        final Map<String, String> regionNames = {
          'cervical': '경추',
          'thoracic': '흉추',
          'lumbar': '요추',
          'pelvic': '골반',
        };
        regionText = regionNames[selectedRegion] ?? selectedRegion;
      }

      // 파일 업로드 상태에 따른 아이콘 선택
      Widget uploadIcon;
      if (fileName == null) {
        // 파일이 없는 경우 기본 업로드 아이콘
        uploadIcon = const Icon(
          Icons.add_photo_alternate,
          color: Colors.white70,
          size: 30,
        );
      } else {
        // 파일이 있는 경우 모드에 맞는 아이콘 표시
        if (isCropMode) {
          // 부분 모드 아이콘
          uploadIcon = Icon(Icons.crop, color: modeColor, size: 30);
        } else {
          // 전신 모드 아이콘
          uploadIcon = Icon(Icons.person_outline, color: modeColor, size: 30);
        }
      }

      return Expanded(
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    // 업로드된 파일이 있을 경우 모드에 따라 테두리 색상 변경
                    color:
                    fileName != null
                        ? modeColor.withOpacity(0.5)
                        : Colors.white24,
                    width: fileName != null ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // 메인 업로드 아이콘 및 텍스트
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 동적으로 결정된 아이콘
                          uploadIcon,
                          const SizedBox(height: 4),
                          Text(
                            fileName == null ? '$label 업로드' : '$label 재업로드',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 업로드된 파일이 있을 경우 모드 표시 배지
                    if (fileName != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: modeColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            modeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // 선택된 부위가 있는 경우 부위 표시 배지
                    if (regionText != null)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            regionText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (fileName != null)
              SizedBox(
                width: 120,
                child: Text(
                  fileName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              )
            else
              Text(
                '$label 이미지 없음',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
          ],
        ),
      );
    }

    // 모드 토글 스위치 위젯 (컴팩트 사이즈)
    Widget _buildCompactModeToggle() {
      return Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 전신 모드 레이블
            Padding(
              padding: const EdgeInsets.only(left: 1, right: 1),
              child: Text(
                '전신',
                style: TextStyle(
                  color:
                  analysisMode == UploadMode.fullBody
                      ? Colors.blue
                      : Colors.white60,
                  fontWeight:
                  analysisMode == UploadMode.fullBody
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
            // 토글 스위치 (축소 버전)
            Transform.scale(
              scale: 0.8, // 스위치 크기 축소
              child: Switch(
                value: analysisMode == UploadMode.cropRegion,
                activeColor: Colors.orange,
                inactiveThumbColor: Colors.white,
                activeTrackColor: Colors.deepOrange.withOpacity(0.3),
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                onChanged: (_) => toggleAnalysisMode(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            // 부위 선택 모드 레이블
            Padding(
              padding: const EdgeInsets.only(left: 1, right: 1),
              child: Text(
                '부분',
                style: TextStyle(
                  color:
                  analysisMode == UploadMode.cropRegion
                      ? Colors.orange
                      : Colors.white60,
                  fontWeight:
                  analysisMode == UploadMode.cropRegion
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          '안녕하세요, $userId 님 👋',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: '로그아웃',
            onPressed: () {
              isLoggedIn = false;
              context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 서비스 설명 카드
            _buildInfoCard(),
            const SizedBox(height: 16),

            // 업로드 안내와 토글 스위치 같은 줄에 배치
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'X‑ray를 업로드하세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 모드 토글 스위치 추가 (오른쪽에 배치, 컴팩트 버전)
                _buildCompactModeToggle(),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                // AP 업로드 부위
                _buildUploadArea(
                  label: '정면(AP)',
                  fileName: apFileName,
                  uploadMode: apUploadMode,
                  selectedRegion: apSelectedRegion,
                  onTap: () async {
                    // 현재 선택된 모드를 다이얼로그에 전달 (UserState에서 가져옴)
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder:
                          (context) => FileUploadAPView(
                        initialMode:
                        userState.analysisMode, // UserState에서 모드 가져오기
                      ),
                    );

                    if (result != null) {
                      final bytes = result['bytes'] as Uint8List;
                      final name = result['name'] as String;
                      final uploadMode = result['uploadMode'] as String?;

                      // 부위 모드에서 선택된 부위 정보 저장
                      if (uploadMode != null &&
                          uploadMode.contains('cropRegion')) {
                        final region = result['selectedRegion'] as String?;
                        if (region != null) {
                          setState(() {
                            apSelectedRegion = region;
                          });
                        }
                      } else {
                        // 전신 모드에서는 선택된 부위 초기화
                        setState(() {
                          apSelectedRegion = null;
                        });
                      }

                      // 업로드 모드 함께 저장
                      xrayState.setApFile(bytes, name, uploadMode);
                    }
                  },
                ),
                const SizedBox(width: 14),
                _buildUploadArea(
                  label: '옆면(LA)',
                  fileName: laFileName,
                  uploadMode: laUploadMode,
                  selectedRegion: laSelectedRegion,
                  onTap: () async {
                    // 현재 선택된 모드를 다이얼로그에 전달 (UserState에서 가져옴)
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder:
                          (context) => FileUploadLAView(
                        initialMode:
                        userState.analysisMode, // UserState에서 모드 가져오기
                      ),
                    );

                    if (result != null) {
                      final bytes = result['bytes'] as Uint8List;
                      final name = result['name'] as String;
                      final uploadMode = result['uploadMode'] as String?;

                      // 부위 모드에서 선택된 부위 정보 저장
                      if (uploadMode != null &&
                          uploadMode.contains('cropRegion')) {
                        final region = result['selectedRegion'] as String?;
                        if (region != null) {
                          setState(() {
                            laSelectedRegion = region;
                          });
                        }
                      } else {
                        // 전신 모드에서는 선택된 부위 초기화
                        setState(() {
                          laSelectedRegion = null;
                        });
                      }

                      // 업로드 모드 함께 저장
                      xrayState.setLaFile(bytes, name, uploadMode);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 부위 카드 리스트
            const Text(
              '분석할 부위를 선택하세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                childAspectRatio: 1.0,
                // 정사각형 비율 보장
                physics: NeverScrollableScrollPhysics(),
                children:
                [
                  {
                    'label': '경추',
                    'image': 'assets/cervical.png',
                    'region': 'cervical',
                  },
                  {
                    'label': '흉추',
                    'image': 'assets/thoracic.png',
                    'region': 'thoracic',
                  },
                  {
                    'label': '요추',
                    'image': 'assets/lumbar.png',
                    'region': 'lumbar',
                  },
                  {
                    'label': '골반',
                    'image': 'assets/pelvic.png',
                    'region': 'pelvic',
                  },
                ].map((region) {
                  return GestureDetector(
                    onTap: () async {
                      final ap = xrayState.apFileBytes;
                      final la = xrayState.laFileBytes;
                      final regionId = region['region'] as String;

                      if (ap == null || la == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("📷 먼저 X‑ray 이미지를 업로드해주세요"),
                          ),
                        );
                        return;
                      }

                      // 부위 모드에서 AP와 LA 모두 같은 부위로 선택되었는지 확인
                      if (userState.analysisMode == UploadMode.cropRegion) {
                        // UserState에서 가져오도록 수정
                        // 부위 모드에서 AP와 LA 업로드 모드 확인
                        final apMode = xrayState.apUploadMode;
                        final laMode = xrayState.laUploadMode;

                        // 두 이미지 모두 부위 모드로 업로드되었는지 확인
                        if (apMode != null &&
                            laMode != null &&
                            apMode.contains('cropRegion') &&
                            laMode.contains('cropRegion')) {
                          // 선택된 부위가 모두 존재하고 일치하는지 확인
                          if (apSelectedRegion != null &&
                              laSelectedRegion != null) {
                            // 선택된 부위가 클릭한 부위와 일치하는지 확인
                            if (apSelectedRegion == regionId &&
                                laSelectedRegion == regionId) {
                              // 이미 크롭된 이미지와 선택된 부위가 일치하면 바로 분석 페이지로 이동
                              print('✅ 부위 모드: 직접 이동 to $regionId');

                              // 크롭된 이미지 데이터 설정 (실제로는 업로드 시 크롭된 이미지를 사용)
                              final cropImages = {
                                regionId: {
                                  'url':
                                  'cropped_image_url', // 실제 URL 또는 데이터
                                  'data': 'base64_encoded_data', // 실제 데이터
                                },
                              };

                              // 크롭 상태 설정
                              context.read<XrayCropState>().setCrops(
                                ViewType.ap,
                                {regionId: ap},
                              );
                              context.read<XrayCropState>().setCrops(
                                ViewType.la,
                                {regionId: la},
                              );

                              // 분석 페이지로 이동
                              context.push('/analysis/$regionId');
                              return; // 여기서 함수 종료
                            } else {
                              // 선택된 부위와 클릭한 부위가 다름
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "⚠️ 선택한 부위(${region['label']})와 업로드 시 크롭한 부위가 다릅니다.\n"
                                        "AP: ${_getRegionName(apSelectedRegion)}, LA: ${_getRegionName(laSelectedRegion)}",
                                  ),
                                ),
                              );
                              return; // 여기서 함수 종료
                            }
                          }
                        }
                      }

                      try {
                        final apBytes = xrayState.apFileBytes;
                        final laBytes = xrayState.laFileBytes;

                        _questionMarkKey.currentState?.stopAnimation();

                        // 앱 전체 분석 모드에 따라 API 엔드포인트 설정
                        final modelEndpoint =
                        userState.analysisMode == UploadMode.fullBody
                            ? ApiService.FULLBODY_MODEL_ENDPOINT
                            : ApiService.CROPPED_MODEL_ENDPOINT;

                        if (apBytes == null ||
                            laBytes == null ||
                            apFileName == null ||
                            laFileName == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('이미지를 먼저 업로드해주세요.'),
                            ),
                          );
                          return;
                        }

                        // 분석 진행 중임을 알리는 다이얼로그 표시
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white30,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.orange,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    '분석 중입니다...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    userState.analysisMode ==
                                        UploadMode.fullBody
                                        ? '전신 모드로 분석 중'
                                        : '부위 모드로 분석 중',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        try {
                          // AP 이미지 분석
                          print(
                            '🔍 AP 분석 시작 (모드: ${userState.analysisMode.toString()})',
                          );
                          final resultAp = await ApiService.uploadToDetect(
                            apBytes,
                            apFileName,
                            ViewType.ap,
                            endpointOverride: modelEndpoint,
                          );

                          // AP crop 이미지 처리
                          print('📷 AP Response: $resultAp');
                          if (resultAp['crops'] != null) {
                            Map<String, dynamic> cropImages = {};
                            for (var region in [
                              'cervical',
                              'thoracic',
                              'lumbar',
                              'pelvic',
                            ]) {
                              if (resultAp['crops'][region] != null) {
                                print(
                                  '📷 AP $region Image: ${resultAp['crops'][region]}',
                                );
                                cropImages[region] =
                                resultAp['crops'][region];
                              }
                            }

                            context.read<XrayCropState>().setCrops(
                              ViewType.ap,
                              cropImages,
                            );
                          }

                          // LA 이미지 분석
                          print(
                            '🔍 LA 분석 시작 (모드: ${userState.analysisMode.toString()})',
                          );
                          final resultLa = await ApiService.uploadToDetect(
                            laBytes,
                            laFileName,
                            ViewType.la,
                            endpointOverride: modelEndpoint,
                          );

                          // LA crop 이미지 처리
                          print('📷 LA Response: $resultLa');
                          if (resultLa['crops'] != null) {
                            Map<String, dynamic> cropImages = {};
                            for (var region in [
                              'cervical',
                              'thoracic',
                              'lumbar',
                              'pelvic',
                            ]) {
                              if (resultLa['crops'][region] != null) {
                                print(
                                  '📷 LA $region Image: ${resultLa['crops'][region]}',
                                );
                                cropImages[region] =
                                resultLa['crops'][region];
                              }
                            }

                            context.read<XrayCropState>().setCrops(
                              ViewType.la,
                              cropImages,
                            );
                          }

                          // 진행 다이얼로그 닫기
                          Navigator.of(context).pop();

                          // 결과에 따라 화면 전환
                          context.push('/analysis/${regionId}');
                        } catch (e) {
                          // 진행 다이얼로그 닫기
                          Navigator.of(context).pop();

                          print('❌ 분석 에러: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('분석 실패: $e')),
                          );
                        }
                      } catch (e) {
                        // 예외 처리
                        print("API 호출 실패: $e");

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("분석에 실패했습니다. 다시 시도해주세요."),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      padding: const EdgeInsets.all(2), // 패딩 줄여서 이미지 공간 확보
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 이미지를 더 크게 표시
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                region['image']!,
                                fit: BoxFit.cover, // cover로 변경하여 컨테이너를 꽉 채움
                              ),
                            ),
                          ),
                          // 반투명 오버레이 추가
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                          ),
                          // 텍스트를 중앙에 배치
                          Text(
                            region['label']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18, // 글자 크기 키움
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Color.fromRGBO(0, 0, 0, 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 1) {
            context.go('/hospital_screen');
          } else if (index == 2) {
            context.go('/myinfo_screen');
          } else {
            context.go('/home_screen');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital),
            label: 'Hospital',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Myinfo',
          ),
        ],
      ),
    );
  }

  // 부위 이름 가져오기 함수 - dispose() 메서드 앞에 추가
  String _getRegionName(String? regionId) {
    if (regionId == null) return '없음';

    final Map<String, String> regionNames = {
      'cervical': '경추',
      'thoracic': '흉추',
      'lumbar': '요추',
      'pelvic': '골반',
    };
    return regionNames[regionId] ?? regionId;
  }

  @override
  void dispose() {
    // SnackBar 닫기
    _snackBarController?.close();
    super.dispose();
  }
}





// 먼저 BouncingQuestionMark 클래스에 애니메이션 제어 메서드 추가
class BouncingQuestionMark extends StatefulWidget {
  final VoidCallback onTap;

  const BouncingQuestionMark({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BouncingQuestionMark> createState() => _BouncingQuestionMarkState();
}

class _BouncingQuestionMarkState extends State<BouncingQuestionMark> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // 애니메이션 시작 메서드 추가
  void startAnimation() {
    _controller.repeat(reverse: true);
  }

  // 애니메이션 중지 메서드 추가
  void stopAnimation() {
    _controller.stop();
  }

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);  // 기본적으로 시작

    // 위아래로 뛰는 애니메이션 생성
    _animation = Tween<double>(
      begin: 0.0,
      end: 6.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            // y축으로 애니메이션 값만큼 이동
            offset: Offset(0, -_animation.value),
            child: const Icon(
              Icons.live_help_outlined,
              color: Colors.orange,
              size: 20,
            ),
          );
        },
      ),
    );
  }
}


