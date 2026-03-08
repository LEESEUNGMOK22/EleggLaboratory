# State Model

## 최상위 GameState
- `run`: 런 메타 상태
- `character`: 캐릭터 상태
- `resources`: 자원 상태
- `relationships`: 관계 상태
- `factions`: 세력 평판
- `world`: 지역/막/퀘스트 진행
- `automation`: 자동화 설정
- `chronicle`: 연대기 상태
- `activeDecisionEvent`: 현재 팝업 이벤트
- `time`: 시간/틱/배속
- `history`: 로그/히스토리

## run state
- `id`, `status(idle|running|paused|ended)`, `seed`, `startedAt`, `endedAt`, `causeOfEnd`

## character state
- `name`, `lineageId`, `classId`, `backgroundId`
- `level`, `xp`, `proficiencyBonus`
- `abilities{STR..CHA}`, `maxHp`, `hp`, `ac`
- `conditions[]`, `subclass`, `tags[]`

## resource state
- `gold`, `supplies`, `fatigue`, `taint`, `renown`, `infamy`
- `consumables{potion,scroll,kit}`

## relationship state
- `npcRelations{[npcId]: {trust,intimacy,tension,desire,respect,fear}}`
- `partyMood`

## faction reputation
- `reputation{guild,temple,mercenary,nobility,underbelly}`

## world progression
- `act`, `day`, `locationId`, `actProgress`
- `quests[]` (`id`,`stage`,`progress`,`state`)

## automation profile
- `decisionPresetId`
- `autoEquip`, `autoQuest`, `autoRest`, `autoPotion`
- `t2Policy` (`ask|timed-auto|always-auto`)
- `manualCategories[]`

## chronicle state
- `entries[]`, `legacyFlags[]`, `inheritancePool[]`

## active decision event
- `eventId`, `tier`, `title`, `text`, `choices[]`, `timeoutSec`, `openedAt`

## time state
- `tick`, `speed`, `accumulatorMs`, `lastFrameMs`

## 코드 매핑
- `src/core/store.js`: 상태 저장/구독
- `src/core/state-machine.js`: 상태 전이
- `src/events/eventDispatcher.js`: activeDecisionEvent 세팅
- `src/loop/autoProgressionController.js`: time/loop 반영

## 이 문서가 실제 게임 기획/UX에 어떻게 쓰이는지
- UI 바인딩 필드 표준
- 저장/로드 포맷 및 디버그 스냅샷 기준
