import { ruleResolver } from "./ruleResolver.js";

export function resolveSocial(state) {
  const check = ruleResolver.abilityCheck({ state, ability: "CHA", dc: 13, proficient: true, disadvantage: state.resources.taint >= 50 });
  const success = check.success;

  return {
    type: "social",
    success,
    effects: {
      renownDelta: success ? 2 : -1,
      relationDelta: success ? { trust: 2, respect: 2 } : { tension: 2, fear: 1 },
      factionDelta: success ? { guild: 1 } : { nobility: -1 },
      xpDelta: success ? 10 : 5
    },
    summary: success
      ? "협상에서 우호적 합의를 끌어냈다."
      : "사회적 마찰이 남아 평판이 흔들렸다."
  };
}
