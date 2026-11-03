extends SceneTree
## 동네 집 그림 굽기(CT85 — 사용자 2026-11-02 "도구도 다시 만들어서 그려 · 그냥 2D 건물을 옮긴다고 생각해"):
## 동네 지도(TownMap)의 집마다 면을 횡스크롤 건물과 같은 붓으로 입면도처럼 그리고(Elev) 기운 3/4 면으로 옮겨 붙여(Warp) 한 장 →
## 지붕·벽 마감(Refine 7구역 색 · 잉크 실루엣 · 색 보정 · 그레인)까지 횡스크롤 건물과 같다. 마지막에 그림판 몇 장으로 묶는다(게임이 읽는다).
##   godot --headless --path . --script res://tools/paint_town_houses.gd -- --part=<i>/<n>   (집 n등분 중 i번째 — 넷을 동시에 돌리면 빠르다)
##   godot --headless --path . --script res://tools/paint_town_houses.gd -- --only=h12,h40    (그 집만 — 시험)
##   godot --headless --path . --script res://tools/paint_town_houses.gd -- --pack            (구운 집 → assets/town/houses/p<k>.webp + index.json)
##   godot --headless --path . --script res://tools/paint_town_houses.gd -- --props           (거리 소품 → assets/town/props/<kind>.webp — PropArt)
## 그림 배율: 칸당 S px(게임 32px의 1.5배 — TownHouse가 줄여 그린다), 입면도는 칸당 P px로 그려 줄인다.
## 구운 집은 user://town_bake/<id>.png + .json(off = 노드 원점 기준 왼쪽 위 · key = 집 모양 값 — 지도가 바뀌면 key가 달라져 게임은 그 집을 선으로 그린다).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Refine := preload("res://tools/city_art/Refine.gd")
const Geo := preload("res://tools/town_art/Geo.gd")
const Elev := preload("res://tools/town_art/Elev.gd")
const Warp := preload("res://tools/town_art/Warp.gd")
const Landmarks := preload("res://tools/town_art/Landmarks.gd")
const PropArt := preload("res://tools/town_art/PropArt.gd")

const S := 48.0
const P := 64.0
const GAME_TILE := 32.0
const BAKE := "user://town_bake"
const OUT := "res://assets/town/houses"
const PAGE := 2048
const BAND := 20  ## 그림판 묶음 띠(칸)


func _init() -> void:
	var part := Vector2i(0, 1)
	var only := PackedStringArray()
	var pack := false
	var props := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--part="):
			var s := a.trim_prefix("--part=").split("/")
			part = Vector2i(s[0].to_int(), s[1].to_int())
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		elif a == "--pack":
			pack = true
		elif a == "--props":
			props = true
	var db := GameDatabase.new()
	db.load_all("res://data")
	if props:
		_props(db)
		quit(0)
		return
	if pack:
		_pack(TownMap.load_for(db))
		quit(0)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BAKE))
	var t := TownMap.load_for(db)
	var t0 := Time.get_ticks_msec()
	var n := 0
	for i in t.houses.size():
		var h: Dictionary = t.houses[i]
		if not only.is_empty() and not only.has(str(h["id"])):
			continue
		if only.is_empty() and i % part.y != part.x:
			continue
		var r := paint_house(h, db.render, 7001 + i * 13)
		(r["image"] as Image).save_png(ProjectSettings.globalize_path(BAKE.path_join(str(h["id"]) + ".png")))
		var meta := FileAccess.open(BAKE.path_join(str(h["id"]) + ".json"), FileAccess.WRITE)
		meta.store_string(JSON.stringify({"off": [r["off"].x, r["off"].y], "key": TownHouse.bake_key(h)}))
		meta.close()
		n += 1
		if n % 20 == 0:
			print("집 %d채 (%.1f초)" % [n, (Time.get_ticks_msec() - t0) / 1000.0])
	print("구움: 집 %d채 %.1f초" % [n, (Time.get_ticks_msec() - t0) / 1000.0])
	quit(0)


## 거리 소품(가로등·통·상자·자루·공시판·천막·광장 돌 단) — 지도에서 크기를 읽어 한 장씩.
static func _props(db: GameDatabase) -> void:
	var t := TownMap.load_for(db)
	var sizes := {}
	for pr: Dictionary in t.props:
		sizes[str(pr["kind"])] = (pr["rect"] as Rect2i).size
	if not t.dais.is_empty():
		var r := int(ceil(float(t.dais["r"])))
		sizes["dais"] = Vector2i(r * 2, r * 2)
	var dir := "res://assets/town/props"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for k: String in PropArt.KINDS:
		PropArt.paint(k, S, sizes.get(k, Vector2i.ONE), 9100 + k.hash() % 1000).save(dir.path_join(k + ".webp"))
		print("그림: 소품 ", k)


