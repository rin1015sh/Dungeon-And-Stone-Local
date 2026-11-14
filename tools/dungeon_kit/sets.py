"""던전 에셋 키트 — 테마별 조합(세트). 세트 = 작은 방 한 칸의 설계: 바닥 · 벽 종류 · 놓을 물건 목록.
세트는 '조합 본보기'일 뿐이다 — 물건은 모두 낱개 에셋이라 따로 놓을 수 있고, 세트의 일부만 골라 써도 된다.

좌표: 방 안쪽 바닥의 왼쪽 위 칸이 (0, 0). at = (x, y) 칸 단위 실수 — 물건의 발(원점)이 놓일 자리(칸 가운데 = +0.5).
  벽 부착물(wall_decal)은 북벽 밑동 선 y = 0에 놓는다. 벽면 가운데에 뜨는 것(글씨 · 낙서 · 선반)은 up = 벽을 따라 올릴 높이(칸).
  v = 변형 이름(없으면 첫 변형), f = 애니메이션 프레임, flip = 좌우 뒤집기, z = 그리는 순서 보정(px — 탁자 위 물건은 +).
size = 안쪽 바닥 (가로, 세로) 칸. 둘레 벽은 저절로(북쪽 3칸 · 나머지 1칸). floor_patches = 일부 칸만 다른 바닥(rect = x, y, 폭, 높이).
wall_states = 북벽 칸 x → 벽면 상태. exits_n = 북벽에서 벽면을 그리지 않는 칸(문 · 통로 에셋이 대신 선다).
"""

SETS = {}


def export(manifest):
    """kit.json에 실을 세트 표 — 없는 에셋 · 변형을 가리키면 여기서 멈춘다."""
    out = {}
    for name, s in SETS.items():
        for it in s.get("items", []) + s.get("floor_patches", []):
            a = manifest["assets"].get(it["id"])
            assert a, "세트 %s: 없는 에셋 %s" % (name, it["id"])
            assert it.get("v") is None or it["v"] in a["variants"], "세트 %s: %s에 없는 변형 %s" % (name, it["id"], it["v"])
        assert s["floor"] in manifest["assets"] and ("wall_" + s.get("wall", "stone")) in manifest["assets"], name
        out[name] = s
    return out


SETS["ruins"] = {
    "name_ko": "고대 유적", "size": [11, 8], "floor": "floor_old", "wall": "ancient",
    "floor_patches": [{"id": "floor_ritual", "rect": [4, 2, 4, 4]}, {"id": "floor_broken", "rect": [0, 5, 3, 3]}, {"id": "floor_sand", "rect": [8, 6, 3, 2]}],
    "wall_states": {"0": "mossy", "1": "mossy", "2": "cracked", "7": "damaged", "8": "cracked", "10": "mossy"}, "exits_n": [5],
    "items": [
        {"id": "doorway", "v": "open", "at": [5.5, 0.0]},
        {"id": "wall_pilaster", "at": [4.0, 0.0]}, {"id": "wall_pilaster", "v": "broken", "at": [7.0, 0.0]},
        {"id": "pillar", "v": "intact", "at": [3.5, 2.2]}, {"id": "pillar", "v": "cracked", "at": [8.5, 2.2]},
        {"id": "pillar", "v": "broken", "at": [3.5, 6.2]}, {"id": "pillar", "v": "fallen", "at": [8.3, 6.4]},
        {"id": "statue", "v": "intact", "at": [1.5, 1.4]}, {"id": "statue", "v": "headless", "at": [9.6, 1.4]},
        {"id": "pedestal", "v": "orb", "at": [6.0, 4.0]},
        {"id": "arch", "v": "ruined", "at": [1.6, 4.6]},
        {"id": "sarcophagus", "v": "ajar", "at": [6.0, 7.2]},
    ],
}


def _i(id, x, y, v=None, **kw):
    d = {"id": id, "at": [x, y]}
    if v:
        d["v"] = v
    d.update(kw)
    return d


