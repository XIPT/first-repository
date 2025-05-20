import 'package:flutter/material.dart';
import '../utils/enums.dart'; // UploadMode enum을 사용하기 위해 import

class UserState extends ChangeNotifier {
  String? _userId;
  String? _address;
  UploadMode _analysisMode = UploadMode.fullBody; // 기본값으로 전신 모드 설정

  // 🔹 Getter
  String? get userId => _userId;
  String? get address => _address;
  UploadMode get analysisMode => _analysisMode; // 분석 모드 getter 추가

  // 🔹 로그인
  void login(String id) {
    _userId = id;
    notifyListeners();
  }

  // 🔹 로그아웃 (모든 정보 초기화)
  void logout() {
    _userId = null;
    _address = null;
    _analysisMode = UploadMode.fullBody; // 로그아웃 시 기본 모드로 초기화
    notifyListeners();
  }

  // 🔹 주소 설정
  void setAddress(String newAddress) {
    _address = newAddress;
    notifyListeners();
  }

  // 🔹 분석 모드 설정
  void setAnalysisMode(UploadMode mode) {
    _analysisMode = mode;
    notifyListeners();
  }

  // 🔹 분석 모드 토글
  void toggleAnalysisMode() {
    _analysisMode = _analysisMode == UploadMode.fullBody
        ? UploadMode.cropRegion
        : UploadMode.fullBody;
    notifyListeners();
  }

  // 🔹 필요 시 개별 초기화
  void clearAddress() {
    _address = null;
    notifyListeners();
  }
}