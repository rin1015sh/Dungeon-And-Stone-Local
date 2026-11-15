"""던전 에셋 키트 — 도시 · 건물 실내 배치 시험 세트(AM69 — 도시 라이브러리). sets.py가 읽어 SETS에 더한다.
에셋이 서로 어울리는지 · 크기가 맞는지 보는 본보기다(게임의 실제 동네 · 시설 실내를 바꾸지 않는다). 틀은 sets.py와 같다.
갤러리(tools/kit_gallery.tscn) 마지막 쪽들과 compose.py 그림으로 본다."""


def _i(id, x, y, v=None, **kw):
    d = {"id": id, "at": [x, y]}
    if v:
        d["v"] = v
    d.update(kw)
    return d


def _row(id, x0, y, vs, **kw):
    """한 칸 폭 조각을 x0부터 오른쪽으로 잇는다(집 벽 · 생울타리)."""
    return [_i(id, x0 + k + 0.5, y, v, **kw) for k, v in enumerate(vs)]


CITY = {}

# 거리: 북쪽에 집 앞면 줄(돌 · 회벽 · 목조) — 그 앞 보도와 연석 · 배수로 · 큰길 · 광장 우물
CITY["city_street"] = {
    "name_ko": "도시 거리 일부", "size": [16, 9], "floor": "street_setts", "wall": "stone",
    "floor_patches": [{"id": "street_sidewalk", "rect": [0, 0, 16, 2]}, {"id": "street_plaza", "rect": [10, 5, 6, 4]}, {"id": "street_worn_setts", "rect": [0, 6, 4, 3]}],
    "items": (
        [_i("house_wall_end", 0.04, 0.6, "stone_l")] + _row("house_wall_stone", 0, 0.6, ["plain", "window", "door", "window_lit", "plain_b"]) + [_i("house_corner", 5.0, 0.6, "stone")]
        + _row("house_wall_plaster", 5, 0.6, ["window_open", "door", "cracked", "window"]) + [_i("house_corner", 9.0, 0.6, "timber")]
        + _row("house_wall_timber", 9, 0.6, ["window", "plain", "door", "worn", "window_lit", "plain_b", "window"]) + [_i("house_wall_end", 15.96, 0.6, "timber_r")]
        + [_i("shop_sign", 2.5, 0.6, "smithy", z=2), _i("wall_awning", 7.0, 0.6, "striped", z=2, up=-0.3), _i("flower_box", 3.5, 0.6, "flowers", z=2, up=0.8), _i("flower_box", 13.5, 0.6, "herb", z=2, up=0.8),
           _i("wall_flag", 14.5, 0.6, "chevron", z=2), _i("shop_sign", 11.5, 0.6, "inn", z=2)]
        + _row("curb", 0, 2.0, ["h"] * 16)
        + [_i("gutter", 4.5, 2.4, "h_flow"), _i("drain_grate", 8.5, 2.4, "grate"), _i("gutter", 12.5, 2.4, "h"),
           _i("rain_barrel", 0.6, 1.3, "full"), _i("planter", 4.2, 1.4, "flowers"), _i("planter", 6.0, 1.4, "group"), _i("sign_aframe", 7.8, 1.5, "shop"),
           _i("produce_crate", 8.6, 1.5, "apples"), _i("barrel", 14.7, 1.4, "intact"), _i("hitching_post", 13.0, 1.5, "rail_rope"),
           _i("street_tree", 2.2, 4.0, "ring"), _i("street_tree", 9.0, 4.0, "trimmed"),
           _i("cart", 5.2, 4.6, "sacks"), _i("handcart", 1.3, 7.6, "loaded"), _i("market_stall", 12.0, 6.3, "produce"), _i("market_stall", 14.6, 6.3, "bread"),
           _i("flag_pole", 10.6, 5.6, "stripes"), _i("manhole", 7.0, 6.8, "closed"), _i("road_patch", 3.4, 6.2, "sunken"), _i("cart_ruts", 6.5, 5.6, "h"),
           _i("fallen_leaves", 2.6, 4.6, "scatter"), _i("puddle", 8.2, 7.6, "small"), _i("straw_scatter", 4.2, 5.4, "a"), _i("junk_pile", 0.9, 5.6, "small"), _i("hay_bale", 15.0, 3.6, "bale")]),
}

