# Seed Pack Review: `ashmark_content_seed_pack`

## 처리 결과
- 시드팩을 프로젝트 표준 위치로 재배치:
  - `data/content/seed-pack-01/`
- 원본 중첩 경로:
  - `ashmark_content_seed_pack/ashmark_content_seed_pack/...`
- 불필요한 원본 임시 폴더 삭제:
  - `ashmark_content_seed_pack/`

## 정리된 구조
- `data/content/seed-pack-01/events/events_batch_01.json` ~ `events_batch_04.json`
- `data/content/seed-pack-01/quests/quests_batch_01.json` ~ `quests_batch_02.json`
- `data/content/seed-pack-01/npcs/npcs_batch_01.json` ~ `npcs_batch_02.json`
- `data/content/seed-pack-01/items/items_batch_01.json` ~ `items_batch_02.json`
- `data/content/seed-pack-01/locations/locations_batch_01.json`
- `data/content/seed-pack-01/meta/manifest.seed-pack-01.json`
- `data/content/seed-pack-01/meta/README_CONTENT_PACK_KO.md`
- `data/content/seed-pack-01/meta/content_schema_ko.md`

## 데이터 무결성 체크
- JSON 파싱: `12/12` 파일 성공
- 레코드 수:
  - events: `320`
  - quests: `96`
  - npcs: `80`
  - items: `120`
  - locations: `48`

## 적용 정책
- 기존 런타임(`data/content/*.json`)은 즉시 덮어쓰지 않음
- 이유: 현재 게임이 참조 중인 스키마와 시드팩 스키마가 다름
  - 기존: `events-t0.json`, `events-t1.json`, ...
  - 시드팩: `events/events_batch_*.json` (통합형 필드셋)

## 다음 단계(권장)
1. 시드팩 전용 로더(`scripts/content/merge_seed_pack.*`)를 추가해 기존 스키마로 변환
2. `id`, `tier`, `pillar`, `choices`, `mustPause`, `portrait` 관련 필드 매핑 규칙 확정
3. 변환 후 검증:
   - tier 분포
   - act/region/faction 참조 무결성
   - T2/T3 선택지/자동처리 힌트 포함 여부
