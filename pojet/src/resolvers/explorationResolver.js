import { ruleResolver } from "./ruleResolver.js";

export function resolveExploration(state) {
  const passive = ruleResolver.passive({ state, ability: "WIS", proficient: true });
  const check = ruleResolver.abilityCheck({ state, ability: "WIS", dc: 12, proficient: true, advantage: passive.total >= 14 });

  const success = check.success;
  return {
    type: "exploration",
    success,
    effects: {
      questProgressDelta: success ? 14 : 7,
      actProgressDelta: success ? 6 : 3,
      suppliesDelta: -1,
      fatigueDelta: success ? 2 : 4,
      xpDelta: success ? 12 : 6,
      goldDelta: success && Math.random() < 0.3 ? 8 : 2
    },
    summary: success
      ? "탐험 경로를 안정적으로 확보했다."
      : "탐험 중 우회가 늘어나 진척이 느려졌다."
  };
}
