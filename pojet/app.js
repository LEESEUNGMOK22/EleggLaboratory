import { createStore } from "./src/core/store.js";
import { createCharacterTemplate, buildCharacterFromTemplate, createQuest, describeCharacter } from "./src/core/state-machine.js";
import { createAutoProgressionController, applyDecisionChoice, evaluateRunEndType } from "./src/loop/autoProgressionController.js";
import {
  ABILITIES,
  CLASS_IDS,
  CLASS_LABELS_KO,
  LINEAGES,
  LINEAGE_LABELS_KO,
  BACKGROUNDS,
  BACKGROUND_LABELS_KO,
  DECISION_PRESETS,
  GEAR_POOL
} from "./src/config/runtimeData.js";
import { loadContentPack } from "./src/config/contentLoader.js";
import { loadPresentationPack } from "./src/presentation/presentationLoader.js";
import { derivePortraitTags, mapPortraitVisual, portraitStateCount } from "./src/presentation/portraitStateMapper.js";
import { applyPortraitRender } from "./src/presentation/portraitRenderer.js";
import { createPanelEmphasisController } from "./src/presentation/panelEmphasisController.js";
import { createSaveLoadManager } from "./src/meta/saveLoadManager.js";
import { resolveLegacyReward, applyLegacyToRun } from "./src/meta/legacyUnlockResolver.js";
import { initNextRunFromLineage } from "./src/meta/lineageInitializer.js";
import { createChronicleEntry } from "./src/meta/chronicleWriter.js";
import { runSimulationTests } from "./src/tests/simulationTests.js";

const store = createStore();
const contentPack = await loadContentPack();
const presentationPack = await loadPresentationPack();
const loop = createAutoProgressionController(store, contentPack);
const emphasis = createPanelEmphasisController(presentationPack.panelEmphasisRules);
const saveManager = createSaveLoadManager();

const ui = {
  log: gid("log-panel"),
  tutorial: gid("tutorial-banner"),
  eventCard: gid("event-card"),
  eventTitle: gid("event-title"),
  eventText: gid("event-text"),
  eventMeta: gid("event-meta"),
  eventChoices: gid("event-choices"),
  eventTimer: gid("event-timer"),
  charName: gid("char-name"),
  charTag: gid("char-tag"),
  charTags: gid("char-status-tags"),
  portraitStates: gid("portrait-state-list"),
  portrait: gid("portrait"),
  face: gid("portrait-face"),
  relBars: gid("relationship-bars"),
  axisBars: gid("axis-bars"),
  comp: gid("companion-strip"),
  act: gid("act-label"),
  loc: gid("location-label"),
  day: gid("day-label"),
  bar: gid("act-progress-bar"),
  hp: gid("hp-label"),
  gold: gid("gold-label"),
  fame: gid("fame-label"),
  taint: gid("taint-label"),
  fatigue: gid("fatigue-label"),
  stats: gid("stats-grid"),
  quests: gid("quest-list"),
  gear: gid("gear-list"),
  legacy: gid("legacy-list"),
  historyTabs: gid("history-tabs"),
  historyBody: gid("history-body"),
  creator: gid("creator-modal"),
  mode: gid("creation-mode"),
  name: gid("create-name"),
  race: gid("create-race"),
  cls: gid("create-class"),
  bg: gid("create-background"),
  begin: gid("begin-btn"),
  randomBtn: gid("randomize-btn"),
  pause: gid("pause-btn"),
  save: gid("save-btn"),
  load: gid("load-btn"),
  endRun: gid("end-run-btn"),
  settingsBtn: gid("settings-btn"),
  newLife: gid("new-life-btn"),
  setModal: gid("settings-modal"),
  setClose: gid("settings-close"),
  setTabs: gid("settings-tabs"),
  setBody: gid("settings-body"),
  inherit: gid("inheritance-note"),
  t2Style: gid("create-t2-style"),
  alloc: gid("ability-allocator"),
  runEndModal: gid("run-end-modal"),
  runEndSummary: gid("run-end-summary"),
  runEndNext: gid("run-end-next-btn"),
  runEndClose: gid("run-end-close-btn")
};

