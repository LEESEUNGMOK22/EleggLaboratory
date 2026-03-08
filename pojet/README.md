# Ashmark Chronicle - Content Pack Phase

## Added content docs
- docs/content/world-bible.md
- docs/content/factions.md
- docs/content/regions.md
- docs/content/quest-structure.md
- docs/content/npc-casting.md
- docs/content/relationship-tones.md
- docs/content/content-style-guide.md

## Added content data
- data/content/regions.json
- data/content/factions.json
- data/content/npcs.json
- data/content/companions.json
- data/content/questlines.json
- data/content/events-t0.json
- data/content/events-t1.json
- data/content/events-t2.json
- data/content/events-t3.json
- data/content/loot-pools.json
- data/content/location-pools.json
- data/content/log-lines.json
- data/content/portrait-state-tags.json

## Runtime integration
- `src/config/contentLoader.js` loads content pack from `data/content`
- auto loop now uses content events/log lines
- sample run now injects region/faction/NPC/companion intro logs

## Current status
- Structure-first content pack is playable with auto progression rhythm.
- Numeric balance and deep branching are intentionally shallow for now.
