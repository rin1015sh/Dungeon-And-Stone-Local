class_name TownMap
extends RefCounted
## 도시 동네 지도(라비기온 7구역 — 2D 3/4 탑뷰, CT82): data/town/<id>.json을 칸 지도로 편다.
##   areas(길·광장·계단·옹벽·수로 …)를 순서대로 칠하고, blocks(주택 덩어리)를 남쪽을 보는 집 줄로 쌓아 필지마다 집 한 채씩,
##   buildings(시설)과 props(가로등·천막·통 …)를 놓는다. 걷기 판정은 FloorMap(걷는 칸 = city.json town.floor_tile) — Kinematics가 쓴다.
## 필지 나누기는 지도 seed의 Rng(같은 지도 = 같은 동네). 오토로드를 참조하지 않는다(헤드리스 시험 — tests/test_town.gd).

## 칸 종류(그리기·걷기). 걷는 칸은 WALK.
const KINDS := ["void", "street", "avenue", "paving", "plaza", "stairs", "bridge", "yard", "court", "water", "retain", "wall", "gate",
	"dais", "house", "prop"]
const WALK := ["street", "avenue", "paving", "plaza", "stairs", "bridge", "yard"]
const ROW_MIN := 4  ## 집 줄 깊이(칸)
const ROW_MAX := 7
const LOT_MIN := 4  ## 필지 폭(칸)
const LOT_MAX := 8
const ALLEY_CHANCE := 0.35  ## 줄 사이 두 칸 골목

var id: String = ""
var def: Dictionary = {}
var width: int = 0
var height: int = 0
var start: Vector2i = Vector2i.ZERO
var map: FloorMap
## 집: {id, rect: Rect2i, ridge: "x"|"y", floors, look(0~999 — 색·지붕·굴뚝을 고르는 값), facility(시설이면 id), style, circle(원형이면 [cx, cy, r]), door: Vector2i}
var houses: Array[Dictionary] = []
## 소품: {kind, rect: Rect2i}
var props: Array[Dictionary] = []
## 문 칸 → 시설 id(문 칸과 좌우 한 칸씩).
var doors: Dictionary = {}
## 구역문 칸 → {id, travel}
var gates: Dictionary = {}
## 광장 돌 단 {center: Vector2i, r}
var dais: Dictionary = {}
var _kind := PackedByteArray()
var _under: Dictionary = {}  # 소품 칸 → 그 밑 바닥 종류(그리기)


static func load_for(db: GameDatabase, overrides: Dictionary = {}) -> TownMap:
	var cfg := CityValues.city_section(db, overrides, "town")
	var t := TownMap.new()
	t._build(db, JsonUtil.get_str(cfg, "map", "district7"), cfg)
	return t


static func rule(db: GameDatabase, overrides: Dictionary, key: String, fallback: float) -> float:
	return JsonUtil.get_float(CityValues.city_section(db, overrides, "town"), key, fallback)


func _build(db: GameDatabase, map_id: String, cfg: Dictionary) -> void:
	id = map_id
	def = db.get_entry("town", map_id)
	var size := JsonUtil.get_array(def, "size")
	width = int(size[0]) if size.size() == 2 else 0
	height = int(size[1]) if size.size() == 2 else 0
	_kind.resize(width * height)
	_kind.fill(0)
	var st := JsonUtil.get_array(def, "start")
	start = Vector2i(int(st[0]), int(st[1])) if st.size() == 2 else Vector2i(width / 2, height / 2)
	for a: Variant in JsonUtil.get_array(def, "areas"):
		_paint_area(a as Dictionary)
	var rng := Rng.new(maxi(1, JsonUtil.get_int(def, "seed", 7)))
	for b: Variant in JsonUtil.get_array(def, "blocks"):
		_block(_rect(b as Array), rng)
	for b: Variant in JsonUtil.get_array(def, "buildings"):
		_building(b as Dictionary, rng)
	for p: Variant in JsonUtil.get_array(def, "props"):
		_props(p as Dictionary)
	map = FloorMap.new(db, width, height, JsonUtil.get_str(cfg, "block_tile", "rock_wall"))
	var floor_tile := JsonUtil.get_str(cfg, "floor_tile", "cave_floor")
	for y in height:
		for x in width:
			if KINDS[_kind[y * width + x]] in WALK:
				map.set_tile(Vector2i(x, y), floor_tile)


func kind_at(c: Vector2i) -> String:
	if c.x < 0 or c.y < 0 or c.x >= width or c.y >= height:
		return "void"
	return KINDS[_kind[c.y * width + c.x]]


