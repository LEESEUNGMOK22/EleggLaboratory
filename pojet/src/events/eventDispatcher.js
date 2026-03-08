import { SAMPLE_EVENTS, DECISION_PRESETS } from "../config/runtimeData.js";

export function maybeDispatchDecisionEvent(state, contentPack) {
  if (state.activeDecisionEvent) return null;

  const tick = state.time.tick;
  const t2Pool = contentPack?.eventsT2?.length ? contentPack.eventsT2 : SAMPLE_EVENTS.t2;
  const t3Pool = contentPack?.eventsT3?.length ? contentPack.eventsT3 : SAMPLE_EVENTS.t3;

  if (tick === 8) return normalizeEvent(structuredClone(t2Pool[0 % t2Pool.length]));
  if (tick === 14) return normalizeEvent(structuredClone(t2Pool[1 % t2Pool.length]));
  if (tick === 20) return normalizeEvent(structuredClone(t3Pool[0 % t3Pool.length]));
  if (tick === 28 || (state.world.act >= 3 && tick % 11 === 0)) return normalizeEvent(structuredClone(t3Pool[1 % t3Pool.length]));

  if (tick % 12 === 0 && Math.random() < 0.3) return normalizeEvent(structuredClone(t2Pool[Math.floor(Math.random() * t2Pool.length)]));
  return null;
}

export function resolveTimedChoice(state, event) {
  const preset = DECISION_PRESETS[state.automation.decisionPresetId] || DECISION_PRESETS["신중형"];
  const mode = preset.t2DefaultChoice;

  if (!event?.choices?.length) return null;

  if (mode === "safest") return event.choices[event.choices.length - 1];
  if (mode === "bold") return event.choices[0];
  if (mode === "profit") {
    const rich = event.choices.find((c) => c.effects?.some((fx) => fx.kind === "gain_gold" && fx.value > 0));
    return rich || event.choices[0];
  }
  if (mode === "mercy") return event.choices.find((c) => c.id === "seal" || c.id === "reject" || c.id === "decline") || event.choices[event.choices.length - 1];
  if (mode === "dominance") return event.choices[0];
  if (mode === "bond") return event.choices.find((c) => c.effects?.some((fx) => fx.kind === "relation")) || event.choices[0];
  if (mode === "oath") return event.choices.find((c) => c.id === "temple" || c.id === "seal" || c.id === "oath") || event.choices[0];

  return event.choices[0];
}

export function shouldForcePause(event) {
  return Boolean(event?.tier === "T3" || event?.mustPause);
}

function normalizeEvent(event) {
  if (!event) return null;
  return {
    ...event,
    eventId: event.eventId || event.id,
    title: event.title || event.logSummary || event.id,
    text: event.text || event.narrativeText || "",
    timeoutSec: event.timeoutSec ?? (event.tier === "T2" ? 12 : 0),
    mustPause: event.mustPause ?? event.tier === "T3"
  };
}
