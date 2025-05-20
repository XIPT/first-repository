
/// 뷰 타입 정의
enum ViewType { ap, la }

extension ViewTypeExtension on ViewType {
  String toApiString() => name.toLowerCase();  // 'ap' 또는 'la'
}

/// 텍스트 정렬 옵션
enum TextAlignment {
  center,
  left,
  right,
  top,
  bottom
}

/// 상태 수준 정의
enum StatusLevel {
  normal,    // 정상
  mild,      // 경미한 이상
  severe     // 심한 이상
}

enum UploadMode {
  fullBody,  // 전신 그대로 업로드
  cropRegion // 특정 부위 크롭해서 업로드
}

enum MeasurementMode {
  none,       // 기본 모드
  horizontal, // 가로 측정 모드
  vertical,   // 세로 측정 모드
}