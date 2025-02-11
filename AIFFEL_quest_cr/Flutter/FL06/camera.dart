import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'gallery.dart';

class TakePictureScreen extends StatefulWidget {
  final Uint8List? imageData;
  final String? imageUrl;

  TakePictureScreen({this.imageData, this.imageUrl});

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  html.VideoElement? _videoElement;
  Uint8List? _capturedImage;
  bool _isCameraActive = true;
  List<Uint8List> _imageList = [];  // 캡처된 이미지를 저장할 리스트

  @override
  void initState() {
    super.initState();
    _capturedImage = widget.imageData; // 기존 이미지 데이터 로드
    _setupCamera();
  }

  // 카메라 설정
  Future<void> _setupCamera() async {
    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({'video': true});
      if (stream != null) {
        _videoElement = html.VideoElement()
          ..autoplay = true
          ..muted = true
          ..srcObject = stream;
        _videoElement!.onLoadedData.listen((event) {
          setState(() {
            _isCameraActive = true;
          });
        });
      }
    } catch (e) {
      print('Error accessing camera: $e');
    }
  }

  // 캡처 기능
  Future<void> _takePicture() async {
    if (_videoElement == null) return;

    final canvas = html.CanvasElement(width: _videoElement!.videoWidth, height: _videoElement!.videoHeight);
    final context = canvas.getContext('2d') as dynamic;
    context.drawImage(_videoElement!, 0, 0);

    final blob = await canvas.toBlob('image/png');
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob!);
    await reader.onLoad.first;

    setState(() {
      _capturedImage = Uint8List.fromList(reader.result as List<int>); // 캡처된 이미지 저장
      _imageList.add(_capturedImage!);  // 찍은 사진을 리스트에 추가
    });
  }

  @override
  void dispose() {
    _videoElement?.srcObject?.getTracks().forEach((track) => track.stop());
    _videoElement?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('카메라 촬영')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isCameraActive)
              Text('카메라 동작중')
            else
              Text('카메라 초기화 중...'),
            SizedBox(height: 20),

            // 전달된 이미지가 있으면 그것을 표시
            if (_capturedImage != null)
              Image.memory(
                _capturedImage!, // 화면 너비에 맞게
                height: 400,  // 원하는 높이 설정
                fit: BoxFit.cover,  // 이미지를 화면에 맞게 보이도록 함
              )  // 촬영된 사진 표시
            else if (widget.imageUrl != null)
              Image.network(widget.imageUrl!,
                height: 400,  // 원하는 높이 설정
                fit: BoxFit.cover,
              ),// 기존 웹 이미지 표시
            SizedBox(height: 20),

            // 버튼들을 가로로 배치하기 위해 Row 위젯 사용
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // 버튼들을 중앙에 배치
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    await _takePicture();  // 사진 찍기
                  },
                  child: Text('사진 찍기'),
                ), // 여기에 괄호를 닫는 부분을 추가
                SizedBox(width: 20), // 버튼 사이에 간격 추가
                ElevatedButton(
                  onPressed: () {
                    // 이미지 리스트를 새로운 화면으로 전달
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageGalleryScreen(imageList: _imageList),
                      ),
                    );
                  },
                  child: Text('사진 갤러리 보기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
