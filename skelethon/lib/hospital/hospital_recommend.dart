/// 추천 병원 리스트 관리 클래스
class HospitalRecommendManager {
  // 추천 병원 정보 목록 (이름과 전화번호 또는 주소)
  static final List<Map<String, String>> recommendedHospitalsByInfo = [
    {'name': '르샤인의원', 'phone': '02-6677-2520'}, // 전화번호로 매칭
    {'name': '강남연세재활의학과의원', 'phone': '02-3478-0216'}, // 전화번호로 매칭
    {'name': '고릴라신경외과의원', 'phone': '032-713-5050'},
    // 더 많은 추천 병원 추가
  ];

  // ID로 지정된 추천 병원 목록
  static final List<Map<String, dynamic>> recommendedHospitals = [];

  // 병원 목록에서 이름과 전화번호/주소가 일치하는 병원을 찾아 ID로 추천 목록 생성
  static void updateRecommendedHospitalsFromList(List<dynamic> hospitals) {
    recommendedHospitals.clear();

    // 디버깅용 출력을 통해 매칭 과정 확인
    print('병원 목록 개수: ${hospitals.length}');

    // 모든 병원 정보 출력 (디버깅용)
    for (var hospital in hospitals) {
      print('병원 정보: ${hospital['place_name']} / ${hospital['phone']} / ${hospital['id']}');
    }

    for (var hospital in hospitals) {
      String hospitalName = hospital['place_name'] ?? '';
      String hospitalPhone = hospital['phone'] ?? '';
      String hospitalAddress = hospital['address_name'] ?? '';
      String hospitalId = hospital['id']?.toString() ?? ''; // ID를 문자열로 변환

      for (var recommendedHospital in recommendedHospitalsByInfo) {
        String recommendedName = recommendedHospital['name'] ?? '';
        String recommendedPhone = recommendedHospital['phone'] ?? '';

        // 디버깅 정보 출력
        print('비교: $hospitalName ($hospitalPhone) vs $recommendedName ($recommendedPhone)');

        // 이름이 포함되는지 확인 (더 유연한 매칭)
        bool nameMatches = hospitalName.toLowerCase().contains(
            recommendedName.toLowerCase()) ||
            recommendedName.toLowerCase().contains(hospitalName.toLowerCase());

        // 전화번호가 있고 일치하는지 확인 (하이픈 제거하고 비교)
        bool phoneMatches = recommendedHospital.containsKey('phone') &&
            hospitalPhone.isNotEmpty &&
            hospitalPhone.replaceAll('-', '').contains(
                recommendedPhone.replaceAll('-', ''));

        // 주소가 있고 일치하는지 확인 (부분 일치도 허용)
        bool addressMatches = recommendedHospital.containsKey('address') &&
            hospitalAddress.isNotEmpty &&
            hospitalAddress.contains(recommendedHospital['address'] ?? '');

        // 이름이 일치하거나 전화번호가 일치하면 추가 (더 유연한 매칭 규칙)
        if (nameMatches || phoneMatches) {
          print('추천 병원 매칭 성공: ${hospital['place_name']} (ID: ${hospital['id']})');
          recommendedHospitals.add({'id': hospitalId});
          break;
        }
      }
    }

    print('매칭된 추천 병원 개수: ${recommendedHospitals.length}');
    print('추천 병원 ID 목록: ${getRecommendedIds()}');
  }

  // 추천 병원 ID 목록만 반환하는 헬퍼 메소드
  static Set<String> getRecommendedIds() {
    return recommendedHospitals.map((e) => e['id'].toString()).toSet();
  }
}