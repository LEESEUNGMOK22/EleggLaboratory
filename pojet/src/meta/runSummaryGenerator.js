export function buildRunSummary(state, endType) {
  const c = state.character;
  const core = state.relationships.npcRelations.core || {};
  return {
    title: `${c.name}의 마지막 장`,
    endType,
    summary: `${c.classId} Lv.${c.level}, 막 ${state.world.act}, 명성 ${state.resources.renown}, 오염 ${state.resources.taint}`,
    majorChoices: (state.history.events || []).filter((e) => (e.tier === "T3") || (e.auto === false)).slice(0, 3),
    completedQuests: (state.world.quests || []).filter((q) => q.state === "completed").slice(0, 5),
    relationshipNotes: [
      `신뢰 ${core.trust || 0}`,
      `친밀 ${core.intimacy || 0}`,
      `긴장 ${core.tension || 0}`
    ]
  };
}
