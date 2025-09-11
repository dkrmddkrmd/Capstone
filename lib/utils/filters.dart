// lib/utils/filters.dart
String _normalize(String s) =>
    s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

bool shouldExcludeLectureByTitle(String title) {
  final t = _normalize(title);
  // 차단 키워드(공백 무시, 소문자 비교)
  const blocked = [
    '연구활동종사자',
    '스마트폰과의존',
  ];
  return blocked.any((b) => t.contains(_normalize(b)));
}
