#!/usr/bin/env python3
"""사건 덱(plans/expansion_f1_3_D §0 — 2026-11-19): 층 JSON에 "incidents"를 넣는다(FloorIncidents가 원정마다 몇 장 뽑아 놓는다).
1층 · 2층 넷 · 3층. 지금은 이미 있는 장치(요소 · 지키는 무리 · 매복)만 쓰는 사건 — 새 장치가 필요한 사건(몬스터끼리 싸움 · 추적자 …)은
그 장치를 만든 뒤 여기에 더한다.

층 JSON은 레이아웃 도구(f2b · f2g · f2r · f3_layout.py)가 만든다 — 그것들을 다시 돌렸으면 이것도 다시 돌린다(route_variety.py ·
floor_explorers.py와 같이). 1층 JSON은 손으로 고친 것이지만 같은 곳에서 관리한다.

    python3 tools/floor_incidents.py
"""
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")

COMMENT = ("사건 덱(FloorIncidents — tools/floor_incidents.py가 넣는다, plans/expansion_f1_3_D): 원정마다 per_expedition장을 가중 무작위로 뽑아 "
           "any 후보 자리 중 하나(다른 사건과 gap칸 · 도착 칸과 entry_gap칸 떨어진)에 days 날에 놓는다. 모두 임시값")

DECKS = {
    "f1_crystal_cave": {
        "per_expedition": [1, 2],
        "pool": [
            {"id": "warm_campfire", "weight": 2, "days": [1, 5],
             "any": [{"feature": "dead_campfire", "at": [5, 0]}, {"feature": "dead_campfire", "at": [-5, 1]},
                     {"feature": "broken_gear", "at": [4, 3]}],
             "features": [{"event": "warm_campfire"}]},
            {"id": "ghoul_feast", "weight": 1, "days": [3, 10],
             "any": [{"feature": "carrion_heap", "at": [3, 2]}, {"feature": "rot_carcass", "at": [-3, 2]}],
             "guards": [{"monsters": ["ghoul", "ghoul", "ghoul", "ghoul"]}]},
            {"id": "wolves_on_kill", "weight": 1, "days": [2, 8],
             "any": [{"feature": "wolf_tracks", "at": [6, 0]}, {"feature": "wolf_kill", "at": [-6, 2]}],
             "features": [{"event": "fresh_corpse"}],
             "guards": [{"monsters": ["blade_wolf", "blade_wolf", "blade_wolf"], "at": [2, 1]}]},
        ],
    },
    "f2_beast_den": {
        "per_expedition": [1, 2],
        "pool": [
            {"id": "predator_meal", "weight": 2, "days": [1, 9],
             "any": [{"mark": "outer_hub", "at": [-6, -3]}, {"mark": "wall_hub", "at": [5, 4]}, {"mark": "bone_pit", "at": [-5, 4]},
                     {"mark": "deep_hub", "at": [6, 6]}],
             "features": [{"event": "wolf_kill", "tile": "f2d_skeleton"}],
             "guards": [{"monsters": ["sabertooth"], "at": [2, 1]}]},
            {"id": "lost_rookie", "weight": 1, "days": [2, 8],
             "any": [{"mark": "ledge1", "at": [3, 3]}, {"mark": "ledge2", "at": [-3, 3]}, {"mark": "bear_cave", "at": [-6, 0]}],
             "features": [{"event": "explorer_corpse", "tile": "f2d_corpse_g"}],
             "ambush": [{"monsters": ["canyon_bat", "canyon_bat"], "radius": 6, "lit_only": True,
                         "line": "field.ambush_bats", "sound": "bat_screech"}]},
        ],
    },
    "f2_land_of_dead": {
        "per_expedition": [1, 2],
        "pool": [
            {"id": "knocking_grave", "weight": 2, "days": [1, 6],
             "any": [{"node": "graveyard", "at": [6, 6]}, {"node": "chapel", "at": [-10, 8]}, {"node": "corridor", "at": [4, -4]},
                     {"node": "levee_bend", "at": [5, 3]}],
             "features": [{"event": "knocking_grave"}]},
            {"id": "ghouls_at_bodies", "weight": 1, "days": [2, 9],
             "any": [{"node": "mire", "at": [4, 4]}, {"node": "bell_isle", "at": [-4, 3]}, {"node": "crossroads", "at": [6, -3]},
                     {"node": "levee_bend", "at": [-5, -4]}],
             "features": [{"event": "fresh_corpse", "tile": "f2d_corpse_g"}, {"event": "fresh_corpse", "tile": "f2d_corpse_g", "at": [2, 1]}],
             "guards": [{"monsters": ["ghoul", "ghoul", "elder_ghoul"], "at": [1, 2]}]},
        ],
    },
    "f2_rock_desert": {
        "per_expedition": [1, 2],
        "pool": [
            {"id": "parched_traveler", "weight": 2, "days": [2, 7],
             "any": [{"mark": "colonnade", "at": [4, 3]}, {"mark": "road_east", "at": [-3, 3]}, {"mark": "plaza", "at": [-6, 4]}],
             "features": [{"event": "parched_traveler"}]},
            {"id": "night_spring", "weight": 1, "days": [3, 10],
             "any": [{"mark": "seep", "at": [3, 2]}],
             "guards": [{"monsters": ["dune_scorpion", "dune_scorpion", "dune_scorpion"]}]},
            {"id": "pack_raiders", "weight": 1, "days": [2, 9],
             "any": [{"mark": "dune_w", "at": [5, 2]}, {"mark": "dune_e", "at": [-5, 2]}],
             "features": [{"event": "buried_pack"}],
             "ambush": [{"monsters": ["kobold", "kobold", "kobold_slinger"], "radius": 3,
                         "line": "field.ambush", "sound": "goblin_shout"}]},
        ],
    },
    "f2_goblin_forest": {
        "per_expedition": [1, 2],
        "pool": [
            {"id": "hunters_rest", "weight": 2, "days": [1, 8],
             "any": [{"mark": "glade", "at": [4, 4]}, {"mark": "grove", "at": [-5, 3]}, {"mark": "outcrop", "at": [3, 4]},
                     {"mark": "valley_corpse", "at": [-4, -3]}],
             "features": [{"event": "dead_campfire", "tile": "f2g_campfire"}, {"event": "hunter_cache", "tile": "f2g_cache", "at": [2, 1]}],
             "guards": [{"monsters": ["goblin_hound", "goblin_hound", "goblin_archer"], "at": [3, -2]}]},
            {"id": "scout_party", "weight": 1, "days": [2, 10],
             "any": [{"mark": "root_a", "at": [4, 0]}, {"mark": "hunter", "at": [5, -5]}, {"mark": "gully_corpse", "at": [4, 3]}],
             "guards": [{"monsters": ["goblin_archer", "goblin_archer", "goblin"]}]},
        ],
    },
    "f3_pilgrim_road": {
        "per_expedition": [2, 3],
        "gap": 60,
        "pool": [
            {"id": "orc_scouts", "weight": 2, "days": [1, 10],
             "any": [{"zone": "f3_steel"}, {"zone": "f3_estuary"}, {"zone": "f3_riverbed"}],
             "guards": [{"monsters": ["orc_warrior", "orc_archer", "orc_archer"]}]},
            {"id": "abandoned_rest", "weight": 2, "days": [1, 9],
             "any": [{"zone": "f3_greentail"}, {"zone": "f3_reeds"}, {"zone": "f3_dusk"}],
             "features": [{"event": "dead_campfire", "tile": "f2g_campfire"},
                          {"event": "f3_explorer_corpse", "tile": "f2d_corpse_g", "at": [2, 1]}],
             "ambush": [{"monsters": ["lizardman", "lizardman"], "radius": 3, "line": "field.ambush", "sound": "beast_grunt"}]},
            {"id": "troll_wanderer", "weight": 1, "days": [3, 10],
             "any": [{"zone": "f3_reeds"}, {"zone": "f3_dusk"}],
             "guards": [{"monsters": ["half_troll"]}]},
            {"id": "falcon_roost", "weight": 1, "days": [1, 10],
             "any": [{"zone": "f3_windpass"}, {"zone": "f3_steel"}],
             "features": [{"event": "hidden_cache"}],
             "guards": [{"monsters": ["iron_falcon", "iron_falcon"], "at": [2, 2]}]},
        ],
    },
}