SETS["ruins"]["items"] += [
    _i("wall_writing", 1.5, 0.0, "worn", up=1.25), _i("vines", 9.6, 0.0, "hang_mid"), _i("wall_roots", 2.6, 0.0, "b"), _i("wall_tablet", 8.5, 0.0, "b", up=1.25),
    _i("moss_patch", 0.9, 3.2, "b"), _i("moss_patch", 10.0, 3.4, "d"), _i("rubble", 2.6, 7.3, "large"), _i("rubble", 9.9, 7.4, "small"), _i("ground_crack", 7.6, 5.4, "b"),
    _i("stone_tablet", 0.8, 6.6, "broken"), _i("rune_stone", 10.2, 4.8, "dormant"), _i("weeds", 0.5, 7.6, "tuft_dry"), _i("weeds", 10.4, 6.2, "fern"), _i("gravel", 5.0, 6.6, "b"),
    _i("glow_rune", 4.6, 2.5, "a_off"), _i("glow_rune", 7.4, 5.5, "c_blue"), _i("broken_weapon", 4.4, 7.2, "shield"), _i("dust", 9.2, 5.0, "drift"),
]

SETS["ritual"] = {
    "name_ko": "제단과 의식 공간", "size": [9, 8], "floor": "floor_flag", "wall": "stone",
    "floor_patches": [{"id": "floor_ritual", "rect": [2, 2, 4, 4]}, {"id": "floor_corrupt", "rect": [0, 6, 2, 2]}],
    "wall_states": {"1": "cracked", "7": "mossy"},
    "items": [
        _i("torch_wall", 1.5, 0.0, "lit"), _i("torch_wall", 7.5, 0.0, "lit", f=2), _i("blood_wall", 3.0, 0.0, "hand", up=1.25), _i("wall_rune", 4.5, 0.0, "red", up=1.95), _i("wall_graffiti", 6.2, 0.0, "blood_b", up=1.25),
        _i("altar", 4.5, 1.3, "ritual"), _i("statue_robed", 2.2, 1.2, "weeping"), _i("statue_robed", 6.8, 1.2, "intact"),
        _i("magic_circle", 4.0, 4.3, "a_red", f=1), _i("candles", 2.3, 3.0, "lit"), _i("candles", 5.8, 3.0, "lit", f=1), _i("candles", 2.4, 5.7, "lit", f=2), _i("candles", 5.7, 5.7, "stubs"),
        _i("ritual_remains", 4.0, 4.5, "offering"), _i("blood_pool", 6.8, 5.0, "fresh"), _i("blood_trail", 6.2, 6.2, "curved"), _i("ritual_remains", 7.6, 6.9, "bone_circle"),
        _i("brazier", 0.7, 3.4, "lit"), _i("brazier", 8.3, 3.4, "lit", f=2), _i("skull", 1.0, 7.2, "heap"), _i("ritual_marks", 1.2, 5.4, "salt_line"),
        _i("candelabra", 0.6, 1.0, "lit"), _i("candelabra", 8.4, 1.0, "lit", f=3), _i("corpse", 7.2, 7.6, "shrouded"), _i("rune_trap", 4.5, 7.2, "armed"), _i("mana_residue", 0.9, 6.9, "violet"),
    ],
}

