# Pacing Metrics

## 목적
자동 진행 관전 RPG의 재미를 수치로 보조 진단한다. 숫자 밸런스 자체보다 `자동 흐름의 리듬`과 `결정 이벤트 밀도`를 우선 본다.

## 핵심 지표
- 평균 로그 발생 간격
  - 틱 기준: `avgLogIntervalTicks`
  - 시간 기준: `avgLogIntervalSeconds`
- 평균 전투 빈도: `avgCombatPerRun`
- 평균 퀘스트 갱신 빈도: `avgQuestUpdatesPerRun`
- T2 이벤트 평균 발생 주기: `avgT2IntervalTicks`
- T3 이벤트 평균 발생 주기: `avgT3IntervalTicks`
- 첫 레벨업 도달 시점
  - 틱: `avgFirstLevelupTicks`
  - 분: `(avgFirstLevelupTicks * baseSecondsPerTick) / 60`
- 첫 관계 의미 이벤트 도달 시점: `avgFirstRelationshipTicks`
- 첫 세력 갈등 도달 시점: `avgFirstFactionConflictTicks`
- 런 종료 평균 시간
  - 틱: `avgRunDurationTicks`
  - 분: `avgRunDurationMinutes`
- 배속별 체감 차이
  - `bySpeed.*.avgDurationMinutes`
  - `bySpeed.*.avgPauseSeconds`
  - `bySpeed.*.avgT2PerRun`, `avgT3PerRun`

## 해석 규칙
- 로그 간격이 너무 짧으면 정보 피로, 너무 길면 관전 몰입 저하.
- T2 주기가 짧으면 자동 흐름이 깨지고, 길면 의지 개입감이 사라진다.
- T3는 기억점이므로 희소하되, 런 내 최소 1회 체감 가능성이 필요하다.
- 첫 레벨업, 첫 관계 의미 이벤트, 첫 세력 갈등은 초반 20분의 감정선을 결정한다.

## 지표 수집 범위
- 런 단위 샘플: 클래스별 최소 100+ 런 권장.
- 클래스/프리셋/배경 축 교차 비교.
- 계승 누적(legacy) 추세를 포함한 다세대 시뮬레이션.

## 이 문서가 실제 게임 기획/UX에 어떻게 쓰이는지
- 페이싱 회귀(too fast/too slow) 탐지 기준으로 사용.
- 릴리즈 전 빌드 헬스체크의 정량 게이트로 사용.