## 그릴 바닥 종류(소품 칸은 그 밑 바닥).
func ground_at(c: Vector2i) -> String:
	var k := kind_at(c)
	return str(_under.get(c, "street")) if k == "prop" else k


func is_walkable(c: Vector2i) -> bool:
	return kind_at(c) in WALK


## 몸(칸 좌표 pos)이 facing 쪽으로 바라보는 것: {door: 시설 id} · {gate: id, travel} · {ring: true} · {}.
func target(pos: Vector2, facing: Vector2i) -> Dictionary:
	var c := Kinematics.cell_of(pos) + facing
	if doors.has(c):
		return {"door": doors[c]}
	if gates.has(c):
		return (gates[c] as Dictionary).duplicate()
	if kind_at(c) == "dais":
		return {"ring": true}
	return {}


## 시설 문 앞(나올 때 서는 자리 — 칸 좌표 몸 중심).
func door_front(facility_id: String) -> Vector2:
	for h in houses:
		if str(h.get("facility", "")) == facility_id:
			var d: Vector2i = h["door"]
			return Vector2(d.x + 0.5, d.y + 1.5)
	return Vector2(start) + Vector2(0.5, 0.5)


func house_of(facility_id: String) -> Dictionary:
	for h in houses:
		if str(h.get("facility", "")) == facility_id:
			return h
	return {}


func _put(c: Vector2i, k: String) -> void:
	if c.x >= 0 and c.y >= 0 and c.x < width and c.y < height:
		_kind[c.y * width + c.x] = KINDS.find(k)


func _fill(r: Rect2i, k: String) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_put(Vector2i(x, y), k)


static func _rect(a: Array) -> Rect2i:
	return Rect2i(int(a[0]), int(a[1]), int(a[2]) - int(a[0]), int(a[3]) - int(a[1])) if a.size() == 4 else Rect2i()


