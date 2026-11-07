extends SceneTree
## 층 정리 그림 재료(헤드리스): 층 하나를 시드 고정으로 만들고 몬스터를 깔아, 지도 그림(구역 색 · 벽 검정 — 1칸 = 1px)과
## 마커 JSON(무리 · 요소 · 포탈 · 표시)을 낸다. 변경 정리 페이지(사용자 2026-11-07)가 쓴다.
##   godot --headless --path . --script res://tools/map_digest.gd -- --floor=<층 id> --out=<폴더> [--seed=4]

const ZONE_COLORS := [Color("#3a3f4a"), Color("#4f6a5a"), Color("#6a5a48"), Color("#4a5a74"), Color("#6a4a5a"), Color("#5a6a3a"),
	Color("#6a6a4a"), Color("#4a6a6a"), Color("#5a4a6a"), Color("#704a3a")]


func _init() -> void:
	var args := {"seed": "4"}
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
	var db := GameDatabase.new()
	db.load_all("res://data")
	var def := db.get_entry("floors", str(args["floor"]))
	var reg := ContentRegistries.new()
	var sd := str(args["seed"]).to_int()
	var map := reg.generator(JsonUtil.get_str(def, "generator")).generate(db, def, Rng.new(sd))
	var pc := PlayerCharacter.create(db, "human", "warrior", "정리", {"str": 12, "agi": 8})
	var s := ExploreSession.new(db, def, map, pc, GameClock.new(), Rng.new(sd + 1), reg.effects)
	s.monsters_enabled = true
	s.start()
	var img := Image.create_empty(map.width, map.height, false, Image.FORMAT_RGB8)
	for y in map.height:
		for x in map.width:
			var p := Vector2i(x, y)
			var c := Color("#0d0d10")
			if map.is_walkable(p):
				var zi := int(map.zones[map.idx(p)])
				c = ZONE_COLORS[zi % ZONE_COLORS.size()]
				var d := map.def_at(p)
				if d.sunk:
					c = c.darkened(0.25)
			img.set_pixel(x, y, c)
	var out := str(args["out"])
	DirAccess.make_dir_recursive_absolute(out)
	img.save_png(out.path_join(str(args["floor"]) + ".png"))
	var groups: Array = []
	for g in s.monsters.groups:
		groups.append({"ids": g.monster_ids.duplicate(), "pos": [g.pos.x, g.pos.y], "boss": g.boss, "region": g.region, "party": not g.party.is_empty()})
	var feats: Array = []
	var seen := {}
	for f: Dictionary in s.features.list + map.features:  # 세션이 놓은 요소(2층 길목 · 갈림길 단서) + 지도에 구운 것
		var fp: Vector2i = f["pos"]
		var key := "%s@%d,%d" % [f["id"], fp.x, fp.y]
		if seen.has(key):
			continue
		seen[key] = true
		feats.append({"id": str(f["id"]), "pos": [fp.x, fp.y]})
	var specials: Array = []  # 망대 · 길목 매복 · 덫(위험 칸) — 세션 규칙이 쥔 자리
	if s.watch != null:
		for t: Dictionary in s.watch._towers:
			var tp: Vector2i = t["at"]
			specials.append({"kind": "watch", "pos": [tp.x, tp.y], "r": float(t["radius"])})
	if s.ambush != null:
		for sp: Dictionary in s.ambush._spots:
			var ap: Vector2i = sp["at"]
			specials.append({"kind": "ambush", "pos": [ap.x, ap.y], "ids": JsonUtil.get_array(sp["def"], "monsters")})
	for hc: Variant in s.features.hazards.at:
		var hp: Vector2i = hc
		specials.append({"kind": "hazard", "pos": [hp.x, hp.y], "id": JsonUtil.get_str(s.features.hazards.at[hc], "id")})
	var portals: Array = []
	for p: Dictionary in map.portals:
		var pp: Vector2i = p["pos"]
		portals.append({"dest": str(p.get("dest", "")), "kind": str(p.get("kind", "")), "pos": [pp.x, pp.y]})
	var marks := {}
	var am: Dictionary = map.anchors.get("marks", {})
	for k: String in am:
		var mp: Vector2i = am[k]
		marks[k] = [mp.x, mp.y]
	var zones := {}
	for i in map.zone_ids.size():
		zones[map.zone_ids[i]] = ZONE_COLORS[i % ZONE_COLORS.size()].to_html(false)
	var data := {"floor": str(args["floor"]), "name": JsonUtil.get_str(def, "name_ko"), "w": map.width, "h": map.height, "entry": [s.pos.x, s.pos.y],
		"groups": groups, "features": feats, "specials": specials, "portals": portals, "marks": marks, "zones": zones}
	var fa := FileAccess.open(out.path_join(str(args["floor"]) + ".json"), FileAccess.WRITE)
	fa.store_string(JSON.stringify(data))
	fa.close()
	print("정리: %s %dx%d 무리 %d 요소 %d" % [args["floor"], map.width, map.height, groups.size(), feats.size()])
	s.detach()
	quit(0)
