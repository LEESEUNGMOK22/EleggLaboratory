import { abilityModifier } from "../core/state-machine.js";

export function rollD20(advantage = false, disadvantage = false) {
  const a = d20();
  const b = d20();
  if (advantage && !disadvantage) return Math.max(a, b);
  if (disadvantage && !advantage) return Math.min(a, b);
  return a;
}

export function resolveAbilityCheck({ state, ability, dc, proficient = false, advantage = false, disadvantage = false, situational = 0 }) {
  const mod = abilityModifier(state.character.abilities[ability] || 10);
  const prof = proficient ? state.character.proficiencyBonus : 0;
  const fatiguePenalty = Math.floor(state.resources.fatigue / 20);
  const renownBonus = ability === "CHA" ? Math.floor(state.resources.renown / 15) : 0;
  const roll = rollD20(advantage, disadvantage);
  const total = roll + mod + prof + situational + renownBonus - fatiguePenalty;
  return { roll, total, dc, success: total >= dc, detail: { mod, prof, situational, fatiguePenalty, renownBonus } };
}

export function resolveSave({ state, ability, dc, proficient = false, advantage = false, disadvantage = false, situational = 0 }) {
  const mod = abilityModifier(state.character.abilities[ability] || 10);
  const prof = proficient ? state.character.proficiencyBonus : 0;
  const taintPenalty = state.resources.taint >= 70 ? 2 : state.resources.taint >= 40 ? 1 : 0;
  const roll = rollD20(advantage, disadvantage);
  const total = roll + mod + prof + situational - taintPenalty;
  return { roll, total, dc, success: total >= dc, detail: { mod, prof, situational, taintPenalty } };
}

export function resolvePassive({ state, ability, proficient = false, situational = 0 }) {
  const mod = abilityModifier(state.character.abilities[ability] || 10);
  const prof = proficient ? state.character.proficiencyBonus : 0;
  const total = 10 + mod + prof + situational;
  return { total, detail: { mod, prof, situational } };
}

export function resolveContested({ left, right }) {
  if (left.total === right.total) return { winner: "tie", left, right };
  return { winner: left.total > right.total ? "left" : "right", left, right };
}

function d20() {
  return Math.floor(Math.random() * 20) + 1;
}
