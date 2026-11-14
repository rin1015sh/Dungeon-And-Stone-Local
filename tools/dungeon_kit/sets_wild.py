"""던전 에셋 키트 — 지역 본보기 세트(에셋 라이브러리 미리보기 · 시험 장면). sets.py가 읽어 SETS에 더한다.
세트의 틀은 sets.py와 같다(둘레는 그 지역의 암벽 — 야외 지역도 절벽으로 둘러싼 빈터로 본다). 지역 표 = regions.py."""


def _i(id, x, y, v=None, **kw):
    d = {"id": id, "at": [x, y]}
    if v:
        d["v"] = v
    d.update(kw)
    return d


WILD = {}

WILD["crystal_cave"] = {
    "name_ko": "수정동굴", "region": "f1_crystal_cave", "size": [12, 8], "floor": "ground_rock", "wall": "cave",
    "floor_patches": [{"id": "ground_rock", "v": "dark", "rect": [8, 4, 4, 4]}, {"id": "floor_dirt", "rect": [0, 5, 4, 3]}],
    "wall_states": {"2": "cracked", "6": "mossy", "9": "damaged"},
    "items": [
        _i("crystal_wall", 1.5, 0.0, "a"), _i("crystal_wall", 4.6, 0.0, "cluster"), _i("crystal_wall", 7.5, 0.0, "b"), _i("crystal_wall", 10.5, 0.0, "c"),
        _i("crystal_ceiling", 3.0, 3.2, "a"), _i("crystal_ceiling", 9.2, 5.6, "b"), _i("stalactite", 6.4, 2.2, "cluster"),
        _i("rock_crystal", 2.2, 2.4, "a"), _i("rock_crystal", 9.6, 2.2, "large"), _i("rock_crystal", 5.4, 6.4, "b"), _i("crystal", 11.0, 6.8, "blue_small"),
        _i("monument", 6.0, 4.0, "offered"), _i("portal_stele", 0.9, 4.2, "idle"),
        _i("stalagmite", 3.8, 5.0, "cluster"), _i("stalagmite", 8.2, 6.9, "tall"), _i("column_natural", 11.0, 3.6, "a"), _i("rock", 7.8, 1.4, "medium_a"), _i("rock", 1.0, 7.0, "slab_a"),
        _i("puddle", 2.6, 6.6, "ripple"), _i("moss_patch", 9.6, 4.4, "a"), _i("mushroom", 0.8, 2.2, "cluster_a"), _i("gravel", 4.6, 3.2, "a"), _i("ground_crack", 8.0, 4.6, "a"),
    ],
}

WILD["dead_land"] = {
    "name_ko": "망자의 땅", "region": "f2_land_of_dead", "size": [12, 8], "floor": "ground_mud", "wall": "stone",
    "floor_patches": [{"id": "ground_rock", "v": "dark", "rect": [7, 0, 5, 5]}, {"id": "ground_bones", "rect": [0, 5, 4, 3]}],
    "wall_states": {"1": "damaged", "4": "cracked", "8": "mossy", "10": "damaged"},
    "items": [
        _i("ruin_wall", 2.0, 1.6, "straight_a"), _i("ruin_wall", 3.8, 1.6, "window"), _i("ruin_wall", 5.6, 1.6, "low"), _i("ruin_wall", 9.6, 3.0, "corner"), _i("ruin_wall", 6.4, 6.6, "stub"),
        _i("mound", 9.4, 6.4, "ruin"), _i("mound", 3.2, 4.6, "a"), _i("mound", 10.2, 1.2, "long"),
        _i("pillar", 7.4, 4.4, "broken"), _i("pillar", 1.2, 3.4, "stump"), _i("pillar", 4.6, 6.8, "fallen"), _i("rubble", 6.6, 2.6, "large"), _i("rubble", 0.9, 6.0, "brick"),
        _i("skull", 2.2, 6.6, "heap"), _i("bones", 5.6, 4.4, "scatter_a"), _i("puddle", 7.8, 7.2, "murky"), _i("puddle", 5.0, 3.2, "medium"), _i("weeds", 11.2, 4.6, "dead_bush"),
        _i("mist", 3.0, 7.4, "grey"), _i("mist", 8.6, 5.0, "grey_b"),
    ],
}

