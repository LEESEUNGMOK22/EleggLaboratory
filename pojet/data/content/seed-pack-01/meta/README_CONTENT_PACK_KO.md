# Ashmark Chronicle 대량 시드 데이터팩

이 패키지는 Codex나 다른 자동화 도구가 바로 읽고 확장할 수 있도록 만든 시드 데이터팩입니다.

## 포함 수량
- 이벤트: 320개
- 퀘스트: 96개
- NPC: 80개
- 아이템: 120개
- 장소: 48개
- 총 레코드: 664개

## 구조
- `data/content/events/events_batch_01.json` ~ `events_batch_04.json`
- `data/content/quests/quests_batch_01.json` ~ `quests_batch_02.json`
- `data/content/npcs/npcs_batch_01.json` ~ `npcs_batch_02.json`
- `data/content/items/items_batch_01.json` ~ `items_batch_02.json`
- `data/content/locations/locations_batch_01.json`
- `data/content/manifest.json`

## 사용 목적
1. UI 프로토타입에 대량 더미/시드 데이터 연결
2. 이벤트 가중치, 퀘스트 빈도, 선택지 등장 리듬 테스트
3. Codex의 대량 생성 프롬프트에 입력 시드로 사용
4. 후속 정제/중복 제거/문체 통일 작업의 출발점

## 주의
- 현재 문장 톤은 “바로 쓸 수 있는 시드” 수준입니다.
- 실제 출시용으로는 중복 감각, 문체, 난이도, 후속 연결을 추가 정제해야 합니다.
- T2/T3 이벤트는 설계상 개입 포인트를 보여주기 위한 예시이며, 밸런스 값은 확정본이 아닙니다.