const tutorials = [
  "이 게임은 전투 버튼을 연타하는 게임이 아니다. 흐름은 자동으로 진행되고, 중요한 순간에만 멈춘다.",
  "당신이 정하는 것은 방향과 태도다.",
  "T2는 개입 가능, T3는 반드시 정지한다.",
  "캐릭터는 화면 한쪽에 남아 삶의 흔적을 증언한다."
];

let tutorialIndex = 0;
let eventCountdown = null;
let currentHistoryTab = "현재 런 로그";
let lastVisualTags = [];
let alreadyEnded = false;

const abilityAlloc = { STR: 15, DEX: 14, CON: 13, INT: 12, WIS: 10, CHA: 8 };

init();

function init() {
  fillSelect(ui.race, LINEAGES, LINEAGE_LABELS_KO);
  fillSelect(ui.cls, CLASS_IDS, CLASS_LABELS_KO);
  fillSelect(ui.bg, BACKGROUNDS, BACKGROUND_LABELS_KO);
  renderAbilityAllocator();
  renderSettingsSummary();
  renderHistoryTabs();
  bindControls();
  openCreator(true);
  ui.tutorial.textContent = tutorials[0];

  const tests = runSimulationTests();
  tests.forEach((t) => pushLog(`[테스트] ${t.name}: ${t.pass ? "PASS" : "FAIL"}`));
  pushLog(`[초상화] 조합 프리셋 ${portraitStateCount(presentationPack.portraitStateMap)}개 준비됨`);

  store.subscribe((state, action) => {
    if (action.type === "LOG") appendLog(action.payload.log);
    renderState(state);
    renderEvent(state.activeDecisionEvent, state);
    renderHistory(state);

    if (state.run.status === "running" && state.time.tick > 0 && state.time.tick % 6 === 0) {
      saveManager.save(state, true);
      if (tutorialIndex < tutorials.length - 1) tutorialIndex += 1;
    }
    ui.tutorial.textContent = tutorials[tutorialIndex];

    if (action.type === "SET_ACTIVE_EVENT") {
      const tier = state.activeDecisionEvent?.tier;
      if (tier === "T3") emphasis.apply(ui.portrait, "T3");
      if (tier === "T2") emphasis.apply(ui.portrait, "T2");
    }
    if (action.type === "HISTORY_EVENT" && action.payload?.entry?.tier === "T3") {
      emphasis.apply(ui.portrait, "T3");
    }
    if (action.type === "APPLY_PATCH" && state.character && state.character.level > 1) {
      emphasis.apply(ui.portrait, "LEVEL_UP");
    }

    const endType = state.character ? evaluateRunEndType(state) : null;
    if (state.run.status === "running" && endType && !alreadyEnded) {
      finalizeRun(endType);
    }
  });
}

function bindControls() {
  qsa("[data-speed]").forEach((b) => {
    b.onclick = () => {
      store.dispatch({ type: "TIME_SPEED", payload: { speed: Number(b.dataset.speed) } });
      setActiveSpeed(Number(b.dataset.speed));
      store.dispatch({ type: "LOG", payload: { log: `배속 ${b.dataset.speed}x` } });
    };
  });

  ui.pause.onclick = () => {
    const status = store.getState().run.status;
    if (status === "running") {
      store.dispatch({ type: "RUN_PAUSE" });
      ui.pause.textContent = "재개";
      store.dispatch({ type: "LOG", payload: { log: "시간이 멈췄다." } });
      return;
    }
    if (status === "paused") {
      store.dispatch({ type: "RUN_RESUME" });
      ui.pause.textContent = "일시정지";
      store.dispatch({ type: "LOG", payload: { log: "시간이 다시 흐른다." } });
      return;
    }
  };

  ui.save.onclick = () => {
    saveManager.save(store.getState(), false);
    store.dispatch({ type: "LOG", payload: { log: "수동 저장 완료." } });
  };

  ui.load.onclick = () => {
    const loaded = saveManager.load(false);
    if (!loaded) {
      store.dispatch({ type: "LOG", payload: { log: "불러올 저장이 없다." } });
      return;
    }
    store.dispatch({ type: "HYDRATE_STATE", payload: { state: loaded } });
    if (loaded.run?.status === "running") loop.start();
    store.dispatch({ type: "LOG", payload: { log: "저장을 불러왔다." } });
  };

  ui.endRun.onclick = () => finalizeRun("glorious_retirement");

  ui.settingsBtn.onclick = () => ui.setModal.classList.remove("hidden");
  ui.setClose.onclick = () => ui.setModal.classList.add("hidden");
  ui.newLife.onclick = () => openCreator(true);

  ui.randomBtn.onclick = randomizeCreator;
  ui.begin.onclick = beginRun;
  ui.mode.onchange = () => { if (ui.mode.value === "random") randomizeCreator(); };

  ui.runEndClose.onclick = () => ui.runEndModal.classList.add("hidden");
  ui.runEndNext.onclick = () => {
    ui.runEndModal.classList.add("hidden");
    openCreator(true);
  };
}

