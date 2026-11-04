class_name TownCollide
extends RefCounted
## 동네 걷기 충돌 지도(CT111 — 2026-11-04 사용자 "건물·장식 히트박스가 넓어 들어갈 수 있어 보여도 막힌다 · 건물 입구 · 좁은 장식"):
##   칸 지도(TownMap.map — 칸 하나 = 32px)는 집·소품을 "칸 가운데가 안이면 칸 전체"로 막아 기운 집·가는 가로등에서 그림보다 크게 막았다.
##   여기서는 칸을 sub × sub로 쪼갠 지도를 만들고, 길에 닿는 집·소품 칸만 실제 모양으로 다시 깎는다:
##     집 = 필지 사각형(각도대로 돈다 — 원형 시설은 원) · 소품 = 발(아래 가운데)에 붙은 작은 상자(city.json town.prop_solid — 칸 크기 대비 [폭, 깊이]).
##   길에 닿지 않는 안쪽 집 칸은 통째로 막은 채(집 사이 틈으로 뒷골목에 새어 들지 않게). 벽·물·옹벽 칸도 그대로 막는다.
## 좌표: 걷는 쪽(TownView)은 칸 좌표 그대로 쓰고, move()가 sub배로 바꿔 Kinematics에 넘긴다.

var sub: int = 4
var map: FloorMap


static func build(t: TownMap, db: GameDatabase, cfg: Dictionary) -> TownCollide:
	var c := TownCollide.new()
	c.sub = maxi(1, JsonUtil.get_int(cfg, "collision_sub", 4))
	var s := c.sub
	c.map = FloorMap.new(db, t.width * s, t.height * s, JsonUtil.get_str(cfg, "block_tile", "rock_wall"))
	var floor_tile := JsonUtil.get_str(cfg, "floor_tile", "cave_floor")
	var solids := JsonUtil.get_dict(cfg, "prop_solid")
	var inset := JsonUtil.get_float(cfg, "house_inset", 0.04)
	var owners := {}  # 칸 → 그 칸을 덮는 집·소품 모양들
	for h in t.houses:
		var r: Rect2i = h["rect"]
		for y in range(r.position.y - 1, r.end.y + 1):
			for x in range(r.position.x - 1, r.end.x + 1):
				_own(owners, Vector2i(x, y), {"house": h, "inset": inset})
	for p in t.props:
		var r: Rect2i = p["rect"]
		var k := str(p["kind"])
		var sz := JsonUtil.get_array(solids, k)
		var f := Vector2(float(sz[0]), float(sz[1])) if sz.size() == 2 else Vector2.ONE
		var box := Rect2((r.position.x + r.size.x * 0.5) - r.size.x * f.x * 0.5, r.end.y - r.size.y * f.y, r.size.x * f.x, r.size.y * f.y)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				_own(owners, Vector2i(x, y), {"box": box})
	for y in t.height:
		for x in t.width:
			var cell := Vector2i(x, y)
			var k := t.kind_at(cell)
			if k in TownMap.WALK:
				c._fill(cell, floor_tile)
				if k == "stairs":  # 계단 양옆 난간(바닥 그림 — tools/town_ground_fine.stair_walls): 바깥 한 줄은 막는다
					for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
						if t.kind_at(cell + d) != "stairs":
							for sy in s:
								c.map.set_tile(cell * s + Vector2i(0 if d.x < 0 else s - 1, sy), JsonUtil.get_str(cfg, "block_tile", "rock_wall"))
			elif k in ["house", "prop"] and _touches_walk(t, cell):
				c._carve(cell, floor_tile, owners.get(cell, []))
	return c


static func _own(owners: Dictionary, cell: Vector2i, shape: Dictionary) -> void:
	if not owners.has(cell):
		owners[cell] = []
	(owners[cell] as Array).append(shape)


static func _touches_walk(t: TownMap, cell: Vector2i) -> bool:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if t.kind_at(cell + d) in TownMap.WALK:
			return true
	return false


func _fill(cell: Vector2i, tile_id: String) -> void:
	for sy in sub:
		for sx in sub:
			map.set_tile(cell * sub + Vector2i(sx, sy), tile_id)


## 칸을 쪼개 모양 밖인 쪽만 걷게 한다.
func _carve(cell: Vector2i, tile_id: String, shapes: Array) -> void:
	for sy in sub:
		for sx in sub:
			var p := Vector2(cell) + (Vector2(sx, sy) + Vector2(0.5, 0.5)) / float(sub)
			var hit := false
			for sh: Dictionary in shapes:
				if _inside(sh, p):
					hit = true
					break
			if not hit:
				map.set_tile(cell * sub + Vector2i(sx, sy), tile_id)


static func _inside(sh: Dictionary, p: Vector2) -> bool:
	if sh.has("box"):
		return (sh["box"] as Rect2).has_point(p)
	var h: Dictionary = sh["house"]
	var inset: float = sh["inset"]
	if h.has("circle"):
		var c: Array = h["circle"]
		return p.distance_to(Vector2(float(c[0]), float(c[1]))) <= float(c[2]) - inset
	var ctr: Vector2 = h.get("center", Vector2.ZERO)
	var size: Vector2 = h.get("size", Vector2.ONE)
	var a := float(h.get("angle", 0.0))
	var d := p - ctr
	return absf(d.dot(Vector2(cos(a), sin(a)))) <= size.x * 0.5 - inset and absf(d.dot(Vector2(-sin(a), cos(a)))) <= size.y * 0.5 - inset


## 칸 좌표 pos에서 delta만큼(Kinematics — sub배 지도에서).
func move(pos: Vector2, delta: Vector2, half: float, assist: float) -> Vector2:
	var k := float(sub)
	return Kinematics.move(map, pos * k, delta * k, half * k, assist * k, 0.25 * k) / k


func walkable_at(pos: Vector2) -> bool:
	return not Kinematics.blocked(map, pos * float(sub), 0.01)
