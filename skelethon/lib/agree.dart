import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; //✅provider를 쓰기 위해서

import '../state/user_state.dart';

class AgreeScreen extends StatelessWidget {
  const AgreeScreen({super.key});

  // 약관 내용 부분만 별도 변수로 분리
  final String agreementContent = '''
1. 본 서비스는 건강 관련 X-ray 분석을 돕기 위한 목적으로 제공될뿐 진단의 용도가 아님을 밝힙니다.
2. 본인의 X-ray만을 사용할것을 원칙으로 하고 다른사람의 것을 무단으로 사용하면 불이익이 있을수 있습니다.
3. 입력된 정보는 안전하게 처리되고 개인정보를 저장하지 않습니다.
4. 이 서비스는 정부의 허가를 받아 법률적으로 문제없이 운영됩니다.
5. 서비스를 이용하기 위해선 병원에서 캡쳐된 그림파일(jpg,jpeg,png 파일 등)이 필요합니다.
6. 정면(AP VIEW)사진과 옆면(LA VIEW)사진이 요구되고 이것은 제품의 성능을 개선하기 위한 자료로 쓰일수 있습니다.
''';

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserState>(context).userId ?? 'unknown';
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/main.gif'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              margin: EdgeInsets.all(16.0),
              padding: EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 약관 제목 - 중앙 정렬 및 크게 표시
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              '[Auto X-line약관]',
                              style: TextStyle(
                                fontSize: 18,  // 더 큰 글씨 크기
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,  // 강조를 위한 색상 변경
                              ),
                              textAlign: TextAlign.center,  // 가운데 정렬
                            ),
                          ),
                          // 약관 내용
                          Text(
                            agreementContent,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 저장 버튼 (심플 스타일)
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('동의하셨습니다')),
                          );
                          Future.delayed(Duration(seconds: 1), () {
                            context.go('/home_screen');
                          });
                        },
                        child: Text(
                          '동의',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.orange,  // 저장 버튼
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                      // 취소 버튼 (심플 스타일)
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('동의하지 않으셨습니다')),
                          );
                          Future.delayed(Duration(seconds: 1), () {
                            context.go('/');
                          });
                        },
                        child: Text(
                          '동의 안 함',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}