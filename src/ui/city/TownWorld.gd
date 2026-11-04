class_name TownWorld
extends Node2D
## 도시 동네 지도 그리기(TownView가 쓴다 — CT82): 바닥 청크(TownGround) 위에 발 높이로 앞뒤를 정하는 것들 —
##   집·시설(TownHouse) · 소품(TownProp — 가로등·천막·통 … · 광장 돌 단) · 플레이어(ActorView, 사람 배율 city.town.actor_scale).
## 집 노드는 화면 둘레 칸 묶음만 올린다(stream — 구운 그림판도 둘레 것만). 플레이어가 집 뒤로 가면 그 집을 흐리게(가림).
## 날씨·구역 색은 CanvasModulate 하나로 곱한다.

const STREAM := 8  ## 집 노드를 올리고 내리는 칸 묶음
const KEEP := Vector2i(2, 2)  ## 화면 가운데 묶음에서 몇 묶음까지 올려 둘까(가로·세로 — 화면 15×8칸 + 남쪽 집 지붕, CT107)
const GROUND_REACH := Vector2(640, 480)  ## 바닥 조각을 올리는 화면 가운데 둘레(세계 px — 화면 15×8칸 = 480×270의 둘레 + 여유)

var player: ActorView
## 플레이어 발 자리(앞뒤 순서) — 몸은 그 안에서 땅 높이만큼 위로(player.position.y = −높이).
var player_root: Node2D
var sorter: Node2D
var town: TownMap
var _tile: float = 32.0
var _buckets: Dictionary = {}  # 칸 묶음 → [집 번호]
var _live: Dictionary = {}  # 집 번호 → TownHouse(지금 올린 것)
var _at := Vector2i(-999, -999)  # 지금 올린 가운데 묶음
var _render: Dictionary = {}
var _faded: Array[TownHouse] = []
var _tint: CanvasModulate
var _ground: Array[Dictionary] = []  # 바닥 조각 {file, rect(세계 px), k}
var _ground_live: Dictionary = {}  # 조각 번호 → Sprite2D(지금 올린 것)
var _ground_parent: Node2D


func build(p_town: TownMap, db: GameDatabase, pc: PlayerCharacter, tile: float) -> void:
	town = p_town
	_tile = tile
	var chunk := int(TownBrush.num(db.render, "chunk", 16.0))
	var ground := Node2D.new()
	add_child(ground)
	var baked := _baked_ground(ground, tile)  # 구운 바닥이 있으면 칸 그리기(TownGround)는 쓰지 않는다
	for cy in range(0, 0 if baked else town.height, chunk):
		for cx in range(0, town.width, chunk):
			var g := TownGround.new()
			g.town = town
			g.render = db.render
			g.tile = tile
			g.rect = Rect2i(cx, cy, mini(chunk, town.width - cx), mini(chunk, town.height - cy))
			ground.add_child(g)
	sorter = Node2D.new()
	sorter.y_sort_enabled = true
	add_child(sorter)
	_render = db.render
	for i in town.houses.size():  # 집은 칸 묶음(STREAM칸)마다 목록만 — 노드는 화면 둘레만 만든다(stream)
		var rc: Rect2i = town.houses[i]["rect"]
		var key := Vector2i(rc.get_center()) / STREAM
		if not _buckets.has(key):
			_buckets[key] = []
		(_buckets[key] as Array).append(i)
	for p: Dictionary in town.props:
		_prop(str(p["kind"]), p["rect"], db.render)
	if not town.dais.is_empty():  # 돌 단은 바닥 바로 위(사람이 그 위를 걷는다 — 선 돌 고리는 소품 dais_ring으로 앞뒤를 가린다, CT111)
		var ctr: Vector2i = town.dais["center"]
		var r := int(ceil(float(town.dais["r"])))
		var flat := TownProp.new()
		flat.setup("dais", Rect2i(ctr - Vector2i(r, r), Vector2i(r * 2, r * 2)), db.render, _tile)
		flat.lift = float(town.dais.get("base", 0.0)) * _tile
		add_child(flat)
		move_child(flat, sorter.get_index())
	player_root = Node2D.new()
	sorter.add_child(player_root)
	player = ActorView.new()
	player_root.add_child(player)
	player.setup_for(pc, db.render)
	player.drop_camera()
	var k := TownBrush.num(db.render, "actor_scale", 0.78)
	player.scale = Vector2(k, k)
	_tint = CanvasModulate.new()
	add_child(_tint)


