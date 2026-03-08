import { SAMPLE_EVENTS, LOCATIONS_BY_ACT, QUEST_NAMES, QUEST_MOODS } from "./runtimeData.js";

const JSON_FILES = [
  "regions",
  "factions",
  "npcs",
  "companions",
  "questlines",
  "events-t0",
  "events-t1",
  "events-t2",
  "events-t3",
  "loot-pools",
  "location-pools",
  "log-lines",
  "portrait-state-tags"
];

export async function loadContentPack() {
  const pack = {};
  for (const key of JSON_FILES) {
    try {
      const res = await fetch(`./data/content/${key}.json`);
      if (!res.ok) throw new Error(`status:${res.status}`);
      pack[toKey(key)] = await res.json();
    } catch {
      pack[toKey(key)] = null;
    }
  }
  return withFallback(pack);
}

function toKey(file) {
  return file.replace(/-([a-z])/g, (_, c) => c.toUpperCase()).replace(/\./g, "");
}

function withFallback(raw) {
  const locationPools = raw.locationPools || Object.entries(LOCATIONS_BY_ACT).map(([act, locations]) => ({ id: `act${act}`, act: Number(act), locations }));
  const questlines = raw.questlines || QUEST_NAMES.map((name, i) => ({ id: `fallback-q-${i + 1}`, title: name, emotionalTheme: QUEST_MOODS[i % QUEST_MOODS.length], questType: "daily" }));

  return {
    regions: raw.regions || [],
    factions: raw.factions || [],
    npcs: raw.npcs || [],
    companions: raw.companions || [],
    questlines,
    eventsT0: raw.eventsT0 || [],
    eventsT1: raw.eventsT1 || [],
    eventsT2: raw.eventsT2 || SAMPLE_EVENTS.t2,
    eventsT3: raw.eventsT3 || SAMPLE_EVENTS.t3,
    lootPools: raw.lootPools || [],
    locationPools,
    logLines: raw.logLines || {},
    portraitStateTags: raw.portraitStateTags || []
  };
}
