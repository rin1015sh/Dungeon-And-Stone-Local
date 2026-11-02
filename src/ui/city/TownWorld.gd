class_name TownWorld
extends Node2D
## 도시 동네 지도 그리기(TownView가 쓴다 — CT82): 바닥 청크(TownGround) 위에 발 높이로 앞뒤를 정하는 것들 —
##   집·시설(TownHouse) · 소품(TownProp — 가로등·천막·통 … · 광장 돌 단) · 플레이어(ActorView, 사람 배율 city.town.actor_scale).
## 플레이어가 집 뒤로 가면 그 집을 흐리게(가림 — 둘레 집만 본다: 집을 열 칸 띠로 나눠 둔 목록).
## 날씨·구역 색은 CanvasModulate 하나로 곱한다.

const BAND := 10  ## 가림 판정용 띠(칸 — 동서)

var player: ActorView
var sorter: Node2D
var town: TownMap
var _tile: float = 32.0
var _bands: Dictionary = {}  # 띠 번호 → [TownHouse]
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
	for h: Dictionary in town.houses:
		var n := TownHouse.new()
		n.setup(h, db.render, tile)
		sorter.add_child(n)
		var rc: Rect2i = h["rect"]
		for band in range(rc.position.x / BAND, (rc.end.x - 1) / BAND + 1):
			if not _bands.has(band):
				_bands[band] = []
			(_bands[band] as Array).append(n)
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


## 플레이어(세계 px — 발)를 가린 집을 흐리게: 발이 집 앞면 아래 끝보다 위(북쪽)이고 집 그림 범위 안이면.
func update_fade(foot: Vector2) -> void:
	var band := int(foot.x / _tile) / BAND
	var now: Array[TownHouse] = []
	for b in [band - 1, band, band + 1]:
		for h: TownHouse in _bands.get(b, []):
			var hit := foot.y < h.position.y - 2.0 and h.bounds.has_point(foot - Vector2(0, 14))
			if hit and not now.has(h):
				now.append(h)
	for h in _faded:
		if not now.has(h):
			h.set_fade(false)
	for h in now:
		if not _faded.has(h):
			h.set_fade(true)
	_faded = now
