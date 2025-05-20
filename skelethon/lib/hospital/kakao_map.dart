import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KakaoMap extends StatefulWidget {
  final double x; // 경도
  final double y; // 위도
  const KakaoMap({super.key, required this.x, required this.y});

  @override
  State<KakaoMap> createState() => _KakaoMapState();
}

class _KakaoMapState extends State<KakaoMap> {
  late final WebViewController _controller;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    // HTML 로드
    final String html = await rootBundle.loadString('assets/web/kakao_map.html');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // 페이지 로드 완료 후 현재 위치로 지도 이동 및 마커 표시
            _moveToInitialLocation();
          },
        ),
      )
      ..loadHtmlString(html);
  }

  // 초기 위치 설정 (페이지 로드 후 호출)
  Future<void> _moveToInitialLocation() async {
    await _controller.runJavaScript(
        'moveToLocation(${widget.y}, ${widget.x});'
    );
    setState(() {
      _isMapReady = true;
    });
  }

  // 현재 위치로 다시 이동하는 함수 (버튼 클릭 시 호출)
  void _moveToCurrentLocation() {
    if (_isMapReady) {
      _controller.runJavaScript('moveToCurrentLocation();');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 전체 화면을 차지하는 WebView (맨 아래 레이어)
        WebViewWidget(controller: _controller),

        // 우측 하단에 GPS 버튼 배치 (맨 위 레이어)
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: "locationButton",
            onPressed: _moveToCurrentLocation,
            backgroundColor: Colors.white,
            mini: true,
            child: Icon(
              Icons.my_location,
              color: Colors.blue[700],
            ),
          ),
        ),
      ],
    );
  }
}