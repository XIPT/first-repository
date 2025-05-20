import 'package:flutter/foundation.dart';
import 'analysis_result.dart';

class AnalysisState extends ChangeNotifier {
  final List<AnalysisResult> _results = [];

  // ✅ 외부에서 읽기 전용으로 접근
  List<AnalysisResult> get results => List.unmodifiable(_results);

  // ✅ 새 분석 결과 추가
  void addResult(AnalysisResult result) {
    _results.insert(0, result); // 최신순으로 위에 추가
    notifyListeners();
  }

  // ✅ 전체 분석 결과 초기화
  void clearResults() {
    _results.clear();
    notifyListeners();
  }

  // ✅ (선택) 특정 결과 삭제
  void removeResult(int index) {
    _results.removeAt(index);
    notifyListeners();
  }
}
