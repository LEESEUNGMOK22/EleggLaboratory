import { CLASS_AI, DEFAULT_CLASS_AI, GEAR_POOL } from "../config/runtimeData.js";
import { ruleResolver } from "./ruleResolver.js";

export function resolveCombat(state) {
  const ai = CLASS_AI[state.character.classId] || DEFAULT_CLASS_AI;
  const enemy = pick(["재사냥꾼", "폐허 도적", "균열 짐승", "타락 추종자", "검은 경비병"]);

  let dealt = 0;
  let taken = 0;
  const rounds = rand(2, 4);

  for (let i = 0; i < rounds; i += 1) {
    const dc = 12 + Math.floor(state.world.act / 2);
    const primaryAbility = inferCombatAbility(state.character.classId);
    const atk = ruleResolver.abilityCheck({ state, ability: primaryAbility, dc, proficient: true, advantage: ai.riskTolerance > 0.65 && Math.random() < 0.25 });

    if (atk.success) {
      dealt += rand(4, 9) + Math.max(1, Math.floor(state.character.level / 2));
    } else if (Math.random() < 0.15) {
      const save = ruleResolver.save({ state, ability: "DEX", dc: 13, proficient: false });
      if (!save.success) taken += rand(2, 5);
    }

    if (Math.random() < 0.55) taken += rand(1, 6);
  }

  const victory = dealt >= rand(10, 22);
  const effects = {
    hpDelta: -(taken + (victory ? 0 : rand(2, 6))),
    fatigueDelta: victory ? 4 : 8,
    xpDelta: victory ? rand(18, 36) : 8,
    goldDelta: victory ? rand(8, 16) : rand(1, 4),
    renownDelta: victory ? 1 : 0,
    taintDelta: !victory && Math.random() < 0.2 ? 1 : 0,
    gearDrop: victory && Math.random() < 0.25 ? pick(GEAR_POOL) : null
  };

  return {
    type: "combat",
    enemy,
    rounds,
    victory,
    dealt,
    taken,
    effects,
    summary: victory
      ? `${enemy}을(를) 자동 전투로 제압했다.`
      : `${enemy}와의 충돌에서 밀려 후퇴했다.`
  };
}

function inferCombatAbility(classId) {
  if (["wizard"].includes(classId)) return "INT";
  if (["cleric", "druid", "ranger", "monk"].includes(classId)) return "WIS";
  if (["bard", "sorcerer", "warlock", "paladin"].includes(classId)) return "CHA";
  if (["rogue", "ranger", "monk"].includes(classId)) return "DEX";
  return "STR";
}

function rand(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function pick(arr) { return arr[rand(0, arr.length - 1)]; }
