import 'package:flutter/material.dart';

/// 재사용 가능한 스크롤 가능한 섹션 위젯
class ScrollableSection extends StatelessWidget {
  final List<Widget> children;
  final bool show;
  final Color backgroundColor;
  final EdgeInsetsGeometry margin;
  final double borderRadius;

  const ScrollableSection({
    Key? key,
    required this.children,
    this.show = true,
    this.backgroundColor = Colors.black87,
    this.margin = const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return const SizedBox.shrink(); // 표시하지 않을 경우 빈 공간 반환
    }

    return Container(
      margin: margin,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: children,
      ),
    );
  }
}

/// 분석 목록의 항목을 생성하는 위젯
class AnalysisListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double titleFontSize;
  final double subtitleFontSize;
  final double verticalPadding;
  final double horizontalPadding;
  final double? tileHeight;
  final bool dense;

  const AnalysisListTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleFontSize = 18.0,
    this.subtitleFontSize = 15.0,
    this.verticalPadding = 4.0,
    this.horizontalPadding = 20.0,
    this.tileHeight,
    this.dense = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: tileHeight,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white70, fontSize: subtitleFontSize),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap,
        tileColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        dense: dense,
      ),
    );
  }
}

/// 키포인트 리스트뷰를 생성하는 위젯
class KeypointsListView extends StatelessWidget {
  final List<dynamic> keypoints;

  const KeypointsListView({
    Key? key,
    required this.keypoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: keypoints.isNotEmpty
          ? ListView.builder(
        itemCount: keypoints.length,
        itemBuilder: (context, index) {
          final keypoint = keypoints[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Card(
              color: Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Point ${index + 1}: x=${keypoint['x']?.toStringAsFixed(2) ?? 'N/A'}, y=${keypoint['y']?.toStringAsFixed(2) ?? 'N/A'}',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          );
        },
      )
          : Center(
        child: Text(
          '키포인트 데이터가 없습니다',
          style: TextStyle(color: Colors.white60),
        ),
      ),
    );
  }
}