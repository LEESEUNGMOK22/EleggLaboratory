import { resolveCombat } from "../resolvers/combatResolver.js";
import { resolveExploration } from "../resolvers/explorationResolver.js";
import { resolveSocial } from "../resolvers/socialResolver.js";
import { applyResolutionEffects, applyEventChoiceEffects, maybeLevelUp } from "../resolvers/rewardResolver.js";
import { maybeDispatchDecisionEvent, resolveTimedChoice, shouldForcePause } from "../events/eventDispatcher.js";
import { LOCATIONS_BY_ACT } from "../config/runtimeData.js";

export function createAutoProgressionController(store, contentPack) {
  let timer = null;
  let t2Timer = null;

  function start() {
    if (timer) return;
    timer = setInterval(step, 900);
  }

  function stop() {
    clearInterval(timer);
    timer = null;
    clearInterval(t2Timer);
    t2Timer = null;
  }

  function step() {
    const state = store.getState();
    if (state.run.status !== "running") return;
    if (state.activeDecisionEvent) return;

    store.dispatch({ type: "TIME_TICK" });

    const current = store.getState();
    const phase = pick(["exploration", "combat", "social", "rest"]);

    if (phase === "exploration") applyPhaseResolution(store, resolveExploration(current), contentPack);
    if (phase === "combat") applyPhaseResolution(store, resolveCombat(current), contentPack);
    if (phase === "social") applyPhaseResolution(store, resolveSocial(current), contentPack);
    if (phase === "rest") {
      const hp = Math.min(current.character.maxHp, current.character.hp + rand(4, 7));
      const prevFatigue = current.resources.fatigue;
      const nextFatigue = Math.max(0, prevFatigue - 5);
      store.dispatch({ type: "APPLY_PATCH", payload: { patch: { character: { hp }, resources: { fatigue: nextFatigue } } } });
      store.dispatch({ type: "LOG", payload: { log: `[휴식] ${pickLogLine(contentPack, "rest", "자동 휴식으로 호흡을 가다듬었다.")}` } });
    }

    const afterPhase = store.getState();
    if (afterPhase.world.actProgress >= 100) {
      const nextAct = Math.min(5, afterPhase.world.act + 1);
      const pool = (contentPack?.locationPools || []).find((x) => x.act === nextAct)?.locations || LOCATIONS_BY_ACT[nextAct];
      store.dispatch({ type: "APPLY_PATCH", payload: { patch: { world: { act: nextAct, actProgress: 0, locationId: pick(pool) } } } });
      store.dispatch({ type: "LOG", payload: { log: `[막 전환] 막 ${nextAct}로 진입했다.` } });
    }

    const possibleEvent = maybeDispatchDecisionEvent(store.getState(), contentPack);
    if (possibleEvent) {
      store.dispatch({ type: "SET_ACTIVE_EVENT", payload: { event: { ...possibleEvent, openedAt: Date.now() } } });
      store.dispatch({ type: "HISTORY_EVENT", payload: { entry: { eventId: possibleEvent.id || possibleEvent.eventId, tier: possibleEvent.tier, category: possibleEvent.category, openedAt: new Date().toISOString() } } });
      store.dispatch({ type: "LOG", payload: { log: `[${possibleEvent.tier}] ${possibleEvent.title || possibleEvent.logSummary}` } });

      if (shouldForcePause(possibleEvent)) {
        store.dispatch({ type: "RUN_PAUSE" });
      } else if (possibleEvent.tier === "T2" && store.getState().automation.t2Policy !== "ask") {
        clearTimeout(t2Timer);
        t2Timer = setTimeout(() => {
          const live = store.getState();
          if (!live.activeDecisionEvent || (live.activeDecisionEvent.id !== possibleEvent.id && live.activeDecisionEvent.eventId !== possibleEvent.eventId)) return;
          const autoChoice = resolveTimedChoice(live, live.activeDecisionEvent);
          applyDecisionChoice(store, autoChoice, true);
        }, (possibleEvent.timeoutSec || 10) * 1000);
      }
    }

    const ended = store.getState().character.hp <= 0;
    if (ended) {
      store.dispatch({ type: "LOG", payload: { log: "[종결] 캐릭터가 쓰러졌다. 연대기에 기록된다." } });
      store.dispatch({ type: "RUN_END", payload: { cause: "battle_death" } });
      stop();
    }
  }

  return { start, stop, step };
}

