import 'package:flutter/material.dart';
import 'URL.dart';
import 'Local.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'X-ray 분석기',
      theme: ThemeData(
        brightness: Brightness.dark,  // 어두운 테마로 설정
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,  // 배경색을 검은색으로 설정
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,  // 앱바 배경색 검은색
          titleTextStyle: TextStyle(
            color: Colors.white,  // 앱바 글자 색 하얀색
            fontSize: 20,
          ),
        ),
        textTheme: TextTheme(
        ),
      ),
      home: FirstPage(),
    );
  }
}

class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final TextEditingController _urlController = TextEditingController();

  void _navigateToNextPage(BuildContext context) {
    final url = _urlController.text;
    if (url.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => URLPage(url: url),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePickerScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,  // 타이틀을 가운데 배치
        title: Text('X-ray 분석기'),
        leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/images/척추 이모티.jpg',
                width: 50,  // 적당한 크기로 설정
                height: 50, // 적당한 크기로 설정
                fit: BoxFit.cover)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: '이미지 URL 입력',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToNextPage(context),
              child: Text('이미지 업로드'),
            ),
          ],
        ),
      ),
    );
  }
}
