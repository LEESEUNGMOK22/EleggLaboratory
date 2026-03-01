# Resource Usage Recommendations (Android Multi-App)

업로드된 공용 리소스를 분석해서, 앱에서 어디에 어떻게 쓰면 좋은지 추천한 문서.

## 1) 분석 요약

- 분석 기준 파일: `mobile-suite/common/**`
- 총 파일 수: **7,316개**
- Android 리소스 네이밍 비권장(파일명 기준) 추정: **3,131개**
- 정규화 후보(드라이런 기준): **1,705개**
- 분석 원본: `mobile-suite/docs/asset-analysis.json`
- 네이밍 정규화 미리보기: `mobile-suite/docs/normalize-preview.txt`

---

## 2) 어떤 리소스를 어디에 쓰면 좋은가

### A. `kenney_ui-pack` (SVG 중심)
**추천 용도**
- 버튼/체크박스/슬라이더/방향 화살표 등 기본 UI 컴포넌트 스킨
- 앱 공통 디자인 시스템의 “테마 베이스”

**추천 위치**
- 원본 보관: `mobile-suite/common/kenney_ui-pack/...`
- 앱 사용본 추출: `apps/<app>/assets/ui/` (필요 subset만)

**실무 팁**
- 앱별로 전량 포함하지 말고, 실제 사용하는 SVG만 추려서 번들 크기 절감
- 컬러 variation은 디자인 토큰으로 통일해 에셋 분기 수 줄이기

---

### B. `kenney_voiceover-pack`, `kenney_voiceover-pack-fighter`, `kenney_*audio*`
**추천 용도**
- 온보딩 음성 안내, 게임/인터랙션 피드백, 상태 알림 사운드

**추천 위치**
- 공용 저장: `mobile-suite/common/sounds/` 또는 현재 pack 폴더 유지
- 앱별 복사본: `apps/<app>/assets/audio/`

**실무 팁**
- UX 알림/효과음은 짧은 파일 우선 사용
- 앱 초기 로딩에 전부 preload 하지 말고, 필요한 시점에 lazy-load
- 중복 파일명 충돌 방지를 위해 prefix 규칙 적용(예: `fighter_round_1.ogg`)

---

### C. 폰트 (`CHOGOONChickenScratch...` 포함)
**추천 용도**
- 브랜드 타이틀용 강조 폰트 (본문 폰트로는 가독성 검증 필요)

**추천 위치**
- `mobile-suite/common/fonts/<family>/...`

**실무 팁**
- 본문 텍스트용 폰트와 타이틀 폰트 분리
- 다국어 지원 시 fallback 폰트 체계 함께 설계
- 폰트 파일명은 Android/Flutter 친화 스네이크 케이스 추천

---

### D. 기타 이미지/샘플/프리뷰 파일
**추천 용도**
- 개발/디자인 참고용 문서성 리소스

**실무 팁**
- `preview`, `sample`, `license` 류 파일은 앱 번들에 그대로 넣지 않는 게 일반적
- 실제 런타임 사용하는 파일만 별도 앱 에셋 폴더로 큐레이션

---

## 3) Android 앱 기준 권장 규칙

1. 파일명 규칙
- 소문자 + 숫자 + 언더스코어 (`[a-z0-9_]+`)
- 공백/대문자/괄호 제거

2. 디렉터리 규칙
- 공용 원본: `common/`
- 앱 사용본: `apps/<app>/assets/...`
- “원본 대용량”과 “실사용 경량” 분리

3. 용량 최적화
- PNG는 필요 시 WebP 변환
- 벡터 가능한 것은 SVG/Vector 우선
- 사운드는 사용 빈도에 따라 preload vs lazy-load 분기

4. 라이선스
- pack 단위 `License.txt`, `Credits.txt`는 공용 폴더에 유지
- 배포시 attribution 요구사항 체크

---

## 4) 바로 적용 가능한 작업 순서

1) 네이밍 정규화 드라이런 확인
- `mobile-suite/docs/normalize-preview.txt`

2) 정규화 실제 적용(원할 때)
- `python3 mobile-suite/scripts/normalize_android_asset_names.py --apply`

3) 앱별 사용 리소스만 선별 복사
- 예: `apps/app-one/assets/ui`, `apps/app-one/assets/audio`

4) 앱 빌드 사이즈 점검
- Flutter 사용 시 `flutter build appbundle --analyze-size`

---

## 5) 참고(검토한 외부 가이드)

- Flutter assets/images: https://docs.flutter.dev/ui/assets/assets-and-images
- Flutter app size: https://docs.flutter.dev/perf/app-size
- (일반 웹 이미지 최적화 참고) https://web.dev/articles/browser-level-image-lazy-loading

※ Android 개발 공식 문서는 리다이렉트 제한으로 직접 본문 fetch가 실패해, Flutter 공식 문서 중심으로 실무 지침을 보강함.