function beginRun() {
  alreadyEnded = false;
  store.reset();

  const tpl = createCharacterTemplate({
    name: ui.name.value.trim() || undefined,
    classId: ui.cls.value,
    lineageId: ui.race.value,
    backgroundId: ui.bg.value,
    abilities: structuredClone(abilityAlloc),
    automationPreset: ui.t2Style.value || "신중형"
  });

  const character = buildCharacterFromTemplate(tpl);
  character.gear.push(pick(GEAR_POOL));
  const dailyPool = (contentPack.questlines || []).filter((q) => q.questType === "daily");
  character.questLog = [dailyPool.length ? toQuestFromContent(pick(dailyPool)) : createQuest()];

  const latestArchive = saveManager.getArchive()[0] || null;
  const latestRunType = latestArchive ? findRunEndMeta(latestArchive.outcome) : null;
  const reward = resolveLegacyReward(presentationPack.legacyRewards, latestRunType?.legacyRewardId);

  store.dispatch({ type: "SET_CHARACTER", payload: { character } });

  if (latestArchive) {
    const lineagePatch = initNextRunFromLineage(store.getState(), latestArchive, reward);
    store.dispatch({ type: "APPLY_PATCH", payload: { patch: lineagePatch } });
    const withLegacy = applyLegacyToRun(store.getState(), reward);
    store.dispatch({ type: "HYDRATE_STATE", payload: { state: withLegacy } });
    store.dispatch({ type: "LOG", payload: { log: `[계승] ${latestArchive.title}의 흔적이 다음 삶에 남았다.` } });
  }

  const region = (contentPack.regions || [])[0];
  const companion = (contentPack.companions || [])[0];
  if (region) store.dispatch({ type: "APPLY_PATCH", payload: { patch: { world: { locationId: region.name } } } });
  if (companion) {
    store.dispatch({ type: "APPLY_PATCH", payload: { patch: { character: { activeCompanion: companion.name } } } });
  }

  store.dispatch({ type: "RUN_START" });
  store.dispatch({ type: "LOG", payload: { log: `${store.getState().character.name}의 연대기가 시작된다.` } });

  if (companion) store.dispatch({ type: "LOG", payload: { log: `[동료] ${companion.name}이(가) 합류했다.` } });
  (contentPack.npcs || []).slice(0, 4).forEach((npc) => {
    store.dispatch({ type: "LOG", payload: { log: `[인물] ${npc.name}: ${npc.firstImpression}` } });
  });
  (contentPack.factions || []).slice(0, 2).forEach((f) => {
    store.dispatch({ type: "LOG", payload: { log: `[세력] ${f.name}: ${f.identity}` } });
  });

  ui.creator.classList.add("hidden");
  ui.pause.textContent = "일시정지";
  loop.start();
}

function finalizeRun(endType) {
  const state = store.getState();
  if (!state.character) return;
  if (state.run.status === "ended") return;
  alreadyEnded = true;
  loop.stop();

  const endMeta = findRunEndMeta(endType);
  const rewardId = endMeta?.legacyRewardId;
  const entry = createChronicleEntry(state, endType, endMeta, rewardId, lastVisualTags);
  store.dispatch({ type: "CHRONICLE_ENTRY", payload: { entry } });
  saveManager.archiveChronicle(entry);
  saveManager.save(store.getState(), false);
  saveManager.clearCurrent();
  store.dispatch({ type: "RUN_END", payload: { cause: endType } });

  const reward = resolveLegacyReward(presentationPack.legacyRewards, rewardId);
  ui.runEndSummary.innerHTML = [
    `<div class="setting-row"><strong>종결</strong><span>${endMeta?.displayName || endType}</span></div>`,
    `<div class="setting-row"><strong>연대기 문장</strong><span>${endMeta?.tone || "비가 멎기 전, 이름이 기록되었다."}</span></div>`,
    `<div class="setting-row"><strong>요약</strong><span>${entry.summary}</span></div>`,
    `<div class="setting-row"><strong>유산</strong><span>${reward?.heirloomItem || "기본 유산"}</span></div>`,
    `<div class="setting-row"><strong>다음 시작 효과</strong><span>명성 +${entry.boonRenown}, 금화 +${entry.boonGold}, 오염 +${entry.boonTaint}</span></div>`
  ].join("");

  ui.runEndModal.classList.remove("hidden");
  store.dispatch({ type: "LOG", payload: { log: `[연대기] ${endMeta?.displayName || endType}로 한 삶이 끝났다.` } });
}

