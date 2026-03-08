# 콘텐츠 스키마 요약

## 이벤트 공통 필드
- id
- title
- tier: T0 / T1 / T2 / T3
- pillar: combat / exploration / social
- theme
- act / actName
- regionId / regionName
- factionIds / factionNames
- npcRefs / npcNames
- triggerTags
- summary
- logLine
- autoBehavior
- portraitMood
- maturityTags
- outcomeTags
- followupSeeds
- choiceModel
- options[]
- mustPause
- defaultTimeoutSec
- stakes

## 퀘스트 공통 필드
- id
- title
- questType
- act / actName
- issuerNpcId / issuerName
- issuerFactionId / issuerFactionName
- regionId / regionName
- hook
- objectives[]
- failureTension
- rewardSummary
- maturityTags
- followupSeeds

## NPC 공통 필드
- id
- name
- factionId / factionName
- homeRegionId / homeRegionName
- role
- classFlavor
- speciesFlavor
- background
- portraitBrief
- relationAxes
- maturityTags
- hooks

## 아이템 공통 필드
- id
- displayName
- slot
- rarity
- mechanicalTags
- summary
- portraitOverlayHint
- caution

## 장소 공통 필드
- id
- regionId
- displayName
- actRange[]
- environment
- dangerTier
- encounterTags
- summary
