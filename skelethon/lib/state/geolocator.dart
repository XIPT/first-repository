import 'package:geolocator/geolocator.dart';

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // GPS 서비스 활성화 여부 확인
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('GPS가 비활성화되어 있습니다.');
  }

  // 권한 확인
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('위치 권한이 거부되었습니다.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('위치 권한이 영구적으로 거부되었습니다.');
  }

  // 현재 위치 가져오기
  return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
}
