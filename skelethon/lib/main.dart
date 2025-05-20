import 'package:flutter/foundation.dart'; // kIsWeb 위해 필요

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; //✅provider를 쓰기 위해서

import 'dart:convert';
import 'dart:typed_data';

import 'state/xray_state.dart';
import 'state/user_state.dart';
import 'state/analysis_state.dart';
import 'state/xray_crop_state.dart';
import 'state/keypoints_state.dart';
import 'state/measurement_state.dart';

import 'login.dart';
import 'agree.dart';

import 'home/home_screen.dart';

import 'home/manualtherapy.dart';
import 'home/insuranceinfo.dart';
import 'home/academyinfo.dart';

import 'analysis/cervical/cervical.dart';

import 'analysis/thoracic/thoracic.dart';
import 'analysis/lumbar/lumbar.dart';
import 'analysis/pelvic/pelvic.dart';

import 'hospital/hospital_screen.dart';

import 'myinfo/myinfo_screen.dart';
import 'myinfo/myinformation.dart';
import 'myinfo/save_cervical.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart'; // 이 줄 추가




void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 순서 명시
  final app = await Firebase.initializeApp();
  print('🔥 Firebase 앱 초기화: ${app.name}');

  // 각 서비스 개별 초기화 (명시적)
  final auth = FirebaseAuth.instance;
  print('🔐 Auth 초기화 완료');

  final firestore = FirebaseFirestore.instance;
  print('📑 Firestore 초기화 완료');

  // Firebase Storage 초기화 추가
  final storage = FirebaseStorage.instance;
  print('📁 Storage 초기화 완료: ${storage.bucket}');

  // 테스트 함수 호출 (선택 사항)
  await testFirebaseStorage();


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => XrayState()),
        ChangeNotifierProvider(create: (_) => UserState()),
        ChangeNotifierProvider(create: (_) => AnalysisState()),
        ChangeNotifierProvider(create: (_) => XrayCropState()),
        ChangeNotifierProvider(create: (_) => KeypointsState()),
        ChangeNotifierProvider(create: (_) => MeasurementState()),
      ],
      child: MyApp(),
    ),
  );
}

// Firebase Storage 간단 테스트 함수
Future<void> testFirebaseStorage() async {
  try {
    // 간단한 텍스트 파일 생성
    final bytes = utf8.encode('Hello, Firebase Storage!');
    final data = Uint8List.fromList(bytes);

    // 루트 경로에 직접 저장 시도
    final ref = FirebaseStorage.instance.ref().child('test.txt');

    print('📁 업로드 시작...');
    await ref.putData(data);
    print('✅ 업로드 성공!');

    final url = await ref.getDownloadURL();
    print('🔗 다운로드 URL: $url');
  } catch (e) {
    print('❌ 테스트 실패: $e');
    if (e is FirebaseException) {
      print('❌ 코드: ${e.code}, 메시지: ${e.message}');
    }
  }
}

// 로그인 여부를 저장하는 간단한 전역 변수
bool isLoggedIn = false;

final GoRouter _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authState = Provider.of<UserState>(context, listen: false);
    if (authState.userId == null && state.uri.path != '/') {
      return '/';
    }
    return null;
  },

//✅GoRouter 정의 및 경로 설정
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => LoginScreen(),
    ),
    // 동의서 화면으로 전환 (예: /skelethon/agree)
    GoRoute(
      path: '/agree',
      builder: (context, state) => const AgreeScreen(),
    ),


    // ✅home_screen으로 화면전달
    GoRoute(
      path: '/home_screen',
      builder: (context, state) {
        final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
        return HomeScreen(); // 유저 ID 전달
      },
    ),
    // ✅manualtherapy로 화면전달
    GoRoute(
      path: '/manualtherapy',
      builder: (context, state) {
        final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
        return ManualTherapyScreen();
      },
    ),
    // ✅insuranceinfo 화면전달
    GoRoute(
      path: '/insuranceinfo',
      builder: (context, state) {
        final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
        return InsuranceScreen();
      },
    ),
    // ✅academyinfo로 화면전달
    GoRoute(
      path: '/academyinfo',
      builder: (context, state) {
        final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
        return AcademyInfoScreen();
      },
    ),


    //✅ analysis에서 각 부위별(목,등,허리,골반 등등)으로 연결할때 각각의 Route로 연결
    //✅ 목으로 연결되는 route
    GoRoute(
      path: '/analysis/cervical',
      builder: (context, state) {
        final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
        return CervicalPage();
      },
    ),

    // //✅목에서 분석으로 연결되는 route
    // //거북목 분석 route
    // GoRoute(
    //   path: '/analysis/cervical/forward-head',
    //   builder: (context, state) {
    //     final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
    //     return ForwardHeadPage();
    //   },
    // ),
    // // 목 각도 분석 route
    // GoRoute(
    //   path: '/analysis/cervical/cervical-angle',
    //   builder: (context, state) {
    //     final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
    //     return CervicalAngle();
    //   },
    // ),
    // //목디스크 거리 분석 route
    // GoRoute(
    //   path: '/analysis/cervical/cervical-disk',
    //   builder: (context, state) {
    //     final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
    //     return CervicalDiscPage();
    //   },
    // ),


    //✅등으로 연결되는 route
    GoRoute(
      path: '/analysis/thoracic',
      builder: (context, state) {
        final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
        return ThoracicPage();
      },
    ),
    //✅허리로 연결되는 route
    GoRoute(
      path: '/analysis/lumbar',
      builder: (context, state) {
        final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
        return LumbarPage();
      },
    ),
    //✅골반으로 연결되는 route
    GoRoute(
      path: '/analysis/pelvic',
      builder: (context, state) {
        final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
        return PelvicPage();
      },
    ),

    // ✅hospital 화면 연결
    GoRoute(
      path: '/hospital_screen',
      builder: (context, state) {
        final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
        return HospitalScreen();
      },
    ),


    // ✅myinfo_screen으로 화면전달
    GoRoute(
      path: '/myinfo_screen',
      builder: (context, state) {
        final userId = Provider.of<UserState>(context, listen: false).userId ?? 'unknown';
        return MyinfoScreen(); // 유저 ID 전달
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: kIsWeb ? '웹용 X-ray 분석' : '모바일용 X-ray 분석',
      debugShowCheckedModeBanner: false,
    );
  }
}