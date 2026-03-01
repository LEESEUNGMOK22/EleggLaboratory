# OpenClaw + 바이브 코딩 딥리서치 (2026-03-02)

## 리서치 목표
요청사항: OpenClaw/바이브 코딩으로 개발할 때의 **제한사항**, **실전 예시**, **결과물 유형**, **운영 가이드**를 깊게 조사해 문서화.

---

## 조사 범위와 방법

### 1) 1차 근거(우선)
- OpenClaw 로컬 공식 문서(`~/.npm-global/lib/node_modules/openclaw/docs`) 중심
- 핵심 문서:
  - `tools/index.md`, `tools/exec.md`, `tools/exec-approvals.md`, `tools/subagents.md`, `tools/acp-agents.md`
  - `concepts/multi-agent.md`, `concepts/agent-workspace.md`
  - `gateway/security/index.md`, `gateway/sandboxing.md`
  - `tools/web.md`

### 2) 2차 근거(보조)
- 웹 문서 직접 fetch
  - OpenClaw docs 사이트/깃허브
  - 바이브 코딩 배경: Wikipedia(Vibe coding), Simon Willison LLM/agentic engineering 관련 공개 글 목록

### 3) 주의점
- 웹 검색 API(Brave key) 미설정으로 `web_search`는 불가.
- 따라서 공식 URL 직접 fetch 방식으로 보완.

---

## A. OpenClaw 개발 모델 핵심 정리

### A-1. OpenClaw는 "메신저+도구 게이트웨이" 모델
- 한 게이트웨이가 메시지 채널(Discord/Telegram/WhatsApp 등)과 도구(exec/read/write/browser/nodes 등)를 연결.
- 개발 생산성은 높지만, 곧바로 **운영권한(파일/명령/브라우저)**과 연결되므로 권한 설계가 필수.

### A-2. 도구 제한은 정책 중심
- `tools.profile`(`minimal/coding/messaging/full`) + `allow/deny` + provider별 제한 조합.
- 의미: "모델이 똑똑한지"보다 "무슨 도구를 호출할 수 있는지"가 실제 위험/성능을 좌우.

### A-3. Exec는 강력하지만 승인 체계가 핵심
- `exec`는 foreground/background/pty 지원으로 실제 개발 자동화에 매우 강함.
- 대신 `security(deny/allowlist/full)`, `ask(off/on-miss/always)`, host target(sandbox/gateway/node) 조합을 잘못 잡으면 위험.
- 승인 체계(`exec-approvals.json`)는 실수 방지 장치이지 멀티테넌트 보안 경계 자체는 아님.

### A-4. Subagent vs ACP 구분
- `subagent`: OpenClaw 내부 delegated run(빠른 병렬 작업/리서치).
- `acp`: Codex/Claude Code/Gemini CLI 같은 외부 하네스 런타임 연결.
- 실무적으로는 “간단 분업=subagent / 하네스 기반 코딩 세션=acp”가 명확한 경계.

---

## B. 제한사항(실무 관점)

### B-1. 기술적 제한
1. **API 키 의존성**
   - 예: web_search는 Brave API key 없으면 바로 차단.
2. **환경차 이슈**
   - 실행/GUI는 설치된 머신에서 일어나므로 원격 채팅 환경과 화면이 불일치.
3. **장기 작업 가시성**
   - 빌드/설치는 background process 관리가 필요(무한 폴링 금지).
4. **도구 권한 불일치**
   - allow/deny, sandbox, elevated 설정 불일치 시 기대와 다른 동작.

### B-2. 운영적 제한
1. **인증 병목**
   - git push, 채널 연동, plugin 설치는 대부분 사용자 인증 필요.
2. **신뢰 경계 모델**
   - OpenClaw는 기본적으로 개인/단일 신뢰 경계 모델.
   - 적대적 다중 사용자 공유 환경에는 분리 운영(게이트웨이/호스트 분리) 권장.
3. **비밀정보 관리**
   - 토큰/키가 대화나 로그로 노출되기 쉬움.

### B-3. 품질 제한(바이브 코딩 공통)
1. 코드 이해도 저하(black-box화)
2. 유지보수성/테스트 부채 증가
3. 보안 결함·예외 처리 누락 확률 증가

---

## C. 바이브 코딩: 장단점과 안전한 사용선

### C-1. 장점
- 아이디어→작동 프로토타입 속도 매우 빠름
- 반복 개선(프롬프트-수정-실행)이 쉬움
- 소규모 앱/자동화/사내툴 MVP에 강함