function applyPhaseResolution(store, resolution, contentPack) {
  const prev = store.getState();
  const patch = applyResolutionEffects(prev, resolution);
  store.dispatch({ type: "APPLY_PATCH", payload: { patch } });
  store.dispatch({ type: "LOG", payload: { log: `[${phaseLabel(resolution.type)}] ${pickLogLine(contentPack, resolution.type, resolution.summary)}` } });

  const next = store.getState();
  const beforeCore = prev.relationships.npcRelations.core || {};
  const afterCore = next.relationships.npcRelations.core || {};
  if (JSON.stringify(beforeCore) !== JSON.stringify(afterCore)) {
    store.dispatch({ type: "RELATION_CHANGE", payload: { entry: { at: new Date().toISOString(), before: beforeCore, after: afterCore, source: resolution.type } } });
  }

  const prevCompleted = (prev.world.quests || []).filter((q) => q.state === "completed").map((q) => q.id);
  const nextCompleted = (next.world.quests || []).filter((q) => q.state === "completed");
  nextCompleted.forEach((q) => {
    if (!prevCompleted.includes(q.id)) {
      store.dispatch({ type: "QUEST_COMPLETE", payload: { entry: { id: q.id, title: q.name, at: new Date().toISOString() } } });
    }
  });

  const lvl = maybeLevelUp(next);
  if (lvl) {
    store.dispatch({ type: "APPLY_PATCH", payload: { patch: lvl } });
    store.dispatch({ type: "LOG", payload: { log: `[성장] 레벨 ${store.getState().character.level} 달성.` } });
  }
}

export function applyDecisionChoice(store, choice, auto = false) {
  const state = store.getState();
  const event = state.activeDecisionEvent;
  if (!event || !choice) return;

  const before = state.relationships.npcRelations.core || {};
  const patch = applyEventChoiceEffects(state, choice, event.defaultEffects || []);
  store.dispatch({ type: "APPLY_PATCH", payload: { patch } });
  store.dispatch({ type: "LOG", payload: { log: `${auto ? "[자동 선택]" : "[선택]"} ${choice.label}` } });
  store.dispatch({ type: "HISTORY_EVENT", payload: { entry: { eventId: event.id || event.eventId, choiceId: choice.id, auto, tier: event.tier, category: event.category, resolvedAt: new Date().toISOString() } } });
  store.dispatch({ type: "CLEAR_ACTIVE_EVENT" });

  const after = store.getState().relationships.npcRelations.core || {};
  if (JSON.stringify(before) !== JSON.stringify(after)) {
    store.dispatch({ type: "RELATION_CHANGE", payload: { entry: { at: new Date().toISOString(), before, after, source: event.id || event.eventId } } });
  }

  if (event.tier === "T3" && store.getState().run.status === "paused") {
    store.dispatch({ type: "RUN_RESUME" });
  }
}

export function evaluateRunEndType(state) {
  if (!state?.character) return null;
  if (state.character.hp <= 0) return "battle_death";
  if (state.resources.taint >= 85) return "corruption_fall";
  if ((state.character.tags || []).includes("forbidden-power")) return "forbidden_fusion";
  if (state.world.act >= 5 && state.resources.renown >= 30) return "faction_ascension";
  if (state.world.act >= 4 && state.time.tick >= 65) return "glorious_retirement";
  if (state.time.tick >= 80) return "vanished_legend";
  return null;
}

function phaseLabel(type) {
  return ({ exploration: "탐험", combat: "전투", social: "사회", rest: "휴식" })[type] || "루프";
}

function pickLogLine(contentPack, phase, fallback) {
  const logs = contentPack?.logLines || {};
  const keyMap = { exploration: "movement", combat: "combat", social: "rumor", rest: "rest" };
  const pool = logs[keyMap[phase]];
  if (Array.isArray(pool) && pool.length) return pool[rand(0, pool.length - 1)];
  return fallback;
}

function rand(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function pick(arr) { return arr[rand(0, arr.length - 1)]; }
