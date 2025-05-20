import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; //✅provider를 쓰기 위해서
import 'state/user_state.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isButtonPressed = false;
  bool _isGoogleButtonPressed = false;

  // 일반 로그인 (원래 방식)
  void _login(BuildContext context) {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email == 'skelethon' && password == '1234') {
      // ✅ Provider로 userId 저장
      Provider.of<UserState>(context, listen: false).login(email);

      // ✅ 이후 페이지로 이동
      context.go('/agree');
    } else {
      _showMessage(context, '로그인 실패');
    }
  }

  // Google 로그인 함수 수정
  void _googleLogin(BuildContext context) async {
    try {
      // ✅ 0. GoogleSignIn 인스턴스를 명시적으로 생성
      final googleSignIn = GoogleSignIn(
        scopes: ['email'],
        signInOption: SignInOption.standard,
        forceCodeForRefreshToken: true,
      );

      // ✅ 1. 이전 로그인 세션 강제 로그아웃 → 계정 선택창 유도
      await googleSignIn.signOut();

      // ✅ 2. 계정 선택 창 띄우기
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _showMessage(context, '로그인 취소됨');
        return;
      }

      // ✅ 3. 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ✅ 4. Firebase 인증
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 토큰이 완전히 설정될 때까지 짧은 지연 추가
      await Future.delayed(Duration(milliseconds: 500));

      final user = userCredential.user!;
      print('✅ Google 로그인 성공: ${user.email}');

      // ✅ 5. Firestore에 유저 정보 저장 (컬렉션 이름 users로 변경 및 오류 처리 추가)
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': user.displayName,
          'photoUrl': user.photoURL,
          'lastLogin': FieldValue.serverTimestamp(), // 마지막 로그인 시간 추가
        });
        print('✅ 사용자 정보 Firestore에 저장 완료');
      } catch (e) {
        print('⚠️ Firestore 저장 오류: $e');
        if (e is FirebaseException) {
          print('⚠️ 코드: ${e.code}, 메시지: ${e.message}');
        }
        // 사용자에게 알림하지만 로그인 프로세스는 계속 진행
        _showMessage(context, '프로필 정보 저장 중 오류가 발생했지만 로그인은 성공했습니다');
      }

      // ✅ 6. Provider 상태 반영 및 이동
      Provider.of<UserState>(context, listen: false).login(user.email ?? '');
      context.go('/agree');

    } catch (e) {
      print('❌ Google 로그인 실패: $e');
      if (e is FirebaseAuthException) {
        print('❌ 인증 오류 코드: ${e.code}, 메시지: ${e.message}');
      }
      _showMessage(context, 'Google 로그인 실패: $e');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 앱바는 제거하여 배경 이미지가 전체화면에 보이도록 함
      body: Stack(
        children: [
          // 배경 이미지와 어둡게 처리된 ColorFilter 적용
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/main.gif'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7), // 어둡게 처리
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          // 중앙에 로그인 박스 배치 (가로 길이는 전체 화면의 40%)
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 상호명 추가
                  Text(
                    'Auto x-line',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 15.0),
                  // 아이디 입력 필드
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: '아이디',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  // 비밀번호 입력 필드
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      labelStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 18.0),
                  // 일반 로그인 버튼
                  // 일반 로그인 버튼
                  GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _isButtonPressed = true;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        _isButtonPressed = false;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isButtonPressed = false;
                      });
                      _login(context); // 일반 로그인 호출
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12.0), // 18px 높이로 조정
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isButtonPressed ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(5.0),
                        boxShadow: _isButtonPressed
                            ? []
                            : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          )
                        ],
                      ),
                      child: Text(
                        '로그인',
                        style: TextStyle(
                          color: _isButtonPressed ? Colors.white : Colors.black,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15.0),
// 구분선
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 10.0),
                          height: 1.0,
                          color: Colors.white30,
                        ),
                      ),
                      Text(
                        '또는',
                        style: TextStyle(color: Colors.white70, fontSize: 12.0),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 10.0),
                          height: 1.0,
                          color: Colors.white30,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15.0),
// Google 로그인 버튼
                  GestureDetector(
                      onTapDown: (_) {
                        setState(() {
                          _isGoogleButtonPressed = true;
                        });
                      },
                      onTapCancel: () {
                        setState(() {
                          _isGoogleButtonPressed = false;
                        });
                      },
                      onTapUp: (_) {
                        setState(() {
                          _isGoogleButtonPressed = false;
                        });

                        // 기존 호출을 try-catch 블록으로 감싸기
                        try {
                          _googleLogin(context);
                        } catch (e, stackTrace) {
                          print('❌ 자세한 오류: $e');
                          print('❌ 스택 트레이스: $stackTrace');
                          _showMessage(context, 'Google 로그인 실패: $e');
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12.0), // 18px 높이로 일반 로그인과 동일하게 맞춤
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isGoogleButtonPressed ? Colors.black : Colors.white, // 일반 로그인과 동일한 색상 변화
                          borderRadius: BorderRadius.circular(5.0),
                          boxShadow: _isGoogleButtonPressed
                              ? []
                              : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google 로고 표현 (눌렀을 때 색상 변경)
                            Container(
                              width: 18.0,
                              height: 18.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300, width: 0.5),
                              ),
                              child: Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: _isGoogleButtonPressed
                                        ? Colors.white  // 누를 때 색상 변경
                                        : Color(0xFF4285F4), // 기본 Google 파란색
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.0),
                            Text(
                              'Google계정 로그인',
                              style: TextStyle(
                                color: _isGoogleButtonPressed ? Colors.white : Colors.black87, // 누를 때 색상 변경
                                fontSize: 14.0, // 일반 로그인과 동일한 폰트 크기
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      )
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}