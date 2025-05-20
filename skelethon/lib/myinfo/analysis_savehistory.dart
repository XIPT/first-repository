import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:encrypt/encrypt.dart' as encrypt;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

// EncryptionUtil 클래스 import
import '/utils/encryption.dart';
import '/utils/keypoints_viewer.dart';
import '/utils/scrollsection.dart';  // ScrollableSection, AnalysisListTile 위젯 임포트
import '/analysis/analysis_listview.dart';  // AnalysisItems 클래스 임포트

// 데이터 선택 및 비교 기능이 추가된 뷰어 화면
class AnalysisSaveHistory extends StatefulWidget {
  final String initialRegion;
  final String initialView;

  const AnalysisSaveHistory({
    Key? key,
    this.initialRegion = 'cervical',
    this.initialView = 'LA',
  }) : super(key: key);

  @override
  _AnalysisSaveHistory createState() => _AnalysisSaveHistory();
}

class _AnalysisSaveHistory extends State<AnalysisSaveHistory> {
  // 첫 번째 데이터셋
  List<dynamic> dataset1Keypoints = [];
  String? dataset1ImageUrl;
  Uint8List? dataset1ImageBytes;
  String dataset1Date = '';
  String dataset1DocumentId = '';
  String dataset1Time = '';
  List<Map<String, dynamic>> dataset1Options = [];

  // 두 번째 데이터셋
  List<dynamic> dataset2Keypoints = [];
  String? dataset2ImageUrl;
  Uint8List? dataset2ImageBytes;
  String dataset2Date = '';
  String dataset2DocumentId = '';
  String dataset2Time = '';
  List<Map<String, dynamic>> dataset2Options = [];

  // 가용한 영역 및 뷰 옵션 추가
  final List<String> regionOptions = [
    'cervical',
    'thoracic',
    'lumbar',
    'pelvic'
  ];
  final List<String> viewOptions = ['LA', 'PA'];

  // 날짜 옵션 목록
  List<String> availableDates = [];

  // 통합된 현재 선택된 영역 및 뷰
  String selectedRegion = 'cervical';
  String selectedView = 'LA';
  String selectedDate1 = '';
  String selectedDate2 = '';

  bool isLoading1 = true;
  bool isLoading2 = true;
  String? errorMessage1;
  String? errorMessage2;

  // 분석 뷰 표시 여부 변수 (사용하지 않음)
  // bool showAnalysisView = false;

  @override
  void initState() {
    super.initState();

    // 초기값 설정
    selectedRegion = widget.initialRegion;
    selectedView = widget.initialView;

    // 오늘 날짜 설정
    final now = DateTime.now();
    final todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now
        .day.toString().padLeft(2, '0')}";
    selectedDate1 = todayDate;
    selectedDate2 = todayDate;

