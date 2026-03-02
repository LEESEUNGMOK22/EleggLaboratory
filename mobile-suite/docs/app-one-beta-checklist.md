# App One Beta Checklist

릴리즈 직전 점검 체크리스트.

## 기능
- [ ] 소환/머지/변성 코어 루프 정상
- [ ] 소환권 충전 + cap 정상
- [ ] 오프라인 정산 팝업 + 상세 그룹 표기 정상
- [ ] 업그레이드 구매/게이트 조건 정상
- [ ] 튜토리얼 5단계 완료 가능

## UX
- [ ] 로그북 필터/검색/정렬 동작
- [ ] 업그레이드 카테고리 섹션 가독성
- [ ] 보드 확장 가능/최대 상태 표기
- [ ] AutoTap/Burst 상태 HUD 표시

## 데이터/저장
- [ ] 앱 종료/재실행 시 상태 복원
- [ ] 로그 필터/검색 상태 복원
- [ ] 튜토리얼 보상 중복 지급 없음

## QA 명령
```bash
flutter analyze
flutter test
flutter run -d linux
```

## 베타 메모
- 광고 BM은 후순위. 코어 체감/리텐션 먼저 검증.
- 수치 튜닝은 `assets/config/balance_preset.json` 우선 변경.
