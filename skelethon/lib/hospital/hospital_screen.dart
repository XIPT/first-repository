import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../upload/edit_address.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart'; // rootBundle을 위한 import 추가

import '/state/user_state.dart';
import '/services/secrets.dart';

import '/hospital/hospital_listview.dart';
import '/hospital/hospital_recommend.dart';


class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreen();
}

class _HospitalScreen extends State<HospitalScreen> {
  List<dynamic> hospitals = [];
  bool isLoading = false;
  int? selectedHospitalIndex; // 선택된 병원 인덱스
  double? x;
  double? y;
  late final WebViewController _controller;   // ✅ 최신 방식으로 변경
  TextEditingController addressController = TextEditingController();

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // GPS 서비스 활성화 여부 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('GPS가 비활성화되어 있습니다.');
    }

    // 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('위치 권한이 영구적으로 거부되었습니다.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }


  @override
  void initState() {
    super.initState();

    // HTML 로드 및 API 키 삽입을 위한 코드 추가
    Future<void> loadMapWithApiKey() async {
      String html = await rootBundle.loadString('assets/kakao_map.html');

      // API 키 교체
      final String apiKeyScript = '<script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=854024e2c6bf06e3291045e9a94a3172"></script>';
      final String newApiKeyScript = '<script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=${Secrets.kakaoMapApiKey}"></script>';

      html = html.replaceAll(apiKeyScript, newApiKeyScript);

      // WebViewController 설정
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..addJavaScriptChannel(
          'onMarkerClicked',
          onMessageReceived: (JavaScriptMessage message) {
            // 마커 클릭 이벤트 처리
            final indexStr = message.message;
            final index = int.tryParse(indexStr);
            if (index != null && index >= 0 && index < hospitals.length) {
              setState(() {
                selectedHospitalIndex = index;
              });

              // 스크롤 위치 업데이트를 위해 Future.microtask 사용
              Future.microtask(() {
                _scrollToSelectedHospital();
              });
            }
          },
        )
        ..loadHtmlString(html); // 수정된 HTML을 로드
    }

    // 수정된 HTML 로드 함수 호출
    loadMapWithApiKey();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Position position = await _determinePosition();

      double lat = position.latitude;
      double lng = position.longitude;

      // 1️⃣ 지도 이동
      _controller.runJavaScript('moveToLocation(${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)});');

      // 2️⃣ 내 위치 마커 (최초 1회만 호출)
      _controller.runJavaScript('showUserLocation(${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)});');

      // 3️⃣ 병원 검색
      await searchNearbyHospitals(lat, lng);

      // 4️⃣ 주소 설정
      await setAddressFromGPS(position);
    });
  }

// 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();