SETS["camp"] = {
    "name_ko": "탐험가의 야영지", "size": [9, 7], "floor": "floor_dirt", "wall": "stone",
    "floor_patches": [{"id": "floor_old", "rect": [0, 0, 9, 2]}, {"id": "floor_cobble", "rect": [6, 2, 3, 2]}],
    "wall_states": {"0": "mossy", "4": "cracked", "8": "damaged"},
    "items": [
        _i("lantern_hanging", 2.5, 0.0, "lit"), _i("wall_graffiti", 5.5, 0.0, "chalk_c", up=1.25), _i("wall_scratches", 7.2, 0.0, "tally", up=1.25), _i("vines", 0.5, 0.0, "hang_short"),
        _i("firepit", 4.5, 3.8, "lit"), _i("cooking_pot", 5.6, 3.3, "stew"), _i("bedroll", 2.6, 4.9, "out"), _i("bedroll", 6.3, 5.4, "used"), _i("bedroll", 2.4, 2.9, "rolled"),
        _i("backpack", 1.7, 4.3, "standing"), _i("backpack", 7.4, 5.0, "opened"), _i("supply_pile", 1.0, 1.4, "a"), _i("crate", 7.9, 1.3, "stack"), _i("barrel", 6.8, 1.2, "water"),
        _i("sack", 2.2, 1.5, "pile"), _i("weapon_rack", 4.3, 0.9, "half"), _i("stool", 3.4, 3.4, "base"), _i("stool", 5.3, 4.8, "toppled"), _i("lantern", 3.3, 5.5, "lit"),
        _i("dishes", 3.8, 4.7, "dirty"), _i("food_scraps", 5.0, 5.0, "a"), _i("bottles", 6.9, 4.3, "wine"), _i("books", 2.0, 5.6, "open"), _i("papers", 1.4, 5.9, "a"),
        _i("torch_stand", 0.6, 6.4, "lit"), _i("torch_stand", 8.4, 6.5, "unlit"), _i("tripwire", 4.5, 6.6, "set"), _i("footprints", 6.5, 6.4, "dust"), _i("rock", 8.4, 3.2, "medium_a"),
        _i("ash_pile", 7.7, 3.0, "campfire"), _i("basket", 0.8, 2.6, "food"),
    ],
}

SETS["prison"] = {
    "name_ko": "감옥", "size": [10, 8], "floor": "floor_brick", "wall": "brick",
    "floor_patches": [{"id": "floor_stained", "rect": [0, 4, 10, 4]}, {"id": "floor_wet", "rect": [7, 5, 3, 3]}],
    "wall_states": {"1": "damaged", "5": "cracked", "8": "mossy"},
    "items": [
        _i("skeleton_chained", 1.5, 0.0), _i("wall_scratches", 3.2, 0.0, "tally_many", up=1.25), _i("torch_wall", 5.0, 0.0, "lit"), _i("blood_wall", 6.6, 0.0, "smear", up=1.25), _i("skeleton_chained", 8.5, 0.0),
        _i("wall_stain", 9.5, 0.0, "b"), _i("wall_hole", 0.5, 0.0, "b"),
        *[_i("bars", x + 0.5, 3.0, v) for x, v in enumerate(["panel", "door", "panel", "post", "rusty", "door_open", "bent", "post", "panel", "door"])],
        _i("straw_pile", 1.2, 1.9, "a"), _i("bones", 2.4, 1.6, "ribcage"), _i("corpse", 5.0, 1.8, "rotten"), _i("straw_pile", 6.2, 1.4, "b"), _i("skeleton", 8.8, 2.2, "sitting"),
        _i("dishes", 0.6, 2.5, "bowls"), _i("rot_stain", 5.2, 2.0, "a"), _i("scratches", 2.6, 2.4, "b"),
        _i("table", 2.0, 5.6, "set"), _i("chair", 1.0, 5.5, "e"), _i("stool", 3.1, 5.9, "toppled"), _i("weapon_rack", 4.6, 4.2, "full"), _i("chest", 6.0, 4.4, "locked"),
        _i("brazier", 0.7, 7.3, "embers"), _i("gibbet", 8.6, 5.6, "skeleton"), _i("puddle", 8.2, 7.2, "murky"), _i("blood_trail", 5.5, 6.6, "straight"), _i("lever", 9.3, 4.3, "left"),
        _i("barrel", 4.0, 7.5, "intact"), _i("bottle_broken", 3.0, 7.0, "brown"), _i("lantern", 2.6, 4.6, "lit"), _i("spike_trap", 6.5, 7.2, "extended"), _i("chained_lock", 9.5, 3.0, "locked", z=2),
    ],
}

