import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'analysis_savehistory.dart';

import '/state/user_state.dart';

class MyinfoScreen extends StatefulWidget {
  const MyinfoScreen({super.key});

  @override
  State<MyinfoScreen> createState() => _MyinfoScreen();
}

class _MyinfoScreen extends State<MyinfoScreen> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserState>().userId ?? '회원';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("내 정보"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/myinfo_screen/myinformation');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        children: [
          Text(
            "$userId님",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          const SectionTitle("진료 정보"),
          _buildListTile(Icons.rate_review, "진료리뷰"),
          _buildListTile(Icons.event_note, "예약내역"),
          _buildListTile(Icons.favorite, "저장한 선생님"),

          const SizedBox(height: 24),

          const SectionTitle("과거 x-ray분석 결과"),
          _buildListTile(
            Icons.accessibility_new,
            "목 분석",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalysisSaveHistory(),
                ),
              );
            },
          ),


          _buildListTile(Icons.back_hand, "등 분석"),
          _buildListTile(Icons.airline_seat_recline_normal, "허리 분석"),
          _buildListTile(Icons.self_improvement, "골반 분석"),

          const SizedBox(height: 24),

          const SectionTitle("혜택 및 이벤트"),
          _buildListTile(Icons.celebration, "혜택코드 입력"),
          _buildListTile(Icons.person_add, "친구초대"),
          _buildListTile(Icons.card_giftcard, "내 기프티콘"),

          const SizedBox(height: 24),

          const SectionTitle("안내"),
          _buildListTile(Icons.help_outline, "자주 묻는 질문"),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            context.go('/hospital_screen');
          } else if (index == 2) {
            context.go('/myinfo_screen');
          } else {
            context.go('/home_screen');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital),
            label: 'Hospital',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Myinfo',
          ),
        ],
      ),
    );
  }



  // ✅ onTap 파라미터를 받을 수 있도록 수정
  Widget _buildListTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[200]),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
      onTap: onTap,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