function renderState(state) {
  const c = state.character;
  if (!c) {
    ui.charName.textContent = "아직 이름 없는 자";
    ui.charTag.textContent = "무명의 생존자";
    return;
  }

  ui.charName.textContent = c.name;
  ui.charTag.textContent = describeCharacter(c);

  ui.charTags.innerHTML = "";
  [
    `Lv.${c.level}`,
    `명성 ${state.resources.renown}`,
    state.resources.taint >= 40 ? "오염 징후" : "정신 안정",
    state.resources.fatigue >= 60 ? "피로 누적" : "호흡 유지"
  ].forEach((t) => {
    const tag = document.createElement("span");
    tag.textContent = t;
    ui.charTags.appendChild(tag);
  });

  const tags = derivePortraitTags(state);
  lastVisualTags = tags;
  const visual = mapPortraitVisual(tags, presentationPack.portraitStateMap);
  applyPortraitRender(ui.portrait, ui.face, ui.portraitStates, visual);

  if ((state.history.events[0]?.tier || "") === "T3") emphasis.apply(ui.portrait, "T3");
  else if ((state.history.events[0]?.tier || "") === "T2") emphasis.apply(ui.portrait, "T2");

  ui.act.textContent = `막 ${state.world.act}`;
  ui.loc.textContent = state.world.locationId || "검은비 변경";
  ui.day.textContent = `${state.world.day}일`;
  ui.bar.style.width = `${Math.min(100, state.world.actProgress)}%`;

  ui.hp.textContent = `${c.hp} / ${c.maxHp}`;
  ui.gold.textContent = state.resources.gold;
  ui.fame.textContent = state.resources.renown;
  ui.taint.textContent = state.resources.taint;
  ui.fatigue.textContent = state.resources.fatigue;

  ui.stats.innerHTML = "";
  ABILITIES.forEach((ab) => {
    const div = document.createElement("div");
    div.textContent = `${ab} ${c.abilities[ab]} (${sign(mod(c.abilities[ab]))})`;
    ui.stats.appendChild(div);
  });

  ui.quests.innerHTML = "";
  (state.world.quests || []).slice(0, 3).forEach((q) => {
    const li = document.createElement("li");
    li.textContent = `${q.name} (${q.progress}%) - ${q.mood}`;
    ui.quests.appendChild(li);
  });

  ui.gear.innerHTML = "";
  (c.gear || []).forEach((g) => {
    const li = document.createElement("li");
    li.textContent = g;
    ui.gear.appendChild(li);
  });

  ui.legacy.innerHTML = "";
  saveManager.getArchive().slice(0, 5).forEach((entry) => {
    const li = document.createElement("li");
    li.textContent = `${entry.title} (${entry.outcome})`;
    ui.legacy.appendChild(li);
  });
  if (!ui.legacy.children.length) {
    const li = document.createElement("li");
    li.textContent = "기록 없음";
    ui.legacy.appendChild(li);
  }

  renderMeter(ui.relBars, [
    ["신뢰", state.relationships.npcRelations.core.trust || 0],
    ["친밀", state.relationships.npcRelations.core.intimacy || 0],
    ["긴장", state.relationships.npcRelations.core.tension || 0],
    ["욕망", state.relationships.npcRelations.core.desire || 0],
    ["존경", state.relationships.npcRelations.core.respect || 0],
    ["두려움", state.relationships.npcRelations.core.fear || 0]
  ]);

  renderMeter(ui.axisBars, [
    ["질서", axis(50 + (state.factions.reputation.temple || 0) - (state.factions.reputation.underbelly || 0))],
    ["자비", axis(50 + (state.relationships.npcRelations.core.trust || 0) - (state.relationships.npcRelations.core.fear || 0))],
    ["신앙", axis(50 + (state.factions.reputation.temple || 0))],
    ["절제", axis(50 + state.resources.renown - state.resources.infamy)]
  ]);

  ui.comp.textContent = c.activeCompanion || "동료 없음";
}

