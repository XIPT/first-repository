import 'package:flutter/material.dart';

class MyInformationScreen extends StatelessWidget {
  const MyInformationScreen({super.key});

  // ✅ 예시용 정보 (향후 Provider 연동 가능)
  final MyInformation info = const MyInformation(
    name: '아이펠',
    address: '서울특별시 강남구',
    phoneNumber: '010-1234-5678',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("이름", info.name),
            const SizedBox(height: 16),
            _buildInfoRow("주소", info.address),
            const SizedBox(height: 16),
            _buildInfoRow("전화번호", info.phoneNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

// ✅ 사용자 정보 데이터 클래스
class MyInformation {
  final String name;
  final String address;
  final String phoneNumber;

  const MyInformation({
    required this.name,
    required this.address,
    required this.phoneNumber,
  });
}
