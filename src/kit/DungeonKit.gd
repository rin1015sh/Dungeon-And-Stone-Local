class_name DungeonKit
extends RefCounted
## 던전 에셋 키트(assets/dungeon_kit — tools/dungeon_kit/build.py가 굽는다)를 게임에서 쓰는 창구. 쓰는 법 docs/DUNGEON_KIT.md.
##   var kit := DungeonKit.open()
##   add_child(kit.make("pillar", "broken"))            # 서 있는 물건 한 개(발 = 노드 위치, 충돌 · 애니메이션 포함)
##   layer.tile_set = kit.tileset()                      # 바닥 · 벽 TileSet → kit.put_floor / kit.put_walls
##   add_child(kit.build_set("prison"))                  # 테마 세트 한 방
## 좌표는 그림 px(한 칸 = px_per_tile 64). 게임 세계(한 칸 32)에 놓을 때는 opts.scale = 0.5 또는 부모 scale.
## 오토로드를 참조하지 않는다(--script 도구 · 테스트에서 그대로 쓴다).

const DEFAULT_PATH := "res://assets/dungeon_kit/kit.json"
const SRC_FLOOR := 0
const SRC_TOP := 1
const SRC_FACE := 2
const SRC_FRINGE := 3  ## 번짐 띠 · 물가 테 · 낭떠러지 턱(64 × 64 — KitEdges)
const SRC_DROP := 4  ## 낭떠러지 벽(64 × 160 — 칸 윗변에서 아래로)
const Z := {"floor": -10, "wall": -8, "decal": -5, "wall_decal": 0, "stand": 0, "over": 20}
const NORTH := 3  ## 세트 방의 북쪽 벽 두께(칸) — tools/dungeon_kit/compose.py와 같다

var data: Dictionary = {}
var px: int = 64
var depth_k: float = 0.72
var _sheets: Dictionary = {}
var _tex: Dictionary = {}
var _tileset: TileSet
var _tiles: Dictionary = {}  # "id.variant" → {"source": int, "base": Vector2i, "span": int}


static func open(path: String = DEFAULT_PATH) -> DungeonKit:
	var kit := DungeonKit.new()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		kit.data = parsed
		kit.px = int(kit.data.get("px_per_tile", 64))
		kit.depth_k = float(kit.data.get("depth_k", 0.72))
	return kit


func has(id: String) -> bool:
	return _assets().has(id)


func info(id: String) -> Dictionary:
	var a: Variant = _assets().get(id, {})
	return a if a is Dictionary else {}


## 분류(cat) · 층(layer) · 꼬리표(tag)로 거른 에셋 id 목록(빈 문자열 = 거르지 않음).
func ids(cat: String = "", layer: String = "", tag: String = "") -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in _assets():
		var a: Dictionary = _assets()[id]
		if (cat.is_empty() or a.get("cat", "") == cat) and (layer.is_empty() or a.get("layer", "") == layer) and (tag.is_empty() or tag in a.get("tags", [])):
			out.append(id)
	return out


func variants(id: String) -> PackedStringArray:
	return PackedStringArray(_variants(id).keys())


## 되풀이 배치용: seed로 변형 하나를 고른다(prefix가 있으면 그 이름으로 시작하는 변형 가운데서).
func pick(id: String, seed: int, prefix: String = "") -> String:
	var names: Array[String] = []
	for v: String in _variants(id):
		if prefix.is_empty() or v.begins_with(prefix):
			names.append(v)
	return "" if names.is_empty() else names[posmod(hash(seed), names.size())]


func frame_count(id: String, variant: String = "") -> int:
	return _frames(id, variant).size()


## 그림 한 장(묶음 그림의 한 조각). 원점(발)은 origin().
func texture(id: String, variant: String = "", frame: int = 0) -> AtlasTexture:
	var key := "%s.%s.%d" % [id, variant, frame]
	if _tex.has(key):
		return _tex[key]
	var fr := _frames(id, variant)
	if fr.is_empty():
		return null
	var f: Array = fr[posmod(frame, fr.size())]
	var t := AtlasTexture.new()
	t.atlas = _sheet(String(info(id).get("sheet", "")))
	t.region = Rect2(float(f[0]), float(f[1]), float(f[2]), float(f[3]))
	_tex[key] = t
	return t