## 구운 바닥(tools/town_ground_bake.py — 곡선 길 · 동심원 광장 · 판석 · 흙 · 옹벽 마름돌, 높이까지 3/4로 그린 조각 그림, CT99). 없으면 false.
## 조각은 목록만 읽고, 화면 둘레 것만 올린다(_stream_ground — 바닥 그림이 칸당 64px라 다 올리면 웹 메모리가 모자라다, CT107).
func _baked_ground(parent: Node2D, tile: float) -> bool:
	const INDEX := "res://assets/town/ground/index.json"
	if not FileAccess.file_exists(INDEX):
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
	if not d is Dictionary:
		return false
	var k := tile / float((d as Dictionary).get("tile", 32))
	_ground_parent = parent
	for c: Variant in JsonUtil.get_array(d as Dictionary, "chunks"):
		var e := c as Dictionary
		var r: Array = e.get("rect", [0, 0, 0, 0])
		_ground.append({"file": "res://assets/town/ground/%s.webp" % str(e.get("file", "")),
			"rect": Rect2(Vector2(float(r[0]), float(r[1])) * k, Vector2(float(r[2]), float(r[3])) * k), "k": k})
	return not _ground.is_empty()


## 화면 가운데(세계 px) 둘레(반경 GROUND_REACH × 화면)의 바닥 조각만 노드로.
func _stream_ground(center: Vector2) -> void:
	var reach := Rect2(center - GROUND_REACH, GROUND_REACH * 2.0)
	for i in _ground.size():
		var e: Dictionary = _ground[i]
		var on := reach.intersects(e["rect"] as Rect2)
		if on and not _ground_live.has(i):
			var tex := load(str(e["file"])) as Texture2D
			if tex == null:
				continue
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.centered = false
			sp.position = (e["rect"] as Rect2).position
			sp.scale = Vector2(float(e["k"]), float(e["k"]))
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_ground_parent.add_child(sp)
			_ground_live[i] = sp
		elif not on and _ground_live.has(i):
			(_ground_live[i] as Node).queue_free()
			_ground_live.erase(i)


## 지금 올린 바닥 조각 수(시험).
func ground_count() -> int:
	return _ground_live.size()


func _prop(kind: String, rect: Rect2i, render: Dictionary) -> void:
	var n := TownProp.new()
	n.setup(kind, rect, render, _tile)
	n.lift = town.height_at(Vector2i(rect.get_center())) * _tile
	sorter.add_child(n)


## 날씨·구역 색(1 = 그대로).
func set_tint(c: Color) -> void:
	_tint.color = c


## 화면 가운데(세계 px) 둘레 묶음의 집만 노드로(구운 그림판도 둘레 것만 읽힌다 — 웹 메모리). 묶음이 바뀔 때만 다시 고른다.
func stream(center: Vector2) -> void:
	if not _ground.is_empty():
		_stream_ground(center)
	var at := Vector2i(center / _tile) / STREAM
	if at == _at:
		return
	_at = at
	var want := {}
	for by in range(at.y - KEEP.y, at.y + KEEP.y + 1):
		for bx in range(at.x - KEEP.x, at.x + KEEP.x + 1):
			for i: int in _buckets.get(Vector2i(bx, by), []):
				want[i] = true
	for i: int in _live.keys():
		if not want.has(i):
			(_live[i] as TownHouse).queue_free()
			_live.erase(i)
	for i: int in want:
		if not _live.has(i):
			var n := TownHouse.new()
			n.setup(town.houses[i], _render, _tile)
			sorter.add_child(n)
			_live[i] = n


## 지금 올린 집 노드 수(시험).
func live_count() -> int:
	return _live.size()


## 플레이어(세계 px — 발)를 가린 집을 흐리게: 발이 집 앞면 아래 끝보다 위(북쪽)이고 집 그림 범위 안이면.
## 가림: 몸이 필지 앞 가장자리(그 x에서 — 기운 집은 남쪽 모서리가 아니라)보다 뒤(북)에 있고 그림에 덮이면 흐리게.
## 돌려주는 값 = 앞뒤 순서용 발 y(px): 기운 집 앞에 서 있는데 집 모서리(정렬 y)보다 북쪽이면 그 집보다 앞에 그려지게 끌어 내린다(CT111).
func update_fade(foot: Vector2, lift: float = 0.0) -> float:
	var now: Array[TownHouse] = []
	var sort_y := foot.y
	var fx := foot.x / _tile
	for h: TownHouse in _live.values():
		if foot.y >= h.position.y or not h.bounds.has_point(foot - Vector2(0, 7 + lift)):
			continue
		var edge := TownHouse.front_at(h.house, fx) * _tile
		if foot.y < edge - 2.0:
			if h.covers(foot - Vector2(0, 7 + lift)) or h.covers(foot - Vector2(0, _tile * 0.8 + lift)):  # 그림이 몸을 실제로 덮을 때만
				now.append(h)
		else:
			sort_y = maxf(sort_y, h.position.y + 0.5)
	for h in _faded:
		if is_instance_valid(h) and not now.has(h):
			h.set_fade(false)
	for h in now:
		if not _faded.has(h):
			h.set_fade(true)
	_faded = now
	return sort_y
