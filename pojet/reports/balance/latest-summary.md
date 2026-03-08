# Balance Summary

- Generated: 2026-03-08T17:38:25.147470Z
- Seed: 441901
- Total runs: 1440 (runs/class=120)

## Pacing Snapshot
- avg log interval: 1.00 ticks / 15.72 sec
- avg combat frequency: 16.84 per run
- avg quest updates: 0.97 per run
- avg T2 cycle: 13.21 ticks
- avg T3 cycle: 46.91 ticks
- avg first level-up: 9.53 minutes
- avg run duration: 12.83 minutes

## Strong/Weak Classes
- strongest survival: bard (0.03)
- weakest survival: wizard (0.00)
- highest growth: cleric (lvl 2.55)
- lowest growth: sorcerer (lvl 1.77)

## Preset Risk Scan
- safest preset by survival: 자비형 (0.01)
- riskiest preset by survival: 관계중시형 (0.00)
- highest taint preset: 권력지향형 (14.86)

## Target Check
- WARN t3IntervalTicks: actual=46.91, target=18.00-40.00
- WARN combatShare: actual=0.28, target=0.28-0.50
- WARN runDurationMinutes: actual=12.83, target=18.00-55.00

## Required Diagnoses
- early-20m empty combinations: barbarian, druid, fighter, monk, paladin, ranger
- T2/T3 target fit: warn
- relationship/social exposure: social=0.18, relationship=0.19
- legacy reward trend(avg delta): 0.31
- early death rate: 0.31
- first T3 mean minute: 26.34

## Top 10 Tuning Candidates
1. 저생존 클래스 보정: wizard (survival 0.00)
2. 고생존 클래스 하향 검토: bard (survival 0.03)
3. 함정 프리셋 점검: 관계중시형 (survival 0.00)
4. 오염 과다 프리셋 완화: 권력지향형 (taint 14.86)
5. 목표 이탈 지표 보정: t3IntervalTicks actual=46.91 target=18.00-40.00
6. 목표 이탈 지표 보정: combatShare actual=0.28 target=0.28-0.50
7. 목표 이탈 지표 보정: runDurationMinutes actual=12.83 target=18.00-55.00
8. 사회 이벤트 노출 증량 (social share 낮음)
9. 이벤트 텍스트 변주율 상향 (중복 방지)
10. 이벤트 텍스트 변주율 상향 (중복 방지)

## Content Validation Warnings
- Relationship event missing relation effect: evt-t1-001
- Relationship event missing relation effect: evt-t1-007
- Relationship event missing relation effect: evt-t1-013
- Relationship event missing relation effect: evt-t1-019
- Relationship event missing relation effect: evt-t1-025
- Relationship event missing relation effect: evt-t1-031
- Relationship event missing relation effect: evt-t1-037
- Relationship event missing relation effect: evt-t1-043
- Relationship event missing relation effect: evt-t1-049
- Relationship event missing relation effect: evt-t1-055
- Relationship event missing relation effect: evt-t1-061
- T0 duplicate narrative ratio high: 0.63
- T1 duplicate narrative ratio high: 0.53

## First Adjustment Record
- Before tune (same seed baseline):
  - earlyDeathRate: 0.71
  - avgRunDurationMinutes: 0.31
  - relationshipEventShare: 0.02
- After tune:
  - earlyDeathRate: 0.31
  - avgRunDurationMinutes: 12.83
  - relationshipEventShare: 0.19
