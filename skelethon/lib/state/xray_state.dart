import 'dart:typed_data';
import 'package:flutter/material.dart';

class XrayState extends ChangeNotifier {
  Uint8List? _apFileBytes;
  Uint8List? _laFileBytes;

  String? _apFileName;
  String? _laFileName;

  // 업로드 모드 상태 추가
  String? _apUploadMode;
  String? _laUploadMode;

  // AP 파일 getter, setter
  Uint8List? get apFileBytes => _apFileBytes;
  String? get apFileName => _apFileName;
  String? get apUploadMode => _apUploadMode;

  void setApFile(Uint8List bytes, String name, [String? uploadMode]) {
    _apFileBytes = bytes;
    _apFileName = name;
    _apUploadMode = uploadMode;
    notifyListeners();
  }

  // LA 파일 getter, setter
  Uint8List? get laFileBytes => _laFileBytes;
  String? get laFileName => _laFileName;
  String? get laUploadMode => _laUploadMode;

  void setLaFile(Uint8List bytes, String name, [String? uploadMode]) {
    _laFileBytes = bytes;
    _laFileName = name;
    _laUploadMode = uploadMode;
    notifyListeners();
  }

  // 모든 데이터 초기화
  void clearAll() {
    _apFileBytes = null;
    _laFileBytes = null;
    _apFileName = null;
    _laFileName = null;
    _apUploadMode = null;
    _laUploadMode = null;
    notifyListeners();
  }
}