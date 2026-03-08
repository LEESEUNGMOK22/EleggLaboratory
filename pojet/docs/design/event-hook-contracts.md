# Event Hook Contracts

## 디스패치 입력
- `eventType`, `tierHint`, `context`, `riskLevel`, `sourceResolver`

## UI 최소 payload
- `eventId`, `tier`, `title`, `text`
- `choices[{id,label,effectsPreview}]`
- `timeoutSec`(T2), `mustPause`(T3), `category`

## 결과 반영 인터페이스
- `applyEventChoice(gameState, eventId, choiceId)`
- 반영 대상: `history`, `resources`, `relationships`, `factions`, `world.quests`, `chronicle`

## 저장 포맷
- `history.events[]`: 입력/선택/결과/timestamp
- `history.logs[]`: 사용자 표시용 단문 로그

## 자동 정책 반영
- `automation.eventTypePolicies`
- `automation.eventResolutionOverrides`

## 이 문서가 실제 게임 기획/UX에 어떻게 쓰이는지
- 이벤트 제작팀과 클라이언트 UI 간 공통 계약
- 신규 이벤트 추가 시 회귀 오류 방지 기준
