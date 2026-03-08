export const ABILITIES = ["STR", "DEX", "CON", "INT", "WIS", "CHA"];

export const CLASS_IDS = [
  "barbarian", "bard", "cleric", "druid", "fighter", "monk", "paladin", "ranger", "rogue", "sorcerer", "warlock", "wizard"
];

export const CLASS_LABELS_KO = {
  barbarian: "바바리안", bard: "바드", cleric: "클레릭", druid: "드루이드", fighter: "파이터", monk: "몽크",
  paladin: "팔라딘", ranger: "레인저", rogue: "로그", sorcerer: "소서러", warlock: "워락", wizard: "위저드"
};

export const LINEAGES = ["draconic", "stonefolk", "longkin", "smallkin", "mixed-grace", "mixed-fury", "smallfoot", "human", "infernal"];

export const LINEAGE_LABELS_KO = {
  draconic: "용혈족",
  stonefolk: "석민족",
  longkin: "장귀인",
  smallkin: "소인 기공족",
  "mixed-grace": "혼혈(은총)",
  "mixed-fury": "혼혈(격노)",
  smallfoot: "소족",
  human: "인간",
  infernal: "지옥혈통"
};

export const BACKGROUNDS = [
  "border-conscript", "crusade-runner", "orphan-cutpurse", "tower-dropout", "funeral-aide",
  "fallen-bastard", "caravan-guard", "smuggler-runner", "forest-watch", "relic-digger"
];

export const BACKGROUND_LABELS_KO = {
  "border-conscript": "변경의 징집병",
  "crusade-runner": "성전의 잔심부름꾼",
  "orphan-cutpurse": "고아원 출신 소매치기",
  "tower-dropout": "유리탑 낙오 견습생",
  "funeral-aide": "장송 의식 도우미",
  "fallen-bastard": "몰락 귀족의 사생아",
  "caravan-guard": "대상단 경비",
  "smuggler-runner": "밀수업자 심부름꾼",
  "forest-watch": "숲 경계 감시자",
  "relic-digger": "유물 발굴 인부"
};

export const DECISION_PRESETS = {
  "신중형": { t2DefaultChoice: "safest", resourceUse: 0.35, riskTolerance: 0.3, reputationVsReward: 0.7, combatConservation: 0.8, relationshipTone: "calm", forbiddenPowerBias: 0.1 },
  "대담형": { t2DefaultChoice: "bold", resourceUse: 0.65, riskTolerance: 0.75, reputationVsReward: 0.45, combatConservation: 0.35, relationshipTone: "direct", forbiddenPowerBias: 0.5 },
  "탐욕형": { t2DefaultChoice: "profit", resourceUse: 0.55, riskTolerance: 0.6, reputationVsReward: 0.15, combatConservation: 0.5, relationshipTone: "transactional", forbiddenPowerBias: 0.65 },
  "자비형": { t2DefaultChoice: "mercy", resourceUse: 0.6, riskTolerance: 0.4, reputationVsReward: 0.8, combatConservation: 0.55, relationshipTone: "empathetic", forbiddenPowerBias: 0.2 },
  "권력지향형": { t2DefaultChoice: "dominance", resourceUse: 0.7, riskTolerance: 0.7, reputationVsReward: 0.35, combatConservation: 0.3, relationshipTone: "assertive", forbiddenPowerBias: 0.8 },
  "관계중시형": { t2DefaultChoice: "bond", resourceUse: 0.5, riskTolerance: 0.45, reputationVsReward: 0.75, combatConservation: 0.6, relationshipTone: "warm", forbiddenPowerBias: 0.25 },
  "신앙중시형": { t2DefaultChoice: "oath", resourceUse: 0.45, riskTolerance: 0.35, reputationVsReward: 0.7, combatConservation: 0.7, relationshipTone: "principled", forbiddenPowerBias: 0.15 }
};

export const CLASS_AI = {
  fighter: { combatStyle: "stable_frontline", riskTolerance: 0.55, openerPriority: ["mark_target", "basic_combo"], sustainPriority: ["guard", "consistent_attack"], finisherPriority: ["weapon_burst", "execute"], supportBehavior: "low_medium", resourceConservation: 0.7, preferredTargets: ["frontline", "boss"], favoredChecks: ["athletics", "intimidation", "perception"], narrativeBias: ["order", "discipline"], recommendedPlayerDecisionBias: "신중형" },
  rogue: { combatStyle: "opportunity_burst", riskTolerance: 0.7, openerPriority: ["stealth_open", "advantage_strike"], sustainPriority: ["reposition", "burst_when_ready"], finisherPriority: ["execute", "escape"], supportBehavior: "low", resourceConservation: 0.6, preferredTargets: ["isolated", "backline"], favoredChecks: ["stealth", "deception", "sleight_of_hand"], narrativeBias: ["opportunism", "survival"], recommendedPlayerDecisionBias: "탐욕형" },
  wizard: { combatStyle: "control_caster", riskTolerance: 0.4, openerPriority: ["control", "aoe_setup"], sustainPriority: ["resource_managed_cast", "defensive_cast"], finisherPriority: ["precision_finish", "safe_cleanup"], supportBehavior: "medium", resourceConservation: 0.75, preferredTargets: ["cluster", "caster"], favoredChecks: ["arcana", "investigation", "history"], narrativeBias: ["knowledge", "restraint"], recommendedPlayerDecisionBias: "신중형" },
  warlock: { combatStyle: "sustained_pressure", riskTolerance: 0.65, openerPriority: ["curse", "pressure_beam"], sustainPriority: ["consistent_spell", "control"], finisherPriority: ["contract_burst", "drain"], supportBehavior: "low_medium", resourceConservation: 0.5, preferredTargets: ["high_value", "weakened"], favoredChecks: ["deception", "arcana", "intimidation"], narrativeBias: ["pact", "ambition"], recommendedPlayerDecisionBias: "권력지향형" },
  bard: { combatStyle: "support_disrupt", riskTolerance: 0.5, openerPriority: ["buff", "debuff", "control"], sustainPriority: ["support", "chip_damage"], finisherPriority: ["assist_finisher", "control_lock"], supportBehavior: "high", resourceConservation: 0.6, preferredTargets: ["caster", "low_resolve"], favoredChecks: ["persuasion", "deception", "insight"], narrativeBias: ["relationship", "finesse"], recommendedPlayerDecisionBias: "관계중시형" }
};