function renderEvent(event, state) {
  clearInterval(eventCountdown);
  eventCountdown = null;

  if (!event) {
    ui.eventCard.classList.add("hidden");
    return;
  }

  ui.eventCard.classList.remove("hidden");
  ui.eventTitle.textContent = `[${event.tier}] ${event.title}`;
  ui.eventText.textContent = event.text;
  ui.eventMeta.textContent = event.tier === "T3" ? "필수 선택: 시간 정지" : "미응답 시 자동 처리";
  ui.eventChoices.innerHTML = "";

  (event.choices || []).forEach((choice) => {
    const btn = document.createElement("button");
    btn.textContent = choice.label;
    btn.onclick = () => applyDecisionChoice(store, choice, false);
    ui.eventChoices.appendChild(btn);
  });

  if (event.tier === "T2" && event.timeoutSec && state.automation.t2Policy !== "ask") {
    let left = event.timeoutSec;
    ui.eventTimer.textContent = `미응답 자동 처리까지 ${left}초`;
    eventCountdown = setInterval(() => {
      left -= 1;
      ui.eventTimer.textContent = `미응답 자동 처리까지 ${left}초`;
      if (left <= 0) clearInterval(eventCountdown);
    }, 1000);
  } else {
    ui.eventTimer.textContent = "";
  }
}

function renderHistoryTabs() {
  const tabs = ["현재 런 로그", "주요 선택", "완료 퀘스트", "관계 변천", "연대기"];
  ui.historyTabs.innerHTML = "";
  tabs.forEach((t) => {
    const b = document.createElement("button");
    b.textContent = t;
    b.classList.toggle("active", t === currentHistoryTab);
    b.onclick = () => {
      currentHistoryTab = t;
      qsa("button", ui.historyTabs).forEach((x) => x.classList.remove("active"));
      b.classList.add("active");
      renderHistory(store.getState());
    };
    ui.historyTabs.appendChild(b);
  });
}

function renderHistory(state) {
  const rows = [];
  if (currentHistoryTab === "현재 런 로그") {
    (state.history.logs || []).slice(0, 40).forEach((x) => rows.push(x));
  } else if (currentHistoryTab === "주요 선택") {
    (state.history.majorChoices || []).slice(0, 30).forEach((x) => rows.push(`${x.tier || "선택"} ${x.eventId || "-"} ${x.choiceId || ""}`));
  } else if (currentHistoryTab === "완료 퀘스트") {
    (state.history.completedQuests || []).slice(0, 30).forEach((x) => rows.push(`${x.title} 완료`));
  } else if (currentHistoryTab === "관계 변천") {
    (state.history.relationChanges || []).slice(0, 30).forEach((x) => rows.push(`${x.source}: 신뢰 ${x.after?.trust ?? "-"}, 긴장 ${x.after?.tension ?? "-"}`));
  } else {
    saveManager.getArchive().slice(0, 30).forEach((x) => rows.push(`${x.title} | ${x.summary} | ${x.outcome}`));
  }

  ui.historyBody.innerHTML = rows.length
    ? rows.map((r) => `<p class="history-row">${escapeHtml(String(r))}</p>`).join("")
    : `<p class="history-row">기록 없음</p>`;
}

function openCreator(random = false) {
  ui.creator.classList.remove("hidden");
  if (random) randomizeCreator();
  const archive = saveManager.getArchive()[0];
  ui.inherit.textContent = archive
    ? `이전 삶의 유산: ${archive.title} (금화 +${archive.boonGold}, 명성 +${archive.boonRenown})`
    : "아직 계승된 기록이 없다. 첫 연대기를 시작하세요.";
}

