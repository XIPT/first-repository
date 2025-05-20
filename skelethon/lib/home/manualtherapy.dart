import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManualTherapyScreen extends StatelessWidget {
  const ManualTherapyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('도수치료란?', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '📌 도수치료 핵심요약',
              style: TextStyle(
                fontSize: 20,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildAccordionTile(
              title: '1) 도수치료의 정의',
              content:
              '도수치료는 치료사의 손을 이용해 신체의 근육과 관절을 직접 조작하여 통증을 완화하고 기능을 개선하는 치료법입니다. '
                  '특별한 기계나 도구 없이 손으로 시행하며, 근골격계 문제에 효과적입니다. '
                  '물리치료와 달리 치료사가 직접 신체를 조작하는 점에서 차이가 있습니다.',
            ),
            _buildAccordionTile(
              title: '2) 도수치료의 역사',
              content:
              '도수치료는 고대 로마, 히포크라테스 시대부터 기원이 있으며, '
                  '18세기 이후 현대적인 형태로 발전했습니다. '
                  '정골의학, 카이로프랙틱 등의 영향을 받아 지금의 체계가 형성되었습니다.',
            ),
            _buildAccordionTile(
              title: '3) 도수치료와 물리치료의 차이점',
              content:
              '물리치료는 기계와 운동 요법 위주, 도수치료는 손으로 직접 근육/관절을 조작하는 치료입니다. '
                  '열, 전기 자극 등은 물리치료에 해당하며, 도수치료는 수기 중심입니다.',
            ),
            _buildAccordionTile(
              title: '4) 도수치료의 적용 사례',
              content:
              '허리, 목, 어깨 통증, 스포츠 손상, 수술 후 재활 등에 도수치료가 활용됩니다. '
                  '자세 불균형, 근육 긴장 완화, 관절 기능 개선에 매우 효과적입니다.',
            ),
            _buildAccordionTile(
              title: '5) 도수치료의 장단점',
              content:
              '장점:\n- 비수술적, 빠른 회복 가능\n- 맞춤 치료로 효과적\n\n'
                  '단점:\n- 숙련도에 따라 차이 있음\n- 반복 치료 필요, 비용 부담 가능성',
            ),
            _buildAccordionTile(
              title: '6) 치료 전 체크리스트',
              content:
              '1. 병원 의사 선생님과의 충분한 상담(환자의 현재상태, 과거기록등으로 도수치료 적응증인지 금기증인지 판단) \n2. 필요한 경우 x-ray, CT, MRI등의 영상촬영(객관적인 평가지표)\n3. 본인의 보험적용 범위 확인\n'
              '4. 도수치료사와의 상담 및 이학적평가(환자의 움직임, 근력상태, 통증상태 등으로 한번더 금기증에 속하지 않는지 판단)\n '
              '5. 치료사는 환자에게 치료방법 및 주의사항을 꼼꼼히 설명하고 환자가 민감하다 생각할수 있는 부위의 치료필요시 충분한 설명 및 동의를 얻어야함\n'
              '6. 환자 역시 본인의 상태 및 과거(교정을 받아 아팠던 경험 또는 이석증이 있어서 고개를 뒤로젖히면 어지러움이 심하다 등)를 꼼꼼히 설명하고 본인이 기분이 나쁠수 있는 부분의 터치나 노출은 미리 설명 및 치료시에도 단호히 거절한다',
            ),
            _buildAccordionTile(
              title: '7) 나에게 맞는 치료사 찾는법',
              content:
              '1. 본인이 원하는 치료스타일을 찾아본다. \n- 아무리 훌륭한 치료라도 본인의 몸에 안맞으면 좋지 않을수 있다. ex)교정시 또는 연부조직(근육,근막)을 풀때 환자가 긴장을 못풀면 제대로 치료가 안되는경우\n'
              '2. 치료사의 경력과 치료방법, 이수한 학회를 확인한다. \n- 학회정보에서 어떤치료를 하는지, 어떤 과학적인 근거 혹은 메카니즘을 가지고 치료하는지, 몇 시간의 코스 과정인지 제공\n'
              '3. 병원 혹은 치료사를 병원정보에서 찾아보고 직접 가서 본인의 문제가 어떤치료에 적합할지를 진료받는다.\n'
              '4. 도수치료는 약물을 쓰지 않고 환자의 자생능력을 도와주므로 부작용이 적고 틀어진 체형으로 인한 만성통증에 효과적이지만 한두번의 치료만으로 완치가 어렵고 본인의 노력여하(교정운동, 습관교정)에 따라 기간의 차이가 있을수 있습니다.',
            ),
            _buildAccordionTile(
              title: '8) 최고의 치료사란?',
              content:
              '10년이상 도수치료사로 일하고 대학병원, 정형외과, 재활의학과, 피부과, 재벌과 연예인 위주의 시크릿한 병원, 체형교정원을 거치면서 다양한 범위의 환자들을 만나면서 느낀 저의 주관적인 생각으로\n'
              '**1등 치료사란 존재하지 않습니다.**\n' '수십년간의 경력과 노하우, 수많은 학회교육, 과학적인 근거, 환자와의 소통방식, 객관적인 평가지표의 결과(영상,통증정도,근력테스트,움직임테스트) 모든것들이 중요하지만\n'
              '가장 중요한건 환자 본인이 원하는 개선방향으로 치료가 되는것 입니다.\n'
              '척추가 많이 틀어지고 디스크의 퇴행이 많이 있어도 거기에 적응해서 통증을 못느끼는 환자에 척추를 바로 세울려고 할때 환자는 변화를 느끼면서 통증을 느끼는경우가 매우 많습니다(뜨거운물에 있다가 실온에 가면 매우 춥게 느끼는것처럼)\n'
              '이런경우 환자가 원하는게 통증이 없는거라고 할때 아무리 치료를 잘해도 이런 원리에 대한 충분한 설명과 환자의 동의가 없다면 그 치료사는 최악의 치료사가 될수있습니다.',
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
