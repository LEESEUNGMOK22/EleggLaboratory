#!/usr/bin/env python3
import argparse
import json
import random
from collections import Counter, defaultdict
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load_json(path):
    with open(path, "r", encoding="utf-8-sig") as f:
        return json.load(f)


def ability_modifier(score):
    return (score - 10) // 2


def proficiency_bonus(level):
    return 2 + (max(level, 1) - 1) // 4


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


def weighted_choice(rng, choices):
    total = sum(w for _, w in choices)
    roll = rng.random() * total
    upto = 0.0
    for value, weight in choices:
        upto += weight
        if roll <= upto:
            return value
    return choices[-1][0]


def d20(rng, advantage=False, disadvantage=False):
    a = rng.randint(1, 20)
    b = rng.randint(1, 20)
    if advantage and not disadvantage:
        return max(a, b)
    if disadvantage and not advantage:
        return min(a, b)
    return a


def resolve_check(rng, state, ability, dc, proficient=False, advantage=False, disadvantage=False, situational=0):
    mod = ability_modifier(state["abilities"].get(ability, 10))
    prof = proficiency_bonus(state["level"]) if proficient else 0
    fatigue_penalty = state["fatigue"] // 20
    taint_penalty = 2 if state["taint"] >= 70 else 1 if state["taint"] >= 40 else 0
    roll = d20(rng, advantage, disadvantage)
    total = roll + mod + prof + situational - fatigue_penalty - taint_penalty
    return {"roll": roll, "total": total, "success": total >= dc}


def pick_event_for_run(rng, pool, class_id, background_id, act):
    eligible = []
    for ev in pool:
        trig = ev.get("triggerConditions", {})
        if act < trig.get("actMin", 1):
            continue
        class_aff = ev.get("classAffinity", [])
        if class_aff and class_id not in class_aff:
            continue
        bg_aff = ev.get("backgroundAffinity", [])
        if bg_aff and background_id not in bg_aff:
            continue
        eligible.append(ev)
    if not eligible:
        eligible = pool
    return deepcopy(rng.choice(eligible)) if eligible else None


def score_choice(choice, preset):
    effects = choice.get("effects", [])
    score = 0.0
    for fx in effects:
        kind = fx.get("kind")
        val = fx.get("value")
        if kind == "gain_gold":
            score += val * (0.8 - preset.get("reputationVsReward", 0.5))
        elif kind == "renown":
            score += val * (0.5 + preset.get("reputationVsReward", 0.5))
        elif kind == "infamy":
            score += val * (0.25 + (1 - preset.get("reputationVsReward", 0.5)))
        elif kind == "taint":
            score += val * (preset.get("forbiddenPowerBias", 0.3) - 0.5)
        elif kind == "faction" and isinstance(val, dict):
            score += sum(val.values()) * 0.3
        elif kind == "relation" and isinstance(val, dict):
            score += (val.get("trust", 0) + val.get("respect", 0) + val.get("intimacy", 0)) * 0.6
            score -= (val.get("fear", 0) + val.get("tension", 0)) * 0.4
        elif kind == "chronicle_tag":
            score += 0.4
        elif kind == "blessing":
            score += 1.5
    return score


def choose_event_choice(event, preset):
    choices = event.get("choices", [])
    if not choices:
        return None

    mode = preset.get("t2DefaultChoice", "safest")
    if mode == "bold":
        return choices[0]
    if mode == "safest":
        return choices[-1]
    if mode == "profit":
        rich = [c for c in choices if any(fx.get("kind") == "gain_gold" and fx.get("value", 0) > 0 for fx in c.get("effects", []))]
        return rich[0] if rich else choices[0]
    if mode == "mercy":
        mercy = [c for c in choices if c.get("id") in {"seal", "reject", "decline", "withdraw"}]
        return mercy[0] if mercy else choices[-1]
    if mode == "oath":
        oath = [c for c in choices if c.get("id") in {"oath", "seal", "temple", "guild"}]
        return oath[0] if oath else choices[0]
    if mode == "bond":
        bond = [c for c in choices if any(fx.get("kind") == "relation" for fx in c.get("effects", []))]
        return bond[0] if bond else choices[0]

    scored = sorted(choices, key=lambda c: score_choice(c, preset), reverse=True)
    return scored[0]


