import 'package:flutter/material.dart';
import 'Running.dart';

class URLPage extends StatelessWidget {
  final String url;

  URLPage({required this.url});

  // 이미지 클릭 처리 함수
  // 이미지 클릭 처리 함수
  void _handleImageClick(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("이미지를 클릭하시면 분석에 들어갑니다. 시간이 조금 걸릴수 있습니다.")),
    );

    // 이미지를 RunningPage로 전달하고 분석을 시작하는 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunningPage(imageUrl: url),  // URL 전달
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('URL에서 이미지 불러오기')),
      body: Center(
        child: GestureDetector(
          onTap: () => _handleImageClick(context),  // 이미지를 클릭했을 때 실행할 함수
          child: Image.network(
            url,  // URL로 이미지를 불러옴
            width: 400,  // 원하는 크기 설정
            height: 400,
            fit: BoxFit.cover,  // 이미지가 잘리거나 비율 맞게 보이도록 설정
          ),
        ),
      ),
    );
  }
}
