import { ABILITIES, CLASS_LABELS_KO, LINEAGE_LABELS_KO, BACKGROUND_LABELS_KO, QUEST_NAMES, QUEST_MOODS } from "../config/runtimeData.js";

export function createInitialState() {
  return {
    run: { id: `run-${Date.now()}`, status: "idle", seed: Math.floor(Math.random() * 1000000), startedAt: null, endedAt: null, causeOfEnd: null },
    character: null,
    resources: { gold: 0, supplies: 5, fatigue: 0, taint: 0, renown: 0, infamy: 0, consumables: { potion: 1, scroll: 0, kit: 1 } },
    relationships: { npcRelations: { core: { trust: 20, intimacy: 5, tension: 8, desire: 6, respect: 10, fear: 4 } }, partyMood: 50 },
    factions: { reputation: { guild: 0, temple: 0, mercenary: 0, nobility: 0, underbelly: 0 } },
    world: { act: 1, day: 1, locationId: "검은비 변경", actProgress: 0, quests: [] },
    automation: {
      decisionPresetId: "신중형",
      autoEquip: true,
      autoQuest: true,
      autoRest: true,
      autoPotion: true,
      t2Policy: "timed-auto",
      manualCategories: ["faction", "relationship", "relic", "legacy"],
      eventTypePolicies: {},
      eventResolutionOverrides: {}
    },
    chronicle: { entries: [], legacyFlags: [], inheritancePool: loadInheritance() },
    activeDecisionEvent: null,
    time: { tick: 0, speed: 1, accumulatorMs: 0, lastFrameMs: performance.now() },
    history: { logs: [], events: [], majorChoices: [], relationChanges: [], completedQuests: [] }
  };
}

export function createCharacterTemplate(overrides = {}) {
  const nowTag = Date.now().toString().slice(-4);
  return {
    name: overrides.name || `무명인-${nowTag}`,
    classId: overrides.classId || "fighter",
    lineageId: overrides.lineageId || "human",
    backgroundId: overrides.backgroundId || "border-conscript",
    abilities: overrides.abilities || { STR: 15, DEX: 13, CON: 14, INT: 10, WIS: 12, CHA: 8 },
    automationPreset: overrides.automationPreset || "신중형"
  };
}

export function buildCharacterFromTemplate(template) {
  const conMod = abilityModifier(template.abilities.CON);
  const baseHp = 10 + conMod;
  return {
    ...template,
    level: 1,
    xp: 0,
    proficiencyBonus: 2,
    maxHp: Math.max(1, baseHp),
    hp: Math.max(1, baseHp),
    ac: 12 + Math.max(0, abilityModifier(template.abilities.DEX)),
    subclass: null,
    conditions: [],
    tags: [],
    gear: ["헐거운 여행복"],
    inventory: [],
    questLog: [createQuest()]
  };
}

