import { createQuest } from "../core/state-machine.js";

export function applyResolutionEffects(state, resolution) {
  const patch = {
    character: {},
    resources: {},
    world: {},
    relationships: { npcRelations: { core: {} } },
    factions: { reputation: {} }
  };

  const c = state.character;
  const e = resolution.effects || {};

  if (typeof e.hpDelta === "number") patch.character.hp = clamp(c.hp + e.hpDelta, 0, c.maxHp);
  if (typeof e.xpDelta === "number") patch.character.xp = c.xp + e.xpDelta;
  if (typeof e.goldDelta === "number") patch.resources.gold = Math.max(0, state.resources.gold + e.goldDelta);
  if (typeof e.suppliesDelta === "number") patch.resources.supplies = Math.max(0, state.resources.supplies + e.suppliesDelta);
  if (typeof e.fatigueDelta === "number") patch.resources.fatigue = clamp(state.resources.fatigue + e.fatigueDelta, 0, 100);
  if (typeof e.taintDelta === "number") patch.resources.taint = clamp(state.resources.taint + e.taintDelta, 0, 100);
  if (typeof e.renownDelta === "number") patch.resources.renown = Math.max(-100, state.resources.renown + e.renownDelta);
  if (typeof e.infamyDelta === "number") patch.resources.infamy = Math.max(0, state.resources.infamy + e.infamyDelta);

  if (typeof e.actProgressDelta === "number") patch.world.actProgress = clamp(state.world.actProgress + e.actProgressDelta, 0, 140);

  if (typeof e.questProgressDelta === "number") {
    const quests = structuredClone(state.world.quests);
    if (!quests.length) quests.push(createQuest());
    quests[0].progress += e.questProgressDelta;
    if (quests[0].progress >= 100) {
      quests[0].progress = 100;
      quests[0].state = "completed";
      quests.unshift(createQuest());
    }
    patch.world.quests = quests.slice(0, 3);
  }

  if (e.relationDelta) {
    Object.entries(e.relationDelta).forEach(([k, v]) => {
      const cur = state.relationships.npcRelations.core[k] || 0;
      patch.relationships.npcRelations.core[k] = clamp(cur + v, 0, 100);
    });
  }

  if (e.factionDelta) {
    Object.entries(e.factionDelta).forEach(([k, v]) => {
      const cur = state.factions.reputation[k] || 0;
      patch.factions.reputation[k] = clamp(cur + v, -100, 100);
    });
  }

  if (e.gearDrop && state.automation.autoEquip) {
    patch.character.gear = [e.gearDrop, ...state.character.gear].slice(0, 6);
  }

  return patch;
}

export function applyEventChoiceEffects(state, choice, defaultEventEffects = []) {
  const patch = { character: {}, resources: {}, relationships: { npcRelations: { core: {} } }, factions: { reputation: {} }, chronicle: {} };
  const effects = [...defaultEventEffects, ...(choice.effects || [])];

  effects.forEach((fx) => {
    switch (fx.kind) {
      case "gain_gold":
        patch.resources.gold = Math.max(0, (patch.resources.gold ?? state.resources.gold) + fx.value);
        break;
      case "renown":
        patch.resources.renown = (patch.resources.renown ?? state.resources.renown) + fx.value;
        break;
      case "infamy":
        patch.resources.infamy = (patch.resources.infamy ?? state.resources.infamy) + fx.value;
        break;
      case "taint":
        patch.resources.taint = clamp((patch.resources.taint ?? state.resources.taint) + fx.value, 0, 100);
        break;
      case "faction":
        Object.entries(fx.value).forEach(([k, v]) => {
          const cur = patch.factions.reputation[k] ?? state.factions.reputation[k] ?? 0;
          patch.factions.reputation[k] = clamp(cur + v, -100, 100);
        });
        break;
      case "relation":
        Object.entries(fx.value).forEach(([k, v]) => {
          const cur = patch.relationships.npcRelations.core[k] ?? state.relationships.npcRelations.core[k] ?? 0;
          patch.relationships.npcRelations.core[k] = clamp(cur + v, 0, 100);
        });
        break;
      case "chronicle_tag": {
        const tags = new Set(state.character.tags || []);
        tags.add(fx.value);
        patch.character.tags = [...tags];
        break;
      }
      case "blessing": {
        const tags = new Set(state.character.tags || []);
        tags.add("blessed");
        patch.character.tags = [...tags];
        break;
      }
      default:
        break;
    }
  });

  return patch;
}

export function maybeLevelUp(state) {
  const need = state.character.level * 100;
  if (state.character.xp < need) return null;
  const newLevel = state.character.level + 1;
  return {
    character: {
      level: newLevel,
      xp: state.character.xp - need,
      proficiencyBonus: 2 + Math.floor((newLevel - 1) / 4),
      maxHp: state.character.maxHp + rand(4, 8),
      hp: state.character.maxHp + rand(4, 8)
    },
    resources: { renown: state.resources.renown + 2 }
  };
}

function clamp(n, min, max) { return Math.max(min, Math.min(max, n)); }
function rand(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