SETS["lab"] = {
    "name_ko": "지하 연구실", "size": [10, 7], "floor": "floor_flag", "floor_variant": "b", "wall": "sewer",
    "floor_patches": [{"id": "floor_stained", "rect": [0, 0, 4, 3]}, {"id": "floor_corrupt", "rect": [6, 3, 4, 4]}, {"id": "floor_wet", "rect": [0, 5, 3, 2]}],
    "wall_states": {"2": "mossy", "6": "cracked"},
    "items": [
        _i("sewer_outlet", 0.6, 0.0, "grate_flow"), _i("wall_shelf", 2.2, 0.0, "bottles", up=1.15), _i("wall_shelf", 3.6, 0.0, "skull", up=1.15), _i("lantern_hanging", 5.0, 0.0, "lit"),
        _i("valve_wheel", 6.6, 0.0, "idle", up=1.25), _i("wall_tablet", 8.2, 0.0, "a", up=1.25), _i("wall_slime", 9.5, 0.0, "a"),
        _i("workbench", 1.8, 1.3, "tools"), _i("bookshelf", 4.3, 0.9, "full"), _i("bookshelf", 5.5, 0.9, "half"), _i("cabinet", 9.2, 1.0, "open"), _i("desk", 7.4, 1.4, "cluttered"), _i("chair", 7.4, 2.2, "n"),
        _i("ancient_machine", 8.0, 4.4, "active"), _i("magic_lamp", 6.2, 3.4, "blue"), _i("magic_lamp", 9.5, 6.3, "violet"), _i("crystal", 6.6, 6.3, "violet_large"), _i("crystal", 9.3, 3.3, "blue_small"),
        _i("mana_residue", 7.6, 5.8, "blue"), _i("glow_crack", 7.6, 6.5, "blue"), _i("gear_pile", 5.6, 5.4, "a"),
        _i("table", 2.6, 4.3, "intact"), _i("bottles", 2.2, 3.8, "group", z=40), _i("bottles", 3.0, 3.9, "potion_red", z=40), _i("books", 2.7, 3.7, "open", z=40),
        _i("corpse", 2.6, 6.2, "shrouded"), _i("black_slime", 0.9, 6.0, "b"), _i("slime_blob", 0.7, 5.4, "a"), _i("bottle_shards", 4.2, 5.2, "green"), _i("papers", 4.6, 2.6, "b"),
        _i("scrolls", 6.2, 2.0, "pile"), _i("barrel", 0.6, 3.6, "intact"), _i("crate", 0.7, 2.6, "open"), _i("candelabra", 3.4, 2.0, "lit"), _i("lever", 5.2, 6.5, "right"), _i("pressure_plate", 4.5, 4.0, "rune"),
    ],
}

