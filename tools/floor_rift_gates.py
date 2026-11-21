#!/usr/bin/env python3
"""2층 균열 여는 문(plans/expansion_f1_3_B §1-1 · RiftGates — 2026-11-20): 층 JSON에 "rift_gates"를 넣는다.
길마다 그 길에서 해낸 일(요소 행동 goal)이 need번 차면 그 층 균열 하나가 열린다(자연 개방 없음 — 균열 JSON natural false).

층 JSON은 레이아웃 도구(f2b · f2g · f2r_layout.py · 망자의 땅 도구)가 만든다 — 그것들을 다시 돌렸으면 이것도 다시 돌린다
(route_variety.py · floor_explorers.py · floor_incidents.py와 같이).

    python3 tools/floor_rift_gates.py
"""
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")

GATES = {
    "f2_land_of_dead": [{
        "_comment": "가라앉은 묘역(RiftGates — expansion_f1_3_B §3): 넋불 끝 종자의 시신을 수습해 비석 곁에 묻으면(grave_stone 행동 bury — goal sunken_graveyard) 비석이 가라앉으며 균열 포탈. 기사가 깨는 5일 차 전(until_day 4)까지. 묻은 비석은 부순 비석처럼 기사를 깨우지 않는다. [창작] 임시값",
        "rift": "rift_sunken_graveyard", "flag": "sunken_graveyard", "need": 1, "until_day": 4,
        "line": "field.rift_sunken_open", "sound": "rift_open", "late_line": "field.rift_gate_late",
    }],
    "f2_rock_desert": [{
        "_comment": "꺼진 태양의 신전(RiftGates — expansion_f1_3_B §4): 모래 바다 한가운데 첨탑 끝(sun_spire — 아래 FEATURES)에 오후 모래 폭풍(13~16시)에만 닿아 횃불로 화로에 불을 붙이면(goal sun_temple) 그 자리에 균열 포탈. 7일 차까지. [창작] 임시값",
        "rift": "rift_sun_temple", "flag": "sun_temple", "need": 1, "until_day": 7,
        "line": "field.rift_sun_temple_open", "sound": "rift_open", "late_line": "field.rift_gate_late",
    }],
    "f2_goblin_forest": [{
        "_comment": "덫꾼의 굴(RiftGates — expansion_f1_3_B §5): 덫 밭 셋 한가운데 덫에 걸린 사냥꾼(trapper_knot — 아래 FEATURES)의 매듭 끈을 셋 다 풀면(goal trapper_den × 3) 마지막 끈 곁 덮은 구덩이가 균열 포탈. 7일 차까지. [창작] 임시값",
        "rift": "rift_trapper_den", "flag": "trapper_den", "need": 3, "until_day": 7,
        "line": "field.rift_trapper_den_open", "sound": "rift_open", "late_line": "field.rift_gate_late",
    }],
    "f2_beast_den": [{
        "_comment": "울부짖는 바람굴(RiftGates — expansion_f1_3_B §2): 갈림길 셋의 바른 갈래 안쪽 끝 막힌 바람 틈(wind_gap — RouteForks right_feature)을 다 뚫으면(goal wind_den × 3) 깊은 굴 아래 벽이 갈라져 균열 포탈. 7일 차까지. [창작] 임시값",
        "rift": "rift_wind_den", "flag": "wind_den", "need": 3, "until_day": 7, "at": {"mark": "deep_hub", "at": [0, 4]},
        "line": "field.rift_wind_den_open", "sound": "wolf_howl", "late_line": "field.rift_gate_late",
    }],
}

# 문을 여는 요소(route_spots.features에 덧붙인다 — 같은 event가 있으면 갈아 끼운다)
FEATURES = {
    "f2_rock_desert": [{"mark": "sea_mid", "at": [5, -4], "event": "sun_spire"}],
    "f2_goblin_forest": [{"mark": "trap1", "event": "trapper_knot"}, {"mark": "trap2", "event": "trapper_knot"}, {"mark": "trap3", "event": "trapper_knot"}],
}

# 후회의 군주(LordWatch — expansion_f1_3_B §6): 네 길 끝(3층 포탈 곁) 제단 · 수호자 넷 기록 · 이 길의 탈(첫 페이즈)
GUARDIANS = ["wolf_king", "sleepless_knight", "sand_colossus", "goblin_trap_king"]
LORD_COMMENT = ("계층군주 후회의 군주(LordWatch altar — expansion_f1_3_B §6): 그 길 끝(3층 포탈 곁) 제단에서 2층 균열 수호자 넷을 모두 쓰러뜨린 적이 있으면 부른다. "
                "mask = 이 길의 탈(첫 페이즈 — RegretMasks). 원정마다 한 번(respawn_hours가 원정보다 길다). 소환 중 시야 vision_m. [창작] 임시값")
LORDS = {
    "f2_beast_den": ("beast", "floor3_from_den", "r2f_altar"),
    "f2_land_of_dead": ("dead", "floor3_from_dead", "r2f_altar"),
    "f2_rock_desert": ("sand", "floor3_from_desert", "r2f_altar"),
    "f2_goblin_forest": ("goblin", "floor3_from_forest", "r2f_altar"),
}


def main():
    for fid, gates in GATES.items():
        path = os.path.join(ROOT, "data", "floors", fid + ".json")
        with open(path, encoding="utf-8") as f:
            d = json.load(f)
        d["rift_gates"] = gates
        if fid in LORDS:
            mask, dest, tile = LORDS[fid]
            d["lord"] = {"_comment": LORD_COMMENT, "monster": "regret_lord", "mask": mask, "guardians": GUARDIANS,
                         "altar": {"event": "regret_altar", "tile": tile, "near_dest": dest, "at": [3, 2]},
                         "respawn_hours": 999.0, "vision_m": 4.0, "rise_fx": False, "rise_sound": "boss_reveal", "summoned_line": "explore.regret_summoned", "spawn_distance_tiles": 4, "tint": "#b8b8b0", "source": "placeholder"}
        add = FEATURES.get(fid, [])
        if add:
            feats = d.setdefault("route_spots", {}).setdefault("features", [])
            names = {f["event"] for f in add}
            feats[:] = [f for f in feats if f.get("event") not in names] + add
        with open(path, "w", encoding="utf-8") as f:
            f.write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
        print("%s: 문 %d" % (fid, len(gates)))


if __name__ == "__main__":
    main()
