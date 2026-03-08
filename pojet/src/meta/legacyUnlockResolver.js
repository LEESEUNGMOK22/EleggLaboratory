export function resolveLegacyReward(legacyRewards, rewardId) {
  if (!rewardId) return null;
  return legacyRewards?.[rewardId] || null;
}

export function applyLegacyToRun(state, reward) {
  if (!reward) return state;
  const next = structuredClone(state);

  next.resources.gold += 10;
  next.resources.renown += Math.floor((reward.legacyXpBonus || 0) * 20);
  if (reward.startingReputation) {
    Object.entries(reward.startingReputation).forEach(([k, v]) => {
      const key = mapRepKey(k);
      next.factions.reputation[key] = (next.factions.reputation[key] || 0) + v;
    });
  }

  next.character.inventory = next.character.inventory || [];
  if (reward.heirloomItem) next.character.inventory.push(reward.heirloomItem);
  if (reward.inheritedBlessing) next.character.tags.push("blessed");
  if (reward.inheritedScar) next.character.tags.push("wounded_minor");
  if (reward.inheritedDebt) next.character.tags.push("hunted");

  next.chronicle.legacyFlags = [...new Set([...(next.chronicle.legacyFlags || []), ...(reward.narrativeTags || [])])];
  return next;
}

function mapRepKey(k) {
  if (k === "nobility") return "nobility";
  if (k === "glass") return "temple";
  return k;
}
