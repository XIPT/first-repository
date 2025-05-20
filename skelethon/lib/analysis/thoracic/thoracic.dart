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


class ThoracicPage extends StatefulWidget {
  const ThoracicPage({super.key});

  @override
  State<ThoracicPage> createState() => _ThoracicPageState();
}

class _ThoracicPageState extends State<ThoracicPage> {
  double overlayBaseSize = 300;
  bool isAnalyzingAp = false;
  bool isAnalyzingLa = false;

  Uint8List? thoracicApBytes;
  Uint8List? thoracicLaBytes;

  double? originalApWidth;
  double? originalApHeight;
  double? originalLaWidth;
  double? originalLaHeight;

  @override
  void initState() {
    super.initState();
    _prepareImages();
  }

  Future<void> _prepareImages() async {
    final cropState = context.read<XrayCropState>();

    // XrayCropState에서 데이터를 가져오기
    final dynamic thoracicApData = cropState.getCropImage(
        ViewType.ap, 'thoracic');
    final dynamic thoracicLaData = cropState.getCropImage(
        ViewType.la, 'thoracic');

    // AP 이미지 처리
    if (thoracicApData != null) {
      try {
        print('🔍 AP 데이터 타입: ${thoracicApData.runtimeType}');

        // 데이터가 문자열처럼 보이지만 실제로는 리스트 형태일 수 있음
        if (thoracicApData is String && thoracicApData.startsWith('[') &&
            thoracicApData.contains(',')) {
          try {
            // 문자열을 파싱하여 int 리스트로 변환
            final String cleanString = thoracicApData
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll(' ', '');

            List<int> intList = cleanString
                .split(',')
                .where((s) => s.isNotEmpty)
                .map((s) => int.parse(s.trim()))
                .toList();

            thoracicApBytes = Uint8List.fromList(intList);
            print('📷 AP: 문자열에서 ${intList.length}개 항목을 Uint8List로 변환');
          } catch (e) {
            print('❌ AP 문자열 파싱 에러: $e');
          }
        }
        // 일반 리스트인 경우
        else if (thoracicApData is List) {
          List<int> intList = [];
          for (var item in thoracicApData) {
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
          thoracicApBytes = Uint8List.fromList(intList);
          print('📷 AP: ${intList.length}개 항목을 Uint8List로 변환');
        }
        // 일반 base64 문자열인 경우
        else if (thoracicApData is String) {
          try {
            thoracicApBytes = base64Decode(thoracicApData);
            print('📷 AP: base64 문자열 디코딩 완료');
          } catch (e) {
            print('❌ AP base64 디코딩 에러: $e');

            // 디코딩 실패 시 다른 방법 시도
            print('⚠️ AP: 다른 방법으로 변환 시도');
            try {
              // 직접 바이트 배열 생성 시도
              final List<int> bytes = [];
              for (int i = 0; i < thoracicApData.length; i++) {
                bytes.add(thoracicApData.codeUnitAt(i));
              }
              thoracicApBytes = Uint8List.fromList(bytes);
              print('📷 AP: 문자열에서 직접 바이트 배열로 변환');
            } catch (e2) {
              print('❌ AP 변환 실패: $e2');
            }
          }
        }

        // 이미지 크기 정보 계산
        if (thoracicApBytes != null) {
          try {
            final apImage = await decodeImageFromList(thoracicApBytes!);
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
    if (thoracicLaData != null) {
      try {
        print('🔍 LA 데이터 타입: ${thoracicLaData.runtimeType}');

        // 데이터가 문자열처럼 보이지만 실제로는 리스트 형태일 수 있음
        if (thoracicLaData is String && thoracicLaData.startsWith('[') &&
            thoracicLaData.contains(',')) {
          try {
            // 문자열을 파싱하여 int 리스트로 변환
            final String cleanString = thoracicLaData
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll(' ', '');

            List<int> intList = cleanString
                .split(',')
                .where((s) => s.isNotEmpty)
                .map((s) => int.parse(s.trim()))
                .toList();

            thoracicLaBytes = Uint8List.fromList(intList);
            print('📷 LA: 문자열에서 ${intList.length}개 항목을 Uint8List로 변환');
          } catch (e) {
            print('❌ LA 문자열 파싱 에러: $e');
          }
        }
        // 일반 리스트인 경우
        else if (thoracicLaData is List) {
          List<int> intList = [];
          for (var item in thoracicLaData) {
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
          thoracicLaBytes = Uint8List.fromList(intList);
          print('📷 LA: ${intList.length}개 항목을 Uint8List로 변환');
        }
        // 일반 base64 문자열인 경우
        else if (thoracicLaData is String) {
          try {
            thoracicLaBytes = base64Decode(thoracicLaData);
            print('📷 LA: base64 문자열 디코딩 완료');
          } catch (e) {
            print('❌ LA base64 디코딩 에러: $e');

            // 디코딩 실패 시 다른 방법 시도
            print('⚠️ LA: 다른 방법으로 변환 시도');
            try {
              // 직접 바이트 배열 생성 시도
              final List<int> bytes = [];
              for (int i = 0; i < thoracicLaData.length; i++) {
                bytes.add(thoracicLaData.codeUnitAt(i));
              }
              thoracicLaBytes = Uint8List.fromList(bytes);
              print('📷 LA: 문자열에서 직접 바이트 배열로 변환');
            } catch (e2) {
              print('❌ LA 변환 실패: $e2');
            }
          }
        }

        // 이미지 크기 정보 계산
        if (thoracicLaBytes != null) {
          try {
            final laImage = await decodeImageFromList(thoracicLaBytes!);
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
    if (originalApWidth == null || originalApHeight == null ||
        originalLaWidth == null || originalLaHeight == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final keypointsState = Provider.of<KeypointsState>(context);

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
                      const Text('AP View', style: TextStyle(
                          color: Colors.orangeAccent, fontSize: 16)),
                      const SizedBox(height: 8),
                      thoracicApBytes != null
                          ? Image.memory(
                          thoracicApBytes!, height: 150, fit: BoxFit.contain)
                          : const Text(
                          '이미지 없음', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: thoracicApBytes == null
                            ? null
                            : () async {
                          await _analyzeKeypointsAndShowDialog(
                              context,
                              ViewType.ap,
                              thoracicApBytes!
                          );
                        },
                        icon: isAnalyzingAp
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
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.5), width: 1),
                          ),
                          elevation: 0,
                          disabledForegroundColor: Colors.grey.withOpacity(
                              0.38),
                          disabledBackgroundColor: Colors.black,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text('LA View', style: TextStyle(
                          color: Colors.orangeAccent, fontSize: 16)),
                      const SizedBox(height: 8),
                      thoracicLaBytes != null
                          ? Image.memory(
                          thoracicLaBytes!, height: 150, fit: BoxFit.contain)
                          : const Text(
                          '이미지 없음', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: thoracicLaBytes == null
                            ? null
                            : () async {
                          await _analyzeKeypointsAndShowDialog(
                              context,
                              ViewType.la,
                              thoracicLaBytes!
                          );
                        },
                        icon: isAnalyzingLa
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
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.5), width: 1),
                          ),
                          elevation: 0,
                          disabledForegroundColor: Colors.grey.withOpacity(
                              0.38),
                          disabledBackgroundColor: Colors.black,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // 스크롤 가능한 결과 리스트뷰 영역
    Widget scrollableResultSection = keypointsState
        .getOverlayedKeypoints('thoracic', 'LA')
        ?.isNotEmpty ?? false
        ? Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(), // 스크롤 가능하도록 변경
        padding: EdgeInsets.zero, // 패딩 제거
        children: [
        ],
      ),
    )
        : SizedBox.shrink(); // 결과가 없으면 빈 공간 표시

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('흉추 분석', style: TextStyle(color: Colors.white)),
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
              child: scrollableResultSection,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisListTile(BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    double titleFontSize = 18.0, // 기본 제목 글자 크기
    double subtitleFontSize = 15.0, // 기본 부제목 글자 크기
    double verticalPadding = 4.0, // 기본 수직 패딩
    double horizontalPadding = 20.0, // 기본 수평 패딩
    double? tileHeight, // 타일 높이 (선택 사항)
    bool dense = false, // 조밀한 레이아웃 옵션
  }) {
    return Container(
      height: tileHeight, // 높이가 지정되면 적용, 아니면 null
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white70,
            fontSize: subtitleFontSize,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap,
        tileColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        dense: dense, // 조밀한 레이아웃 적용 여부
      ),
    );
  }

  Future<void> _analyzeKeypointsAndShowDialog(BuildContext context,
      ViewType viewType, Uint8List imageBytes) async {
    setState(() {
      if (viewType == ViewType.ap) {
        isAnalyzingAp = true;
      } else {
        isAnalyzingLa = true;
      }
    });

    try {
      final keypoints = await ApiService.predictKeypoints(
        region: 'thoracic',
        viewType: viewType,
        cropBytes: imageBytes,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            Dialog(
              backgroundColor: Colors.transparent,
              child: KeypointsOverlay(
                imageBytes: imageBytes,
                keypoints: keypoints,
                originalWidth: viewType == ViewType.ap
                    ? originalApWidth!
                    : originalLaWidth!,
                originalHeight: viewType == ViewType.ap
                    ? originalApHeight!
                    : originalLaHeight!,
                imageId: '${viewType == ViewType.ap ? 'ap' : 'la'}_${DateTime
                    .now()
                    .millisecondsSinceEpoch}',
                region: 'thoracic',
                view: viewType == ViewType.ap ? 'AP' : 'LA',
                onClose: () => Navigator.pop(context),
                // 정밀 예측을 위한 predictKeypoints 함수 추가
                predictKeypoints: (Uint8List bytes) async {
                  // 기존 키포인트 예측 모델 활용
                  return await ApiService.predictKeypoints(
                    region: 'thoracic',
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
