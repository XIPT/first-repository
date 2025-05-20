import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/analysis_state.dart'; //state폴더에 analysis_state.dart와 연결


class AnalysisHistoryNeckScreen extends StatefulWidget {
  const AnalysisHistoryNeckScreen({super.key});

  @override
  State<AnalysisHistoryNeckScreen> createState() => _AnalysisHistoryNeckScreen();
}

class _AnalysisHistoryNeckScreen extends State<AnalysisHistoryNeckScreen> {

  @override
  Widget build(BuildContext context) {
    final results = context.watch<AnalysisState>().results;

    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 결과 목록'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: results.isEmpty
          ? Center(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.search_off, color: Colors.white54, size: 80),
              SizedBox(height: 16),
              Text(
                '아직 분석된 데이터가 없습니다.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: result.previewImage != null
                  ? Image.memory(result.previewImage!,
                  width: 50, fit: BoxFit.cover)
                  : const Icon(Icons.image, color: Colors.white54),
              title: Text(
                result.title,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                result.description,
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Text(
                "${result.createdAt.hour}:${result.createdAt.minute}",
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
