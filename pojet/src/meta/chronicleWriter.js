import { buildRunSummary } from "./runSummaryGenerator.js";

export function createChronicleEntry(state, endType, runEndMeta, legacyId, portraitTags) {
  const summary = buildRunSummary(state, endType);
  return {
    id: `chr-${Date.now()}`,
    runId: state.run.id,
    title: summary.title,
    tone: runEndMeta?.tone || "비가 멎기 전 기록된 삶",
    summary: summary.summary,
    outcome: endType,
    majorChoices: summary.majorChoices,
    completedQuests: summary.completedQuests,
    relationshipNotes: summary.relationshipNotes,
    portraitSnapshotTags: portraitTags,
    legacyRewardId: legacyId,
    tags: state.character.tags || [],
    boonGold: Math.max(10, Math.floor(state.resources.gold * 0.2)),
    boonRenown: Math.max(0, Math.floor(state.resources.renown * 0.5)),
    boonTaint: Math.max(0, Math.floor(state.resources.taint * 0.3)),
    createdAt: new Date().toISOString()
  };
}