func origin(id: String, variant: String = "", frame: int = 0) -> Vector2:
	var fr := _frames(id, variant)
	if fr.is_empty():
		return Vector2.ZERO
	var f: Array = fr[posmod(frame, fr.size())]
	return Vector2(float(f[4]), float(f[5]))


## 이 변형이 빛을 내면 {"color", "radius"(칸), "at"[x, y, z], "flicker"}, 아니면 빈 dict.
func light_of(id: String, variant: String = "") -> Dictionary:
	var lg: Variant = info(id).get("light", {})
	if not (lg is Dictionary) or (lg as Dictionary).is_empty():
		return {}
	var names: Array = (lg as Dictionary).get("variants", [])
	return lg if names.is_empty() or _variant_name(id, variant) in names else {}


## 물건 하나를 노드로. 노드 위치 = 발(원점). opts: scale(1.0) · collision(true) · light(false — PointLight2D를 단다) ·
## playing(true) · flip(false) · up(벽을 따라 올릴 칸) · z(그리는 순서 보정 px).
func make(id: String, variant: String = "", opts: Dictionary = {}) -> Node2D:
	var a := info(id)
	var node := Node2D.new()
	node.name = id
	if a.is_empty():
		return node
	var vname := _variant_name(id, variant)
	var layer := String(a.get("layer", "stand"))
	node.z_index = int(Z.get(layer, 0))
	node.set_meta("kit_id", id)
	node.set_meta("kit_variant", vname)
	node.set_meta("kit_layer", layer)
	var bias := float(opts.get("z", 0.0))
	var lift := Vector2(0.0, -bias - float(opts.get("up", 0.0)) * px)
	node.position.y = bias
	var flip := bool(opts.get("flip", false))
	var fr := _frames(id, vname)
	if fr.size() > 1:
		node.add_child(_animated(id, vname, fr, lift, flip, bool(opts.get("playing", true)), float(_variants(id)[vname].get("fps", 8))))
	elif fr.size() == 1:
		var sp := Sprite2D.new()
		sp.texture = texture(id, vname)
		sp.centered = false
		var o := origin(id, vname)
		sp.flip_h = flip
		sp.offset = Vector2(-(float(fr[0][2]) - o.x) if flip else -o.x, -o.y)
		sp.position = lift
		node.add_child(sp)
	if bool(opts.get("collision", true)) and a.has("collide"):
		var body := StaticBody2D.new()
		body.name = "Body"
		for r: Array in a["collide"]:
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(float(r[2]), float(r[3])) * px
			shape.shape = rect
			shape.position = Vector2((float(r[0]) + float(r[2]) * 0.5) * (-1.0 if flip else 1.0), -(float(r[1]) + float(r[3]) * 0.5)) * px + Vector2(0.0, -bias)
			body.add_child(shape)
		node.add_child(body)
	var lg := light_of(id, vname)
	if not lg.is_empty():
		node.set_meta("kit_light", lg)
		if bool(opts.get("light", false)):
			node.add_child(_point_light(lg, lift))
	node.scale = Vector2.ONE * float(opts.get("scale", 1.0))
	return node


## 바닥 · 벽 타일 TileSet(한 번 만들어 돌려 쓴다). 소스 0 = 바닥, 1 = 벽 윗면(충돌), 2 = 벽면(64 × 160, 칸 아래에 맞춤).
func tileset() -> TileSet:
	if _tileset != null:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(px, px)
	ts.add_physics_layer()
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "kit")
	ts.set_custom_data_layer_type(0, TYPE_STRING)
	var half := px * 0.5
	var square := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for spec: Array in [[SRC_FLOOR, "floors", Vector2i(px, px)], [SRC_TOP, "wall_tops", Vector2i(px, px)], [SRC_FACE, "wall_faces", Vector2i(px, int(float(data.get("wall_h", 2.5)) * px))],
			[SRC_FRINGE, "fringes", Vector2i(px, px)], [SRC_DROP, "cliff_drops", Vector2i(px, int(float(data.get("wall_h", 2.5)) * px))]]:
		if _sheet(spec[1]) == null:
			continue
		var src := TileSetAtlasSource.new()
		src.texture = _sheet(spec[1])
		src.texture_region_size = spec[2]
		ts.add_source(src, int(spec[0]))
		var size: Vector2i = spec[2]
		for id: String in _assets():
			var a: Dictionary = _assets()[id]
			if a.get("sheet", "") != spec[1]:
				continue
			for vname: String in a["variants"]:
				var f: Array = a["variants"][vname]["frames"][0]
				var base := Vector2i(int(f[0]) / size.x, int(f[1]) / size.y)
				var span := Vector2i(int(f[2]) / size.x, int(f[3]) / size.y)
				_tiles["%s.%s" % [id, vname]] = {"source": int(spec[0]), "base": base, "span": span}
				for ty in span.y:
					for tx in span.x:
						var at := base + Vector2i(tx, ty)
						src.create_tile(at)
						var td := src.get_tile_data(at, 0)
						td.set_custom_data("kit", "%s.%s" % [id, vname])
						if int(spec[0]) == SRC_FACE:
							td.texture_origin = Vector2i(0, (size.y - px) / 2)
						elif int(spec[0]) == SRC_DROP:
							td.texture_origin = Vector2i(0, -(size.y - px) / 2)
						elif int(spec[0]) == SRC_TOP:
							td.add_collision_polygon(0)
							td.set_collision_polygon_points(0, 0, square)
	_tileset = ts
	return ts


