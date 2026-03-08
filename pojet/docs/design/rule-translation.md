# Rule Translation

## 목표
- SRD 감각 유지, 자동 진행 UX에 맞게 단순화

## 공통 판정
- ability check: d20 + ability mod + proficiency(optional) + situational
- save: d20 + save mod + proficiency(if proficient)
- passive: 10 + ability mod + proficiency(optional)
- contested: 각자 check 후 높은 값

## 자동 전투 번역
- 행동/보너스/반응은 내부 액션 큐로 통합
- class-ai-presets 기반으로 행동 우선순위 결정
- 라운드 상세는 옵션, 기본은 요약

## 탐험/사회 번역
- 탐험: 패시브 탐지 + 위험 체크 + 보상/피로 반영
- 사회: 관계/평판 가중치 + CHA계열 체크
- 결과는 T0/T1 로그 또는 T2/T3 이벤트로 승격

## 수치 단순화
- 슬롯/세부 예외보다 `resourcePressure` 지표로 통합
- 복잡한 상태 상호작용은 핵심 조건군만 유지

## 이 문서가 실제 게임 기획/UX에 어떻게 쓰이는지
- 리졸버 구현에서 복잡도 상한선 유지
- “D&D풍 감각 vs 자동 UX” 트레이드오프 기준