    // 사용 가능한 날짜 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailableDates();
    });
  }

  // 사용 가능한 날짜 목록 로드
  Future<void> _loadAvailableDates() async {
    setState(() {
      isLoading1 = true;
      isLoading2 = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('keypoints')
          .where('userId', isEqualTo: user.uid)
          .get();

      // 중복 없는 날짜 목록 생성
      final Set<String> dateSet = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['date'] != null && data['date'] is String) {
          dateSet.add(data['date']);
        }
      }

      setState(() {
        // 날짜를 최신순으로 정렬
        availableDates = dateSet.toList()
          ..sort((a, b) => b.compareTo(a));

        // 날짜가 있으면 첫 번째 날짜 선택
        if (availableDates.isNotEmpty) {
          print('사용 가능한 날짜: $availableDates');
          selectedDate1 = availableDates.first;
          selectedDate2 = availableDates.first;
          // 데이터 로드
          _loadDataset1();
          _loadDataset2();
        } else {
          print('사용 가능한 날짜가 없습니다');
          isLoading1 = false;
          isLoading2 = false;
          errorMessage1 = '저장된 데이터가 없습니다';
          errorMessage2 = '저장된 데이터가 없습니다';
        }
      });
    } catch (e) {
      print('날짜 로드 오류: ${e.toString()}');
      setState(() {
        isLoading1 = false;
        isLoading2 = false;
        errorMessage1 = '데이터 로드 중 오류 발생: ${e.toString()}';
        errorMessage2 = '데이터 로드 중 오류 발생: ${e.toString()}';
      });
    }
  }

  // 첫 번째 데이터셋 로드
  Future<void> _loadDataset1() async {
    setState(() {
      isLoading1 = true;
      errorMessage1 = null;
    });

    try {
      final results = await loadKeypointsDataByTime(
        selectedDate1,
        selectedRegion,
        selectedView,
      );

      setState(() {
        dataset1Options = results;
        isLoading1 = false;

        if (results.isNotEmpty) {
          // 첫 번째 결과를 기본값으로 설정
          _selectDataset1(results[0]);
        } else {
          errorMessage1 = '해당 조건에 맞는 데이터가 없습니다';
          dataset1Keypoints = [];
          dataset1ImageUrl = null;
          dataset1ImageBytes = null;
        }
      });
    } catch (e) {
      setState(() {
        isLoading1 = false;
        errorMessage1 = e.toString();
        dataset1Keypoints = [];
        dataset1ImageUrl = null;
        dataset1ImageBytes = null;
      });
    }
  }

  // 두 번째 데이터셋 로드
  Future<void> _loadDataset2() async {
    setState(() {
      isLoading2 = true;
      errorMessage2 = null;
    });

    try {
      final results = await loadKeypointsDataByTime(
        selectedDate2,
        selectedRegion,
        selectedView,
      );

      setState(() {
        dataset2Options = results;
        isLoading2 = false;

        if (results.isNotEmpty) {
          // 첫 번째 결과를 기본값으로 설정
          _selectDataset2(results[0]);
        } else {
          errorMessage2 = '해당 조건에 맞는 데이터가 없습니다';
          dataset2Keypoints = [];
          dataset2ImageUrl = null;
          dataset2ImageBytes = null;
        }
      });
    } catch (e) {
      setState(() {
        isLoading2 = false;
        errorMessage2 = e.toString();
        dataset2Keypoints = [];
        dataset2ImageUrl = null;
        dataset2ImageBytes = null;
      });
    }
  }

  // 첫 번째 데이터셋 선택
  void _selectDataset1(Map<String, dynamic> data) async {
    setState(() {
      dataset1Keypoints = data['keypoints'] ?? [];
      dataset1ImageUrl = data['imageUrl'];
      dataset1Date = data['date'] ?? '';
      dataset1DocumentId = data['documentId'] ?? '';
      dataset1Time = data['timeString'] ?? '';
    });

    // 이미지 로드
    if (dataset1ImageUrl != null && dataset1ImageUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(dataset1ImageUrl!));
        if (response.statusCode == 200) {
          setState(() {
            dataset1ImageBytes = response.bodyBytes;
          });
        }
      } catch (e) {
        print('이미지 로드 실패: $e');
      }
    }
  }

  // 두 번째 데이터셋 선택
  void _selectDataset2(Map<String, dynamic> data) async {
    setState(() {
      dataset2Keypoints = data['keypoints'] ?? [];
      dataset2ImageUrl = data['imageUrl'];
      dataset2Date = data['date'] ?? '';
      dataset2DocumentId = data['documentId'] ?? '';
      dataset2Time = data['timeString'] ?? '';
    });

    // 이미지 로드
    if (dataset2ImageUrl != null && dataset2ImageUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(dataset2ImageUrl!));
        if (response.statusCode == 200) {
          setState(() {
            dataset2ImageBytes = response.bodyBytes;
          });
        }
      } catch (e) {
        print('이미지 로드 실패: $e');
      }
    }
  }

  // 시간대별 키포인트 데이터를 불러오는 함수
  Future<List<Map<String, dynamic>>> loadKeypointsDataByTime(String date,
      String region, String view) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      // Firestore에서 해당 날짜, 부위, 뷰에 맞는 모든 데이터 쿼리
      final querySnapshot = await FirebaseFirestore.instance
          .collection('keypoints')
          .where('date', isEqualTo: date)
          .where('region', isEqualTo: region)
          .where('userId', isEqualTo: user.uid)
          .where('view', isEqualTo: view)
          .orderBy('timestamp', descending: true) // 최신 데이터가 먼저 오도록 정렬
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('저장된 데이터가 없습니다');
      }

      // 각 문서별로 데이터 처리
      List<Map<String, dynamic>> results = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        final encryptedCoordinates = data['encryptedCoordinates'];
        final timestamp = data['timestamp'] as Timestamp;
        final dateTime = timestamp.toDate();

        // 시간 포맷팅
        final timeString = '${dateTime.hour.toString().padLeft(
            2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

        try {
          // 키포인트 데이터 복호화
          dynamic parsedData;

          try {
            final decryptedString = EncryptionUtil.decryptData(
                encryptedCoordinates);
            parsedData = json.decode(decryptedString);
          } catch (decryptError) {
            // 대체 메서드 시도
            parsedData = EncryptionUtil.decryptJsonData(encryptedCoordinates);
          }

          // 결과 추가
          results.add({
            'keypoints': parsedData ?? [],
            'imageUrl': data['imageUrl'],
            'date': data['date'],
            'timestamp': timestamp,
            'timeString': timeString,
            'documentId': doc.id,
          });
        } catch (e) {
          // 오류가 있는 문서는 건너뛰고 계속 진행
        }
      }

      return results;
    } catch (e) {
      rethrow;
    }
  }

  // 분석 뷰 모드 전환 메서드 제거
  /* 사용하지 않는 메서드 제거
  void _toggleViewMode() {
    setState(() {
      showAnalysisView = !showAnalysisView;
    });
  }
  */

