import 'package:flutter/material.dart';
import '../utils/enums.dart';

class XrayCropState with ChangeNotifier {
  Map<String, String> apCrops = {};
  Map<String, String> laCrops = {};

  void setCrops(ViewType viewType, Map<String, dynamic> data) {
    print('💾 입력된 데이터: $data');
    final crops = data.map((k, v) => MapEntry(k, v.toString()));
    print('💾 변환된 crops: $crops');
    
    if (viewType == ViewType.ap) {
      apCrops = crops;
      print('✅ 저장된 AP Crops: $apCrops');
    } else if (viewType == ViewType.la) {
      laCrops = crops;
      print('✅ 저장된 LA Crops: $laCrops');
    }
    notifyListeners();
  }


  String? getCropImage(ViewType viewType, String part) {
    switch (viewType) {
      case ViewType.ap:
        return apCrops[part];
      case ViewType.la:
        return laCrops[part];
    }
  }
}
