class_name TownWorld
extends Node2D
## 도시 동네 지도 그리기(TownView가 쓴다 — CT82): 바닥 청크(TownGround) 위에 발 높이로 앞뒤를 정하는 것들 —
##   집·시설(TownHouse) · 소품(TownProp — 가로등·천막·통 … · 광장 돌 단) · 플레이어(ActorView, 사람 배율 city.town.actor_scale).
## 집 노드는 화면 둘레 칸 묶음만 올린다(stream — 구운 그림판도 둘레 것만). 플레이어가 집 뒤로 가면 그 집을 흐리게(가림).
## 날씨·구역 색은 CanvasModulate 하나로 곱한다.

const STREAM := 8  ## 집 노드를 올리고 내리는 칸 묶음
const KEEP := Vector2i(4, 3)  ## 화면 가운데 묶음에서 몇 묶음까지 올려 둘까(가로·세로 — 화면 40×22칸 + 남쪽 집 지붕)

var player: ActorView
var sorter: Node2D
var town: TownMap
var _tile: float = 32.0
var _buckets: Dictionary = {}  # 칸 묶음 → [집 번호]
var _live: Dictionary = {}  # 집 번호 → TownHouse(지금 올린 것)
var _at := Vector2i(-999, -999)  # 지금 올린 가운데 묶음
var _render: Dictionary = {}
var _faded: Array[TownHouse] = []
var _tint: CanvasModulate


func build(p_town: TownMap, db: GameDatabase, pc: PlayerCharacter, tile: float) -> void:
	town = p_town
	_tile = tile
	var chunk := int(TownBrush.num(db.render, "chunk", 16.0))
	var ground := Node2D.new()
	add_child(ground)
	for cy in range(0, town.height, chunk):
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
	if not town.dais.is_empty():
		var ctr: Vector2i = town.dais["center"]
		var r := int(ceil(float(town.dais["r"])))
		_prop("dais", Rect2i(ctr - Vector2i(r, r), Vector2i(r * 2, r * 2)), db.render)
	player = ActorView.new()
	sorter.add_child(player)
	player.setup_for(pc, db.render)
	player.drop_camera()
	var k := TownBrush.num(db.render, "actor_scale", 0.78)
	player.scale = Vector2(k, k)
	_tint = CanvasModulate.new()
	add_child(_tint)


func _prop(kind: String, rect: Rect2i, render: Dictionary) -> void:
	var n := TownProp.new()
	n.setup(kind, rect, render, _tile)
	sorter.add_child(n)


## 날씨·구역 색(1 = 그대로).
func set_tint(c: Color) -> void:
	_tint.color = c


## 화면 가운데(세계 px) 둘레 묶음의 집만 노드로(구운 그림판도 둘레 것만 읽힌다 — 웹 메모리). 묶음이 바뀔 때만 다시 고른다.
func stream(center: Vector2) -> void:
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
func update_fade(foot: Vector2) -> void:
	var now: Array[TownHouse] = []
	for h: TownHouse in _live.values():
		if foot.y < h.position.y - 2.0 and h.bounds.has_point(foot - Vector2(0, 14)):
			now.append(h)
	for h in _faded:
		if is_instance_valid(h) and not now.has(h):
			h.set_fade(false)
	for h in now:
		if not _faded.has(h):
			h.set_fade(true)
	_faded = now
