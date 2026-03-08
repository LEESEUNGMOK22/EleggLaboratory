import { resolveAbilityCheck, resolveSave, resolvePassive, resolveContested } from "./checkResolver.js";

export const ruleResolver = {
  abilityCheck: resolveAbilityCheck,
  save: resolveSave,
  passive: resolvePassive,
  contested: resolveContested
};
