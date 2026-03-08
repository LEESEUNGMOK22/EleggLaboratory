export function derivePortraitTags(state, context = {}) {
  const tags = new Set(state.character?.tags || []);
  const hpRatio = (state.character?.hp || 0) / Math.max(1, state.character?.maxHp || 1);

  if (hpRatio < 0.35) tags.add("wounded_severe");
  else if (hpRatio < 0.7) tags.add("wounded_minor");

  if (state.resources.fatigue >= 60) tags.add("exhausted");
  if (state.resources.taint >= 40) tags.add("tainted");
  if ((state.character?.tags || []).includes("blessed")) tags.add("blessed");

  const location = state.world.locationId || "";
  if (location.includes("변경") || location.includes("비")) tags.add("rain_soaked");
  if (location.includes("항구") || location.includes("구릉") || location.includes("궁정")) tags.add("city_formal");

  const core = state.relationships.npcRelations.core || {};
  if ((core.intimacy || 0) >= 20) tags.add("intimate_afterglow");
  if ((core.trust || 0) >= 40) tags.add("trusted_companion_nearby");
  if ((core.tension || 0) >= 28) tags.add("hunted");

  const rep = state.factions.reputation || {};
  if ((rep.nobility || 0) >= 20) tags.add("noble_favor");
  if ((rep.underbelly || 0) <= -15) tags.add("hunted");

  const recent = context.recentEvent || state.history.events[0] || {};
  if (recent.tier === "T3") tags.add("resolved");
  if (recent.tier === "T2") tags.add("tempted");
  if (recent.category === "relic") tags.add("relic_bearer");
  if (recent.category === "relationship") tags.add("intimate_afterglow");

  const gear = (state.character?.gear || []).join(" ");
  if (/성물|문장|성패/.test(gear)) tags.add("spellglow_divine");
  if (/반지|유리|파편|봉인/.test(gear)) tags.add("spellglow_arcane");
  if (/혈|피/.test(gear)) tags.add("bloodied");

  return [...tags];
}

export function mapPortraitVisual(tags, mapData) {
  const output = {
    expression: mapData?.baseLayers?.expression || "neutral_face",
    lighting: mapData?.baseLayers?.lighting || "low_warm",
    posture: mapData?.baseLayers?.posture || "upright",
    frameStyle: mapData?.baseLayers?.frameStyle || "iron_frame",
    microMotion: mapData?.baseLayers?.microMotion || "idle_slow",
    overlays: [],
    ambientSymbols: [],
    attireOverlay: null,
    tags
  };

  const rules = mapData?.tagRules || [];
  for (const r of rules) {
    if ((r.requires || []).every((x) => tags.includes(x))) {
      const ap = r.apply || {};
      if (ap.expression) output.expression = ap.expression;
      if (ap.lighting) output.lighting = ap.lighting;
      if (ap.posture) output.posture = ap.posture;
      if (ap.frameStyle) output.frameStyle = ap.frameStyle;
      if (ap.microMotion) output.microMotion = ap.microMotion;
      if (ap.attireOverlay) output.attireOverlay = ap.attireOverlay;
      if (Array.isArray(ap.overlays)) output.overlays.push(...ap.overlays);
      if (Array.isArray(ap.ambientSymbols)) output.ambientSymbols.push(...ap.ambientSymbols);
    }
  }

  output.overlays = [...new Set(output.overlays)];
  output.ambientSymbols = [...new Set(output.ambientSymbols)];
  return output;
}

export function portraitStateCount(mapData) {
  return (mapData?.comboShowcase || []).length;
}