### C-2. 단점
- “동작은 하지만 이해는 부족한” 상태가 누적됨
- 리팩터링/확장 시 인지 부채(cognitive debt) 급증
- 개발자 책임(검증/보안/장기 유지보수)이 AI에게 대체되지 않음

### C-3. 권장 사용선
- 적합: 프로토타입, 내부 툴, 개인 생산성 앱, 실험 기능
- 주의: 결제/개인정보/인증 핵심 경로, 장기 서비스 코어 로직

---

## D. 실전 워크플로우 템플릿 (OpenClaw + 바이브 코딩)

### 단계 1) 환경 검증
- 설치 확인(언어/SDK/빌드툴)
- 누락 항목 설치
- `doctor`류 명령으로 최종 상태 체크

### 단계 2) 시작점 확보
- 과도하게 큰 저장소보다 작고 명확한 샘플/템플릿 선택
- 첫 목표는 "기능 1개 + 테스트 통과"

### 단계 3) 변경 단위 최소화
- 기능을 1~2개 단위로만 추가
- 매 단계마다 analyze/test/run

### 단계 4) 실행 증거 남기기
- 실행 로그/테스트 결과를 파일로 요약
- GUI 확인 어려우면 VM service/devtools 로그로 대체 확인

### 단계 5) Git 운영
- user.name/email 선설정
- 커밋 메시지에 “무엇+왜”
- 인증 문제는 사전 준비(gh/PAT)

### 단계 6) 보안 점검
- 민감 정보 제거
- 도구 권한 최소화
- 필요 시 sandbox + allowlist

---

## E. 결과물 형태(권장)

### E-1. 최소 산출물
1. 리서치/설계 문서(md)
2. 구조화 요약(json)
3. 실행/테스트 증거(log 또는 report)
4. 재현 커맨드 목록

### E-2. 운영 문서 세트
- `implementation-notes.md`
- `test-report.md`
- `risk-register.md`
- `runbook.md`

---

## F. 위험 시나리오와 대응

### F-1. 대표 위험
1. 공개/그룹 채널에서 과도한 도구 권한 노출
2. prompt injection으로 도구 호출 유도
3. 토큰/자격증명 채팅 노출
4. host exec 무분별 허용

### F-2. 실무 대응
1. 기본 프로필 최소화(`messaging`/`minimal` 출발)
2. 고위험 도구 deny(필요 시만 임시 허용)
3. sandbox 활성화 + workspace 접근 제한
4. DM/그룹 정책(allowlist/pairing/mention) 엄격 적용
5. 정기 `openclaw security audit` 실행

---

## G. OpenClaw에서 "바이브 코딩 품질" 올리는 핵심 규칙

1. **생성보다 검증이 우선**: `analyze/test/run` 누락 금지
2. **큰 요청을 작은 단계로 분해**: 변경 단위 작게
3. **근거 기반 커밋**: 로그/테스트 통과 확인 후 커밋
4. **권한 최소화**: 필요한 순간만 확대, 끝나면 원복
5. **문서 동기화**: 리서치 결과를 md/json으로 남겨 재사용 가능하게

---

## H. 심화 권장 과제 (다음 단계)

1. 리서치 문서를 팀용 SOP로 변환
2. 프로젝트 템플릿에 체크리스트 자동 포함
3. CI 파이프라인에 최소 품질 게이트 추가
   - lint/analyze/test
   - secrets 스캔
4. OpenClaw 에이전트별 권한 프로파일 표준화
   - personal / coding / public-support 등

---

## I. 결론

OpenClaw + 바이브 코딩은 "속도" 관점에서 매우 강력하다.
하지만 실무 품질은 자동으로 오지 않는다.

성공 패턴은 명확하다:
- 빠르게 만들고,
- 작게 검증하고,
- 권한을 좁게 유지하고,
- 증거(로그/테스트/문서)를 남기는 것.

즉, 바이브 코딩은 개발을 대체하는 방식이 아니라, **검증 중심 엔지니어링 루프를 가속하는 방식**으로 쓸 때 가장 강하다.

---

## 부록: 참고 소스

### OpenClaw 로컬 문서
- `docs/tools/index.md`
- `docs/tools/exec.md`
- `docs/tools/exec-approvals.md`
- `docs/tools/subagents.md`
- `docs/tools/acp-agents.md`
- `docs/concepts/multi-agent.md`
- `docs/concepts/agent-workspace.md`
- `docs/gateway/security/index.md`
- `docs/gateway/sandboxing.md`
- `docs/tools/web.md`

### 웹 참고(보조)
- https://docs.openclaw.ai
- https://github.com/openclaw/openclaw
- https://en.wikipedia.org/wiki/Vibe_coding
- https://simonwillison.net/tags/llms/
