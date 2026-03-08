export async function loadPresentationPack() {
  const keys = [
    "portrait-state-map",
    "emotion-presets",
    "panel-emphasis-rules",
    "run-end-types",
    "legacy-rewards"
  ];
  const pack = {};
  for (const key of keys) {
    try {
      const r = await fetch(`./data/presentation/${key}.json`);
      if (!r.ok) throw new Error(String(r.status));
      pack[toKey(key)] = await r.json();
    } catch {
      pack[toKey(key)] = null;
    }
  }
  return {
    portraitStateMap: pack.portraitStateMap || { baseLayers: {}, tagRules: [], priority: [] },
    emotionPresets: pack.emotionPresets || {},
    panelEmphasisRules: pack.panelEmphasisRules || { default: { border: "normal", glow: 0.1, scale: 1 } },
    runEndTypes: pack.runEndTypes || [],
    legacyRewards: pack.legacyRewards || {}
  };
}

function toKey(v) { return v.replace(/-([a-z])/g, (_, c) => c.toUpperCase()); }