WILD["desert_ruins"] = {
    "name_ko": "바위사막", "region": "f2_rock_desert", "size": [12, 8], "floor": "floor_sand", "wall": "sandstone",
    "floor_patches": [{"id": "ground_hardpan", "rect": [0, 0, 5, 4]}, {"id": "ground_hardpan", "v": "b", "rect": [8, 5, 4, 3]}],
    "wall_states": {"3": "cracked", "7": "mossy", "10": "damaged"},
    "items": [
        _i("rock_sandstone", 1.6, 1.8, "hoodoo"), _i("rock_sandstone", 10.4, 2.0, "arch"), _i("rock_sandstone", 4.2, 2.2, "strata_a"), _i("rock_sandstone", 8.2, 6.6, "stack"),
        _i("rock_sandstone", 1.4, 6.6, "buried"), _i("rock_sandstone", 6.4, 1.2, "strata_b"), _i("rock_sandstone", 11.0, 5.6, "hoodoo_b"),
        _i("ruin_wall", 6.0, 4.2, "sunk"), _i("ruin_wall", 7.8, 4.2, "low"), _i("pillar", 3.6, 5.6, "fallen"), _i("pillar", 9.6, 4.0, "stump"), _i("rubble", 5.2, 6.8, "scatter"),
        _i("skeleton", 2.8, 3.8, "lying"), _i("broken_weapon", 7.0, 7.2, "sword"), _i("weeds", 0.7, 4.6, "dead_bush"), _i("drift", 4.0, 4.0, "dust"), _i("drift", 9.0, 2.6, "dust"),
    ],
}

WILD["witch_forest"] = {
    "name_ko": "마녀의 숲과 오두막 앞", "region": "f3_witch_forest", "size": [13, 9], "floor": "ground_forest", "wall": "cave",
    "floor_patches": [{"id": "ground_meadow", "rect": [8, 4, 5, 5]}, {"id": "ground_forest", "v": "b", "rect": [0, 4, 4, 5]}],
    "wall_states": {"2": "mossy", "5": "mossy", "9": "cracked"},
    "items": [
        _i("tree_thorn", 1.6, 2.4, "a"), _i("tree_thorn", 4.4, 2.0, "vined"), _i("tree_thorn", 6.8, 3.0, "b"), _i("tree_thorn", 2.6, 5.6, "vined_b"), _i("tree_thorn", 5.6, 7.4, "c"), _i("tree_thorn", 0.9, 8.2, "stir"),
        _i("tree_thorn", 8.4, 4.2, "glow"), _i("tree_thorn", 11.6, 2.6, "leafy"),
        _i("flowers", 9.8, 6.0, "mixed_a"), _i("flowers", 11.4, 7.4, "white"), _i("flowers", 9.0, 8.0, "violet"), _i("flowers", 12.0, 5.2, "yellow"), _i("bush", 10.6, 4.6, "flowering"),
        _i("mist", 8.6, 5.6, "violet"), _i("mist", 4.0, 4.4, "grey"), _i("roots", 3.8, 7.6, "knot"), _i("roots", 7.6, 6.2, "a"), _i("vines", 3.0, 0.0, "hang_long"), _i("vines", 9.6, 0.0, "dead"),
        _i("stump", 6.2, 5.2, "mossy"), _i("log", 10.2, 1.4, "mossy"), _i("toadstool", 1.4, 4.4, "glow_violet"), _i("grass_tall", 12.2, 8.4, "a"),
    ],
}

