import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InsuranceScreen extends StatelessWidget {
  const InsuranceScreen({super.key});

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
          '실손보험정보',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '📌 실손보험 핵심 기초지식',
              style: TextStyle(
                fontSize: 20,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildAccordionTile(
              title: '1) 실손보험의 기본 개념입니다.',
              content:
              '실손보험은 의료비 보장을 목적으로 하는 보험 상품입니다. '
                  '이 보험은 질병이나 상해로 인해 발생한 실제 의료비를 보상해줍니다. '
                  '일반적으로 건강보험에서 보장하지 않는 비급여 항목도 포함되며, '
                  '실손보험은 ‘제2의 건강보험’으로 불릴 만큼 중요한 보험으로 인식되고 있습니다. '
                  '이를 통해 예상치 못한 의료비 부담을 줄일 수 있습니다.',
            ),
            _buildAccordionTile(
              title: '2) 실손보험의 세대별 차이입니다.',
              content:
              '실손보험은 세대별로 보장 내용과 자기부담금이 다릅니다. '
                  '1세대와 2세대는 보장이 넓고 자기부담금이 낮은 반면, '
                  '3세대와 4세대는 비급여 항목이 특약으로 분리되고 자기부담금이 높아졌습니다. '
                  '특히 4세대는 모든 비급여 항목을 특약으로 가입해야 합니다. '
                  '또한, 재가입 주기가 15년에서 5년으로 줄어들어 보장 내용이 자주 변경될 수 있습니다. '
                  '각 세대의 차이를 잘 이해하고 자신에게 맞는 실손보험을 선택하는 것이 중요합니다.',
            ),
            _buildAccordionTile(
              title: '3) 4세대 실손보험의 특징입니다.',
              content:
              '4세대 실손보험은 2021년 7월부터 판매되기 시작했습니다. '
                  '이 보험은 기존 세대보다 보험료가 저렴하지만, 자기부담금 비율이 높아졌습니다. '
                  '또한, 비급여 항목은 모두 특약으로 분리되어 있어 필요한 특약을 추가로 가입해야 합니다. '
                  '이러한 변화는 보험사의 손해율을 줄이기 위한 조치로 이해됩니다.',
            ),
            _buildAccordionTile(
              title: '4) 실손보험 전환 시 고려사항입니다.',
              content:
              '기존의 실손보험 가입자가 4세대로 전환할지 고민할 때는 몇 가지 고려사항이 있습니다. '
                  '4세대 보험은 보험료가 저렴하지만 보장 내용이 축소될 수 있고, '
                  '특약을 통한 보장 범위 확장이 필요합니다. '
                  '본인의 건강 상태와 의료비 지출 패턴을 고려하여 신중히 판단해야 하며, '
                  '보험전환은 신중한 결정이 필요한 중요한 문제입니다.',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAccordionTile({required String title, required String content}) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              content,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
