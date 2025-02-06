# -*- coding: utf-8 -*-
"""Untitled

Automatically generated by Colab.

Original file is located at
    https://colab.research.google.com/drive/16NmJBmAbmg8eyXFZ1GpuvbZhL8fQFv0I
"""

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String result = "";
  TextEditingController urlController =
  TextEditingController(); // URL을 입력 받는 컨트롤러

  Future<void> fetchLabelData() async {
    try {
      final enteredUrl = urlController.text; // 입력된 URL 가져오기
      final response = await http.get(
        Uri.parse(enteredUrl + "sample"), // 입력된 URL 사용
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          result = "predicted_label: ${data['predicted_label']}";
        });
      } else {
        setState(() {
          result = "Failed to fetch data. Status Code: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
    }
  }

  Future<void> fetchScoreData() async {
    try {
      final enteredUrl = urlController.text; // 입력된 URL 가져오기
      final response = await http.get(
        Uri.parse(enteredUrl + "sample"), // 입력된 URL 사용
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '69420',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          result = "prediction_score: ${data['prediction_score']}";
        });
      } else {
        setState(() {
          result = "Failed to fetch data. Status Code: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0), // 이미지 주변 여백 조정
          child: Image.asset(
            'images/lab_instagram_icon_4.jpg', // 좌측에 넣을 이미지
          ),
        ),
        title: Text(
          'Jellyfish controller', // 앱바 중앙에 텍스트
          style: TextStyle(
            fontSize: 24, // 글자 크기 설정
            color: Colors.white, // 텍스트 색상
            fontWeight: FontWeight.bold, // 글자 굵게
          ),
        ),
        centerTitle: true, // 제목을 센터로 배치
        backgroundColor: Colors.blue, // 앱바 배경 색상
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 수직 중앙 정렬
          children: [
            // 이미지 추가
            Image.asset('images/jellyfish.jpg'), // 이미지 파일 경로를 적어주세요.
            SizedBox(height: 20), // 이미지와 입력 필드 간의 간격

            // URL 입력을 위한 텍스트 필드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              // 텍스트 필드 주변 여백 추가
              child: TextField(
                controller: urlController, // URL 입력을 위한 TextField
                decoration: InputDecoration(labelText: "URL 입력"), // 입력 필드의 라벨
              ),
            ),

            SizedBox(height: 20), // 텍스트 필드와 버튼 간의 간격

            // 데이터 가져오기 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // 버튼을 중앙에 정렬
              children: [
                // 첫 번째 버튼
                ElevatedButton(
                  onPressed: fetchLabelData,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // 버튼 끝을 둥글게
                    ),
                  ),
                  child: Text("데이터 가져오기"),
                ),

                SizedBox(width: 20), // 버튼 간의 간격

                // 두 번째 버튼
                ElevatedButton(
                  onPressed: fetchScoreData,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // 버튼 끝을 둥글게
                    ),
                  ),
                  child: Text("예측하기"),
                ),
              ],
            ),

            SizedBox(height: 20), // 버튼과 결과 간의 간격

            // 결과 출력
            Text(
              result,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}