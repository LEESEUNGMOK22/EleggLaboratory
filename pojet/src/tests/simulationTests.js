import { createStore } from "../core/store.js";
import { createCharacterTemplate, buildCharacterFromTemplate } from "../core/state-machine.js";
import { ruleResolver } from "../resolvers/ruleResolver.js";
import { CLASS_AI, DECISION_PRESETS } from "../config/runtimeData.js";
import { shouldForcePause } from "../events/eventDispatcher.js";

export function runSimulationTests() {
  const results = [];
  const store = createStore();
  const character = buildCharacterFromTemplate(createCharacterTemplate({ classId: "fighter" }));
  store.dispatch({ type: "SET_CHARACTER", payload: { character } });
  store.dispatch({ type: "RUN_START" });

  const state = store.getState();

  const chk = ruleResolver.abilityCheck({ state, ability: "STR", dc: 10, proficient: true });
  results.push({ name: "ability check 계산", pass: typeof chk.total === "number" && typeof chk.success === "boolean" });

  const save = ruleResolver.save({ state, ability: "CON", dc: 12, proficient: false });
  results.push({ name: "save 계산", pass: typeof save.total === "number" && typeof save.success === "boolean" });

  const preset = DECISION_PRESETS["신중형"];
  results.push({ name: "decision preset 적용", pass: preset.t2DefaultChoice === "safest" });

  const ai = CLASS_AI.fighter;
  results.push({ name: "class AI 로직 호출", pass: Array.isArray(ai.openerPriority) && ai.openerPriority.length > 0 });

  const fakeT3 = { tier: "T3", mustPause: true };
  results.push({ name: "T3 강제 정지 플래그", pass: shouldForcePause(fakeT3) === true });

  store.dispatch({ type: "LOG", payload: { log: "test-log" } });
  store.dispatch({ type: "HISTORY_EVENT", payload: { entry: { eventId: "test", tier: "T1" } } });
  const final = store.getState();
  results.push({ name: "런 상태 로그/히스토리 기록", pass: final.history.logs.length > 0 && final.history.events.length > 0 });

  return results;
}
