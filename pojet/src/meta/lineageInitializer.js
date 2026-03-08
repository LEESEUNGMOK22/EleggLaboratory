export function initNextRunFromLineage(state, archiveEntry, reward) {
  const patch = { resources: {}, factions: { reputation: {} }, character: { tags: [] } };
  if (!archiveEntry) return patch;

  patch.resources.gold = Math.max(20, Math.floor((archiveEntry.boonGold || 10) + 10));
  patch.resources.renown = archiveEntry.boonRenown || 0;
  patch.resources.taint = archiveEntry.boonTaint || 0;

  if (reward?.startingReputation) {
    Object.entries(reward.startingReputation).forEach(([k, v]) => { patch.factions.reputation[k] = v; });
  }

  if (reward?.inheritedScar) patch.character.tags.push("wounded_minor");
  if (reward?.inheritedBlessing) patch.character.tags.push("blessed");
  if (reward?.inheritedDebt) patch.character.tags.push("hunted");

  return patch;
}
