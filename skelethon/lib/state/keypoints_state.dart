import 'package:flutter/material.dart';
import 'dart:typed_data';

class KeypointsState with ChangeNotifier {
  // ✅ 원본 keypoints (원본 이미지 기준 좌표)
  Map<String, Map<String, List<Map<String, dynamic>>>> originalKeypoints = {
    'cervical': {'AP': [], 'LA': []},
    'thoracic': {'AP': [], 'LA': []},
    'lumbar': {'AP': [], 'LA': []},
    'pelvic': {'AP': [], 'LA': []},
  };

  // ✅ overlayedKeypoints (화면용, 스케일된 좌표)
  Map<String, Map<String, List<Map<String, dynamic>>>> overlayedKeypoints = {
    'cervical': {'AP': [], 'LA': []},
    'thoracic': {'AP': [], 'LA': []},
    'lumbar': {'AP': [], 'LA': []},
    'pelvic': {'AP': [], 'LA': []},
  };

  // 원본 이미지 바이트 저장
  Map<String, Map<String, Uint8List?>> originalImages = {
    'cervical': {'AP': null, 'LA': null},
    'thoracic': {'AP': null, 'LA': null},
    'lumbar': {'AP': null, 'LA': null},
    'pelvic': {'AP': null, 'LA': null},
  };

  // overlay 이미지 바이트 저장
  Map<String, Map<String, Uint8List?>> overlayedImages = {
    'cervical': {'AP': null, 'LA': null},
    'thoracic': {'AP': null, 'LA': null},
    'lumbar': {'AP': null, 'LA': null},
    'pelvic': {'AP': null, 'LA': null},
  };

  String? currentImageId;

  // ✅ 원본 keypoints 저장
  void setOriginalKeypoints(String region, String view, List<Map<String, dynamic>> keypoints) {
    if (keypoints.isNotEmpty) {
      originalKeypoints[region]?[view] = keypoints;
    }
    notifyListeners();
  }

  // ✅ overlayedKeypoints 저장
  void setOverlayedKeypoints(String region, String view, List<Map<String, dynamic>> keypoints, {String? imageId}) {
    if (keypoints.isNotEmpty) {
      overlayedKeypoints[region]?[view] = keypoints;
    }
    currentImageId = imageId;
    notifyListeners();
  }

  // ✅ 원본 이미지 바이트 저장
  void setOriginalImage(String region, String view, Uint8List imageBytes) {
    originalImages[region]?[view] = imageBytes;
    notifyListeners();
  }


  // ✅ overlayed 이미지 저장
  void setOverlayedImage(String region, String view, Uint8List imageBytes) {
    overlayedImages[region]?[view] = imageBytes;
    notifyListeners();
  }


  // ✅ originalKeypoints 가져오기
  List<Map<String, dynamic>>? getOriginalKeypoints(String region, String view) {
    return originalKeypoints[region]?[view];
  }


  // ✅ overlayedKeypoints 가져오기
  List<Map<String, dynamic>>? getOverlayedKeypoints(String region, String view) {
    return overlayedKeypoints[region]?[view];
  }

  // ✅ 원본 이미지 가져오기
  Uint8List? getOriginalImage(String region, String view) {
    return originalImages[region]?[view];
  }

  // ✅ overlayed 이미지 가져오기
  Uint8List? getOverlayedImage(String region, String view) {
    return overlayedImages[region]?[view];
  }

  // 전체 초기화
  void clear() {
    for (var region in overlayedKeypoints.keys) {
      for (var view in overlayedKeypoints[region]!.keys) {
        originalImages[region]![view] = null;
        overlayedKeypoints[region]![view] = [];
        originalKeypoints[region]![view] = [];
        overlayedImages[region]![view] = null;
      }
    }
    currentImageId = null;
    notifyListeners();
  }
}