# 대장간: 화덕 · 풀무 · 모루 · 담금질 통 · 진열 — 그을린 돌벽
CITY["smithy_room"] = {
    "name_ko": "대장간 내부 일부", "size": [11, 7], "floor": "floor_flag", "wall": "stone",
    "floor_patches": [{"id": "floor_dirt", "rect": [0, 0, 5, 4]}], "wall_states": {"2": "damaged", "8": "cracked"},
    "items": [
        _i("wall_soot", 2.5, 0.0, "plume"), _i("forge", 2.5, 1.0, "lit"), _i("forge_smoke", 2.5, 1.0, "thin", up=3.0), _i("bellows", 0.8, 1.6, "idle"),
        _i("tool_rack_wall", 5.0, 0.0, "full"), _i("sword_display", 7.5, 0.0, "full"), _i("smithy_wall_hang", 9.5, 0.0, "horseshoes"),
        _i("anvil", 3.3, 3.0, "hammer"), _i("forge_sparks", 3.3, 2.9, "hammer"), _i("quench_tub", 4.6, 2.6, "steam"), _i("smith_tools", 2.0, 3.4, "block"),
        _i("post_vise", 5.6, 1.4, "work"), _i("workbench", 7.0, 1.6, "tools"), _i("grindstone", 9.6, 1.6, "base"),
        _i("coal_pile", 0.8, 4.6, "bin"), _i("iron_ore", 1.0, 6.2, "crate"), _i("ingots", 2.6, 5.6, "iron_stack"), _i("firewood", 4.0, 6.3, "cord"),
        _i("shield_rack", 7.0, 4.4, "full"), _i("axe_display", 8.8, 4.2, "full"), _i("spear_display", 10.2, 3.6, "full"), _i("weapon_rack", 9.4, 6.2, "full"),
        _i("armor_stand", 6.2, 6.2, "armor"), _i("water_bucket", 5.4, 3.6, "full"), _i("scorch", 2.6, 2.2, "a"), _i("crucible", 1.6, 2.6, "molten"),
    ],
}

# 상점: 계산대 · 진열 선반 · 약재 서랍 · 청과
CITY["shop_room"] = {
    "name_ko": "상점 내부 일부", "size": [10, 7], "floor": "floor_old", "wall": "brick",
    "items": [
        _i("goods_shelf", 1.0, 0.8, "provisions"), _i("goods_shelf", 2.6, 0.8, "potions"), _i("goods_shelf", 4.2, 0.8, "hardware"), _i("apothecary_drawers", 6.2, 0.8, "open"),
        _i("herb_bundles", 8.0, 0.0, "full"), _i("hanging_bags", 9.0, 0.0, "full"), _i("price_tags", 7.8, 0.0, "chalk_board", up=0.5),
        _i("shop_counter", 5.0, 3.0, "busy"), _i("scale", 4.5, 2.9, "coins", z=30), _i("ledger", 5.6, 2.9, "open", z=30),
        _i("goods_stand", 1.2, 3.6, "food"), _i("potion_rack", 8.6, 2.6, "tidy"), _i("meat_rail", 9.2, 4.6, "full"),
        _i("goods_crate", 1.0, 5.6, "produce"), _i("goods_crate", 2.0, 5.8, "bottles"), _i("grain_bin", 3.4, 5.8, "full"), _i("rope_coil", 6.4, 5.8, "stack"),
        _i("tool_bundle", 7.6, 6.0, "barrel"), _i("torch_bin", 8.6, 6.2, "full"), _i("parcels", 6.8, 4.4, "stack"), _i("barrel", 0.6, 4.5, "intact"), _i("sack", 2.8, 4.4, "full"),
    ],
}

# 신전: 제단 · 단 · 석상 · 신도석 · 기도대
CITY["shrine_room"] = {
    "name_ko": "신전 내부 일부", "size": [11, 8], "floor": "floor_flag", "wall": "ancient",
    "floor_patches": [{"id": "floor_old", "rect": [3, 0, 5, 3]}],
    "items": (
        _row("shrine_dais", 3, 1.6, ["corner", "straight", "runner", "straight", "end"])
        + [_i("shrine_altar", 5.5, 1.4, "lit"), _i("shrine_statue", 1.5, 1.4, "lamp"), _i("shrine_statue", 9.5, 1.4, "offerings"), _i("reliquary", 3.2, 1.2, "closed"), _i("lectern", 7.8, 1.6, "open"),
           _i("candelabra", 2.4, 2.2, "lit"), _i("candelabra", 8.6, 2.2, "lit"),
           _i("pew", 3.4, 4.0, "facing_n"), _i("pew", 7.6, 4.0, "facing_n"), _i("pew", 3.4, 5.4, "books"), _i("pew", 7.6, 5.4, "facing_n"),
           _i("prayer_kneeler", 5.5, 3.0, "cushion"), _i("offering_box", 0.8, 6.6, "post"), _i("shrine_statuette", 10.2, 6.6, "pair"), _i("chalice_stand", 4.6, 2.6, "set"),
           _i("carpet", 5.5, 6.2, "red"), _i("prayer_books", 9.6, 4.4, "stack"), _i("pillar_white", 0.6, 3.6, "intact"), _i("pillar_white", 10.4, 3.6, "intact")]),
}

TESTS = ["city_street", "smithy_room", "inn_room", "shrine_room", "shop_room", "bank_room"]