def _splice(text, block):
    """손으로 짠 층 JSON(1층)은 모양을 지키려고 "incidents" 키만 글자로 갈아 끼운다(맨 끝 키로)."""
    body = json.dumps(block, ensure_ascii=False, indent=2).replace("\n", "\n  ")
    key = '\n  "incidents": '
    if key in text:
        text = text[:text.index(key)].rstrip().rstrip(",") + "\n}\n"
    end = text.rstrip().rindex("}")
    return text[:end].rstrip() + ',\n  "incidents": ' + body + "\n}\n"


def main():
    for fid, deck in DECKS.items():
        path = os.path.join(ROOT, "data", "floors", fid + ".json")
        with open(path, encoding="utf-8") as f:
            text = f.read()
        d = json.loads(text)
        block = dict({"_comment": COMMENT}, **deck)
        if text == json.dumps(d, ensure_ascii=False, indent=2) + "\n":
            d["incidents"] = block
            text = json.dumps(d, ensure_ascii=False, indent=2) + "\n"
        else:
            keys = list(d.keys())
            if "incidents" in keys and keys[-1] != "incidents":
                raise SystemExit("%s: incidents가 맨 끝 키가 아니다 — 손으로 옮겨 달라" % fid)
            text = _splice(text, block)
        json.loads(text)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        print("%s: 덱 %d장" % (fid, len(deck["pool"])))


if __name__ == "__main__":
    main()