def apply_effects(state, effects, run_stats):
    for fx in effects:
        kind = fx.get("kind")
        value = fx.get("value")
        if kind == "gain_xp":
            state["xp"] += int(value)
        elif kind == "gain_gold":
            state["gold"] = max(0, state["gold"] + int(value))
        elif kind == "renown":
            state["renown"] += int(value)
        elif kind == "infamy":
            state["infamy"] = max(0, state["infamy"] + int(value))
        elif kind == "taint":
            state["taint"] = clamp(state["taint"] + int(value), 0, 100)
        elif kind == "blessing":
            state["blessing"] = clamp(state["blessing"] + int(value), 0, 100)
        elif kind == "relation" and isinstance(value, dict):
            for k, v in value.items():
                state["relation"][k] = clamp(state["relation"].get(k, 0) + int(v), 0, 100)
        elif kind == "faction" and isinstance(value, dict):
            for k, v in value.items():
                state["factions"][k] = clamp(state["factions"].get(k, 0) + int(v), -100, 100)
        elif kind == "chronicle_tag":
            state["chronicle_tags"].add(str(value))

    trust_like = state["relation"].get("trust", 0) + state["relation"].get("respect", 0) + state["relation"].get("intimacy", 0)
    tension_like = state["relation"].get("tension", 0) + state["relation"].get("fear", 0)
    if trust_like - tension_like > 25 and run_stats["relationship_route_tick"] is None:
        run_stats["relationship_route_tick"] = state["tick"]


def do_level_up(state, run_stats, rng):
    while state["xp"] >= state["level"] * 180:
        state["xp"] -= state["level"] * 180
        state["level"] += 1
        hp_gain = rng.randint(4, 8)
        state["max_hp"] += hp_gain
        state["hp"] = min(state["max_hp"], state["hp"] + hp_gain)
        if run_stats["first_levelup_tick"] is None:
            run_stats["first_levelup_tick"] = state["tick"]


def initial_state_for(class_id, background_id, preset_id, legacy_bonus, rng):
    primary = {
        "barbarian": "STR", "fighter": "STR", "paladin": "CHA", "ranger": "DEX", "rogue": "DEX", "monk": "DEX",
        "wizard": "INT", "cleric": "WIS", "druid": "WIS", "bard": "CHA", "warlock": "CHA", "sorcerer": "CHA"
    }.get(class_id, "STR")

    abilities = {"STR": 10, "DEX": 10, "CON": 10, "INT": 10, "WIS": 10, "CHA": 10}
    abilities[primary] = 15
    abilities["CON"] = max(12, abilities["CON"])
    for key in abilities:
        if key != primary and key != "CON":
            abilities[key] += rng.randint(-1, 2)

    hp_base = {
        "barbarian": 15, "fighter": 13, "paladin": 12, "ranger": 11,
        "rogue": 10, "monk": 10, "bard": 10, "cleric": 11,
        "druid": 10, "warlock": 10, "wizard": 9, "sorcerer": 9
    }.get(class_id, 10)

    con_mod = ability_modifier(abilities["CON"])
    max_hp = max(8, hp_base + con_mod + legacy_bonus.get("hp", 0))

    return {
        "class_id": class_id,
        "background_id": background_id,
        "preset_id": preset_id,
        "act": 1,
        "tick": 0,
        "level": 1,
        "xp": 0,
        "abilities": abilities,
        "max_hp": max_hp,
        "hp": max_hp,
        "gold": 20 + legacy_bonus.get("gold", 0),
        "supplies": 5 + legacy_bonus.get("supplies", 0),
        "fatigue": 0,
        "taint": clamp(legacy_bonus.get("taint", 0), 0, 100),
        "blessing": max(0, legacy_bonus.get("blessing", 0)),
        "renown": legacy_bonus.get("renown", 0),
        "infamy": max(0, legacy_bonus.get("infamy", 0)),
        "quest_progress": 0,
        "quest_updates": 0,
        "act_progress": 0,
        "relation": {"trust": 20, "intimacy": 5, "tension": 8, "desire": 6, "respect": 10, "fear": 4},
        "factions": {"guild": 0, "temple": 0, "mercenary": 0, "nobility": 0, "underbelly": 0},
        "chronicle_tags": set(),
        "legacy_score": legacy_bonus.get("score", 0)
    }