// 뷰 빌드
  Widget build(BuildContext context) {
    return Theme(
      // 앱 전체 테마를 검은색으로 설정
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          background: Colors.black,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
        canvasColor: Colors.black, // 드롭다운 메뉴와 스크롤 효과의 배경색
        shadowColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('분석 기록 비교', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                _loadDataset1();
                _loadDataset2();
              },
            ),
          ],
        ),
        body: Container(
          color: Colors.black, // body 영역 배경색을 검은색으로 명시적 설정
          child: Column(
            children: [
              // 상단 제어 패널 - 통합 영역 및 뷰 선택
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // 통합 영역 및 뷰 선택 컨트롤
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // 영역 선택 텍스트 (왼쪽)
                              Text(
                                '영역 선택:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                              SizedBox(width: 8),
                              // 드롭다운 (오른쪽)
                              Expanded(
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedRegion,
                                    dropdownColor: Colors.grey[900],
                                    style: TextStyle(color: Colors.white),
                                    icon: Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                                    underline: Container(),
                                    items: regionOptions.map((region) {
                                      return DropdownMenuItem<String>(
                                        value: region,
                                        child: Text(region, style: TextStyle(fontSize: 14)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          selectedRegion = value;
                                        });
                                        _loadDataset1();
                                        _loadDataset2();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              // 뷰 선택 텍스트 (왼쪽)
                              Text(
                                '뷰 선택:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                              SizedBox(width: 8),
                              // 드롭다운 (오른쪽)
                              Expanded(
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedView,
                                    dropdownColor: Colors.grey[900],
                                    style: TextStyle(color: Colors.white),
                                    icon: Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                                    underline: Container(),
                                    items: viewOptions.map((view) {
                                      return DropdownMenuItem<String>(
                                        value: view,
                                        child: Text(view, style: TextStyle(fontSize: 14)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          selectedView = value;
                                        });
                                        _loadDataset1();
                                        _loadDataset2();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 이미지 영역
              Expanded(
                flex: 3, // 이미지 영역 비율
                child: Row(
                  children: [
                    // 왼쪽 패널
                    Expanded(
                      child: _buildAdvancedDatasetPanel(
                        isLoading: isLoading1,
                        errorMessage: errorMessage1,
                        selectedDate: selectedDate1,
                        datasetOptions: dataset1Options,
                        datasetKeypoints: dataset1Keypoints.cast<Map<String, dynamic>>(),
                        datasetImageBytes: dataset1ImageBytes,
                        datasetDate: dataset1Date,
                        datasetTime: dataset1Time,
                        onDateChanged: (date) {
                          setState(() {
                            selectedDate1 = date;
                          });
                          _loadDataset1();
                        },
                        onDatasetSelected: _selectDataset1,
                        isPanelOne: true,
                      ),
                    ),

                    // 오른쪽 패널
                    Expanded(
                      child: _buildAdvancedDatasetPanel(
                        isLoading: isLoading2,
                        errorMessage: errorMessage2,
                        selectedDate: selectedDate2,
                        datasetOptions: dataset2Options,
                        datasetKeypoints: dataset2Keypoints.cast<Map<String, dynamic>>(),
                        datasetImageBytes: dataset2ImageBytes,
                        datasetDate: dataset2Date,
                        datasetTime: dataset2Time,
                        onDateChanged: (date) {
                          setState(() {
                            selectedDate2 = date;
                          });
                          _loadDataset2();
                        },
                        onDatasetSelected: _selectDataset2,
                        isPanelOne: false,
                      ),
                    ),
                  ],
                ),
              ),

              // 하단 분석 항목 영역
              Expanded(
                flex: 2, // 리스트뷰 영역 비율
                child: Column(
                  children: [
                    // 분석 항목 헤더
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                    ),
                    // 분석 항목 리스트뷰 - 함수 이름 변경
                    Expanded(
                      child: _buildAnalysisListView(dataset1Keypoints),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 고급 확대/축소 기능이 있는 데이터셋 패널
  Widget _buildAdvancedDatasetPanel({
    required bool isLoading,
    required String? errorMessage,
    required String selectedDate,
    required List<Map<String, dynamic>> datasetOptions,
    required List<Map<String, dynamic>> datasetKeypoints,
    required Uint8List? datasetImageBytes,
    required String datasetDate,
    required String datasetTime,
    required Function(String) onDateChanged,
    required Function(Map<String, dynamic>) onDatasetSelected,
    required bool isPanelOne,
  }) {
    // 시간 선택 드롭다운의 현재 값 확인
    String? currentTimeValue;

    // datasetOptions에서 선택된 시간이 있는지 확인
    bool timeExists = datasetOptions.any((option) => option['timeString'] == datasetTime);
    if (timeExists && datasetTime.isNotEmpty) {
      currentTimeValue = datasetTime;
    } else {
      currentTimeValue = null;
    }

    // 중복된 시간이 있는지 확인
    final timeValues = datasetOptions.map((option) => option['timeString'] as String).toList();
    final uniqueTimeValues = timeValues.toSet().toList();
    bool hasDuplicateTimes = timeValues.length != uniqueTimeValues.length;

    // 중복된 시간이 있는 경우 documentId와 함께 표시
    List<DropdownMenuItem<String>> timeDropdownItems = [];
    if (hasDuplicateTimes) {
      // documentId를 조합하여 고유한 값 생성
      for (var option in datasetOptions) {
        final timeString = option['timeString'] as String;
        final docId = option['documentId'] as String;
        final uniqueValue = '$timeString|$docId'; // 고유 ID 생성

        timeDropdownItems.add(DropdownMenuItem<String>(
          value: uniqueValue,
          child: Text(timeString),
        ));
      }

      // 현재 선택된 값도 업데이트
      if (currentTimeValue != null) {
        final selectedDoc = datasetOptions.firstWhere(
                (option) => option['timeString'] == currentTimeValue,
            orElse: () => datasetOptions.first
        );
        currentTimeValue = '${currentTimeValue}|${selectedDoc['documentId']}';
      }
    } else {
      // 중복이 없는 경우 기본 방식으로 아이템 생성
      timeDropdownItems = datasetOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option['timeString'],
          child: Text(option['timeString']),
        );
      }).toList();
    }

    return Column(
      children: [
        // 데이터 표시 영역 (첫 번째로 배치) - 확대/축소 가능
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : errorMessage != null
              ? Center(child: Text(errorMessage!, style: TextStyle(color: Colors.red)))
              : (datasetImageBytes != null && datasetKeypoints.isNotEmpty)
              ? Container(
            // 이미지 박스 사이 거리
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade800),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: KeypointsViewer(
                imageBytes: datasetImageBytes!,
                keypoints: datasetKeypoints,
              ),
            ),
          )
              : Center(child: Text('이미지 또는 키포인트 데이터가 없습니다', style: TextStyle(color: Colors.white70))),
        ),

        // 날짜 및 시간 선택 컨트롤
        Padding(
          padding: const EdgeInsets.all(4.0), // 패딩 축소
          child: Row(
            children: [
              // 날짜 선택 (Flex 2로 변경)
              Expanded(
                flex: 2, // 2/3 비율로 차지하도록 설정
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: EdgeInsets.only(right: 8),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('날짜', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    value: availableDates.contains(selectedDate) ? selectedDate : null,
                    dropdownColor: Colors.grey[900],
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                    underline: Container(),
                    items: availableDates.map((date) {
                      return DropdownMenuItem<String>(
                        value: date,
                        child: Text(date, style: TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        print('선택된 날짜: $value');
                        onDateChanged(value);
                      }
                    },
                  ),
                ),
              ),

              // 시간대 선택 (Flex 1로 변경)
              Expanded(
                flex: 1, // 1/3 비율로 차지하도록 설정
                child: datasetOptions.isNotEmpty
                    ? Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('시간', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    value: currentTimeValue,
                    dropdownColor: Colors.grey[900],
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                    underline: Container(),
                    items: timeDropdownItems.map((item) {
                      return DropdownMenuItem<String>(
                        value: item.value,
                        child: Text(
                            item.child is Text ? (item.child as Text).data! : '',
                            style: TextStyle(fontSize: 13)
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        Map<String, dynamic> selectedData;

                        if (hasDuplicateTimes) {
                          // 값에서 시간과 문서 ID 분리
                          final parts = value.split('|');
                          final timeStr = parts[0];
                          final docId = parts.length > 1 ? parts[1] : '';

                          // 정확한 문서 찾기
                          selectedData = datasetOptions.firstWhere(
                                  (option) => option['timeString'] == timeStr && option['documentId'] == docId,
                              orElse: () => datasetOptions.first
                          );
                        } else {
                          // 시간으로만 검색
                          selectedData = datasetOptions.firstWhere(
                                  (option) => option['timeString'] == value,
                              orElse: () => datasetOptions.first
                          );
                        }

                        onDatasetSelected(selectedData);
                      }
                    },
                  ),
                )
                    : Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text('시간 데이터 없음', style: TextStyle(color: Colors.white60, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 분석 항목 리스트뷰 구성 함수
  Widget _buildAnalysisListView(List<dynamic> keypoints) {
    // 선택된 부위와 뷰에 맞는 분석 항목 가져오기
    final analysisItems = AnalysisItems.getItemsByRegionAndView(
        context,
        selectedRegion,
        selectedView.toLowerCase() == 'pa' ? 'ap' : selectedView.toLowerCase()
    );

    return Container(
      margin: EdgeInsets.all(4), // 마진 줄임
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: ClipRRect( // 자식 위젯을 경계내로 제한하는 클리핑 추가
        borderRadius: BorderRadius.circular(8),
        child: analysisItems.isNotEmpty
            ? ScrollConfiguration( // 스크롤 설정 추가
          behavior: ScrollConfiguration.of(context).copyWith(
            overscroll: false, // 오버스크롤 효과 제거
          ),
          child: ListView(
            padding: EdgeInsets.zero, // 패딩 제거
            children: analysisItems,
          ),
        )
            : Center(
          child: Text(
            '선택한 부위와 뷰에 대한 분석 항목이 없습니다',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      ),
    );
  }
}