export function reduce(state, action) {
  const next = structuredClone(state);
  switch (action.type) {
    case "RUN_START": {
      next.run.status = "running";
      next.run.startedAt = new Date().toISOString();
      return next;
    }
    case "RUN_PAUSE": {
      next.run.status = "paused";
      return next;
    }
    case "RUN_RESUME": {
      next.run.status = "running";
      return next;
    }
    case "RUN_END": {
      next.run.status = "ended";
      next.run.endedAt = new Date().toISOString();
      next.run.causeOfEnd = action.payload?.cause || "unknown";
      return next;
    }
    case "HYDRATE_STATE": {
      const incoming = action.payload?.state;
      if (!incoming) return next;
      return incoming;
    }
    case "SET_CHARACTER": {
      next.character = action.payload.character;
      next.automation.decisionPresetId = action.payload.character.automationPreset;
      next.resources.gold = 20 + (next.chronicle.inheritancePool[0]?.boonGold || 0);
      next.resources.renown = next.chronicle.inheritancePool[0]?.boonRenown || 0;
      next.resources.taint = next.chronicle.inheritancePool[0]?.boonTaint || 0;
      next.world.quests = structuredClone(action.payload.character.questLog || []);
      next.world.day = 1;
      next.world.act = 1;
      next.world.actProgress = 0;
      return next;
    }
    case "TIME_SPEED": {
      next.time.speed = action.payload.speed;
      return next;
    }
    case "TIME_TICK": {
      next.time.tick += 1;
      if (next.time.tick % 4 === 0) next.world.day += 1;
      return next;
    }
    case "SET_ACTIVE_EVENT": {
      next.activeDecisionEvent = action.payload.event;
      return next;
    }
    case "CLEAR_ACTIVE_EVENT": {
      next.activeDecisionEvent = null;
      return next;
    }
    case "LOG": {
      next.history.logs.unshift(action.payload.log);
      if (next.history.logs.length > 240) next.history.logs.length = 240;
      return next;
    }
    case "HISTORY_EVENT": {
      next.history.events.unshift(action.payload.entry);
      if (next.history.events.length > 180) next.history.events.length = 180;
      if (action.payload.entry?.tier === "T3" || action.payload.entry?.auto === false) {
        next.history.majorChoices.unshift(action.payload.entry);
        if (next.history.majorChoices.length > 80) next.history.majorChoices.length = 80;
      }
      return next;
    }
    case "RELATION_CHANGE": {
      next.history.relationChanges.unshift(action.payload.entry);
      if (next.history.relationChanges.length > 120) next.history.relationChanges.length = 120;
      return next;
    }
    case "QUEST_COMPLETE": {
      next.history.completedQuests.unshift(action.payload.entry);
      if (next.history.completedQuests.length > 120) next.history.completedQuests.length = 120;
      return next;
    }
    case "APPLY_PATCH": {
      deepMerge(next, action.payload.patch);
      return next;
    }
    case "CHRONICLE_ENTRY": {
      next.chronicle.entries.unshift(action.payload.entry);
      next.chronicle.entries = next.chronicle.entries.slice(0, 20);
      const inheritance = {
        id: `inherit-${Date.now()}`,
        title: action.payload.entry.title,
        boonGold: action.payload.entry.boonGold,
        boonRenown: action.payload.entry.boonRenown,
        boonTaint: action.payload.entry.boonTaint
      };
      next.chronicle.inheritancePool.unshift(inheritance);
      next.chronicle.inheritancePool = next.chronicle.inheritancePool.slice(0, 12);
      saveInheritance(next.chronicle.inheritancePool);
      return next;
    }
    default:
      return next;
  }
}

export function questLabel(quest) {
  return `${quest.name} (${quest.progress}%) - ${quest.mood}`;
}

export function describeCharacter(character) {
  if (!character) return "아직 이름 없는 자";
  return `${character.name} | ${LINEAGE_LABELS_KO[character.lineageId] || character.lineageId} ${CLASS_LABELS_KO[character.classId] || character.classId} | ${BACKGROUND_LABELS_KO[character.backgroundId] || character.backgroundId}`;
}

export function createQuest() {
  return {
    id: `quest-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
    name: QUEST_NAMES[Math.floor(Math.random() * QUEST_NAMES.length)],
    mood: QUEST_MOODS[Math.floor(Math.random() * QUEST_MOODS.length)],
    progress: Math.floor(Math.random() * 20),
    stage: "active",
    state: "ongoing"
  };
}

export function abilityModifier(score) {
  return Math.floor((score - 10) / 2);
}

function deepMerge(target, patch) {
  Object.entries(patch).forEach(([k, v]) => {
    if (v && typeof v === "object" && !Array.isArray(v)) {
      target[k] = target[k] || {};
      deepMerge(target[k], v);
      return;
    }
    target[k] = v;
  });
}

function loadInheritance() {
  try { return JSON.parse(localStorage.getItem("ashmark.inheritance") || "[]"); } catch { return []; }
}

function saveInheritance(entries) {
  localStorage.setItem("ashmark.inheritance", JSON.stringify(entries));
}

export const GAME_STATE_KEYS = ["run", "character", "resources", "relationships", "factions", "world", "automation", "chronicle", "activeDecisionEvent", "time", "history", ...ABILITIES];
