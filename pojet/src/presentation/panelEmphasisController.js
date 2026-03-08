export function createPanelEmphasisController(rules) {
  let clearTimer = null;

  function apply(portraitEl, cue) {
    const base = rules?.default || { border: "normal", scale: 1 };
    const rule = resolveRule(rules, cue);
    if (!portraitEl) return;

    portraitEl.classList.remove("emphasis-soft", "emphasis-strong", "frame-focus-soft", "frame-focus-strong", "frame-gold", "frame-blood", "frame-shadow");

    const eff = rule?.emphasis || base;
    if ((eff.scale || 1) > 1.03) portraitEl.classList.add("emphasis-strong");
    else if ((eff.scale || 1) > 1.0) portraitEl.classList.add("emphasis-soft");

    if (eff.border === "focus_soft") portraitEl.classList.add("frame-focus-soft");
    if (eff.border === "focus_strong") portraitEl.classList.add("frame-focus-strong");
    if (eff.border === "gold") portraitEl.classList.add("frame-gold");
    if (eff.border === "blood") portraitEl.classList.add("frame-blood");
    if (eff.border === "shadow") portraitEl.classList.add("frame-shadow");

    clearTimeout(clearTimer);
    const duration = rule?.durationMs ?? 1200;
    if (duration > 0) {
      clearTimer = setTimeout(() => {
        portraitEl.classList.remove("emphasis-soft", "emphasis-strong", "frame-focus-soft", "frame-focus-strong", "frame-gold", "frame-blood", "frame-shadow");
      }, duration);
    }
  }

  return { apply };
}

function resolveRule(rules, cue) {
  if (!rules) return null;
  if (cue === "T3") return rules.t3_event;
  if (cue === "T2") return rules.t2_event;
  if (cue === "LEVEL_UP") return rules.level_up;
  if (cue === "DEFEAT_MAJOR") return rules.major_defeat;
  if (cue === "REL_GAIN") return rules.relationship_gain;
  if (cue === "TAINT_GAIN") return rules.taint_gain;
  return rules.log;
}
