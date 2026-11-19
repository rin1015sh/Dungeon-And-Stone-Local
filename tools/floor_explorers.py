#!/usr/bin/env python3
"""2 · 3층 다른 탐험가(plans/expansion_f1_3_D §1 · CP-12 — 2026-11-19): 층 JSON에 "explorers"를 넣는다(FieldParties · FieldPartyMeet).
1층 블록을 바탕으로 그 층 마석(explorers.stone) · 수 · 거래 값만 바꾼다. 다친 탐험가 · 싸우는 탐험가는 1층처럼 0
(사용자 2026-10-26 — 1층 결정을 위층에도 그대로).

층 JSON은 레이아웃 도구(f2b · f2g · f2r · f3_layout.py)가 만든다 — 그것들을 다시 돌렸으면 이것도 다시 돌린다(route_variety.py와 같이).

    python3 tools/floor_explorers.py
"""
import copy
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")

COMMENT = ("다른 탐험가(FieldParties · FieldPartyMeet — tools/floor_explorers.py가 1층 블록을 바탕으로 넣는다). stone = 거래 · 사례 마석(그 층 마석). "
           "다친 탐험가 · 싸우는 탐험가는 1층처럼 0. 수는 원정 날(10일)마다. 모두 임시값")

F2 = {
    "stone": "magic_stone_8",
    "rookies_by_day": [1, 1, 2, 2, 2, 1, 1, 1, 0, 0],
    "raiders_by_day": [0, 1, 1, 1, 2, 2, 2, 2, 2, 2],
    "portal_from_day": 5,
    "raider_pack": ["raider_cutthroat", "raider_cutthroat", "raider_archer", "raider_archer"],
    "raider_member_chance": 0.8,
    "death_per_hour": 0.015,
    "trades": [
        {"give": "ration", "n": 2, "price": 1},
        {"give": "torch_stub", "n": 2, "price": 1},
        {"give": "minor_potion", "n": 1, "price": 12},
        {"give": "stone_bread", "n": 4, "price": 1},
    ],
    "rewards": {
        "give_potion": [{"item": "magic_stone_7", "count": [1, 2]}],
        "give_food": [{"item": "magic_stone_8", "count": [2, 3]}],
        "help": [{"item": "magic_stone_8", "count": [3, 5]}, {"item": "torch_stub", "count": [1, 1], "chance": 0.5}],
    },
}

F3 = {
    "stone": "magic_stone_7",
    "rookies_by_day": [2, 2, 3, 3, 3, 2, 2, 2, 1, 1],
    "raiders_by_day": [1, 1, 1, 2, 2, 2, 3, 3, 3, 3],
    "portal_from_day": 7,
    "members": [4, 5],
    "raider_pack": ["raider_cutthroat", "raider_cutthroat", "raider_cutthroat", "raider_archer", "raider_archer"],
    "raider_member_chance": 0.85,
    "death_per_hour": 0.012,
    "raider_hunt_tiles": 90,
    "trades": [
        {"give": "ration", "n": 4, "price": 1},
        {"give": "torch_stub", "n": 3, "price": 1},
        {"give": "minor_potion", "n": 1, "price": 5},
        {"give": "medium_potion", "n": 1, "price": 12},
    ],
    "rewards": {
        "give_potion": [{"item": "magic_stone_7", "count": [2, 3]}],
        "give_food": [{"item": "magic_stone_7", "count": [1, 2]}],
        "help": [{"item": "magic_stone_7", "count": [2, 4]}, {"item": "torch_stub", "count": [1, 2], "chance": 0.5}],
    },
}

TARGETS = {
    "f2_beast_den": F2, "f2_goblin_forest": F2, "f2_land_of_dead": F2, "f2_rock_desert": F2,
    "f3_pilgrim_road": F3,
}


def main():
    with open(os.path.join(ROOT, "data", "floors", "f1_crystal_cave.json"), encoding="utf-8") as f:
        base = json.load(f)["explorers"]
    for fid, over in TARGETS.items():
        path = os.path.join(ROOT, "data", "floors", fid + ".json")
        with open(path, encoding="utf-8") as f:
            d = json.load(f)
        e = copy.deepcopy(base)
        e["_comment"] = COMMENT
        e.update(copy.deepcopy(over))
        e["wounded_per_hour"] = 0
        e["fight_per_hour"] = 0
        d["explorers"] = e
        with open(path, "w", encoding="utf-8") as f:
            f.write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
        print(fid)


if __name__ == "__main__":
    main()