## 타일 표: "id.변형" → {source, base, span}(KitEdges가 쓴다).
func tile_of(key: String) -> Dictionary:
	tileset()
	return _tiles.get(key, {})


## 바닥 한 칸. 넓은 그림(span 4)이라 칸 좌표를 4로 나눈 나머지 조각을 깐다 — 이웃 칸과 그림이 이어진다.
func put_floor(layer: TileMapLayer, cell: Vector2i, id: String, variant: String = "") -> void:
	tileset()
	var t: Dictionary = _tiles.get("%s.%s" % [id, _variant_name(id, variant)], {})
	if t.is_empty():
		return
	var span: Vector2i = t["span"]
	layer.set_cell(cell, SRC_FLOOR, (t["base"] as Vector2i) + Vector2i(posmod(cell.x, span.x), posmod(cell.y, span.y)))


## 벽 칸들을 깐다: tops = 윗면(이웃 벽에 따라 16가지 — 모서리 · 끝 · T자 · 십자), faces = 남쪽이 벽이 아닌 칸의 벽면(위로 2.5칸).
## walls = {칸: true}, states = {칸: "cracked" …}(없으면 clean), skip_face = 벽면을 그리지 않을 칸(문 · 통로 에셋 자리).
func put_walls(tops: TileMapLayer, faces: TileMapLayer, walls: Dictionary, kind: String = "stone", states: Dictionary = {}, skip_face: Dictionary = {}, bounds: Rect2i = Rect2i()) -> void:
	tileset()
	var top: Dictionary = _tiles.get("wall_top.%s" % kind, _tiles.get("wall_top.a", {}))  # 자연 암벽은 종류별 윗면
	for cell: Vector2i in walls:
		var mask := 0
		for b: Array in [[1, Vector2i.UP], [2, Vector2i.RIGHT], [4, Vector2i.DOWN], [8, Vector2i.LEFT]]:
			var n: Vector2i = cell + (b[1] as Vector2i)
			if walls.has(n) or (bounds.size != Vector2i.ZERO and not bounds.has_point(n)):
				mask |= int(b[0])
		if not top.is_empty():
			tops.set_cell(cell, SRC_TOP, (top["base"] as Vector2i) + Vector2i(mask % 4, mask / 4))
		var south := cell + Vector2i.DOWN
		if walls.has(south) or skip_face.has(cell) or (bounds.size != Vector2i.ZERO and not bounds.has_point(south)):
			continue
		var face: Dictionary = _tiles.get("wall_%s.%s" % [kind, String(states.get(cell, "clean"))], {})
		if not face.is_empty():
			faces.set_cell(cell, SRC_FACE, (face["base"] as Vector2i) + Vector2i(posmod(cell.x, (face["span"] as Vector2i).x), 0))


## ── 지역 표(에셋 라이브러리 — tools/dungeon_kit/regions.py · docs/asset_library/REGIONAL_ASSET_PLAN.md) ──
## 지역 = 미궁 설정 문서의 층 · 필드 · 균열 · 히든 필드. lore가 "none"인 지역의 에셋은 확장 후보다(확정 설정이 아니다).
func region_names() -> PackedStringArray:
	return PackedStringArray((data.get("regions", {}) as Dictionary).keys())


func region(id: String) -> Dictionary:
	var r: Variant = (data.get("regions", {}) as Dictionary).get(id, {})
	return r if r is Dictionary else {}


