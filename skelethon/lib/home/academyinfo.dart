import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AcademyInfoScreen extends StatelessWidget {
  const AcademyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '학회 정보',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '1. 의료 학회 핵심 정보',
              style: TextStyle(
                fontSize: 20,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            SectionTitle('1) 학회란 무엇인가요?'),
            SectionContent(
              '의료 학회는 특정 분야의 전문가들이 모여 지식과 정보를 공유하고 연구 결과를 발표하는 공식적인 단체입니다. '
                  '의료계에서는 의사, 물리치료사, 연구자 등 다양한 전문가들이 학회에 소속되어 최신 지견을 나누며 학문과 임상의 발전을 도모합니다.',
            ),

            SectionTitle('2) 학회의 주요 역할'),
            SectionContent(
              '학회는 학술대회 개최, 연구 발표, 임상 지침 제정, 교육 프로그램 제공 등의 다양한 역할을 수행합니다. '
                  '이를 통해 의료인들의 전문성과 최신 지식을 강화하고, 환자 진료의 질을 향상시키는 데 기여합니다.',
            ),

            SectionTitle('3) 왜 학회에 참여해야 하나요?'),
            SectionContent(
              '학회에 참여함으로써 최신 의료 정보와 기술을 접할 수 있고, 동료 전문가들과의 네트워크도 형성할 수 있습니다. '
                  '또한, 자격 갱신이나 학점 취득 등의 실질적인 혜택도 받을 수 있어 의료인이라면 적극적인 참여가 권장됩니다.',
            ),

            SectionTitle('4) 국내 주요 학회 예시'),
            SectionContent(
              '대한정형외과학회, 대한재활의학회, 대한도수의학회, 대한의사협회 등 다양한 학회들이 있으며, '
                  '각 학회는 분야별로 특화된 연구와 학술대회를 주최합니다. 관심 있는 학회의 연례 행사나 워크숍에 참여해 보세요.',
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class SectionContent extends StatelessWidget {
  final String text;
  const SectionContent(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white70,
          height: 1.5,
        ),
      ),
    );
  }
}