export const DEFAULT_CLASS_AI = { combatStyle: "balanced", riskTolerance: 0.5, openerPriority: ["basic_attack"], sustainPriority: ["basic_attack"], finisherPriority: ["execute"], supportBehavior: "low", resourceConservation: 0.6, preferredTargets: ["frontline"], favoredChecks: ["perception"], narrativeBias: ["survival"], recommendedPlayerDecisionBias: "신중형" };

export const LOCATIONS_BY_ACT = {
  1: ["검은비 변경", "회색 수문", "묘지 외곽", "마른 숲길"],
  2: ["도시 하층", "등불 시장", "붉은 예배당", "밀수 부두"],
  3: ["봉인의 계단", "유리탑 하부", "재의 폐허", "균열 전실"],
  4: ["철의 의회", "침묵 성문", "전쟁 지휘소", "몰락 궁정"],
  5: ["계승의 전당", "무명인의 묘역", "잿빛 관문", "이름 없는 첨탑"]
};

export const QUEST_NAMES = ["굶주린 순찰", "흙벽 아래 기도", "회색 계약", "잿더미의 열쇠", "피 묻은 서약", "밤 항구의 빚", "부서진 성상", "침묵의 증인"];
export const QUEST_MOODS = ["굶주림", "죄책감", "충성", "탐욕", "광신", "슬픔", "해방"];
export const GEAR_POOL = ["마모된 쇠검", "재봉선 망토", "기도 매듭띠", "낡은 사슬갑", "검은 가죽장갑", "은실 성물", "균열 반지", "무언의 부적"];

export const SAMPLE_EVENTS = {
  t2: [
    {
      eventId: "t2-bribe-pouch",
      tier: "T2",
      category: "contract",
      title: "입막음의 봉투",
      text: "밀수 조합이 금화를 제시한다. 눈감아 주면 금화는 늘고, 명성은 흐려진다.",
      timeoutSec: 12,
      mustPause: false,
      choices: [
        { id: "take", label: "받는다", effects: [{ kind: "gain_gold", value: 45 }, { kind: "renown", value: -3 }, { kind: "taint", value: 3 }] },
        { id: "reject", label: "거절한다", effects: [{ kind: "gain_gold", value: 0 }, { kind: "renown", value: 4 }, { kind: "faction", value: { underbelly: -2, guild: 1 } }] },
        { id: "spy", label: "정보만 챙긴다", effects: [{ kind: "gain_gold", value: 12 }, { kind: "relation", value: { trust: 1, tension: 1 } }] }
      ]
    },
    {
      eventId: "t2-masked-vow",
      tier: "T2",
      category: "identity",
      title: "이름을 숨길 기회",
      text: "연회 초대장이 도착했다. 가면은 안전을 주지만 이름은 희미해진다.",
      timeoutSec: 12,
      mustPause: false,
      choices: [
        { id: "mask", label: "가면을 쓴다", effects: [{ kind: "gain_gold", value: 20 }, { kind: "renown", value: -1 }, { kind: "relation", value: { tension: 1 } }] },
        { id: "reveal", label: "본명을 밝힌다", effects: [{ kind: "renown", value: 5 }, { kind: "faction", value: { nobility: 2 } }] },
        { id: "decline", label: "초대를 찢는다", effects: [{ kind: "gain_gold", value: -5 }, { kind: "relation", value: { trust: 2 } }] }
      ]
    }
  ],
  t3: [
    {
      eventId: "t3-faction-oath",
      tier: "T3",
      category: "faction",
      title: "세력 맹세의 밤",
      text: "길드, 신전, 용병단이 동시에 손을 내민다. 어느 깃발 아래 설지 결정해야 한다.",
      mustPause: true,
      choices: [
        { id: "guild", label: "검은 길드", effects: [{ kind: "faction", value: { guild: 6, temple: -2 } }, { kind: "renown", value: 2 }] },
        { id: "temple", label: "등불 신전", effects: [{ kind: "faction", value: { temple: 6, underbelly: -1 } }, { kind: "blessing", value: 1 }] },
        { id: "mercs", label: "자유 용병단", effects: [{ kind: "faction", value: { mercenary: 6, nobility: -1 } }, { kind: "gain_gold", value: 24 }] }
      ]
    },
    {
      eventId: "t3-forbidden-relic",
      tier: "T3",
      category: "relic",
      title: "금지된 유물의 심장",
      text: "유물은 힘을 준다. 대신 당신의 꿈과 평판을 조금씩 갉아먹는다.",
      mustPause: true,
      choices: [
        { id: "use", label: "사용한다", effects: [{ kind: "taint", value: 12 }, { kind: "renown", value: 4 }, { kind: "chronicle_tag", value: "forbidden-power" }] },
        { id: "seal", label: "봉인한다", effects: [{ kind: "renown", value: 2 }, { kind: "chronicle_tag", value: "keeper-of-seal" }] },
        { id: "trade", label: "거래한다", effects: [{ kind: "gain_gold", value: 70 }, { kind: "infamy", value: 3 }] }
      ]
    }
  ]
};
