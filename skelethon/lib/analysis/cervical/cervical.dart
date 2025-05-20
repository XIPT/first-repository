import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '/state/xray_crop_state.dart';
import '/state/keypoints_state.dart';

import '../../utils/keypoints_save.dart';

import '/services/api_service.dart';
import '../../utils/enums.dart';

// ScrollableSection과 AnalysisItems 임포트
import '/utils/scrollsection.dart';
import '/analysis/analysis_listview.dart';


class CervicalPage extends StatefulWidget {
  const CervicalPage({super.key});

  @override
  State<CervicalPage> createState() => _CervicalPageState();
}

class _CervicalPageState extends State<CervicalPage> {
  double overlayBaseSize = 300;
  bool isAnalyzingAp = false;
  bool isAnalyzingLa = false;

  Uint8List? cervicalApBytes;
  Uint8List? cervicalLaBytes;

  double? originalApWidth;
  double? originalApHeight;
  double? originalLaWidth;
  double? originalLaHeight;

  bool showCervicalApSection = false;
  bool showCervicalLaSection = false;

  @override
  void initState() {
    super.initState();
    _prepareImages();
  }

  Future<void> _prepareImages() async {
    final cropState = context.read<XrayCropState>();

    // XrayCropState에서 데이터를 가져오기
    final dynamic cervicalApData = cropState.getCropImage(
      ViewType.ap,
      'cervical',
    );
    final dynamic cervicalLaData = cropState.getCropImage(
      ViewType.la,
      'cervical',
    );

    // AP 이미지 처리
    if (cervicalApData != null) {
      try {
        print('🔍 AP 데이터 타입: ${cervicalApData.runtimeType}');

        // 데이터가 문자열처럼 보이지만 실제로는 리스트 형태일 수 있음
        if (cervicalApData is String &&
            cervicalApData.startsWith('[') &&
            cervicalApData.contains(',')) {
          try {
            // 문자열을 파싱하여 int 리스트로 변환
            final String cleanString = cervicalApData
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll(' ', '');

            List<int> intList =
            cleanString
                .split(',')
                .where((s) => s.isNotEmpty)
                .map((s) => int.parse(s.trim()))
                .toList();

            cervicalApBytes = Uint8List.fromList(intList);
            print('📷 AP: 문자열에서 ${intList.length}개 항목을 Uint8List로 변환');
          } catch (e) {
            print('❌ AP 문자열 파싱 에러: $e');
          }
        }
        // 일반 리스트인 경우
        else if (cervicalApData is List) {
          List<int> intList = [];
          for (var item in cervicalApData) {
            if (item is int) {
              intList.add(item);
            } else if (item is String) {
              try {
                intList.add(int.parse(item));
              } catch (e) {
                print('⚠️ 항목 변환 실패: $item');
              }
            }
          }
          cervicalApBytes = Uint8List.fromList(intList);
          print('📷 AP: ${intList.length}개 항목을 Uint8List로 변환');
        }
        // 일반 base64 문자열인 경우
        else if (cervicalApData is String) {
          try {
            cervicalApBytes = base64Decode(cervicalApData);
            print('📷 AP: base64 문자열 디코딩 완료');
          } catch (e) {
            print('❌ AP base64 디코딩 에러: $e');

            // 디코딩 실패 시 다른 방법 시도
            print('⚠️ AP: 다른 방법으로 변환 시도');
            try {
              // 직접 바이트 배열 생성 시도
              final List<int> bytes = [];
              for (int i = 0; i < cervicalApData.length; i++) {
                bytes.add(cervicalApData.codeUnitAt(i));
              }
              cervicalApBytes = Uint8List.fromList(bytes);
              print('📷 AP: 문자열에서 직접 바이트 배열로 변환');
            } catch (e2) {
              print('❌ AP 변환 실패: $e2');
            }
          }
        }

        // 이미지 크기 정보 계산
        if (cervicalApBytes != null) {
          try {
            final apImage = await decodeImageFromList(cervicalApBytes!);
            setState(() {
              originalApWidth = apImage.width.toDouble();
              originalApHeight = apImage.height.toDouble();
            });
            print('📐 AP 이미지 크기: ${originalApWidth}x${originalApHeight}');
          } catch (e) {
            print('❌ AP 이미지 디코딩 에러: $e');
          }
        }
      } catch (e) {
        print('❌ AP 이미지 처리 에러: $e');
      }
    }

    // LA 이미지도 동일한 방식으로 처리
    if (cervicalLaData != null) {
      try {
        print('🔍 LA 데이터 타입: ${cervicalLaData.runtimeType}');

        // 데이터가 문자열처럼 보이지만 실제로는 리스트 형태일 수 있음
        if (cervicalLaData is String &&
            cervicalLaData.startsWith('[') &&
            cervicalLaData.contains(',')) {
          try {
            // 문자열을 파싱하여 int 리스트로 변환
            final String cleanString = cervicalLaData
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll(' ', '');

            List<int> intList =
            cleanString
                .split(',')
                .where((s) => s.isNotEmpty)
                .map((s) => int.parse(s.trim()))
                .toList();

            cervicalLaBytes = Uint8List.fromList(intList);
            print('📷 LA: 문자열에서 ${intList.length}개 항목을 Uint8List로 변환');
          } catch (e) {
            print('❌ LA 문자열 파싱 에러: $e');
          }
        }
        // 일반 리스트인 경우
        else if (cervicalLaData is List) {
          List<int> intList = [];
          for (var item in cervicalLaData) {
            if (item is int) {
              intList.add(item);
            } else if (item is String) {
              try {
                intList.add(int.parse(item));
              } catch (e) {
                print('⚠️ 항목 변환 실패: $item');
              }
            }
          }
          cervicalLaBytes = Uint8List.fromList(intList);
          print('📷 LA: ${intList.length}개 항목을 Uint8List로 변환');
        }
        // 일반 base64 문자열인 경우
        else if (cervicalLaData is String) {
          try {
            cervicalLaBytes = base64Decode(cervicalLaData);
            print('📷 LA: base64 문자열 디코딩 완료');
          } catch (e) {
            print('❌ LA base64 디코딩 에러: $e');

            // 디코딩 실패 시 다른 방법 시도
            print('⚠️ LA: 다른 방법으로 변환 시도');
            try {
              // 직접 바이트 배열 생성 시도
              final List<int> bytes = [];
              for (int i = 0; i < cervicalLaData.length; i++) {
                bytes.add(cervicalLaData.codeUnitAt(i));
              }
              cervicalLaBytes = Uint8List.fromList(bytes);
              print('📷 LA: 문자열에서 직접 바이트 배열로 변환');
            } catch (e2) {
              print('❌ LA 변환 실패: $e2');
            }
          }
        }

        // 이미지 크기 정보 계산
        if (cervicalLaBytes != null) {
          try {
            final laImage = await decodeImageFromList(cervicalLaBytes!);
            setState(() {
              originalLaWidth = laImage.width.toDouble();
              originalLaHeight = laImage.height.toDouble();
            });
            print('📐 LA 이미지 크기: ${originalLaWidth}x${originalLaHeight}');
          } catch (e) {
            print('❌ LA 이미지 디코딩 에러: $e');
          }
        }
      } catch (e) {
        print('❌ LA 이미지 처리 에러: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 데이터가 준비되지 않았다면 로딩 표시
    if (originalApWidth == null ||
        originalApHeight == null ||
        originalLaWidth == null ||
        originalLaHeight == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 상단에 고정될 이미지 + 분석 버튼 영역
    Widget topFixedSection = Container(
      decoration: BoxDecoration(
        color: Colors.black, // 배경색
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 사진 + 분석 버튼 (Row로 묶어서 위에 고정)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        'AP View',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      cervicalApBytes != null
                          ? Image.memory(
                        cervicalApBytes!,
                        height: 150,
                        fit: BoxFit.contain,
                      )
                          : const Text(
                        '이미지 없음',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed:
                        cervicalApBytes == null
                            ? null
                            : () async {
                          // 분석 중임을 표시
                          setState(() {
                            isAnalyzingAp = true;
                          });

                          try {
                            // 분석 수행
                            await _analyzeKeypointsAndShowDialog(
                              context,
                              ViewType.ap,
                              cervicalApBytes!,
                            );

                            // 분석 완료 후 결과 섹션 표시
                            if (mounted) {
                              setState(() {
                                showCervicalApSection = true;
                                showCervicalLaSection = false; // AP만 표시
                                isAnalyzingAp = false;
                              });
                            }
                          } catch (e) {
                            print('분석 중 오류: $e');
                            if (mounted) {
                              setState(() {
                                isAnalyzingAp = false;
                              });
                            }
                          }
                        },
                        icon:
                        isAnalyzingAp
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          '분석모델 준비중..',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                          disabledForegroundColor: Colors.grey.withOpacity(
                            0.38,
                          ),
                          disabledBackgroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        'LA View',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      cervicalLaBytes != null
                          ? Image.memory(
                        cervicalLaBytes!,
                        height: 150,
                        fit: BoxFit.contain,
                      )
                          : const Text(
                        '이미지 없음',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed:
                        cervicalLaBytes == null
                            ? null
                            : () async {
                          // 분석 중임을 표시
                          setState(() {
                            isAnalyzingLa = true;
                          });

                          try {
                            // 분석 수행
                            await _analyzeKeypointsAndShowDialog(
                              context,
                              ViewType.la,
                              cervicalLaBytes!,
                            );

                            // 분석 완료 후 결과 섹션 표시
                            if (mounted) {
                              setState(() {
                                showCervicalApSection = false; // LA만 표시
                                showCervicalLaSection = true;
                                isAnalyzingLa = false;
                              });
                            }
                          } catch (e) {
                            print('분석 중 오류: $e');
                            if (mounted) {
                              setState(() {
                                isAnalyzingLa = false;
                              });
                            }
                          }
                        },
                        icon:
                        isAnalyzingLa
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          '분석하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                          disabledForegroundColor: Colors.grey.withOpacity(
                            0.38,
                          ),
                          disabledBackgroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('경추 분석', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 1. 상단에 고정된 영역
          topFixedSection,

          // 2. 스크롤 가능한 결과 영역
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // AP 섹션
                  ScrollableSection(
                    show: showCervicalApSection,
                    backgroundColor: Colors.black.withOpacity(0.85),
                    children: AnalysisItems.getCervicalApItems(context),
                  ),

                  // LA 섹션
                  ScrollableSection(
                    show: showCervicalLaSection,
                    backgroundColor: Colors.black.withOpacity(0.85),
                    children: AnalysisItems.getCervicalLaItems(context),
                  ),

                  // 분석 결과가 없는 경우 안내 메시지
                  if (!showCervicalApSection && !showCervicalLaSection)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        '위에서 AP 또는 LA 이미지를 분석하면\n결과를 확인할 수 있습니다.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeKeypointsAndShowDialog(
      BuildContext context,
      ViewType viewType,
      Uint8List imageBytes,
      ) async {
    setState(() {
      if (viewType == ViewType.ap) {
        isAnalyzingAp = true;
      } else {
        isAnalyzingLa = true;
      }
    });

    try {
      final keypoints = await ApiService.predictKeypoints(
        region: 'cervical',
        viewType: viewType,
        cropBytes: imageBytes,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: KeypointsOverlay(
            imageBytes: imageBytes,
            keypoints: keypoints,
            originalWidth:
            viewType == ViewType.ap
                ? originalApWidth!
                : originalLaWidth!,
            originalHeight:
            viewType == ViewType.ap
                ? originalApHeight!
                : originalLaHeight!,
            imageId:
            '${viewType == ViewType.ap ? 'ap' : 'la'}_${DateTime.now().millisecondsSinceEpoch}',
            region: 'cervical',
            view: viewType == ViewType.ap ? 'AP' : 'LA',
            onClose: () => Navigator.pop(context),
            // 정밀 예측을 위한 predictKeypoints 함수 추가
            predictKeypoints: (Uint8List bytes) async {
              // 기존 키포인트 예측 모델 활용
              return await ApiService.predictKeypoints(
                region: 'cervical',
                viewType: viewType,
                cropBytes: bytes,
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ℹ️ 분석 모델은 준비 중입니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        if (viewType == ViewType.ap) {
          isAnalyzingAp = false;
        } else {
          isAnalyzingLa = false;
        }
      });
    }
  }
}