## 집 한 채 → {image, off(게임 px — 노드 원점(0, 필지 남쪽 끝) 기준 그림 왼쪽 위)}.
static func paint_house(h: Dictionary, render: Dictionary, seed_value: int) -> Dictionary:
	var g := Geo.new(render)
	match str(h.get("style", "")):
		"rotunda":
			Landmarks.rotunda(g, h)
		"gothic":
			Landmarks.gothic(g, h)
		_:
			g.house(h)
	g.faces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["depth"]) < float(b["depth"]))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for f in g.faces:
		for q: Vector3 in f["pts"]:
			var s := Warp.proj(q, S, Vector2.ZERO)
			lo = lo.min(s)
			hi = hi.max(s)
	var origin := (lo - Vector2(8, 8)).floor()
	var size := Vector2i((hi - origin + Vector2(8, 8)).ceil())
	var sp := Paint.new(size.x, size.y, seed_value)
	for i in g.faces.size():
		var f: Dictionary = g.faces[i]
		var t0 := Time.get_ticks_msec()
		var flat := Landmarks.face(f, h, P, seed_value + i) if Landmarks.handles(str(f["kind"])) else Elev.face(f, h, P, seed_value + i)
		var t1 := Time.get_ticks_msec()
		Warp.compose(sp, f, flat, P, S, origin)
		if OS.has_environment("TOWN_PROF"):
			print("  %s %dx%d 그림 %d ms · 옮김 %d ms" % [f["kind"], flat.w, flat.h, t1 - t0, Time.get_ticks_msec() - t1])
	var tf := Time.get_ticks_msec()
	Refine.look(sp, 2)
	Ink.silhouette(sp, 2)
	Ink.grade(sp, 0.22, 1.12)
	Ink.finish(sp, 0.03)
	if OS.has_environment("TOWN_PROF"):
		print("  마감 %dx%d %d ms" % [sp.w, sp.h, Time.get_ticks_msec() - tf])
	var front_y := TownHouse.front_y_of(h)
	var off := origin / S * GAME_TILE - Vector2(0, front_y * GAME_TILE)
	return {"image": sp.to_image(), "off": off}


## 구운 집들을 남북 띠 순서로 그림판(2048²)에 선반식으로 담는다 → p<k>.webp + index.json {id: {page, rect [x, y, w, h], off [x, y], key}}.
static func _pack(t: TownMap) -> void:
	var dir := DirAccess.open(BAKE)
	if dir == null:
		push_warning("구운 집이 없다 — 먼저 --part로 굽는다")
		return
	var items: Array[Dictionary] = []
	var live := {}  # 지금 지도의 집만(지도를 바꾸면 옛 지도의 구운 집이 user://에 남아 있다 — CT95)
	for h: Dictionary in t.houses:
		live[str(h["id"])] = true
	for f in dir.get_files():
		if not f.ends_with(".png"):
			continue
		var id := f.get_basename()
		if not live.has(id):
			continue
		var img := Image.load_from_file(ProjectSettings.globalize_path(BAKE.path_join(f)))
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BAKE.path_join(id + ".json")))
		items.append({"id": id, "img": img, "meta": meta})
	var band := {}  # 집 id → 남북 띠(BAND칸) — 가까운 집끼리 같은 그림판에(게임은 둘레 집만 올려 그림판도 둘레 것만 읽는다)
	for h: Dictionary in t.houses:
		band[str(h["id"])] = int(TownHouse.front_y_of(h) / BAND) * 100000 + int((h["rect"] as Rect2i).position.x)
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(band.get(a["id"], 0)) < int(band.get(b["id"], 0)))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for old in DirAccess.get_files_at(OUT):
		if old.begins_with("p") and (old.ends_with(".webp") or old.ends_with(".import")):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(OUT.path_join(old)))
	var index := {}
	var pages: Array[Image] = []
	var x := 0
	var y := 0
	var row_h := 0
	for it in items:
		var img: Image = it["img"]
		if pages.is_empty() or x + img.get_width() > PAGE:
			x = 0
			y += row_h
			row_h = 0
		if pages.is_empty() or y + img.get_height() > PAGE:
			pages.append(Image.create(PAGE, PAGE, false, Image.FORMAT_RGBA8))
			x = 0
			y = 0
			row_h = 0
		var page := pages.back() as Image
		page.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, y))
		var meta: Dictionary = it["meta"]
		index[it["id"]] = {"page": pages.size() - 1, "rect": [x, y, img.get_width(), img.get_height()], "off": meta["off"], "key": meta["key"]}
		x += img.get_width() + 2
		row_h = maxi(row_h, img.get_height() + 2)
	for k in pages.size():
		pages[k].save_webp(ProjectSettings.globalize_path(OUT.path_join("p%d.webp" % k)), true, 0.86)
	var out := FileAccess.open(OUT.path_join("index.json"), FileAccess.WRITE)
	out.store_string(JSON.stringify({"_comment": "tools/paint_town_houses.gd --pack가 만든다(손으로 고치지 않는다). 집 id → 그림판·자리·노드 원점 기준 왼쪽 위(게임 px)·모양 값.", "scale": S / GAME_TILE, "houses": index}))
	out.close()
	print("묶음: 집 %d채 → 그림판 %d장" % [items.size(), pages.size()])