## 그 지역에 쓸 수 있는 에셋 참조("id" 또는 "id.변형") 목록. cat으로 거른다(빈 문자열 = 전부, "floor" = 바닥 타일).
func region_assets(id: String, cat: String = "") -> PackedStringArray:
	var r := region(id)
	var out := PackedStringArray()
	for ref: String in (r.get("floor", []) as Array) + (r.get("assets", []) as Array):
		if cat.is_empty() or info(ref.get_slice(".", 0)).get("cat", "") == cat:
			out.append(ref)
	return out


## 참조("id" 또는 "id.변형")로 노드를 만든다 — 변형이 없으면 seed로 고른다(되풀이 배치).
func make_ref(ref: String, seed: int = 0, opts: Dictionary = {}) -> Node2D:
	var id := ref.get_slice(".", 0)
	return make(id, ref.get_slice(".", 1) if ref.contains(".") else pick(id, seed), opts)


## 재사용성: "common" 공용 · "ext" 지역 확장형(공용 에셋의 틀을 넓힌 것 — info(id)["base"]) · "region" 지역 전용.
func reuse_of(id: String) -> String:
	return String(info(id).get("reuse", "common"))


func set_names() -> PackedStringArray:
	return PackedStringArray((data.get("sets", {}) as Dictionary).keys())


## 테마 세트 한 방을 노드로 쌓는다(바닥 · 벽 TileMapLayer + 물건들). 돌려준 노드는 Y-정렬이 켜져 있다 — 몸(플레이어 · 몬스터)을 그 자식으로 넣으면 물건과 앞뒤가 맞는다.
## 방 안쪽 바닥 (0, 0) 칸 = 노드 좌표 (px, NORTH × px). opts는 make()와 같다(scale은 방 전체에).
func build_set(set_name: String, opts: Dictionary = {}) -> Node2D:
	var s: Dictionary = (data.get("sets", {}) as Dictionary).get(set_name, {})
	var room := Node2D.new()
	room.name = set_name
	room.y_sort_enabled = true
	if s.is_empty():
		return room
	var w := int(s["size"][0])
	var h := int(s["size"][1])
	var bounds := Rect2i(0, 0, w + 2, h + NORTH + 1)
	var layers: Array[TileMapLayer] = []
	for z: int in [Z["floor"], Z["floor"] + 1, Z["wall"]]:
		var tl := TileMapLayer.new()
		tl.tile_set = tileset()
		tl.z_index = z
		tl.collision_enabled = bool(opts.get("collision", true))
		room.add_child(tl)
		layers.append(tl)
	var walls := {}
	for y in bounds.size.y:
		for x in bounds.size.x:
			if x >= 1 and x <= w and y >= NORTH and y < NORTH + h:
				put_floor(layers[0], Vector2i(x, y), String(s["floor"]), String(s.get("floor_variant", "")))
			else:
				walls[Vector2i(x, y)] = true
	for p: Dictionary in s.get("floor_patches", []):
		for y in int(p["rect"][3]):
			for x in int(p["rect"][2]):
				var cell := Vector2i(int(p["rect"][0]) + x + 1, int(p["rect"][1]) + y + NORTH)
				if not walls.has(cell):
					put_floor(layers[0], cell, String(p["id"]), String(p.get("v", "")))
	_set_edges(s, layers[0], w, h, walls)
	var states := {}
	for x: String in s.get("wall_states", {}):
		states[Vector2i(int(x) + 1, NORTH - 1)] = s["wall_states"][x]
	var skip := {}
	for x: Variant in s.get("exits_n", []):
		skip[Vector2i(int(x) + 1, NORTH - 1)] = true
	put_walls(layers[1], layers[2], walls, String(s.get("wall", "stone")), states, skip, bounds)
	var item_opts := opts.duplicate()
	item_opts.erase("scale")
	for it: Dictionary in s.get("items", []):
		var o := item_opts.duplicate()
		o.merge({"flip": it.get("flip", false), "up": it.get("up", 0.0), "z": it.get("z", 0.0)})
		var node := make(String(it["id"]), String(it.get("v", "")), o)
		node.position += Vector2(float(it["at"][0]) + 1.0, float(it["at"][1]) + NORTH) * px
		if it.has("f"):
			var anim := node.get_child(0) as AnimatedSprite2D
			if anim != null:
				anim.frame = int(it["f"])
		room.add_child(node)
	room.scale = Vector2.ONE * float(opts.get("scale", 1.0))
	return room