function randomizeCreator() {
  ui.name.value = `${pick(["엘린", "케른", "마리브", "타스", "레이나", "브란", "실바", "오르덴"])}${rand(11, 99)}`;
  ui.race.value = pick(LINEAGES);
  ui.cls.value = pick(CLASS_IDS);
  ui.bg.value = pick(BACKGROUNDS);
  ui.t2Style.value = pick(Object.keys(DECISION_PRESETS));
  const pool = [15, 14, 13, 12, 10, 8].sort(() => Math.random() - 0.5);
  ABILITIES.forEach((ab, i) => { abilityAlloc[ab] = pool[i]; });
  renderAbilityAllocator();
}

function renderSettingsSummary() {
  const tabs = ["일반", "속도와 자동화", "선택지 처리", "서사와 로그", "초상화/연출", "성인/민감도 필터", "접근성"];
  ui.setTabs.innerHTML = "";
  tabs.forEach((t, i) => {
    const b = document.createElement("button");
    b.textContent = t;
    b.classList.toggle("active", i === 0);
    b.onclick = () => {
      qsa("button", ui.setTabs).forEach((x) => x.classList.remove("active"));
      b.classList.add("active");
      ui.setBody.innerHTML = `<div class="setting-row"><strong>${t}</strong><span>구조 연결됨 (콘텐츠/아트 단계에서 확장)</span></div>`;
    };
    ui.setTabs.appendChild(b);
  });
  ui.setBody.innerHTML = `<div class="setting-row"><strong>자동 처리 성향</strong><span>${Object.keys(DECISION_PRESETS).join(", ")}</span></div>`;
}

function renderAbilityAllocator() {
  ui.alloc.innerHTML = "";
  ABILITIES.forEach((ab) => {
    const row = document.createElement("div");
    row.className = "row";
    const name = document.createElement("strong");
    name.textContent = ab;
    const input = document.createElement("input");
    input.type = "range";
    input.min = "8";
    input.max = "15";
    input.value = String(abilityAlloc[ab]);
    const value = document.createElement("span");
    value.textContent = String(abilityAlloc[ab]);
    input.oninput = () => {
      abilityAlloc[ab] = Number(input.value);
      value.textContent = input.value;
    };
    row.append(name, input, value);
    ui.alloc.appendChild(row);
  });
}

function fillSelect(select, values, labels = {}) {
  select.innerHTML = "";
  values.forEach((v) => {
    const opt = document.createElement("option");
    opt.value = v;
    opt.textContent = labels[v] || v;
    select.appendChild(opt);
  });
}

function toQuestFromContent(q) {
  return { id: q.id, name: q.title, mood: q.emotionalTheme || "의무", progress: 0, stage: "active", state: "ongoing" };
}

function findRunEndMeta(id) {
  return (presentationPack.runEndTypes || []).find((x) => x.id === id) || null;
}

function renderMeter(target, rows) {
  target.innerHTML = "";
  rows.forEach(([name, value]) => {
    const m = document.createElement("div");
    m.className = "meter";
    const val = clamp(value, 0, 100);
    m.innerHTML = `<span>${name}</span><div class="track"><span style="width:${val}%"></span></div><strong>${Math.round(val)}</strong>`;
    target.appendChild(m);
  });
}

function setActiveSpeed(speed) {
  qsa("[data-speed]").forEach((b) => b.classList.toggle("active", Number(b.dataset.speed) === speed));
}

function appendLog(text) {
  const p = document.createElement("p");
  p.className = "log-entry";
  p.textContent = text;
  ui.log.prepend(p);
  if (ui.log.children.length > 260) ui.log.removeChild(ui.log.lastChild);
}

function pushLog(text) {
  const p = document.createElement("p");
  p.className = "log-entry dim";
  p.textContent = text;
  ui.log.prepend(p);
}

function escapeHtml(v) {
  return v.replace(/[&<>\"]/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[ch]));
}

function axis(v) { return clamp(v, 0, 100); }
function gid(id) { return document.getElementById(id); }
function qsa(sel, parent = document) { return [...parent.querySelectorAll(sel)]; }
function mod(score) { return Math.floor((score - 10) / 2); }
function sign(n) { return n >= 0 ? `+${n}` : `${n}`; }
function rand(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function pick(arr) { return arr[rand(0, arr.length - 1)]; }
function clamp(n, min, max) { return Math.max(min, Math.min(max, n)); }