// 선택된 병원으로 스크롤
  void _scrollToSelectedHospital() {
    if (selectedHospitalIndex != null) {
      // 리스트 아이템 높이 예상 (여기서는 임의로 120으로 설정)
      final itemHeight = 120.0;
      final screenHeight = MediaQuery.of(context).size.height;
      final scrollOffset = (selectedHospitalIndex! * itemHeight) - (screenHeight / 4);

      _scrollController.animateTo(
        scrollOffset > 0 ? scrollOffset : 0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    _scrollController.dispose(); // 스크롤 컨트롤러 해제
    super.dispose();
  }

// ✅ 초기 GPS 기반 병원 검색 + 도수치료 필터링
  Future<void> searchNearbyHospitals(double lat, double lng) async {
    setState(() => isLoading = true);
    try {
      print('🔍 [병원검색] 호출 좌표: lat=$lat, lng=$lng');

      // 1단계: 일반 병원 검색
      final hospitalUrl = Uri.parse(
          'https://dapi.kakao.com/v2/local/search/category.json'
              '?category_group_code=HP8'
              '&x=$lng&y=$lat&radius=5000&sort=distance'
      );

      print('🔗 [병원검색] 요청 URL: $hospitalUrl');

      final res = await http.get(
        hospitalUrl,
        headers: {
          'Authorization': 'KakaoAK ${Secrets.kakaoRestApiKey}',
          'KA': 'sdk/1.0.0 os/android lang/ko'
        },
      );

      print('📨 [병원검색] 응답 코드: ${res.statusCode}');

      if (res.statusCode != 200) {
        print('❌ 병원 검색 실패');
        setState(() {
          hospitals = [];
          selectedHospitalIndex = null; // 선택 초기화
        });
        return;
      }

      final data = json.decode(res.body);
      List<dynamic> allHospitals = data['documents'];

      // 2단계: 도수치료 키워드로 추가 검색
      final manualTherapyUrl = Uri.parse(
          'https://dapi.kakao.com/v2/local/search/keyword.json'
              '?query=도수치료'
              '&x=$lng&y=$lat&radius=5000&sort=distance'
      );

      final manualRes = await http.get(
        manualTherapyUrl,
        headers: {
          'Authorization': 'KakaoAK ${Secrets.kakaoRestApiKey}',
          'KA': 'sdk/1.0.0 os/android lang/ko'
        },
      );

      if (manualRes.statusCode == 200) {
        final manualData = json.decode(manualRes.body);
        List<dynamic> manualTherapyPlaces = manualData['documents'];

        // 도수치료 검색 결과 중 병원(HP8)만 필터링
        List<dynamic> manualTherapyHospitals = manualTherapyPlaces
            .where((place) => place['category_group_code'] == 'HP8')
            .toList();

        // 3단계: 두 검색 결과 병합 (병원ID 기준으로 중복 제거)
        Set<String> hospitalIds = {}; // 중복 체크용 Set
        List<dynamic> combinedHospitals = [];

        // 먼저 도수치료 키워드로 검색된 병원들에 태그 추가
        for (var hospital in manualTherapyHospitals) {
          hospital['has_manual_therapy'] = true; // 도수치료 제공 표시
          hospitalIds.add(hospital['id']);
          combinedHospitals.add(hospital);
        }

        // 일반 병원 검색 결과 중 중복되지 않는 것들 추가
        for (var hospital in allHospitals) {
          if (!hospitalIds.contains(hospital['id'])) {
            hospital['has_manual_therapy'] = false; // 도수치료 미제공 표시
            hospitalIds.add(hospital['id']);
            combinedHospitals.add(hospital);
          }
        }

        // 4단계: 도수치료 제공 병원만 필터링 (옵션)
        List<dynamic> filteredHospitals = combinedHospitals
            .where((hospital) => hospital['has_manual_therapy'] == true)
            .toList();

        // 여기에 추천 병원 목록 업데이트 코드 추가
        HospitalRecommendManager.updateRecommendedHospitalsFromList(filteredHospitals);

        setState(() {
          // 도수치료 제공 병원만 표시하려면:
          hospitals = filteredHospitals;

          // 또는 모든 병원을 표시하되 도수치료 제공 여부를 표시하려면:
          // hospitals = combinedHospitals;

          selectedHospitalIndex = null; // 검색 결과가 바뀌면 선택 초기화
        });
      } else {
        // 도수치료 검색에 실패하면 일반 병원 결과만 사용
        setState(() {
          hospitals = allHospitals;
          selectedHospitalIndex = null;
        });
      }

      print('🏥 [병원검색] 찾은 병원 수: ${hospitals.length}');
      print('🏥 [병원검색] 도수치료 가능 병원 수: ${hospitals.where((h) => h['has_manual_therapy'] == true).length}');

      // 여기에 추천 병원 정렬 코드를 넣으세요
      final recommendIds = HospitalRecommendManager.getRecommendedIds();
      final recommendedHospitals = <dynamic>[];
      final otherHospitals = <dynamic>[];

      for (var hospital in hospitals) {
        if (recommendIds.contains(hospital['id'])) {
          hospital['is_recommended'] = true;
          recommendedHospitals.add(hospital);
        } else {
          hospital['is_recommended'] = false;
          otherHospitals.add(hospital);
        }
      }

      // 추천 병원이 먼저, 그 외 병원이 뒤에 오도록 합침
      final sortedHospitals = [...recommendedHospitals, ...otherHospitals];
      hospitals = sortedHospitals;

      // ✅ 병원 리스트 받아온 직후, 마커 찍기 호출!
      final markerData = sortedHospitals.map((h) {
        return {
          'name': h['place_name'],
          'lat': double.parse(h['y']),   // 위도
          'lng': double.parse(h['x']),   // 경도
          'address': h['address_name'],  // 주소
          'phone': h['phone'],           // 전화번호
          'place_url': h['place_url'],   // 장소 URL
          'distance': h['distance'],     // 거리 추가
          'has_manual_therapy': h['has_manual_therapy'] ?? false, // 도수치료 가능 여부
          'is_recommended': h['is_recommended'] ?? false, // 추천 병원 여부 추가
        };
      }).toList();

      final jsonMarkers = jsonEncode(markerData);

      // JS 함수 호출 (마커 찍기)
      _controller.runJavaScript('addHospitalMarkers(\'$jsonMarkers\')');

      setState(() {
        hospitals = sortedHospitals;
        selectedHospitalIndex = null;
      });

    } catch (e) {
      print('🔥 [병원검색] 에러 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러가 발생했습니다. 다시 시도해주세요!')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // GPS 세팅
  Future<void> setAddressFromGPS(Position position) async {
    final lat = position.latitude;
    final lng = position.longitude;

    final geoUrl = Uri.parse(
        'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lng&y=$lat');

    final res = await http.get(
      geoUrl,
      headers: {
        'Authorization': 'KakaoAK ${Secrets.kakaoRestApiKey}',
      },
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final docs = data['documents'];

      if (docs.isNotEmpty) {
        final addressName = docs[0]['address']['address_name'];
        context.read<UserState>().setAddress(addressName);  // 📍 주소 저장
      }
    } else {
      print('❌ 역지오코딩 실패: ${res.statusCode}');
    }
  }

  // 주소검색 기반 병원서치
  Future<void> searchNearbyHospitalsByAddress(String address) async {
    setState(() => isLoading = true);
    try {
      final encoded = Uri.encodeComponent(address);

      // analyze_type=similar 파라미터 추가
      final geoUrl = Uri.parse('https://dapi.kakao.com/v2/local/search/address.json?query=$encoded&analyze_type=similar');

      final geoRes = await http.get(
        geoUrl,
        headers: {
          'Authorization': 'KakaoAK ${Secrets.kakaoRestApiKey}',
          'KA': 'sdk/1.0.0 os/android lang/ko'
        },
      );

      if (geoRes.statusCode != 200) {
        print('❌ 주소 검색 실패: ${geoRes.statusCode} / ${geoRes.body}');

        // 주소 검색 실패 시 키워드 검색으로 폴백
        await searchNearbyHospitalsByKeyword(address);
        return;
      }

      final geoData = json.decode(geoRes.body);
      final docs = geoData['documents'];
      if (docs.isEmpty) {
        print('⚠️ 주소 검색 결과 없음, 키워드 검색으로 시도');

        // 주소 검색 결과가 없을 때 키워드 검색으로 폴백
        await searchNearbyHospitalsByKeyword(address);
        return;
      }

      final location = docs[0];
      double lng = double.parse(location['x']);
      double lat = double.parse(location['y']);

      // ✅ 검색된 주소 정보 출력
      print('📍 검색된 주소: ${location['address_name']}');

      // ✅ 지도 이동
      _controller.runJavaScript('moveToLocation(${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)});');

      // ✅ 병원 검색
      await searchNearbyHospitals(lat, lng);

      // 검색 완료 후 사용자에게 피드백
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${location['address_name']} 주변 병원을 검색합니다')),
      );

    } catch (e) {
      print('에러 발생: $e');
      setState(() => hospitals = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

// 키워드 검색 폴백 함수 추가
  Future<void> searchNearbyHospitalsByKeyword(String keyword) async {
    try {
      print('🔍 키워드로 검색 시도: $keyword');

      final encodedKeyword = Uri.encodeComponent(keyword);
      final keywordUrl = Uri.parse('https://dapi.kakao.com/v2/local/search/keyword.json?query=$encodedKeyword&analyze_type=similar');

      final keywordRes = await http.get(
        keywordUrl,
        headers: {
          'Authorization': 'KakaoAK ${Secrets.kakaoRestApiKey}',
          'KA': 'sdk/1.0.0 os/android lang/ko'
        },
      );

      if (keywordRes.statusCode != 200) {
        print('❌ 키워드 검색 실패: ${keywordRes.statusCode}');
        setState(() => hospitals = []);
        return;
      }

      final keywordData = json.decode(keywordRes.body);
      final keywordDocs = keywordData['documents'];

      if (keywordDocs.isEmpty) {
        print('⚠️ 키워드 검색 결과 없음');
        setState(() => hospitals = []);

        // 사용자에게 검색 결과 없음 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 결과가 없습니다. 다른 검색어를 입력해보세요.')),
        );
        return;
      }

      final place = keywordDocs[0];
      double lng = double.parse(place['x']);
      double lat = double.parse(place['y']);

      print('📍 키워드 검색 결과: ${place['place_name']} (${place['address_name']})');

      // ✅ 지도 이동
      _controller.runJavaScript('moveToLocation(${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)});');

      // ✅ 병원 검색
      await searchNearbyHospitals(lat, lng);

      // 검색 완료 후 사용자에게 피드백
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${place['place_name']} 주변 병원을 검색합니다')),
      );

    } catch (e) {
      print('키워드 검색 에러 발생: $e');
      setState(() => hospitals = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = context.watch<UserState>().address ?? '위치 없음';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('주변 병원 찾기', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 여기가 지도 영역
          SizedBox(
            height: 300,
            child: WebViewWidget(controller: _controller),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '현재위치: ',
                          style: const TextStyle(
                            color: Colors.orange,  // 현재위치 글자만 주황색으로
                            fontWeight: FontWeight.bold,  // 굵게 표시
                          ),
                        ),
                        TextSpan(
                          text: '${context.watch<UserState>().address ?? '위치 확인 중...'}',
                          style: const TextStyle(
                            color: Colors.white,  // 주소 부분은 흰색 유지
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => EditAddressDialog(
                        currentAddress: context.read<UserState>().address ?? "",  // UserState에서 주소 가져오기
                      ),
                    );

                    if (result != null && result.trim().isNotEmpty) {
                      addressController.text = result.trim();
                      context.read<UserState>().setAddress(result.trim());

                      // ✅ 주소 기반 검색 함수 호출
                      searchNearbyHospitalsByAddress(result.trim());
                    }
                  },
                  icon: Icon(
                    Icons.location_on,
                    color: Color(0xFFFF8C00),  // 이미지와 비슷한 주황색
                    size: 18,  // 아이콘 크기를 약간 줄여 더 세련되게
                  ),
                  label: Text(
                    '위치찾기',
                    style: TextStyle(
                      color: Color(0xFFFF8C00),  // 텍스트도 같은 주황색
                      fontWeight: FontWeight.w500,  // 약간 굵게
                      fontSize: 14,  // 이미지처럼 작은 글씨
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A1A1A),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),  // 이미지처럼 많이 둥근 모서리
                    ),
                    elevation: 0,  // 그림자 제거하여 플랫한 디자인
                    shadowColor: Colors.transparent,  // 그림자 색상 투명하게
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hospitals.isEmpty
                ? const Center(child: Text('주변 병원이 없습니다.', style: TextStyle(color: Colors.white)))
                : HospitalListView(
              hospitals: hospitals,
              selectedIndex: selectedHospitalIndex,
              scrollController: _scrollController,
              onHospitalTap: (index) {
                setState(() {
                  selectedHospitalIndex = index;
                });
                // 지도의 해당 위치로 이동하고 마커 강조 표시
                // moveToHospital 내부에서 자동으로 정보창을 표시하므로
                // showMarkerInfo 호출은 제거합니다
                _controller.runJavaScript('moveToHospital($index)');
              },
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) {
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
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Hospital'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Myinfo'),
        ],
      ),
    );
  }
}