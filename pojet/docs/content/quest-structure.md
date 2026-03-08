# Quest Structure

## 퀘스트 유형
- 자동 일상 의뢰(daily): 반복 가능, 짧은 루프, 빠른 보상
- 의미 있는 서브 퀘스트(side): 관계/세력/윤리 분기 포함
- 막 단위 메인 퀘스트(main): 챕터 전환, T3 비중 높음

## 공통 필드
- title
- emotionalTheme
- questType
- trigger
- stages
- likelyChecks
- failureStates
- rewards
- followUps
- chronicleImpact

## 자동 진행 맞춤 규칙
- stage당 텍스트는 짧게, 결과는 로그+태그로 누적
- 실패는 종료보다 "비용"으로 설계 (평판/관계/오염)

## 이 문서가 실제 게임 기획/UX에 어떻게 쓰이는지
- 퀘스트 JSON 스키마 통일
- 자동 루프에서 stage 진행과 이벤트 승격 기준 정의