## 원 안의 칸(칸 가운데가 반지름 안).
static func circle_cells(cx: float, cy: float, r: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(int(floor(cy - r)), int(ceil(cy + r)) + 1):
		for x in range(int(floor(cx - r)), int(ceil(cx + r)) + 1):
			if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r:
				out.append(Vector2i(x, y))
	return out


func _paint_area(a: Dictionary) -> void:
	var k := JsonUtil.get_str(a, "kind", "street")
	var cells: Array[Vector2i] = []
	if a.has("circle"):
		var c := JsonUtil.get_array(a, "circle")
		cells = circle_cells(float(c[0]), float(c[1]), float(c[2]))
		if k == "dais":
			dais = {"center": Vector2i(int(c[0]), int(c[1])), "r": float(c[2])}
	else:
		var r := _rect(JsonUtil.get_array(a, "rect"))
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				cells.append(Vector2i(x, y))
	for c in cells:
		_put(c, k)
		if k == "gate":
			gates[c] = {"gate": JsonUtil.get_str(a, "id"), "travel": JsonUtil.get_bool(a, "travel")}


## 덩어리 → 남쪽을 보는 집 줄(깊이 ROW_MIN~ROW_MAX칸)을 북에서 남으로 쌓고, 줄마다 폭 LOT_MIN~LOT_MAX칸 필지(참고 그림처럼 앞면이 모두 남쪽 —
## 뒷줄 집 앞면 위로 앞줄 지붕이 겹친다). 줄 사이에 가끔 두 칸 골목(덩어리 양옆 길과 이어진다). 좁고 긴 덩어리(폭 ≤ 8)는 남북으로 늘어선 박공집.
func _block(r: Rect2i, rng: Rng) -> void:
	if r.size.x <= LOT_MAX and r.size.y > r.size.x:
		_row(r, false, rng)
		return
	var y := r.position.y
	while y < r.end.y:
		var rest := r.end.y - y
		var d := rng.randi_range(ROW_MIN, ROW_MAX)
		if rest - d < ROW_MIN:
			d = rest if rest <= ROW_MAX + 2 else rest - ROW_MIN
		_row(Rect2i(r.position.x, y, r.size.x, d), true, rng)
		y += d
		if r.end.y - y >= ROW_MIN * 2 + 2 and rng.randf() < ALLEY_CHANCE:
			_fill(Rect2i(r.position.x, y, r.size.x, 2), "street")  # 줄 사이 골목
			y += 2


## 한 줄의 필지: along_x면 동서로 폭 LOT_MIN~LOT_MAX칸씩(깊이 = 줄 높이), 아니면 남북으로.
func _row(r: Rect2i, along_x: bool, rng: Rng) -> void:
	var length := r.size.x if along_x else r.size.y
	var depth := r.size.y if along_x else r.size.x
	var pos := 0
	while pos < length:
		var rest := length - pos
		var lw := rng.randi_range(LOT_MIN, LOT_MAX)
		if rest - lw < LOT_MIN:
			lw = rest if rest <= LOT_MAX + 2 else rest - LOT_MIN
		var lot := Rect2i(r.position.x + pos, r.position.y, lw, depth) if along_x else Rect2i(r.position.x, r.position.y + pos, depth, lw)
		var ridge := "x" if along_x else "y"
		if along_x and lw <= 6 and rng.randf() < 0.45:
			ridge = "y"  # 좁은 집은 박공을 길 쪽으로(지붕선이 들쭉날쭉하게)
		_add_house({"rect": lot, "ridge": ridge, "floors": rng.randi_range(2, 4), "look": rng.randi_range(0, 999), "style": "house"})
		pos += lw


func _building(b: Dictionary, rng: Rng) -> void:
	var h := {"facility": JsonUtil.get_str(b, "facility"), "style": JsonUtil.get_str(b, "style", "stone"),
		"floors": JsonUtil.get_int(b, "floors", 3), "look": rng.randi_range(0, 999), "ridge": "x"}
	var d := JsonUtil.get_array(b, "door")
	h["door"] = Vector2i(int(d[0]), int(d[1])) if d.size() == 2 else Vector2i(-1, -1)
	if b.has("circle"):
		var c := JsonUtil.get_array(b, "circle")
		h["circle"] = [float(c[0]), float(c[1]), float(c[2])]
		var cells := circle_cells(float(c[0]), float(c[1]), float(c[2]))
		var lo := cells[0]
		var hi := cells[0]
		for cc in cells:
			lo = Vector2i(mini(lo.x, cc.x), mini(lo.y, cc.y))
			hi = Vector2i(maxi(hi.x, cc.x), maxi(hi.y, cc.y))
			_put(cc, "house")
		h["rect"] = Rect2i(lo, hi - lo + Vector2i.ONE)
		houses.append(h)
	else:
		h["rect"] = _rect(JsonUtil.get_array(b, "rect"))
		_add_house(h)
	var door: Vector2i = h["door"]
	for dx in [-1, 0, 1]:
		doors[door + Vector2i(dx, 0)] = str(h["facility"])


func _add_house(h: Dictionary) -> void:
	h["id"] = "h%d" % houses.size()
	if not h.has("door"):
		h["door"] = Vector2i(-1, -1)
	if not h.has("facility"):
		h["facility"] = ""
	_fill(h["rect"], "house")
	houses.append(h)


func _props(p: Dictionary) -> void:
	var k := JsonUtil.get_str(p, "kind", "lamp")
	var at: Array[Rect2i] = []
	if p.has("rect"):
		at.append(_rect(JsonUtil.get_array(p, "rect")))
	elif p.has("line"):
		var l := JsonUtil.get_array(p, "line")
		var a := Vector2i(int(l[0]), int(l[1]))
		var b := Vector2i(int(l[2]), int(l[3]))
		var step := maxi(1, JsonUtil.get_int(p, "step", 6))
		var n := maxi(absi(b.x - a.x), absi(b.y - a.y)) / step
		for i in n + 1:
			at.append(Rect2i(a + (b - a) * i * step / maxi(1, maxi(absi(b.x - a.x), absi(b.y - a.y))), Vector2i.ONE))
	elif p.has("ring"):
		var r := JsonUtil.get_array(p, "ring")
		var n := int(r[3])
		for i in n:
			var ang := TAU * (float(i) + 0.5) / float(n)
			at.append(Rect2i(Vector2i(int(floor(float(r[0]) + cos(ang) * float(r[2]))), int(floor(float(r[1]) + sin(ang) * float(r[2])))), Vector2i.ONE))
	else:
		for v: Variant in JsonUtil.get_array(p, "at"):
			at.append(Rect2i(Vector2i(int((v as Array)[0]), int((v as Array)[1])), Vector2i.ONE))
	for r in at:
		if not is_walkable(r.position):
			continue  # 길 위에만(집·물·벽 위의 소품은 건너뛴다)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				_under[Vector2i(x, y)] = kind_at(Vector2i(x, y))
		_fill(r, "prop")
		props.append({"kind": k, "rect": r})
