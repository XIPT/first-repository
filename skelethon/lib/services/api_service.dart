import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

import '../utils/enums.dart';  // 📂 Enum 경로 확인!

class ApiService {
  // Base URL은 상수로 관리
  static const String baseUrl = 'https://72e3-210-90-73-240.ngrok-free.app';

  // 모델 엔드포인트 - 업로드 모드별로 다른 엔드포인트 사용
  static const String FULLBODY_MODEL_ENDPOINT = '/detect';
  static const String CROPPED_MODEL_ENDPOINT = '/detect/cropped';

  /// 1️⃣ YOLO Detection (AP / LA 구분 - Enum 사용)
  static Future<Map<String, dynamic>> uploadToDetect(
      Uint8List bytes,
      String filename,
      ViewType viewType,
      {String? endpointOverride}
      ) async {
    try {
      // 사용할 엔드포인트 결정 (기본값은 전신 모드)
      final endpoint = endpointOverride ?? FULLBODY_MODEL_ENDPOINT;

      // 파일 업로드를 위한 요청 데이터 생성
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint/${viewType.toApiString()}'),
      );

      // 파일 추가
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      // 요청 전송
      print('📫 호출 URL: ${request.url}');
      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        try {
          return jsonDecode(resBody);
        } catch (e) {
          print('❌ JSON 파싱 에러: $e');
          print('❌ 응답 내용: $resBody');
          throw Exception('응답 데이터 파싱 오류: $e');
        }
      } else {
        print('❌ Detection 실패: ${response.statusCode}');
        print('❌ 응답: $resBody');
        throw Exception('Detection 실패: ${response.statusCode} - $resBody');
      }
    } catch (e) {
      print('❌ 서버 에러: $e');
      throw Exception('서버 에러: $e');
    }
  }

  /// 🕹 Keypoints 분석 API 호출
  static Future<List<Map<String, dynamic>>> predictKeypoints({
    required String region,   // 예: 'cervical'
    required ViewType viewType,  // AP / LA 구분
    required Uint8List cropBytes,
    String? modelEndpoint,  // 모델 엔드포인트 추가 (전신/부위 모드에 따라 다른 엔드포인트 사용)
  }) async {
    // 사용할 엔드포인트 설정
    final endpointPath = modelEndpoint ?? '/keypoints';
    final url = Uri.parse('$baseUrl$endpointPath/$region/${viewType.toApiString()}');
    final base64Image = base64Encode(cropBytes);

    try {
      // 요청 정보 로깅
      print('🕹 Keypoints 분석 요청:');
      print('  - URL: $url');
      print('  - Headers: Content-Type: application/json');
      print('  - Base64 Image Length: ${base64Image.length}');

      // 요청 보내기
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image  // FastAPI의 PoseRequest.image와 매칭
        }),
      );

      // 응답 로깅
      print('🕹 서버 응답:');
      print('  - Status: ${response.statusCode}');
      print('  - Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['error'] != null) {
            throw Exception('서버 에러: ${data['error']}');
          }
          final keypoints = data['keypoints'] as List;
          print('  - Keypoints count: ${keypoints.length}');
          return keypoints.cast<Map<String, dynamic>>();
        } catch (e) {
          print('❌ JSON 파싱 에러: $e');
          throw Exception('응답 데이터 파싱 오류: $e');
        }
      } else {
        print('❌ Keypoints 분석 실패: ${response.statusCode}');
        throw Exception('Keypoints 분석 실패 (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('❌ 서버 통신 오류: $e');
      throw Exception('서버 통신 오류: $e');
    }
  }
}