WILD["thorn_reeds"] = {
    "name_ko": "가시갈대 밭 · 강어귀", "region": "f3_thorn_reeds", "size": [12, 8], "floor": "ground_grass", "floor_variant": "dry", "wall": "cave",
    "floor_patches": [{"id": "ground_water", "v": "black", "rect": [8, 0, 4, 8]}, {"id": "ground_swamp", "rect": [6, 0, 2, 8]}, {"id": "ground_mud", "rect": [5, 5, 1, 3]}],
    "wall_states": {"7": "mossy", "8": "mossy"},
    "items": [_i("reed_thorn", 0.8 + (i % 5) * 1.05 + (0.4 if (i // 5) % 2 else 0), 1.0 + (i // 5) * 1.05, ("a", "b", "c", "dense", "a", "sparse", "b")[i % 7]) for i in range(30) if i not in (12, 13, 17, 18)] + [
        _i("reed_thorn", 3.2, 3.6, "trampled"), _i("reed_thorn", 4.2, 4.2, "trampled", flip=True),
        _i("cattail", 6.4, 1.6, "a"), _i("cattail", 7.2, 3.8, "b"), _i("cattail", 6.6, 6.6, "c"), _i("grass_tall", 6.2, 4.8, "wide"), _i("log", 9.6, 3.0, "mossy"), _i("rock", 10.4, 6.4, "medium_b"),
        _i("mist", 9.6, 5.2, "grey"), _i("debris_wood", 7.4, 7.4, "planks"),
    ],
}

WILD["hellfire"] = {
    "name_ko": "지옥불 협곡", "region": "f5_hellfire_canyon", "size": [12, 8], "floor": "ground_ash", "wall": "basalt",
    "floor_patches": [{"id": "ground_lava", "rect": [0, 5, 12, 3]}, {"id": "ground_ash", "v": "ember", "rect": [0, 4, 12, 1]}, {"id": "ground_lava", "rect": [9, 0, 3, 2]}],
    "wall_states": {"2": "cracked", "6": "damaged", "8": "mossy"},
    "items": [
        _i("rock_basalt", 1.4, 1.8, "columns_a"), _i("rock_basalt", 5.0, 1.2, "columns_b"), _i("rock_basalt", 7.6, 2.6, "spire"), _i("rock_basalt", 3.2, 3.4, "molten"), _i("rock_basalt", 10.6, 3.4, "scorched"),
        _i("rock_basalt", 8.8, 4.4, "columns_low"), _i("rock_basalt", 0.8, 4.2, "molten"),
        _i("rope_crossing", 5.6, 4.4, "taut_e"), _i("skeleton", 2.4, 2.4, "lying"), _i("scorch", 6.4, 3.2, "blast"), _i("ash_pile", 4.4, 2.6),
        _i("drift", 2.0, 6.0, "ember"), _i("drift", 6.0, 6.2, "ember"), _i("drift", 10.0, 6.0, "ember"), _i("drift", 10.2, 1.2, "ash"), _i("tree_burning", 9.8, 2.6, "charred"),
    ],
}

WILD["ice_cave"] = {
    "name_ko": "빙하굴 · 아이스록", "region": "rift_glacier_cave", "size": [12, 8], "floor": "ground_ice", "wall": "ice",
    "floor_patches": [{"id": "ground_snow", "rect": [0, 0, 5, 4]}, {"id": "ground_ice", "v": "clear", "rect": [7, 3, 5, 5]}, {"id": "ground_snow", "v": "thin", "rect": [0, 4, 4, 4]}],
    "wall_states": {"3": "cracked", "6": "mossy", "9": "mossy", "10": "damaged"},
    "items": [
        _i("rock_ice", 2.5, 2.0, "pillar"), _i("rock_ice", 5.5, 2.0, "pillar_frozen"), _i("rock_ice", 8.5, 2.0, "pillar"), _i("rock_ice", 11.0, 2.2, "pillar_broken"),
        _i("rock_ice", 1.2, 5.2, "snowcap"), _i("rock_ice", 4.4, 6.6, "shards_a"), _i("rock_ice", 9.6, 5.4, "block"), _i("rock_ice", 7.2, 7.2, "shards_b"), _i("rock_ice", 11.2, 7.0, "block_cracked"),
        _i("icicles", 4.0, 3.8, "a"), _i("icicles", 9.0, 6.8, "b"), _i("icicles", 6.8, 4.6, "sparse"),
        _i("snow_drift", 1.6, 1.2, "a"), _i("snow_drift", 3.6, 3.4, "long"), _i("snow_drift", 0.9, 7.4, "b"), _i("tree_pine", 0.9, 3.2, "snowy"), _i("bush", 3.0, 5.2, "snowy"),
        _i("rope_crossing", 6.2, 5.8, "coiled"), _i("drift", 2.0, 2.0, "snow"), _i("drift", 9.0, 4.0, "frost"), _i("skeleton", 8.2, 3.8, "lying"),
    ],
}

WILD["bone_plain"] = {
    "name_ko": "용의 심처 · 패자의 안식처", "region": "f7_dragon_depth", "size": [13, 8], "floor": "ground_bones", "wall": "basalt",
    "floor_patches": [{"id": "ground_rock", "v": "dark", "rect": [8, 0, 5, 8]}, {"id": "ground_bones", "v": "b", "rect": [0, 4, 5, 4]}],
    "wall_states": {"4": "cracked", "9": "damaged"},
    "items": [
        _i("giant_bone", 3.4, 3.2, "rib_arch"), _i("giant_bone", 2.0, 6.4, "skull"), _i("giant_bone", 5.6, 6.6, "spine"), _i("giant_bone", 6.6, 1.6, "vertebra"), _i("giant_bone", 0.9, 1.8, "rib_single"),
        _i("giant_bone", 6.4, 4.4, "femur"), _i("giant_bone", 4.6, 5.0, "shards"), _i("skull", 7.2, 7.4, "heap"), _i("bones", 1.2, 4.4, "scatter_a"),
        _i("planted_sword", 9.2, 1.6, "cluster"), _i("planted_sword", 11.4, 2.6, "a"), _i("planted_sword", 10.2, 4.2, "cluster_b"), _i("planted_sword", 8.8, 5.6, "b"), _i("planted_sword", 11.8, 6.2, "c"),
        _i("planted_sword", 9.8, 7.2, "broken"), _i("planted_sword", 12.2, 4.6, "b"), _i("broken_weapon", 10.8, 6.0, "shield"),
        _i("mist", 10.4, 3.4, "black"), _i("mist", 9.4, 6.6, "black_b"), _i("mist", 11.6, 1.4, "black_b"),
    ],
}

WILD["green_mine"] = {
    "name_ko": "녹색 탄광", "region": "rift_green_mine", "size": [12, 7], "floor": "ground_rock", "wall": "cave",
    "floor_patches": [{"id": "floor_dirt", "rect": [0, 2, 12, 3]}, {"id": "ground_rock", "v": "dark", "rect": [8, 5, 4, 2]}],
    "wall_states": {"1": "cracked", "5": "damaged", "9": "cracked"},
    "items": [
        _i("mine_track", 1.0, 3.5, "straight_h"), _i("mine_track", 3.0, 3.5, "straight_h"), _i("mine_track", 5.0, 3.5, "straight_h"), _i("mine_track", 7.0, 3.5, "broken"), _i("mine_track", 10.4, 3.5, "end", flip=True),
        _i("mine_cart", 3.2, 3.4, "ore"), _i("mine_cart", 8.6, 4.6, "tipped"), _i("mine_support", 1.6, 2.2, "intact"), _i("mine_support", 5.6, 2.2, "sagging"), _i("mine_support", 10.2, 2.4, "collapsed"),
        _i("ore_vein", 0.9, 1.2, "green"), _i("ore_vein", 7.6, 1.2, "green_b"), _i("ore_vein", 11.0, 6.0, "mined"), _i("ore_vein", 3.6, 6.2, "iron"), _i("wall_breach", 3.5, 0.0),
        _i("lantern_hanging", 6.4, 0.0, "lit"), _i("debris_wood", 6.4, 5.6, "planks"), _i("debris_wood", 9.2, 6.4, "splinters"), _i("rubble", 1.6, 5.8, "large"), _i("crate", 0.8, 4.8, "broken"), _i("barrel", 11.2, 1.4, "intact"),
    ],
}

WILD["trial_hall"] = {
    "name_ko": "시련의 석실 · 심연의 문 앞", "region": "f4_sky_tower", "size": [13, 8], "floor": "floor_flag", "wall": "stone",
    "floor_patches": [{"id": "floor_old", "rect": [8, 3, 5, 5]}, {"id": "ground_water", "v": "silver", "rect": [0, 6, 4, 2]}],
    "wall_states": {"6": "cracked"}, "exits_n": [0, 1, 3, 4, 6, 7, 9, 10],
    "items": [
        _i("sealed_door", 1.0, 0.0, "courage"), _i("sealed_door", 4.0, 0.0, "wisdom"), _i("sealed_door", 7.0, 0.0, "lit"), _i("sealed_door", 10.0, 0.0, "open"),
        _i("pillar_white", 2.5, 2.4, "intact"), _i("pillar_white", 5.5, 2.4, "glowing"), _i("pillar_white", 8.5, 2.4, "cracked"), _i("pillar_white", 11.6, 2.6, "broken"), _i("pillar_white", 1.2, 5.2, "sunken"),
        _i("portal_stele", 6.4, 5.0, "active"), _i("portal_stele", 4.0, 6.6, "leaning"), _i("great_mirror", 11.4, 5.0, "active"), _i("great_mirror", 9.4, 7.0, "broken"),
        _i("death_tile", 8.5, 4.5, "hidden"), _i("death_tile", 9.5, 4.5, "revealed"), _i("death_tile", 10.5, 4.5, "armed"), _i("death_tile", 8.5, 5.5, "sprung"), _i("death_tile", 9.5, 5.5, "hidden_b"),
        _i("collapse_crack", 3.6, 4.0, "web", up=1.2), _i("collapse_crack", 5.2, 7.0, "seed", up=1.0), _i("light_orb", 2.2, 6.8, "cluster"), _i("light_orb", 7.6, 7.2, "rise"),
    ],
}

WILD["dawn_meadow"] = {
    "name_ko": "초원 · 밀림 · 운석", "region": "f8_dawn_land", "size": [14, 9], "floor": "ground_grass", "wall": "cave",
    "floor_patches": [{"id": "ground_meadow", "rect": [0, 4, 5, 5]}, {"id": "ground_thicket", "rect": [9, 0, 5, 5]}, {"id": "ground_redsoil", "rect": [9, 5, 5, 4]}, {"id": "ground_water", "v": "clear", "rect": [5, 7, 4, 2]}],
    "wall_states": {"2": "mossy", "10": "mossy", "12": "mossy"},
    "items": [
        _i("tree_broadleaf", 1.6, 2.2, "a"), _i("tree_broadleaf", 4.6, 1.8, "fruit"), _i("tree_pine", 7.2, 2.4, "a"), _i("tree_broadleaf", 6.4, 5.4, "young"), _i("tree_giant", 11.6, 3.2, "hollow"),
        _i("bush", 3.0, 3.4, "a"), _i("bush", 8.6, 4.0, "wide"), _i("bush", 0.8, 5.0, "flowering"), _i("grass_tall", 5.6, 3.4, "a"), _i("grass_tall", 9.8, 1.2, "wide"), _i("grass_tall", 13.0, 4.4, "c"),
        _i("flowers", 2.2, 6.2, "mixed_a"), _i("flowers", 3.8, 7.6, "red"), _i("flowers", 1.0, 8.0, "mixed_b"), _i("flowers", 4.2, 5.2, "yellow"),
        _i("stump", 8.0, 6.2, "axe"), _i("log", 3.4, 4.6, "a"), _i("cattail", 5.6, 6.8, "a"), _i("cattail", 8.4, 7.6, "b"), _i("portal", 0.0 + 7.2, 0.6, "violet"),
        _i("red_beam", 11.4, 7.0, "pulse"), _i("crater", 11.4, 7.0, "small"), _i("meteorite", 11.4, 6.9, "glowing"), _i("meteorite", 13.0, 8.2, "shards"), _i("lightning", 9.6, 8.4, "strike"), _i("tent", 6.8, 4.2, "canvas"), _i("palisade", 9.4, 5.6, "broken"),
    ],
}
