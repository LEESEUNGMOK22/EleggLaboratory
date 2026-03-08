import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / "data" / "content"


def load(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def save(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def garbled(s):
    if not isinstance(s, str):
        return False
    t = s.strip()
    if not t:
        return True
    if "??" in t:
        return True
    return t.count("?") >= 2


REGION_KO = {
    "ashen-frontier": "검은비 변경",
    "gray-harbor": "회색 항구",
    "stella-hill": "성좌 언덕",
    "glass-lower": "유리탑 하층",
    "ashgate-ruins": "재문 폐허",
}

CATEGORY_KO = {
    "combat": "전투",
    "exploration": "탐험",
    "social": "사회",
    "relationship": "관계",
    "faction": "세력",
    "relic": "유물",
    "market": "시장",
    "faith": "신앙",
    "corruption": "오염",
    "travel": "여정",
    "legacy": "계승",
}


def fix_events(filename, tier):
    p = CONTENT / filename
    events = load(p)
    for i, e in enumerate(events, start=1):
        cat = e.get("category", "social")
        cat_ko = CATEGORY_KO.get(cat, "사건")
        region_tag = (e.get("regionTags") or ["ashen-frontier"])[0]
        region_ko = REGION_KO.get(region_tag, "변경")

        if garbled(e.get("logSummary", "")):
            e["logSummary"] = f"{cat_ko} 사건 #{i}"
        if garbled(e.get("narrativeText", "")):
            if tier in ("T0", "T1"):
                e["narrativeText"] = f"{region_ko}에서 {cat_ko.lower()} 관련 기류가 포착됐다. 자동 흐름 속에서 처리된다."
            elif tier == "T2":
                e["narrativeText"] = f"{region_ko}에서 {cat_ko.lower()} 문제가 불거졌다. 개입하지 않으면 성향 프리셋에 따라 자동 처리된다."
            else:
                e["narrativeText"] = f"{region_ko}에서 운명을 바꿀 {cat_ko.lower()} 결단의 순간이 찾아왔다."

        if tier in ("T2", "T3"):
            choices = e.get("choices") or []
            defaults_t2 = ["강행한다", "신중히 처리한다", "물러선다"]
            defaults_t3 = ["맹세를 따른다", "대가를 감수한다", "봉인하고 떠난다"]
            defaults = defaults_t2 if tier == "T2" else defaults_t3
            for cidx, c in enumerate(choices):
                if garbled(c.get("label", "")):
                    c["label"] = defaults[min(cidx, len(defaults) - 1)]
    save(p, events)


def fix_log_lines():
    p = CONTENT / "log-lines.json"
    data = load(p)
    templates = {
        "movement": "먼지 낀 길을 지나 {n}번째 이정표를 확인했다.",
        "combat": "짧은 충돌 끝에 숨을 고르고 전열을 정리했다. ({n})",
        "loot": "낡은 상자에서 쓸 만한 물건을 건졌다. ({n})",
        "rest": "모닥불 옆에서 상처를 추스르며 밤을 넘겼다. ({n})",
        "market": "장터에서 값을 흥정하며 짐을 정리했다. ({n})",
        "relationship": "짧은 눈맞춤 뒤에 묘한 여운이 남았다. ({n})",
        "faith_corruption": "기도와 속삭임이 뒤섞인 밤공기가 스쳤다. ({n})",
        "quest": "의뢰 장부에 새 줄이 추가됐다. ({n})",
        "rumor": "술집 구석에서 낯선 소문이 번졌다. ({n})",
    }
    for key, arr in data.items():
        if not isinstance(arr, list):
            continue
        changed = False
        for i, v in enumerate(arr, start=1):
            if garbled(v):
                arr[i - 1] = templates.get(key, "기록이 갱신됐다. ({n})").format(n=i)
                changed = True
        if changed:
            data[key] = arr
    save(p, data)


def fix_simple_objects():
    for fname, name_key, summary_key, default_name, default_summary in [
        ("regions.json", "name", "summary", "무명 지역", "오래된 소문이 떠도는 곳이다."),
        ("factions.json", "name", "identity", "무명 세력", "도시의 균형을 흔드는 단체다."),
    ]:
        p = CONTENT / fname
        rows = load(p)
        for i, row in enumerate(rows, start=1):
            if garbled(row.get(name_key, "")):
                row[name_key] = f"{default_name} {i}"
            if garbled(row.get(summary_key, "")):
                row[summary_key] = default_summary
        save(p, rows)

    p = CONTENT / "location-pools.json"
    pools = load(p)
    fallback = {
        1: ["검은비 변경", "회색 수문", "묘지 외곽", "마른 숲길"],
        2: ["도시 하층", "등불 시장", "붉은 예배당", "밀수 부두"],
        3: ["봉인의 계단", "유리탑 하부", "재의 폐허", "균열 전실"],
        4: ["철의 의회", "침묵 성문", "전쟁 지휘소", "몰락 궁정"],
        5: ["계승의 전당", "무명인의 묘역", "잿빛 관문", "이름 없는 첨탑"],
    }
    for row in pools:
        act = int(row.get("act", 1))
        locs = row.get("locations", [])
        if any(garbled(x) for x in locs):
            row["locations"] = fallback.get(act, fallback[1])
    save(p, pools)

    p = CONTENT / "loot-pools.json"
    pools = load(p)
    default_items = ["마모된 쇠검", "재봉선 망토", "검은 가죽장갑", "은실 성물", "균열 반지"]
    for i, row in enumerate(pools, start=1):
        if garbled(row.get("name", "")):
            row["name"] = f"전리품 묶음 {i}"
        items = row.get("items", [])
        if any(garbled(x) for x in items):
            row["items"] = default_items
    save(p, pools)


def fix_npcs_and_quests():
    p = CONTENT / "npcs.json"
    npcs = load(p)
    for i, n in enumerate(npcs, start=1):
        if garbled(n.get("name", "")):
            n["name"] = f"인물-{i:03d}"
        for key, text in {
            "role": "도시의 중개인",
            "publicFace": "겉으로는 침착한 인상",
            "hiddenAngle": "숨겨진 이해관계를 품고 있다.",
            "firstImpression": "첫인상은 단정하지만 경계를 늦출 수 없다.",
            "routePotential": "동맹/경쟁 루트",
        }.items():
            if garbled(n.get(key, "")):
                n[key] = text
    save(p, npcs)

    p = CONTENT / "questlines.json"
    quests = load(p)
    for i, q in enumerate(quests, start=1):
        if garbled(q.get("title", "")):
            q["title"] = f"재의 의뢰 {i:03d}"
        if garbled(q.get("emotionalTheme", "")):
            q["emotionalTheme"] = "의무"
        stages = q.get("stages", [])
        if isinstance(stages, list):
            q["stages"] = [s if not garbled(s) else f"단계 {idx+1} 진행" for idx, s in enumerate(stages)]
        fails = q.get("failureStates", [])
        if isinstance(fails, list):
            q["failureStates"] = [f if not garbled(f) else "진행 지연" for f in fails]
        rewards = q.get("rewards", {})
        if isinstance(rewards, dict) and isinstance(rewards.get("narrative"), list):
            rewards["narrative"] = [x if not garbled(x) else "도시의 시선이 달라졌다." for x in rewards["narrative"]]
            q["rewards"] = rewards
    save(p, quests)


def default_by_key(key, idx=0):
    key = key or ""
    mapping = {
        "name": "이름 미정",
        "role": "역할 미정",
        "publicFace": "겉으로는 침착한 인상",
        "hiddenAngle": "숨은 의도가 있다.",
        "firstImpression": "첫인상은 강렬하다.",
        "routePotential": "동맹/갈등 루트",
        "displayName": "상태 태그",
        "visualHint": "표정과 조명에 반영",
        "identity": "세력 소개 문구",
        "hiddenCost": "숨겨진 대가가 따른다.",
        "reward": "보상 획득",
        "risk": "위험 증가",
        "summary": "기록 정리 중",
        "label": "선택",
        "title": "기록 제목",
        "mood": "긴장",
        "hook": "수상한 제안이 도착했다.",
    }
    return mapping.get(key, f"정리 문구 {idx+1}")


def walk_clean(obj, parent_key="", idx=0):
    if isinstance(obj, dict):
        out = {}
        for k, v in obj.items():
            out[k] = walk_clean(v, k, idx)
        return out
    if isinstance(obj, list):
        return [walk_clean(v, parent_key, i) for i, v in enumerate(obj)]
    if isinstance(obj, str) and garbled(obj):
        return default_by_key(parent_key, idx)
    return obj


def fix_generic_files():
    targets = [
        "companions.json",
        "factions.json",
        "portrait-state-tags.json",
        "npcs.json",
    ]
    for fname in targets:
        p = CONTENT / fname
        data = load(p)
        data = walk_clean(data)
        save(p, data)


def main():
    fix_events("events-t0.json", "T0")
    fix_events("events-t1.json", "T1")
    fix_events("events-t2.json", "T2")
    fix_events("events-t3.json", "T3")
    fix_log_lines()
    fix_simple_objects()
    fix_npcs_and_quests()
    fix_generic_files()
    print("repair complete")


if __name__ == "__main__":
    main()