SETS["battle"] = {
    "name_ko": "전투가 벌어진 흔적", "size": [10, 7], "floor": "floor_flag", "wall": "stone",
    "floor_patches": [{"id": "floor_cracked", "rect": [3, 1, 4, 3]}, {"id": "floor_broken", "rect": [7, 4, 3, 3]}],
    "wall_states": {"2": "cracked", "3": "damaged", "6": "cracked", "9": "damaged"}, "exits_n": [8],
    "items": [
        _i("doorway", 8.5, 0.0, "wood_broken"), _i("blood_wall", 2.4, 0.0, "a", up=1.25), _i("wall_scratches", 5.4, 0.0, "claw_a", up=1.25), _i("torch_wall", 4.0, 0.0, "stub"), _i("torch_wall", 6.6, 0.0, "lit"),
        _i("wall_hole", 0.6, 0.0, "a"), _i("dart_holes", 1.6, 0.0, "fired", up=0.8),
        _i("corpse", 3.0, 3.2, "explorer"), _i("corpse", 6.6, 5.2, "explorer_b"), _i("skeleton", 5.4, 2.0, "armored"), _i("blood_pool", 3.2, 3.5, "fresh_b"), _i("blood_pool", 6.4, 5.4, "dried"),
        _i("blood_splat", 4.6, 2.8, "c"), _i("blood_splat", 7.8, 3.2, "a"), _i("blood_trail", 4.8, 4.6, "hand"), _i("footprints", 6.0, 6.5, "bloody_fade"),
        _i("broken_weapon", 2.0, 4.6, "sword"), _i("broken_weapon", 4.4, 5.8, "spear"), _i("broken_weapon", 7.4, 2.2, "shield"), _i("broken_weapon", 5.8, 3.6, "arrows"), _i("broken_weapon", 1.2, 2.0, "helmet"),
        _i("broken_armor", 8.2, 4.6, "breastplate"), _i("broken_armor", 2.6, 6.2, "pieces"), _i("darts_spent", 1.8, 1.4, "bloody"),
        _i("table", 1.4, 5.9, "toppled"), _i("chair", 0.8, 4.2, "toppled"), _i("chair", 3.6, 1.4, "broken"), _i("crate", 9.2, 1.4, "broken"), _i("barrel", 9.0, 2.6, "broken"), _i("debris_wood", 7.8, 1.2, "furniture"),
        _i("torch_stand", 0.7, 1.2, "fallen"), _i("scorch", 8.4, 6.0, "blast"), _i("scratches", 5.0, 1.2, "deep"), _i("pillar", 9.2, 6.3, "broken"), _i("bottle_broken", 0.8, 6.6, "red"),
        _i("trap_remains", 3.8, 6.6, "sprung_spears"), _i("drag_marks", 7.4, 6.4, "a"),
    ],
}

SETS["sewer"] = {
    "name_ko": "지하수로", "size": [10, 6], "floor": "floor_cobble", "wall": "sewer",
    "floor_patches": [{"id": "floor_wet", "rect": [0, 2, 10, 2]}, {"id": "floor_mossy", "rect": [0, 4, 4, 2]}],
    "wall_states": {"1": "mossy", "4": "damaged", "5": "mossy", "8": "cracked"},
    "items": [
        _i("sewer_outlet", 1.5, 0.0, "flow"), _i("sewer_outlet", 6.5, 0.0, "grate"), _i("wall_moss", 3.4, 0.0, "base_a"), _i("wall_slime", 8.3, 0.0, "b"), _i("lantern_hanging", 4.6, 0.0, "lit"),
        _i("mushroom_shelf", 9.4, 0.0, "a", up=0.7), _i("wall_stain", 5.6, 0.0, "c"),
        _i("puddle", 2.0, 2.8, "large"), _i("puddle", 6.8, 3.0, "murky"), _i("puddle", 4.6, 3.4, "ripple", f=2), _i("black_slime", 8.6, 3.2, "a"), _i("slime_blob", 9.2, 2.4, "b"),
        _i("toadstool", 0.7, 4.8, "glow_a"), _i("toadstool", 3.2, 5.5, "glow_b"), _i("mushroom", 1.6, 5.4, "cluster_a"), _i("moss_patch", 2.2, 4.6, "a"), _i("roots", 5.6, 5.2, "b"),
        _i("barrel", 8.6, 1.0, "toppled"), _i("crate", 7.6, 1.0, "broken"), _i("bones", 5.2, 1.2, "scatter_a"), _i("skull", 3.0, 1.4, "side"), _i("gas_vent", 7.4, 5.0, "venting"),
        _i("rubble", 9.2, 5.3, "brick_large"), _i("nest", 0.9, 1.3, "eggs"), _i("web_cocoon", 9.4, 4.2, "standing"), _i("railing", 4.5, 4.4, "straight"), _i("railing", 5.5, 4.4, "broken"),
    ],
}

# 지역 본보기 세트(에셋 라이브러리 — docs/asset_library): 야외 · 지역 에셋의 조합 본보기
from sets_wild import WILD  # noqa: E402

SETS.update(WILD)
