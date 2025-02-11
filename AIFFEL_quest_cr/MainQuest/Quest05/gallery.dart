import 'package:flutter/material.dart';
import 'dart:typed_data';

class ImageGalleryScreen extends StatelessWidget {
  final List<Uint8List> imageList;

  ImageGalleryScreen({required this.imageList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('사진 갤러리')),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3개의 사진을 한 줄에 표시
        ),
        itemCount: imageList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.memory(
              imageList[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
