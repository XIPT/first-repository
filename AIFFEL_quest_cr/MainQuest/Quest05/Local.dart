import 'package:flutter/material.dart';
import 'dart:html' as html; // 웹에서 파일을 처리하기 위한 패키지
import 'dart:typed_data';  // Uint8List 타입을 사용하기 위한 패키지
import 'dart:convert';  // base64 인코딩을 위한 패키지
import 'package:http/http.dart' as http; // HTTP 요청용
import 'Running.dart'; // Running.dart 파일을 import

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImagePickerScreen(),
    );
  }
}

class ImagePickerScreen extends StatefulWidget {
  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  Uint8List? _imageData;  // 선택한 이미지 데이터를 저장할 변수
  String _responseText = "분석 중...";  // API 응답 결과를 표시할 변수

  // 파일을 선택하고 처리하는 함수
  Future<void> _pickImage() async {
    // 파일 선택 다이얼로그 열기
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';  // 이미지 파일만 선택 가능
    uploadInput.click();  // 다이얼로그 열기

    // 파일을 선택한 후 처리
    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      // 파일을 읽어서 이미지로 변환
      final reader = html.FileReader();
      reader.readAsArrayBuffer(files[0] as html.File);  // 파일을 ArrayBuffer로 읽기
      reader.onLoadEnd.listen((e) {
        // 이미지 데이터가 로드되었으면 상태를 갱신
        setState(() {
          _imageData = reader.result as Uint8List?;
        });
      });
    });
  }

  // 이미지를 클릭하면 실행되는 함수
  void _handleImageClick(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("이미지를 클릭하시면 분석에 들어갑니다. 시간이 조금 걸릴수 있습니다.")),
    );
    if (_imageData != null) {
      // 이미지를 클릭하면 RunningPage로 이동하고 이미지를 전달
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RunningPage(imageData: _imageData!),  // URL 전달
        ),
      );
    } else {
      // 이미지가 없으면 Snackbar로 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이미지를 선택해주세요.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("웹에서 이미지 업로드"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickImage,  // 이미지 선택 버튼
              child: Text("이미지 선택"),
            ),
            SizedBox(height: 20),
            // 이미지가 선택되었으면 화면에 표시
            _imageData != null
                ? GestureDetector(
              onTap: () => _handleImageClick(context),  // 이미지를 클릭하면 실행할 함수
              child: Image.memory(
                _imageData!,
                width: 400,  // 크기만 표시
              ),
            )
                : Text("이미지를 선택해주세요."),  // 이미지가 없으면 텍스트 표시
          ],
        ),
      ),
    );
  }
}
