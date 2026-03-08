#!/usr/bin/env python3
import json
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
METRICS_PATH = ROOT / "reports" / "balance" / "latest-metrics.json"
SUMMARY_PATH = ROOT / "reports" / "balance" / "latest-summary.md"


def load_json(path):
    with open(path, "r", encoding="utf-8-sig") as f:
        return json.load(f)


def sorted_items(d, key):
    return sorted(d.items(), key=lambda kv: kv[1].get(key, 0), reverse=True)


def fmt(n, digits=2):
    if n is None:
        return "-"
    return f"{n:.{digits}f}"


def main():
    data = load_json(METRICS_PATH)
    metrics = data["metrics"]
    pacing = metrics["pacing"]
    by_class = metrics["byClass"]
    by_preset = metrics["byPreset"]
    checks = metrics["targetChecks"]
    category_mix = metrics["categoryMix"]

    class_survival = sorted_items(by_class, "survivalRate")
    class_level = sorted_items(by_class, "avgFinalLevel")
    preset_survival = sorted_items(by_preset, "survivalRate")
    preset_taint = sorted_items(by_preset, "avgTaint")
    warned_checks = [k for k, v in checks.items() if v.get("status") == "warn"]

    top_candidates = []
    if class_survival:
        top_candidates.append(f"저생존 클래스 보정: {class_survival[-1][0]} (survival {fmt(class_survival[-1][1]['survivalRate'])})")
        top_candidates.append(f"고생존 클래스 하향 검토: {class_survival[0][0]} (survival {fmt(class_survival[0][1]['survivalRate'])})")
    if preset_survival:
        top_candidates.append(f"함정 프리셋 점검: {preset_survival[-1][0]} (survival {fmt(preset_survival[-1][1]['survivalRate'])})")
    if preset_taint:
        top_candidates.append(f"오염 과다 프리셋 완화: {preset_taint[0][0]} (taint {fmt(preset_taint[0][1]['avgTaint'])})")
    if warned_checks:
        for ck in warned_checks[:4]:
            c = checks[ck]
            top_candidates.append(f"목표 이탈 지표 보정: {ck} actual={fmt(c.get('actual'))} target={fmt(c.get('min'))}-{fmt(c.get('max'))}")
    if category_mix.get("social", 0) < 0.2:
        top_candidates.append("사회 이벤트 노출 증량 (social share 낮음)")
    if category_mix.get("relationship", 0) < 0.08:
        top_candidates.append("관계 이벤트 비중 확장 (relationship share 낮음)")
    while len(top_candidates) < 10:
        top_candidates.append("이벤트 텍스트 변주율 상향 (중복 방지)")
    top_candidates = top_candidates[:10]

    first_t3_ticks = checks.get("firstT3Minutes", {}).get("actual")
    early_dead = metrics["totals"]["earlyDeathRate"]
    empty_early = []
    for class_id, v in by_class.items():
        if v.get("avgFinalLevel", 0) < 2.2 or v.get("avgT2PerRun", 0) < 1.5:
            empty_early.append(class_id)

    lines = []
    lines.append("# Balance Summary")
    lines.append("")
    lines.append(f"- Generated: {datetime.utcnow().isoformat()}Z")
    lines.append(f"- Seed: {data.get('seed')}")
    lines.append(f"- Total runs: {data['scenario']['totalRuns']} (runs/class={data['scenario']['runsPerClass']})")
    lines.append("")
    lines.append("## Pacing Snapshot")
    lines.append(f"- avg log interval: {fmt(pacing['avgLogIntervalTicks'])} ticks / {fmt(pacing['avgLogIntervalSeconds'])} sec")
    lines.append(f"- avg combat frequency: {fmt(pacing['avgCombatPerRun'])} per run")
    lines.append(f"- avg quest updates: {fmt(pacing['avgQuestUpdatesPerRun'])} per run")
    lines.append(f"- avg T2 cycle: {fmt(pacing['avgT2IntervalTicks'])} ticks")
    lines.append(f"- avg T3 cycle: {fmt(pacing['avgT3IntervalTicks'])} ticks")
    base_seconds_per_tick = data.get("scenario", {}).get("baseSecondsPerTick", 1)
    lines.append(f"- avg first level-up: {fmt((pacing['avgFirstLevelupTicks'] * base_seconds_per_tick) / 60)} minutes")
    lines.append(f"- avg run duration: {fmt(pacing['avgRunDurationMinutes'])} minutes")
    lines.append("")
    lines.append("## Strong/Weak Classes")
    lines.append(f"- strongest survival: {class_survival[0][0]} ({fmt(class_survival[0][1]['survivalRate'])})")
    lines.append(f"- weakest survival: {class_survival[-1][0]} ({fmt(class_survival[-1][1]['survivalRate'])})")
    lines.append(f"- highest growth: {class_level[0][0]} (lvl {fmt(class_level[0][1]['avgFinalLevel'])})")
    lines.append(f"- lowest growth: {class_level[-1][0]} (lvl {fmt(class_level[-1][1]['avgFinalLevel'])})")
    lines.append("")
    lines.append("## Preset Risk Scan")
    lines.append(f"- safest preset by survival: {preset_survival[0][0]} ({fmt(preset_survival[0][1]['survivalRate'])})")
    lines.append(f"- riskiest preset by survival: {preset_survival[-1][0]} ({fmt(preset_survival[-1][1]['survivalRate'])})")
    lines.append(f"- highest taint preset: {preset_taint[0][0]} ({fmt(preset_taint[0][1]['avgTaint'])})")
    lines.append("")
    lines.append("## Target Check")
    if warned_checks:
        for ck in warned_checks:
            v = checks[ck]
            lines.append(f"- WARN {ck}: actual={fmt(v.get('actual'))}, target={fmt(v.get('min'))}-{fmt(v.get('max'))}")
    else:
        lines.append("- All target checks are within configured ranges.")
    lines.append("")
    lines.append("## Required Diagnoses")
    lines.append(f"- early-20m empty combinations: {', '.join(empty_early[:6]) if empty_early else 'none'}")
    lines.append(f"- T2/T3 target fit: {'warn' if ('t2IntervalTicks' in warned_checks or 't3IntervalTicks' in warned_checks) else 'ok'}")
    lines.append(f"- relationship/social exposure: social={fmt(category_mix.get('social',0))}, relationship={fmt(category_mix.get('relationship',0))}")
    lines.append(f"- legacy reward trend(avg delta): {fmt(list(metrics['legacyTrend'].values())[-1] if metrics['legacyTrend'] else 0)}")
    lines.append(f"- early death rate: {fmt(early_dead)}")
    lines.append(f"- first T3 mean minute: {fmt(first_t3_ticks)}")
    lines.append("")
    lines.append("## Top 10 Tuning Candidates")
    for i, item in enumerate(top_candidates, start=1):
        lines.append(f"{i}. {item}")
    lines.append("")
    lines.append("## Content Validation Warnings")
    warnings = data.get("contentValidationWarnings", [])
    if warnings:
        for w in warnings[:30]:
            lines.append(f"- {w}")
        if len(warnings) > 30:
            lines.append(f"- ... {len(warnings) - 30} more")
    else:
        lines.append("- none")

    SUMMARY_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(SUMMARY_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print(f"Summary generated: {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
