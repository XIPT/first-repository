import 'package:flutter/material.dart';
import '/utils/scrollsection.dart';


// 각 부위별 분석 페이지 임포트
import '/analysis/cervical/cervical_la/cervical_angle.dart';
import '/analysis//cervical/cervical_la/cervical_disc.dart';
import '/analysis//cervical/cervical_la/cervical_georgesline.dart';
import '/analysis//cervical/cervical_la/cervical_gravityline.dart';
import '/analysis//cervical/cervical_la/cervical_slope.dart';

// 여기서 thoracic, lumbar, pelvic 관련 페이지도 임포트합니다
// import 'thoracic_la/....dart';
// import 'lumbar_la/....dart';
// import 'pelvic_la/....dart';

/// 분석 항목 관리 헬퍼 클래스
class AnalysisItems {

  /// 경추(Cervical) AP 분석 항목 리스트
  static List<Widget> getCervicalApItems(BuildContext context) {
    // 현재는 빈 리스트지만 필요한 항목들을 추가할 수 있습니다
    return [
      // AP 관련 분석 항목들을 여기에 추가
    ];
  }

  /// 경추(Cervical) LA 분석 항목 리스트
  static List<Widget> getCervicalLaItems(BuildContext context) {
    return [
      AnalysisListTile(
        title: '경추 전만 각도',
        subtitle: 'cervical cobb\'s angle',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CervicalAnglePage(),
            ),
          );
        },
      ),
      AnalysisListTile(
        title: '디스크 사이 거리',
        subtitle: 'Cervical Disc Distance',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CervicalDiscPage(),
            ),
          );
        },
      ),
      AnalysisListTile(
        title: '경추 중력선',
        subtitle: 'Cervical Gravity Line',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CervicalGravityLinePage(),
            ),
          );
        },
      ),
      AnalysisListTile(
        title: '조지스 라인',
        subtitle: "George's line",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GeorgesLinePage(),
            ),
          );
        },
      ),
      AnalysisListTile(
        title: '경추 경사 각도',
        subtitle: "Cervical slope angle",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CervicalSlopePage(),
            ),
          );
        },
      ),
    ];
  }

  /// 흉추(Thoracic) AP 분석 항목 리스트
  static List<Widget> getThoracicApItems(BuildContext context) {
    // 흉추 AP 관련 항목들을 여기에 추가
    return [
      // 예시:
      /*
      AnalysisListTile(
        title: '흉추 측만 각도',
        subtitle: 'Thoracic scoliosis angle',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ThoracicScoliosisPage(),
            ),
          );
        },
      ),
      */
    ];
  }

  /// 흉추(Thoracic) LA 분석 항목 리스트
  static List<Widget> getThoracicLaItems(BuildContext context) {
    // 흉추 LA 관련 항목들을 여기에 추가
    return [
      // 예시:
      /*
      AnalysisListTile(
        title: '흉추 후만 각도',
        subtitle: 'Thoracic kyphosis angle',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ThoracicKyphosisPage(),
            ),
          );
        },
      ),
      */
    ];
  }

  /// 요추(Lumbar) AP 분석 항목 리스트
  static List<Widget> getLumbarApItems(BuildContext context) {
    // 요추 AP 관련 항목들을 여기에 추가
    return [];
  }

  /// 요추(Lumbar) LA 분석 항목 리스트
  static List<Widget> getLumbarLaItems(BuildContext context) {
    // 요추 LA 관련 항목들을 여기에 추가
    return [];
  }

  /// 골반(Pelvic) AP 분석 항목 리스트
  static List<Widget> getPelvicApItems(BuildContext context) {
    // 골반 AP 관련 항목들을 여기에 추가
    return [];
  }

  /// 골반(Pelvic) LA 분석 항목 리스트
  static List<Widget> getPelvicLaItems(BuildContext context) {
    // 골반 LA 관련 항목들을 여기에 추가
    return [];
  }

  /// 부위와 뷰 타입에 따라 적절한 분석 항목 리스트를 반환하는 메서드
  static List<Widget> getItemsByRegionAndView(BuildContext context, String region, String view) {
    switch (region.toLowerCase()) {
      case 'cervical':
        return view.toLowerCase() == 'ap'
            ? getCervicalApItems(context)
            : getCervicalLaItems(context);
      case 'thoracic':
        return view.toLowerCase() == 'ap'
            ? getThoracicApItems(context)
            : getThoracicLaItems(context);
      case 'lumbar':
        return view.toLowerCase() == 'ap'
            ? getLumbarApItems(context)
            : getLumbarLaItems(context);
      case 'pelvic':
        return view.toLowerCase() == 'ap'
            ? getPelvicApItems(context)
            : getPelvicLaItems(context);
      default:
        return [];
    }
  }
}