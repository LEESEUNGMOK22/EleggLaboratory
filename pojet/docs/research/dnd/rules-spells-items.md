# Rules Spells & Items (태그 중심 설계)

기준: SRD 5.1 우선, 5.2.1 보조
마지막 확인: 2026-03-09 (KST)

## 원칙
- 주문/아이템 목록을 룰북처럼 통째 복제하지 않는다.
- 자동 진행 전투/이벤트/AI에 필요한 태그 체계만 추출한다.

## 주문 태그 체계(권장)
- direct_damage
- control
- defense
- heal
- utility
- summon
- mobility
- ritual
- buff
- debuff
- concentration
- aoe
- single_target

## 아이템 태그 체계(권장)
- mundane
- martial
- finesse
- ranged
- heavy
- light_armor
- medium_armor
- heavy_armor
- shield
- arcane_focus
- divine_symbol
- relic
- cursed
- unique
- consumable

## 자동 진행형 적용 방식
- 전투 AI: 태그 기반 우선순위 트리
  - 예) `low_hp -> heal/defense`, `enemy_clustered -> aoe/control`
- 이벤트: 태그 기반 해결 옵션 생성
  - 예) ritual 태그 보유 시 봉인 이벤트에서 대체 선택지 해금
- 장비 자동 교체: 희귀/저주/유니크는 수동 확인 이벤트로 승격

## 데이터 연결
- `data/reference/dnd-spell-tags.json`를 단일 태그 사전으로 사용
- 무기/방어구/조건/클래스 JSON의 `mechanicalTags`와 교차 참조

## 이 문서가 실제 게임 기획/UX에 어떻게 쓰이는지
- 스킬/주문 UI를 간소화하면서도 클래스별 전투 개성을 유지하는 설계 기준
- 콘텐츠 팀이 새 주문/유물을 만들 때 공통 태그 표준으로 사용
