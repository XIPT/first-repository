import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'hospital_recommend.dart'; // 추천 병원 리스트 import

class HospitalListView extends StatelessWidget {
  final List<dynamic> hospitals;
  final int? selectedIndex;
  final ScrollController? scrollController;
  final Function(int)? onHospitalTap;

  const HospitalListView({
    Key? key,
    required this.hospitals,
    this.selectedIndex,
    this.scrollController,
    this.onHospitalTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 추천 병원이 있으면 맨 위로 오도록 정렬
    final recommendIds = HospitalRecommendManager.getRecommendedIds();
    final recommendedHospitals = <dynamic>[];
    final otherHospitals = <dynamic>[];

    for (var hospital in hospitals) {
      if (recommendIds.contains(hospital['id'])) {
        hospital['is_recommended'] = true; // 추천 병원 표시 추가
        recommendedHospitals.add(hospital);
      } else {
        hospital['is_recommended'] = false; // 추천 병원 아님 표시 추가
        otherHospitals.add(hospital);
      }
    }

    // 추천 병원이 먼저, 그 외 병원이 뒤에 오도록 합침
    final sortedHospitals = [...recommendedHospitals, ...otherHospitals];

    return ListView.builder(
      controller: scrollController,
      itemCount: sortedHospitals.length,
      itemBuilder: (context, index) {
        final hospital = sortedHospitals[index];
        final bool isSelected = selectedIndex == index;
        final bool hasManualTherapy = hospital['has_manual_therapy'] == true;
        final bool isRecommended = hospital['is_recommended'] == true;

        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5
          ),
          child: Card(
            elevation: isSelected ? 8 : 2,
            color: isSelected ? Color(0xFF2A2A2A) : (
                isRecommended // 추천 병원은 특별한 배경색 사용
                    ? Color(0xFF22282E)
                    : Colors.grey[900]),
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? BorderSide(color: Colors.orange, width: 2)
                  : (isRecommended // 추천 병원은 테두리 표시
                  ? BorderSide(color: Colors.amber.withOpacity(0.5), width: 1)
                  : BorderSide.none),
            ),
            child: InkWell(
              onTap: () {
                if (onHospitalTap != null) {
                  onHospitalTap!(index);

                  // 선택 시 바텀시트 표시
                  _showHospitalDetailSheet(context, hospital);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.orange.withOpacity(0.2) :
                            (hasManualTherapy
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            hasManualTherapy ? Icons.medical_services : Icons
                                .local_hospital,
                            color: isSelected ? Colors.orange :
                            (hasManualTherapy ? Colors.green[400] : Colors
                                .blue[300]),
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      hospital['place_name'] ?? '병원 이름 없음',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.orange
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (isRecommended) // 추천 병원에만 라벨 표시
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '추천',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Text(
                                hospital['address_name'] ?? '주소 없음',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.orange.withOpacity(
                                    0.2) : Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(double.parse(hospital['distance']) / 1000)
                                    .toStringAsFixed(1)}km',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.orange : Colors
                                      .grey[300],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (hospital['phone'] != null &&
                        hospital['phone'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, left: 38),
                        child: Row(
                          children: [
                            Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey[500]
                            ),
                            SizedBox(width: 5),
                            Text(
                              hospital['phone'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// 바텀시트 표시 함수
  void _showHospitalDetailSheet(BuildContext context,
      Map<String, dynamic> hospital) {
    final bool hasManualTherapy = hospital['has_manual_therapy'] == true;
    final bool isRecommended = hospital['is_recommended'] ==
        true; // 추천 병원 여부 확인
    final hospitalName = hospital['place_name'] ?? '병원 정보';
    final hospitalAddress = hospital['address_name'] ?? '주소 정보 없음';
    final hospitalPhone = hospital['phone'] ?? '전화번호 정보 없음';
    final placeUrl = hospital['place_url'] ?? '';

    // WebViewController를 미리 초기화하여 상태를 유지
    final webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF2A2A2A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // 페이지 로딩 시작 시 처리할 내용
          },
          onPageFinished: (String url) {
            // 페이지 로딩 완료 시 처리할 내용
          },
          onWebResourceError: (WebResourceError error) {
            // 에러 발생 시 처리할 내용
            print('WebView 에러: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // 특정 URL은 앱에서 직접 처리하도록 설정
            if (request.url.startsWith('tel:') ||
                request.url.startsWith('sms:') ||
                request.url.startsWith('mailto:') ||
                request.url.startsWith('kakaomap:')) {
              launchUrl(Uri.parse(request.url));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..enableZoom(true)
      ..loadRequest(Uri.parse(placeUrl));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // DraggableScrollableController 선언
        final DraggableScrollableController dragController = DraggableScrollableController();

        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.2,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: [0.5, 0.95],
          controller: dragController, // 컨트롤러 연결
          builder: (_, scrollController) {
            // 시트가 최대 크기에 도달했는지 확인하기 위한 변수
            bool hasReachedMaxSize = false;

            // 드래그 컨트롤러에 리스너 추가
            dragController.addListener(() {
              try {
                // 현재 시트의 크기 확인
                final currentSize = dragController.size;

                // 현재 시트의 크기가 최대 크기에 매우 가까워졌을 때 (0.93 이상)
                if (currentSize >= 0.93 && !hasReachedMaxSize) {
                  hasReachedMaxSize = true;

                  // 약간의 지연 시간을 두고 전체 화면으로 전환
                  Future.delayed(Duration(milliseconds: 200), () {
                    // 컨텍스트가 유효한지 확인
                    if (Navigator.of(context).canPop()) {
                      Navigator.pop(context); // 바텀시트 닫기

                      // 전체 화면 WebView로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HospitalWebView(
                            title: hospitalName,
                            url: placeUrl,
                          ),
                        ),
                      );
                    }
                  });
                } else if (currentSize < 0.9) {
                  // 시트 크기가 줄어들면 플래그 리셋
                  hasReachedMaxSize = false;
                }
              } catch (e) {
                print('DraggableScrollableController 오류: $e');
              }
            });

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: CustomScrollView(
                controller: scrollController, // 스크롤 컨트롤러는 여기에 연결
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[800]!,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: 40),
                          Container(
                            width: 36,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.fullscreen, color: Colors.white, size: 22),
                            padding: EdgeInsets.all(4),
                            constraints: BoxConstraints(),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HospitalWebView(
                                    title: hospitalName,
                                    url: placeUrl,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    child: WebViewWidget(
                      controller: webViewController,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// 전체 화면 WebView 페이지
class HospitalWebView extends StatelessWidget {
  final String title;
  final String url;

  const HospitalWebView({Key? key, required this.title, required this.url})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFF2A2A2A))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {},
              onPageFinished: (String url) {},
              onWebResourceError: (WebResourceError error) {
                print('WebView 에러: ${error.description}');
              },
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith('tel:') ||
                    request.url.startsWith('sms:') ||
                    request.url.startsWith('mailto:') ||
                    request.url.startsWith('kakaomap:')) {
                  launchUrl(Uri.parse(request.url));
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..enableZoom(true)
          ..loadRequest(Uri.parse(url));

    return Scaffold(
      backgroundColor: const Color(0xFF2A2A2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebViewWidget(controller: webViewController),
    );
  }
}