def phase_weights_for(class_ai):
    style = class_ai.get("combatStyle", "balanced")
    if "frontline" in style or "brutal" in style:
        return [("combat", 0.42), ("exploration", 0.27), ("social", 0.18), ("rest", 0.13)]
    if "support" in style:
        return [("combat", 0.3), ("exploration", 0.27), ("social", 0.29), ("rest", 0.14)]
    if "control" in style:
        return [("combat", 0.33), ("exploration", 0.29), ("social", 0.24), ("rest", 0.14)]
    return [("combat", 0.35), ("exploration", 0.3), ("social", 0.22), ("rest", 0.13)]


def apply_phase(rng, state, phase, class_ai, run_stats):
    if phase == "combat":
        atk_ability = "STR"
        if state["class_id"] in {"rogue", "ranger", "monk"}:
            atk_ability = "DEX"
        elif state["class_id"] in {"wizard"}:
            atk_ability = "INT"
        elif state["class_id"] in {"bard", "sorcerer", "warlock", "paladin"}:
            atk_ability = "CHA"
        elif state["class_id"] in {"cleric", "druid"}:
            atk_ability = "WIS"

        dc = 10 + state["act"] + int((state["tick"] / 50))
        advantage = class_ai.get("riskTolerance", 0.5) > 0.65 and rng.random() < 0.2
        chk = resolve_check(rng, state, atk_ability, dc, proficient=True, advantage=advantage)
        victory = chk["success"] or rng.random() < 0.2

        if victory:
            state["xp"] += rng.randint(10, 20)
            state["gold"] += rng.randint(6, 15)
            state["act_progress"] += rng.randint(3, 7)
            state["fatigue"] = clamp(state["fatigue"] + rng.randint(2, 5), 0, 100)
            state["renown"] += 1 if rng.random() < 0.55 else 0
            hp_loss = rng.randint(0, 3)
        else:
            state["xp"] += rng.randint(4, 8)
            hp_loss = rng.randint(3, 8)
            state["fatigue"] = clamp(state["fatigue"] + rng.randint(5, 9), 0, 100)
            if rng.random() < 0.35:
                state["taint"] = clamp(state["taint"] + 1, 0, 100)
        state["hp"] = max(0, state["hp"] - hp_loss)
        run_stats["combat_count"] += 1
    elif phase == "exploration":
        dc = 12 + state["act"] // 2
        chk = resolve_check(rng, state, "WIS", dc, proficient=True, advantage=(state["blessing"] >= 5))
        success = chk["success"]
        state["quest_progress"] += rng.randint(11, 18) if success else rng.randint(5, 9)
        state["act_progress"] += rng.randint(4, 8) if success else rng.randint(2, 4)
        state["supplies"] = max(0, state["supplies"] - 1)
        state["fatigue"] = clamp(state["fatigue"] + (2 if success else 4), 0, 100)
        state["xp"] += rng.randint(8, 14) if success else rng.randint(4, 8)
        run_stats["exploration_count"] += 1
    elif phase == "social":
        disadvantage = state["taint"] >= 50
        chk = resolve_check(rng, state, "CHA", 13 + state["act"] // 2, proficient=True, disadvantage=disadvantage)
        if chk["success"]:
            state["renown"] += 2
            state["xp"] += rng.randint(8, 12)
            state["relation"]["trust"] = clamp(state["relation"]["trust"] + 2, 0, 100)
            state["relation"]["respect"] = clamp(state["relation"]["respect"] + 2, 0, 100)
            state["factions"]["guild"] = clamp(state["factions"]["guild"] + 1, -100, 100)
        else:
            state["renown"] -= 1
            state["xp"] += rng.randint(4, 7)
            state["relation"]["tension"] = clamp(state["relation"]["tension"] + 2, 0, 100)
            state["relation"]["fear"] = clamp(state["relation"]["fear"] + 1, 0, 100)
            state["factions"]["nobility"] = clamp(state["factions"]["nobility"] - 1, -100, 100)
        run_stats["social_count"] += 1
        run_stats["relationship_events"] += 1
    else:
        rest_gain = rng.randint(4, 8)
        state["hp"] = min(state["max_hp"], state["hp"] + rest_gain)
        state["fatigue"] = max(0, state["fatigue"] - rng.randint(4, 7))
        if state["supplies"] == 0:
            state["taint"] = clamp(state["taint"] + 1, 0, 100)
        run_stats["rest_count"] += 1

    if state["quest_progress"] >= 100:
        run_stats["quest_updates"] += 1
        state["quest_progress"] %= 100

    if state["act_progress"] >= 100:
        state["act"] = min(5, state["act"] + 1)
        state["act_progress"] %= 100

    if state["supplies"] == 0:
        run_stats["resource_starvation_ticks"] += 1


def validate_content(data, rules):
    warnings = []
    all_events = data["events_all"]
    all_event_ids = {e.get("id") for e in all_events}

    if rules["dataRules"].get("requireChronicleImpactForT3"):
        for e in data["events_t3"]:
            if not e.get("chronicleTags"):
                warnings.append(f"T3 event missing chronicleTags: {e.get('id')}")

    if rules["dataRules"].get("requireRelationshipAxisDeltaForRelationshipEvents"):
        relation_events = [e for e in all_events if e.get("category") == "relationship"]
        for e in relation_events:
            has_rel = False
            for c in e.get("choices", []):
                if any(fx.get("kind") == "relation" for fx in c.get("effects", [])):
                    has_rel = True
                    break
            if not has_rel:
                warnings.append(f"Relationship event missing relation effect: {e.get('id')}")

    if rules["dataRules"].get("requireValidFollowUpEventIds"):
        for e in all_events:
            for fid in e.get("followUpEventIds", []):
                if fid not in all_event_ids:
                    warnings.append(f"Invalid follow-up event id: {e.get('id')} -> {fid}")

    if rules["dataRules"].get("requireKnownFactionNpcIds"):
        faction_ids = {f.get("id") for f in data["factions"]}
        npc_ids = {n.get("id") for n in data["npcs"]}
        companion_ids = {c.get("id") for c in data["companions"]}
        for n in data["npcs"]:
            if n.get("faction") and n.get("faction") not in faction_ids:
                warnings.append(f"NPC unknown faction: {n.get('id')} -> {n.get('faction')}")
        for c in data["companions"]:
            if c.get("faction") and c.get("faction") not in faction_ids:
                warnings.append(f"Companion unknown faction: {c.get('id')} -> {c.get('faction')}")
            for eid in c.get("eventLinks", []):
                if eid not in all_event_ids:
                    warnings.append(f"Companion unknown event link: {c.get('id')} -> {eid}")
        for q in data["questlines"]:
            for s in q.get("stages", []):
                if not isinstance(s, dict):
                    continue
                for npc in s.get("npcs", []):
                    if npc not in npc_ids and npc not in companion_ids:
                        warnings.append(f"Quest unknown npc id: {q.get('id')} -> {npc}")

    max_len = rules["dataRules"].get("maxLogLineLength", 95)
    for cat, lines in data["log_lines"].items():
        for line in lines:
            if len(line) > max_len:
                warnings.append(f"Long log line ({len(line)}): {cat}")

    banned = [w.lower() for w in rules["dataRules"].get("bannedProperNouns", [])]
    for e in all_events:
        text = f"{e.get('narrativeText', '')} {e.get('logSummary', '')}".lower()
        for bad in banned:
            if bad and bad in text:
                warnings.append(f"Banned proper noun in event {e.get('id')}: {bad}")

    max_dup = rules["dataRules"].get("maxDuplicateNarrativeRatio", 0.35)
    for tier_name, evs in [("T0", data["events_t0"]), ("T1", data["events_t1"]), ("T2", data["events_t2"]), ("T3", data["events_t3"])]:
        normalized = []
        for e in evs:
            txt = (e.get("narrativeText") or e.get("logSummary") or "").strip().lower()
            normalized.append(" ".join(txt.split()))
        if normalized:
            total = len(normalized)
            dup = total - len(set(normalized))
            ratio = dup / total
            if ratio > max_dup:
                warnings.append(f"{tier_name} duplicate narrative ratio high: {ratio:.2f}")
    return warnings


def simulate_one_run(rng, class_id, preset_id, background_id, datasets, config, legacy_bonus):
    class_ai = datasets["class_ai"].get(class_id, datasets["class_ai"].get("fighter", {}))
    preset = datasets["decision_presets"].get(preset_id, datasets["decision_presets"]["신중형"])

    state = initial_state_for(class_id, background_id, preset_id, legacy_bonus, rng)
    speed = rng.choice(config["speedDistribution"])
    run_stats = {
        "class_id": class_id,
        "preset_id": preset_id,
        "background_id": background_id,
        "speed": speed,
        "logs": 0,
        "combat_count": 0,
        "exploration_count": 0,
        "social_count": 0,
        "rest_count": 0,
        "quest_updates": 0,
        "t2_count": 0,
        "t3_count": 0,
        "relationship_events": 0,
        "faction_events": 0,
        "first_levelup_tick": None,
        "first_relationship_tick": None,
        "first_faction_conflict_tick": None,
        "first_t3_tick": None,
        "relationship_route_tick": None,
        "resource_starvation_ticks": 0,
        "pause_seconds": 0.0,
        "survived": True,
        "end_type": "unknown",
        "legacy_delta": 0.0,
        "time_seconds": 0.0,
        "ticks": 0,
        "log_interval_ticks": []
    }

    phase_weights = phase_weights_for(class_ai)
    last_log_tick = 0
    last_t2_tick = -999
    last_t3_tick = -999

    for tick in range(1, config["maxTicksPerRun"] + 1):
        state["tick"] = tick
        run_stats["logs"] += 1
        run_stats["log_interval_ticks"].append(tick - last_log_tick)
        last_log_tick = tick

        phase = weighted_choice(rng, phase_weights)
        apply_phase(rng, state, phase, class_ai, run_stats)
        do_level_up(state, run_stats, rng)
        # Auto resource behavior: when low HP, consume supplies as emergency treatment.
        if state["hp"] < state["max_hp"] * 0.35 and state["supplies"] > 0 and rng.random() < 0.55:
            state["hp"] = min(state["max_hp"], state["hp"] + rng.randint(6, 10))
            state["supplies"] = max(0, state["supplies"] - 1)
            state["fatigue"] = max(0, state["fatigue"] - 1)

        if run_stats["first_relationship_tick"] is None:
            if (state["relation"]["trust"] - 20) >= 6 or (state["relation"]["tension"] - 8) >= 6:
                run_stats["first_relationship_tick"] = tick

        if run_stats["first_faction_conflict_tick"] is None:
            reps = state["factions"]
            if abs(reps.get("guild", 0) - reps.get("underbelly", 0)) >= 8 or abs(reps.get("temple", 0) - reps.get("nobility", 0)) >= 8:
                run_stats["first_faction_conflict_tick"] = tick

        event_cfg = config["event"]
        t2_chance = event_cfg["t2BaseChance"]
        if tick - last_t2_tick >= event_cfg["t2EscalationAfterTicks"]:
            t2_chance += event_cfg["t2EscalationBonus"]
        t2_chance += 0.03 * preset.get("riskTolerance", 0.5)

        t3_chance = 0.0
        if tick >= event_cfg["t3MinTick"]:
            t3_chance = event_cfg["t3BaseChance"] + state["act"] * event_cfg["t3ActBonus"]
            if tick - last_t3_tick >= event_cfg["t3EscalationAfterTicks"]:
                t3_chance += event_cfg["t3EscalationBonus"]

        if rng.random() < t2_chance:
            event = pick_event_for_run(rng, datasets["events_t2"], class_id, background_id, state["act"])
            if event:
                run_stats["t2_count"] += 1
                last_t2_tick = tick
                run_stats["pause_seconds"] += 1.5
                if event.get("category") == "relationship":
                    run_stats["relationship_events"] += 1
                if event.get("category") == "faction":
                    run_stats["faction_events"] += 1
                choice = choose_event_choice(event, preset)
                if choice:
                    apply_effects(state, choice.get("effects", []), run_stats)
                for outcome in event.get("outcomes", []):
                    apply_effects(state, outcome.get("effects", []), run_stats)

        if rng.random() < t3_chance:
            event = pick_event_for_run(rng, datasets["events_t3"], class_id, background_id, state["act"])
            if event:
                run_stats["t3_count"] += 1
                last_t3_tick = tick
                run_stats["pause_seconds"] += 5.0
                if run_stats["first_t3_tick"] is None:
                    run_stats["first_t3_tick"] = tick
                if event.get("category") == "relationship":
                    run_stats["relationship_events"] += 1
                if event.get("category") == "faction":
                    run_stats["faction_events"] += 1
                choice = choose_event_choice(event, preset)
                if choice:
                    apply_effects(state, choice.get("effects", []), run_stats)
                for outcome in event.get("outcomes", []):
                    apply_effects(state, outcome.get("effects", []), run_stats)

        if state["hp"] <= 0:
            run_stats["survived"] = False
            run_stats["end_type"] = "battle_death"
            break
        if state["taint"] >= 90:
            run_stats["survived"] = False
            run_stats["end_type"] = "corruption_fall"
            break
        if state["act"] >= 5 and state["renown"] >= 35 and tick >= 55:
            run_stats["end_type"] = "faction_ascension"
            break
        if "forbidden-power" in state["chronicle_tags"] and state["taint"] > 60:
            run_stats["end_type"] = "forbidden_fusion"
            break

    if run_stats["end_type"] == "unknown":
        if state["act"] >= 4 and state["renown"] >= 18:
            run_stats["end_type"] = "glorious_retirement"
        elif state["tick"] >= config["maxTicksPerRun"]:
            run_stats["end_type"] = "vanished_legend"
        else:
            run_stats["end_type"] = "glorious_retirement"

    run_stats["ticks"] = state["tick"]
    run_stats["time_seconds"] = state["tick"] * (config["baseSecondsPerTick"] / speed) + run_stats["pause_seconds"]
    run_stats["final_level"] = state["level"]
    run_stats["final_gold"] = state["gold"]
    run_stats["final_renown"] = state["renown"]
    run_stats["final_taint"] = state["taint"]
    run_stats["final_supplies"] = state["supplies"]
    run_stats["final_act"] = state["act"]
    run_stats["legacy_delta"] = (state["level"] - 1) * 0.5 + (1 if run_stats["end_type"] in {"glorious_retirement", "faction_ascension"} else -0.25)
    run_stats["category_counts"] = {
        "combat": run_stats["combat_count"],
        "exploration": run_stats["exploration_count"],
        "social": run_stats["social_count"],
        "rest": run_stats["rest_count"],
        "relationship": run_stats["relationship_events"],
        "faction": run_stats["faction_events"]
    }
    return run_stats


def aggregate_metrics(runs, rules, base_seconds_per_tick):
    def avg(values):
        return sum(values) / len(values) if values else 0.0

    totals = {
        "runs": len(runs),
        "survivalRate": avg([1.0 if r["survived"] else 0.0 for r in runs]),
        "earlyDeathRate": avg([1.0 if (not r["survived"] and r["ticks"] < 30) else 0.0 for r in runs])
    }

    pacing = {
        "avgLogIntervalTicks": avg([avg(r["log_interval_ticks"]) for r in runs]),
        "avgLogIntervalSeconds": avg([(r["time_seconds"] / max(r["logs"], 1)) for r in runs]),
        "avgCombatPerRun": avg([r["combat_count"] for r in runs]),
        "avgQuestUpdatesPerRun": avg([r["quest_updates"] for r in runs]),
        "avgT2PerRun": avg([r["t2_count"] for r in runs]),
        "avgT3PerRun": avg([r["t3_count"] for r in runs]),
        "avgFirstLevelupTicks": avg([r["first_levelup_tick"] for r in runs if r["first_levelup_tick"] is not None]),
        "avgFirstRelationshipTicks": avg([r["first_relationship_tick"] for r in runs if r["first_relationship_tick"] is not None]),
        "avgFirstFactionConflictTicks": avg([r["first_faction_conflict_tick"] for r in runs if r["first_faction_conflict_tick"] is not None]),
        "avgRunDurationTicks": avg([r["ticks"] for r in runs]),
        "avgRunDurationMinutes": avg([r["time_seconds"] / 60 for r in runs])
    }

    pacing["avgT2IntervalTicks"] = avg([r["ticks"] / r["t2_count"] for r in runs if r["t2_count"] > 0])
    pacing["avgT3IntervalTicks"] = avg([r["ticks"] / r["t3_count"] for r in runs if r["t3_count"] > 0])

    speed_groups = defaultdict(list)
    for r in runs:
        speed_groups[str(r["speed"])].append(r)

    by_speed = {}
    for speed, group in speed_groups.items():
        by_speed[speed] = {
            "runs": len(group),
            "avgDurationMinutes": avg([g["time_seconds"] / 60 for g in group]),
            "avgT2PerRun": avg([g["t2_count"] for g in group]),
            "avgT3PerRun": avg([g["t3_count"] for g in group]),
            "avgPauseSeconds": avg([g["pause_seconds"] for g in group])
        }

    by_class = {}
    class_groups = defaultdict(list)
    for r in runs:
        class_groups[r["class_id"]].append(r)
    for class_id, group in class_groups.items():
        by_class[class_id] = {
            "runs": len(group),
            "survivalRate": avg([1.0 if g["survived"] else 0.0 for g in group]),
            "avgFinalLevel": avg([g["final_level"] for g in group]),
            "avgRunMinutes": avg([g["time_seconds"] / 60 for g in group]),
            "avgT2PerRun": avg([g["t2_count"] for g in group]),
            "avgT3PerRun": avg([g["t3_count"] for g in group]),
            "avgRelationshipRouteTick": avg([g["relationship_route_tick"] for g in group if g["relationship_route_tick"] is not None]),
            "earlyDeathRate": avg([1.0 if (not g["survived"] and g["ticks"] < 30) else 0.0 for g in group])
        }

    by_preset = {}
    preset_groups = defaultdict(list)
    for r in runs:
        preset_groups[r["preset_id"]].append(r)
    for preset_id, group in preset_groups.items():
        by_preset[preset_id] = {
            "runs": len(group),
            "survivalRate": avg([1.0 if g["survived"] else 0.0 for g in group]),
            "avgFinalLevel": avg([g["final_level"] for g in group]),
            "avgTaint": avg([g["final_taint"] for g in group]),
            "avgT2PerRun": avg([g["t2_count"] for g in group]),
            "avgT3PerRun": avg([g["t3_count"] for g in group])
        }

    by_background = {}
    bg_groups = defaultdict(list)
    for r in runs:
        bg_groups[r["background_id"]].append(r)
    for bg, group in bg_groups.items():
        by_background[bg] = {
            "runs": len(group),
            "survivalRate": avg([1.0 if g["survived"] else 0.0 for g in group]),
            "avgFinalLevel": avg([g["final_level"] for g in group]),
            "avgGold": avg([g["final_gold"] for g in group])
        }

    category_totals = Counter()
    for r in runs:
        category_totals.update(r["category_counts"])
    cat_sum = sum(category_totals.values()) or 1
    category_mix = {k: v / cat_sum for k, v in category_totals.items()}
    end_types = Counter(r["end_type"] for r in runs)

    legacy_trend = {}
    bucket_size = max(1, len(runs) // 8)
    running = 0.0
    for i, r in enumerate(runs, start=1):
        running += r["legacy_delta"]
        if i % bucket_size == 0 or i == len(runs):
            legacy_trend[f"run_{i}"] = round(running / i, 4)

    targets = rules.get("targets", {})
    target_checks = {}
    for key, bounds in targets.items():
        min_v = bounds.get("min")
        max_v = bounds.get("max")
        actual = None
        if key == "t2IntervalTicks":
            actual = pacing.get("avgT2IntervalTicks")
        elif key == "t3IntervalTicks":
            actual = pacing.get("avgT3IntervalTicks")
        elif key == "combatShare":
            actual = category_mix.get("combat", 0)
        elif key == "explorationShare":
            actual = category_mix.get("exploration", 0)
        elif key == "socialShare":
            actual = category_mix.get("social", 0)
        elif key == "relationshipEventShare":
            actual = category_mix.get("relationship", 0)
        elif key == "firstLevelupMinutes":
            actual = (pacing.get("avgFirstLevelupTicks", 0) * base_seconds_per_tick) / 60 if pacing.get("avgFirstLevelupTicks") else None
        elif key == "firstT3Minutes":
            first_t3 = [r["first_t3_tick"] for r in runs if r["first_t3_tick"] is not None]
            actual = ((avg(first_t3) * base_seconds_per_tick) / 60) if first_t3 else None
        elif key == "runDurationMinutes":
            actual = pacing.get("avgRunDurationMinutes")
        elif key == "earlyDeathRate":
            actual = totals.get("earlyDeathRate")
        status = "unknown"
        if actual is not None:
            status = "pass" if min_v <= actual <= max_v else "warn"
        target_checks[key] = {"actual": actual, "min": min_v, "max": max_v, "status": status}

    return {
        "totals": totals,
        "pacing": pacing,
        "bySpeed": by_speed,
        "byClass": by_class,
        "byPreset": by_preset,
        "byBackground": by_background,
        "categoryMix": category_mix,
        "endTypes": dict(end_types),
        "legacyTrend": legacy_trend,
        "targetChecks": target_checks
    }


def main():
    parser = argparse.ArgumentParser(description="Run balance simulation for Ashmark Chronicle.")
    parser.add_argument("--runs", type=int, default=None, help="Override total runs.")
    parser.add_argument("--runs-per-class", type=int, default=None, help="Override runs per class.")
    parser.add_argument("--seed", type=int, default=None, help="Seed override.")
    parser.add_argument("--out", default=str(ROOT / "reports" / "balance" / "latest-metrics.json"), help="Output json path")
    args = parser.parse_args()

    scenarios = load_json(ROOT / "tools" / "sim" / "sample-scenarios.json")
    rules = load_json(ROOT / "tools" / "sim" / "validation-rules.json")
    classes = sorted(load_json(ROOT / "data" / "gameplay" / "class-ai-presets.json").keys())
    decision_presets = load_json(ROOT / "data" / "gameplay" / "decision-presets.json")

    datasets = {
        "class_ai": load_json(ROOT / "data" / "gameplay" / "class-ai-presets.json"),
        "decision_presets": decision_presets,
        "events_t0": load_json(ROOT / "data" / "content" / "events-t0.json"),
        "events_t1": load_json(ROOT / "data" / "content" / "events-t1.json"),
        "events_t2": load_json(ROOT / "data" / "content" / "events-t2.json"),
        "events_t3": load_json(ROOT / "data" / "content" / "events-t3.json"),
        "factions": load_json(ROOT / "data" / "content" / "factions.json"),
        "npcs": load_json(ROOT / "data" / "content" / "npcs.json"),
        "companions": load_json(ROOT / "data" / "content" / "companions.json"),
        "questlines": load_json(ROOT / "data" / "content" / "questlines.json"),
        "log_lines": load_json(ROOT / "data" / "content" / "log-lines.json")
    }
    datasets["events_all"] = datasets["events_t0"] + datasets["events_t1"] + datasets["events_t2"] + datasets["events_t3"]
    content_warnings = validate_content(datasets, rules)

    runs_per_class = args.runs_per_class if args.runs_per_class is not None else scenarios.get("runsPerClass", 120)
    target_total_runs = args.runs
    seed = args.seed if args.seed is not None else scenarios.get("seed", 0)
    rng = random.Random(seed)

    presets = [p for p in scenarios.get("presets", list(decision_presets.keys())) if p in decision_presets]
    if not presets:
        presets = list(decision_presets.keys())
    backgrounds = scenarios.get("backgrounds", ["border-conscript"])

    runs = []
    class_legacy = {c: {"score": 0, "gold": 0, "renown": 0, "taint": 0, "blessing": 0, "supplies": 0, "hp": 0, "infamy": 0} for c in classes}
    for class_id in classes:
        run_count = runs_per_class
        if target_total_runs is not None:
            run_count = max(1, target_total_runs // max(1, len(classes)))
        for i in range(run_count):
            preset_id = presets[i % len(presets)]
            background_id = backgrounds[i % len(backgrounds)]
            legacy_bonus = deepcopy(class_legacy[class_id])
            run = simulate_one_run(rng, class_id, preset_id, background_id, datasets, scenarios, legacy_bonus)
            class_legacy[class_id]["score"] = max(-5, min(30, class_legacy[class_id]["score"] + run["legacy_delta"]))
            class_legacy[class_id]["gold"] = int(class_legacy[class_id]["score"] * 0.6)
            class_legacy[class_id]["renown"] = int(class_legacy[class_id]["score"] * 0.25)
            class_legacy[class_id]["taint"] = int(max(0, class_legacy[class_id]["score"] - 6) * 0.2)
            class_legacy[class_id]["blessing"] = int(max(0, class_legacy[class_id]["score"] - 4) * 0.15)
            class_legacy[class_id]["supplies"] = int(max(0, class_legacy[class_id]["score"]) * 0.05)
            class_legacy[class_id]["hp"] = int(max(0, class_legacy[class_id]["score"]) * 0.05)
            runs.append(run)

    metrics = aggregate_metrics(runs, rules, scenarios.get("baseSecondsPerTick", 1))
    output = {
        "generatedAt": __import__("datetime").datetime.utcnow().isoformat() + "Z",
        "seed": seed,
        "scenario": {
            "runsPerClass": runs_per_class,
            "totalRuns": len(runs),
            "classes": classes,
            "presets": presets,
            "backgrounds": backgrounds,
            "maxTicksPerRun": scenarios.get("maxTicksPerRun"),
            "baseSecondsPerTick": scenarios.get("baseSecondsPerTick")
        },
        "contentValidationWarnings": content_warnings,
        "metrics": metrics
    }

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"Simulation complete: {len(runs)} runs")
    print(f"Output: {out_path}")
    print(f"Validation warnings: {len(content_warnings)}")


if __name__ == "__main__":
    main()
