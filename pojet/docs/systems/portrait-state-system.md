# Portrait State System

## 입력 축
- HP/부상: `character.hp`, `character.maxHp`
- 피로: `resources.fatigue`
- 오염/축복: `resources.taint`, `character.tags`
- 지역/환경: `world.locationId`, `world.act`
- 장비 태그: `character.gear[]` 문자열 태그화
- 최근 이벤트 감정: `history.events[0]`의 tier/category
- 관계 변화: `relationships.npcRelations.core`
- 세력 상태: `factions.reputation`
- 상태 플래그: 추적/은신/도시체류(월드/이벤트에서 파생)

## 출력 레이어
- 표정(`expression`)
- 조명(`lighting`)
- 오버레이(`overlays[]`)
- 포즈(`posture`)
- 장비 반영(`attireOverlay`)
- 프레임 장식(`frameStyle`)
- 상징물(`ambientSymbols[]`)
- 미세 애니메이션(`microMotion`)

## 결정 순서
1. 치명 상태(중상/몰락) 우선
2. 장기 상태(오염/축복/세력 표식)
3. 감정 상태(최근 이벤트/T2/T3)
4. 관계 상태(친밀/긴장/질투)
5. 장비/환경 상태

## 조합 규칙
- 태그는 다중 부여 가능
- 충돌 시 우선순위: severe wound > tainted > t3 emphasis > relation softening
- 최소 12개 조합 프리셋을 기본 제공

## 이 문서가 실제 게임 기획/UX에 어떻게 쓰이는지
- 초상화 렌더러의 입력/출력 계약
- 아트 확장 시 레이어 추가 기준
