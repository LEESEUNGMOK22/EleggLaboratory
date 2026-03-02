class TutorialStep {
  const TutorialStep({required this.id, required this.title, required this.desc});

  final String id;
  final String title;
  final String desc;
}

const List<TutorialStep> kTutorialSteps = [
  TutorialStep(id: 'summon_3', title: '소환해보기', desc: '소환 3회를 달성하세요'),
  TutorialStep(id: 'merge_1', title: '머지해보기', desc: '머지 1회를 달성하세요'),
  TutorialStep(id: 'transform_1', title: '변성보기', desc: '변성 1회를 경험하세요'),
  TutorialStep(id: 'upgrade_1', title: '업그레이드', desc: '업그레이드 1개 구매하세요'),
  TutorialStep(id: 'log_open', title: '로그확인', desc: '로그 탭을 열어보세요'),
];