## 세트의 낭떠러지(voids — 빈 칸 네모들) · 바닥 번짐(fringe: true): 가장자리 층들을 바닥 층의 자식으로 단다.
func _set_edges(s: Dictionary, floor_layer: TileMapLayer, w: int, h: int, walls: Dictionary) -> void:
	var voids := {}
	for r: Array in s.get("voids", []):
		for y in int(r[3]):
			for x in int(r[2]):
				var cell := Vector2i(int(r[0]) + x + 1, int(r[1]) + y + NORTH)
				voids[cell] = true
				floor_layer.erase_cell(cell)
	var floor_of := {}
	for cell: Vector2i in floor_layer.get_used_cells():
		var key := String(floor_layer.get_cell_tile_data(cell).get_custom_data("kit"))
		floor_of[cell] = key.trim_suffix(".a").trim_suffix(".b") if not (key.ends_with(".poison") or key.contains("ground_water")) else key
	var made: Array[TileMapLayer] = []
	for i in (8 if bool(s.get("fringe", false)) else 0) + (2 if not voids.is_empty() else 0):
		var tl := TileMapLayer.new()
		tl.tile_set = tileset()
		tl.collision_enabled = false
		floor_layer.add_child(tl)
		made.append(tl)
	if bool(s.get("fringe", false)):
		KitEdges.put_fringe(self, made.slice(4, 8), floor_of, made.slice(0, 4))
	if not voids.is_empty():
		KitEdges.put_cliffs(self, made[-2], made[-1], voids, floor_of, String(s.get("wall", "cave")) if has("cliff_drop") and variants("cliff_drop").has(String(s.get("wall", "cave"))) else "cave")


func _assets() -> Dictionary:
	var a: Variant = data.get("assets", {})
	return a if a is Dictionary else {}


func _variants(id: String) -> Dictionary:
	var v: Variant = info(id).get("variants", {})
	return v if v is Dictionary else {}


func _variant_name(id: String, variant: String) -> String:
	var vs := _variants(id)
	if vs.has(variant) or vs.is_empty():
		return variant
	return String(vs.keys()[0])


func _frames(id: String, variant: String) -> Array:
	var v: Variant = _variants(id).get(_variant_name(id, variant), {})
	return (v as Dictionary).get("frames", []) if v is Dictionary else []


func _sheet(sheet: String) -> Texture2D:
	if not _sheets.has(sheet):
		var s: Dictionary = (data.get("sheets", {}) as Dictionary).get(sheet, {})
		_sheets[sheet] = load(String(s.get("path", ""))) as Texture2D if not s.is_empty() else null
	return _sheets[sheet]


## 프레임마다 잘린 크기 · 원점이 달라서, 여백(margin)을 덧대 모두 같은 판 · 같은 원점으로 맞춘다(일렁일 때 떨리지 않게).
func _animated(id: String, vname: String, fr: Array, lift: Vector2, flip: bool, playing: bool, fps: float) -> AnimatedSprite2D:
	var left := 0.0
	var top := 0.0
	var right := 0.0
	var bottom := 0.0
	for f: Array in fr:
		left = maxf(left, float(f[4]))
		top = maxf(top, float(f[5]))
		right = maxf(right, float(f[2]) - float(f[4]))
		bottom = maxf(bottom, float(f[3]) - float(f[5]))
	var frames := SpriteFrames.new()
	frames.set_animation_speed(&"default", fps)
	frames.set_animation_loop(&"default", true)
	for i in fr.size():
		var f: Array = fr[i]
		var t := texture(id, vname, i).duplicate() as AtlasTexture
		t.margin = Rect2(left - float(f[4]), top - float(f[5]), left + right - float(f[2]), top + bottom - float(f[3]))
		frames.add_frame(&"default", t)
	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = frames
	sp.centered = false
	sp.flip_h = flip
	sp.offset = Vector2(-right if flip else -left, -top)
	sp.position = lift
	if playing:
		sp.play(&"default")
	return sp


func _point_light(lg: Dictionary, lift: Vector2) -> PointLight2D:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	var light := PointLight2D.new()
	light.texture = gt
	light.color = Color(String(lg.get("color", "#ffffff")))
	light.texture_scale = float(lg.get("radius", 2.0)) * px * 2.0 / 128.0
	var at: Array = lg.get("at", [0, 0, 0])
	light.position = Vector2(float(at[0]), -(float(at[2]) + depth_k * float(at[1]))) * px + lift
	return light
