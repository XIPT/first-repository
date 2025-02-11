import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'camera.dart';

class RunningPage extends StatefulWidget {
  final Uint8List? imageData; // 로컬 이미지 데이터
  final String? imageUrl; // 웹 이미지 URL

  RunningPage({this.imageData, this.imageUrl});

  @override
  _RunningPageState createState() => _RunningPageState();
}

class _RunningPageState extends State<RunningPage> {
  Uint8List? _imageData; // 변경 가능한 로컬 이미지 변수
  String? _imageUrl; // 변경 가능한 웹 이미지 변수
  String _result = "분석 대기 중..."; // 분석 결과

  @override
  void initState() {
    super.initState();
    _imageData = widget.imageData;
    _imageUrl = widget.imageUrl;
  }

  // Gemini API 호출 함수
  Future<void> analyzeImageWithGemini(Uint8List imageBytes) async {
    String apiKey = "API키"; // Gemini API 키
    String apiUrl =
        'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent?key=$apiKey';

    setState(() {
      _result = "이미지 분석 중...";
    });

    try {
      var requestBody = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "이 사진은 x-ray의 어느 위치야"},
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Encode(imageBytes)
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,
          "topP": 1,
          "topK": 32,
          "maxOutputTokens": 2048
        },
      });

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        var responseJson = jsonDecode(response.body);
        String analysisResult =
        responseJson['candidates'][0]['content']['parts'][0]['text'];

        setState(() {
          _result = analysisResult;
        });
      } else {
        setState(() {
          _result = "API 오류: ${response.statusCode}, ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "네트워크 오류: $e";
      });
    }
  }

  // 이미지 분석을 위한 클릭 함수
  void _onImageClick() async {
    if (_imageData != null) {
      analyzeImageWithGemini(_imageData!);
    } else if (_imageUrl != null) {
      final response = await http.get(Uri.parse(_imageUrl!));
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        analyzeImageWithGemini(imageBytes);
      } else {
        setState(() {
          _result = "이미지 다운로드 실패: ${response.statusCode}";
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이미지를 선택해주세요.")),
      );
    }
  }

  // 카메라 화면으로 이동하는 함수
  Future<void> navigateToCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePictureScreen(
          imageData: _imageData, // 이미지 데이터 전달
          imageUrl: _imageUrl,   // 이미지 URL 전달
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result is Uint8List) {
          _imageData = result;
          _imageUrl = null; // 새 이미지가 들어오면 URL은 초기화
        } else if (result is String) {
          _imageUrl = result;
          _imageData = null; // 새 URL이 들어오면 로컬 이미지는 초기화
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('이미지 분석')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageData != null)
              GestureDetector(
                onTap: _onImageClick,
                child: Image.memory(
                  _imageData!,
                  fit: BoxFit.cover,
                ),
              )
            else if (_imageUrl != null)
              GestureDetector(
                onTap: _onImageClick,
                child: Image.network(
                  _imageUrl!,
                  width: 400,
                  height: 400,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 20),
            Text(_result, textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: navigateToCamera,
              child: Text('캡처'),
            ),
          ],
        ),
      ),
    );
  }
}
