# Class Balance Notes

## 평가 기준
- 생존률
- 평균 최종 레벨
- 조기 사망률(30틱 이전)
- T2/T3 체감 빈도
- 관계 루트 진입 시점

## 판정 원칙
- 클래스 판타지는 유지하되, 생존률 격차가 과하면 조정 대상.
- 고점 클래스는 직접 너프보다 자원 소모/리스크 노출로 완화.
- 저점 클래스는 초반 20분 체감 강점 이벤트를 우선 보강.

## 튜닝 레버
- 전투 판정 DC 계수
- 클래스별 리스크 허용값(riskTolerance)
- 자원 보존/소모 경향(resourceConservation)
- 클래스 친화 이벤트(classAffinity) 노출 가중치
- 클래스별 기본 회복/피로 축적 곡선

## 최신 시뮬레이션 요약
- 샘플: 1,440런 (클래스당 120런, seed 441901)
- 상위 생존 클래스: `bard`, `cleric`
- 하위 생존 클래스: `wizard`, `sorcerer`
- 고오염 프리셋: `권력지향형`
- 저생존 프리셋: `관계중시형`

## 1차 조정 전후 (동일 시드)
- 조정 전
  - earlyDeathRate: `0.71`
  - avgRunDurationMinutes: `0.31`
  - relationshipEventShare: `0.02`
  - firstLevelupMinutes: `0.13`
- 조정 후
  - earlyDeathRate: `0.31`
  - avgRunDurationMinutes: `12.83`
  - relationshipEventShare: `0.19`
  - firstLevelupMinutes: `9.53`

## 남은 이슈
- T3 간격이 목표보다 김 (`46.91` ticks, 목표 최대 `40`)
- 런 평균 길이가 목표 하한보다 짧음 (`12.83` min, 목표 `18+`)
- 클래스 생존률 절대값이 여전히 낮아 초반 난이도 체감이 높을 가능성

## 이 문서가 실제 게임 기획/UX에 어떻게 쓰이는지
- 클래스별 감정 곡선(생존/성장/드라마)의 균형 조정 메모로 사용.
