#!/usr/bin/env python3
"""2층 새 몬스터 15종 자리(docs/plans/floor2_monsters.md — 사용자 2026-11-08)를 층 JSON 넷에 넣는다(몇 번 돌려도 같다).
지역(regions)은 id로 바꿔 넣고, route_spots의 매복 · 지키는 무리는 "new_monsters": true 표시가 붙은 것만 지우고 다시 넣는다.
층 배치 스크립트(tools/f2g_layout.py · f2b_layout.py · f2r_layout.py)를 다시 돌렸으면 이것도 다시 돌린다.
  python3 tools/f2_new_monsters.py
[창작] 임시값."""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TAG = {"new_monsters": True}

PLAN = {
    "f2_goblin_forest": {
        "regions": [
            {"id": "f2g_village", "add": {"goblin_shaman": 1}, "escort": {"goblin_shaman": {"monster": "goblin", "count": [2, 2]}}},
            {"id": "f2g_eaves", "add": {"goblin_trapper": 1}},
            {"id": "f2g_gully", "add": {"goblin_trapper": 2}},
            {"id": "f2g_riders", "zone": "f2g_eaves", "name_ko": "숲 어귀", "monsters": ["goblin_wolf_rider"], "weights": {"goblin_wolf_rider": 1}, "groups": [2, 2], "pack": [1, 1], "entry_dist": [25, 0]},
            {"id": "f2g_hounds", "zone": "f2g_brook", "name_ko": "개울", "monsters": ["goblin_hound"], "weights": {"goblin_hound": 1}, "groups": [2, 3], "pack": [2, 2]},
            {"id": "f2g_village", "add": {"goblin_drummer": 1}, "escort": {"goblin_drummer": {"monster": "goblin_archer", "count": [1, 2]}}},
            {"id": "f2g_thieves", "zone": "f2g_eaves", "name_ko": "숲 어귀", "monsters": ["goblin_thief"], "weights": {"goblin_thief": 1}, "groups": [2, 2], "pack": [1, 1], "entry_dist": [12, 0]},
            {"id": "f2g_thieves_brook", "zone": "f2g_brook", "name_ko": "개울", "monsters": ["goblin_thief"], "weights": {"goblin_thief": 1}, "groups": [1, 2], "pack": [1, 1]},
        ],
        "guards": [
            {"mark": "hunters_camp", "at": [3, 2], "monsters": ["goblin_hound", "goblin_hound"]},
            {"mark": "village", "at": [0, -6], "monsters": ["goblin_shaman", "goblin", "goblin"]},
            {"mark": "gate_n", "at": [0, 3], "monsters": ["goblin_drummer", "goblin", "goblin_archer"]},
            {"mark": "mush_ring", "at": [-3, 2], "monsters": ["spore_shroom"]},
            {"mark": "mush_ring", "at": [4, -2], "monsters": ["spore_shroom", "spore_shroom"]},
            {"mark": "grove", "at": [6, -4], "monsters": ["spore_shroom"]},
        ],
        "ambush": [
            {"mark": "root_a", "at": [3, -4], "monsters": ["thorn_creeper"], "radius": 2, "line": "field.ambush_creeper", "sound": "crumble"},
            {"mark": "gully_ring", "at": [4, 3], "monsters": ["thorn_creeper", "thorn_creeper"], "radius": 2, "line": "field.ambush_creeper", "sound": "crumble"},
            {"mark": "valley_corpse", "at": [-3, 2], "monsters": ["thorn_creeper"], "radius": 2, "line": "field.ambush_creeper", "sound": "crumble"},
            {"mark": "outcrop", "at": [-4, 3], "monsters": ["thorn_creeper"], "radius": 2, "line": "field.ambush_creeper", "sound": "crumble"},
            {"mark": "glade", "at": [5, 4], "monsters": ["forest_wasp", "forest_wasp"], "radius": 3, "line": "field.ambush_wasps", "sound": "wasp_buzz"},
            {"mark": "grove", "at": [-6, -6], "monsters": ["forest_wasp", "forest_wasp", "forest_wasp"], "radius": 3, "line": "field.ambush_wasps", "sound": "wasp_buzz"},
            {"mark": "valley_cache", "at": [3, -3], "monsters": ["forest_wasp", "forest_wasp"], "radius": 3, "line": "field.ambush_wasps", "sound": "wasp_buzz"},
        ],
    },
    "f2_beast_den": {
        "regions": [
            {"id": "f2b_wall", "add": {"spine_boar": 2}},
            {"id": "f2b_boars", "zone": "f2b_outer", "name_ko": "바깥 협곡", "monsters": ["spine_boar"], "weights": {"spine_boar": 1}, "groups": [2, 3], "pack": [1, 2], "entry_dist": [20, 0]},
            {"id": "f2b_hyenas", "zone": "f2b_outer", "name_ko": "바깥 협곡", "monsters": ["bone_hyena"], "weights": {"bone_hyena": 1}, "groups": [2, 2], "pack": [2, 2], "entry_dist": [30, 0]},
            {"id": "f2b_hyenas_wall", "zone": "f2b_wall", "name_ko": "두더지 벽", "monsters": ["bone_hyena"], "weights": {"bone_hyena": 1}, "groups": [1, 2], "pack": [2, 2]},
        ],
        "ambush": [
            {"mark": "f2_w_block", "at": [0, 4], "monsters": ["canyon_bat", "canyon_bat"], "radius": 6, "lit_only": True, "line": "field.ambush_bats", "sound": "bat_screech"},
            {"mark": "f2_e_block", "at": [0, 4], "monsters": ["canyon_bat", "canyon_bat"], "radius": 6, "lit_only": True, "line": "field.ambush_bats", "sound": "bat_screech"},
            {"mark": "deep_hub", "at": [-6, 4], "monsters": ["canyon_bat", "canyon_bat", "canyon_bat"], "radius": 6, "lit_only": True, "line": "field.ambush_bats", "sound": "bat_screech"},
            {"mark": "fork3", "at": [0, 3], "monsters": ["canyon_bat", "canyon_bat"], "radius": 6, "lit_only": True, "line": "field.ambush_bats", "sound": "bat_screech"},
        ],
    },
    "f2_land_of_dead": {
        "regions": [
            {"id": "f2d_keepers", "zone": "f2d_ruins", "name_ko": "석조 잔해", "monsters": ["grave_keeper"], "weights": {"grave_keeper": 1}, "groups": [2, 2], "pack": [1, 1],
             "escort": {"grave_keeper": {"monster": "skeleton", "count": [2, 2]}}},
            {"id": "f2d_crows", "zone": "f2d_marsh", "name_ko": "검은 늪", "monsters": ["carrion_crow"], "weights": {"carrion_crow": 1}, "groups": [2, 3], "pack": [1, 1], "entry_dist": [30, 0]},
            {"id": "f2d_crows_ruins", "zone": "f2d_ruins", "name_ko": "석조 잔해", "monsters": ["carrion_crow"], "weights": {"carrion_crow": 1}, "groups": [2, 2], "pack": [1, 1]},
            {"id": "f2d_wraiths", "zone": "f2d_marsh", "name_ko": "검은 늪", "monsters": ["wraith"], "weights": {"wraith": 1}, "groups": [2, 3], "pack": [1, 1], "hours": [19, 5], "entry_dist": [30, 0]},
            {"id": "f2d_wraiths_ruins", "zone": "f2d_ruins", "name_ko": "석조 잔해", "monsters": ["wraith"], "weights": {"wraith": 1}, "groups": [2, 3], "pack": [1, 1], "hours": [19, 5]},
        ],
        "ambush": [
            {"on_tiles": ["f2d_mud", "f2d_flood"], "chance": 0.012, "max": 4, "monsters": ["drowned", "drowned"], "line": "field.ambush_drowned", "sound": "undead_moan"},
        ],
    },
    "f2_rock_desert": {
        "regions": [
            {"id": "f2r_pilgrims", "zone": "f2r_road", "name_ko": "횃불 옛길", "monsters": ["dried_pilgrim"], "weights": {"dried_pilgrim": 1}, "groups": [2, 2], "pack": [3, 4], "entry_dist": [20, 0]},
            {"id": "f2r_vultures", "zone": "f2r_road", "name_ko": "횃불 옛길", "monsters": ["desert_vulture"], "weights": {"desert_vulture": 1}, "groups": [2, 3], "pack": [1, 2]},
            {"id": "f2r_vultures_sea", "zone": "f2r_sea", "name_ko": "모래 바다", "monsters": ["desert_vulture"], "weights": {"desert_vulture": 1}, "groups": [2, 2], "pack": [1, 2]},
            {"id": "f2r_scorpions", "zone": "f2r_road", "name_ko": "횃불 옛길", "monsters": ["dune_scorpion"], "weights": {"dune_scorpion": 1}, "groups": [2, 3], "pack": [1, 1], "hours": [18, 8], "entry_dist": [20, 0]},
        ],
        "ambush": [
            {"on_tiles": ["f2r_ruin", "f2r_statue", "f2r_fire"], "near": 2, "hours": [8, 18], "chance": 0.05, "max": 3, "monsters": ["dune_scorpion"], "line": "field.ambush_scorpion", "sound": "scorpion_click"},
        ],
    },
}


def main() -> None:
    for fid, plan in PLAN.items():
        path = os.path.join(ROOT, "data/floors/%s.json" % fid)
        d = json.load(open(path))
        regions = d["regions"]
        for r in plan["regions"]:
            if "add" in r:  # 있는 지역에 몬스터 더하기
                base = next(x for x in regions if x["id"] == r["id"])
                for mid, w in r["add"].items():
                    if mid not in base["monsters"]:
                        base["monsters"].append(mid)
                    base["weights"][mid] = w
                if "escort" in r:
                    base.setdefault("escort", {}).update(r["escort"])
                continue
            regions[:] = [x for x in regions if x["id"] != r["id"]] + [r]
        rs = d.setdefault("route_spots", {})
        for key in ("guards", "ambush"):
            keep = [x for x in rs.get(key, []) if not x.get("new_monsters")]
            rs[key] = keep + [dict(x, **TAG) for x in plan.get(key, [])]
        json.dump(d, open(path, "w"), ensure_ascii=False, indent=2)
        open(path, "a").write("\n")
        print(fid, "지역", len(regions), "매복", len(rs.get("ambush", [])), "지키는 무리", len(rs.get("guards", [])))


main()
