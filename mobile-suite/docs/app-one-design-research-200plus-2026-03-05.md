# App One 디자인/아트 대규모 리서치 (200+ 소스)

- 총 수집 소스: **264개**
- 범위: UI 트렌드, 모바일 디자인 시스템, 무료 상업적 이용 가능 에셋, 원소/알케미 장르 레퍼런스, 오픈소스 클론

## 핵심 인사이트 요약
1. 최신 모바일 UI는 정보 밀도보다 컨텍스트 기반 단순 인터랙션+모션 피드백 강화 경향.
2. 알케미류는 "발견/도감/힐끗 가능한 힌트"가 잔존율 핵심이며 외부 공략 의존이 높음.
3. 자유 배치 캔버스 UX는 드래그 판정, 충돌 완화, 시각 피드백(카운트다운/합성불가 표식)이 품질 핵심.
4. 아트 파이프라인은 런타임 생성보다 사전 제작+레이어 합성이 유지보수/비용 측면에서 유리.
5. 무료 소스는 라이선스 혼합 이슈가 크므로 에셋 메타(출처/라이선스/상업이용 여부) 레지스트리 필수.

## 리서치 하이라이트(실제 fetch 확인)
- https://fluent2.microsoft.design/ — component systems + figma plugin resources
- https://play.google.com/store/apps/details?id=com.recloak.littlealchemy2 — market fit signals + reviews
- https://lottiefiles.com — motion pipeline and runtimes
- https://opengameart.org — free asset ecosystem and licensing caution
- https://m.blog.naver.com/dpslzkfmsk/222640867935 — KR guide demand pattern for recipes

## 카테고리별 수량
- `alchemy`: 14
- `assets`: 20
- `behance-query`: 40
- `dribbble-query`: 60
- `figma-community-query`: 80
- `github-query`: 30
- `official`: 20

## 대규모 아트 확립 마일스톤 (기획)
### A0. 아트/라이선스 레지스트리 구축
- 목적: 소스 혼입/저작권 리스크 제거
- 산출물: asset_registry.csv (name/source/license/commercial_use/attribution)
### A1. UI 방향 확정
- 목적: 홈/시간/가챠/도감/대규모합성 5페이지 일관성 확보
- 산출물: 와이어+컴포넌트 토큰(색/타입/간격/모션 2단계)
### A2. 원소 비주얼 시스템
- 목적: 6등급(일반~신화) 시각 규칙 통일
- 산출물: 원소 베이스 아이콘 + 등급 오버레이 + 상태 FX
### A3. 인터랙션/모션 시스템
- 목적: 2초 합성 홀드/합성불가/X/쓰레기통 삭제 피드백 표준화
- 산출물: 모션 스펙 + Lottie/스프라이트 세트
### A4. 콘텐츠 팩 생산
- 목적: 레시피 1차(핵심), 2차(확장), 대규모 합성(신화 루프) 확장
- 산출물: recipes_v1/v2, mega_recipes_v1, codex text pack
### A5. 게임-아트 통합 QA
- 목적: 시인성/판정/성능/접근성 문제 제거
- 산출물: device QA matrix + perf budget + fix backlog
### A6. 베타 아트락(Art Lock)
- 목적: 베타 빌드 안정화, 후속 시즌형 확장 준비
- 산출물: art lock 태그, 변경관리 규칙, 시즌팩 템플릿

## 실행용 스크립트/소스
- 리서치 인벤토리 JSON: `mobile-suite/docs/app-one-design-research-200plus-2026-03-05.json`
- 본 요약 문서: `mobile-suite/docs/app-one-design-research-200plus-2026-03-05.md`
- 다음 단계: 상위 40개 소스 심화 분석 자동화 스크립트 생성 예정
