# Channel Persona Overrides

이 폴더는 채널별 페르소나 오버라이드를 저장합니다.

- 파일명 규칙: `channel-<channel>.md`
- 예시: `channel-discord.md`, `channel-telegram.md`, `channel-whatsapp.md`

로딩 우선순위:
1. `PERSONA_ELEGG_GLOBAL.md` (글로벌 기본)
2. `persona/channel-<channel>.md` (채널별 덮어쓰기)

권장 사용:
- 글로벌 규칙은 최대한 공통으로 유지
- 채널별 파일에는 차이점만 작성
