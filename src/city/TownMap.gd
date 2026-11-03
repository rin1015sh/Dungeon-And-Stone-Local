class_name TownMap
extends RefCounted
## 도시 동네 지도(라비기온 7구역 — 2D 3/4 탑뷰, CT82): data/town/<id>.json을 칸 지도로 편다.
##   areas(길·광장·계단·옹벽·수로 …)를 순서대로 칠하고, buildings(시설)를 세운 뒤 blocks(주택 덩어리)를 기운 줄의 작은 집으로 채우고,
##   buildings(시설)과 props(가로등·천막·통 …)를 놓는다. 걷기 판정은 FloorMap(걷는 칸 = city.json town.floor_tile) — Kinematics가 쓴다.
## 필지 나누기는 지도 seed의 Rng(같은 지도 = 같은 동네). 오토로드를 참조하지 않는다(헤드리스 시험 — tests/test_town.gd).

## 칸 종류(그리기·걷기). 걷는 칸은 WALK.
const KINDS := ["void", "street", "avenue", "paving", "plaza", "stairs", "bridge", "yard", "court", "water", "retain", "wall", "gate",
	"dais", "house", "prop"]
const WALK := ["street", "avenue", "paving", "plaza", "stairs", "bridge", "yard"]
const W_MIN := 3.2  ## 집 폭(칸 — 줄 방향)
const W_MAX := 5.4
const D_MIN := 3.4  ## 집 깊이(칸)
const D_MAX := 5.0
const JITTER := 5.0  ## 집마다 더 비트는 각도(도)
const FLOORS_MIN := 2
const FLOORS_MAX := 4
const HIP_CHANCE := 0.4  ## 모임지붕(나머지는 박공)
const ALLEY_CHANCE := 0.3  ## 줄 사이 골목

var id: String = ""
var def: Dictionary = {}
var width: int = 0
var height: int = 0
var start: Vector2i = Vector2i.ZERO
var map: FloorMap
## 집: {id, center: Vector2(칸), size: Vector2(폭·깊이), angle(라디안), rect: Rect2i(감싸는 칸), floors, roof(hip·gable), ridge_long, style(stone·timber·plaster 또는 시설 꼴), look(0~999), facility(시설이면 id), circle(원형이면 [cx, cy, r]), door: Vector2i}
var houses: Array[Dictionary] = []
## 소품: {kind, rect: Rect2i}
var props: Array[Dictionary] = []
## 문 칸 → 시설 id(문 칸과 좌우 한 칸씩).
var doors: Dictionary = {}
## 구역문 칸 → {id, travel}
var gates: Dictionary = {}
## 광장 돌 단 {center: Vector2i, r}
var dais: Dictionary = {}
## 퀘스트 · 거리 사건 자리(data places — 지금은 자리만, CT95): [{id, name_ko, at: [Vector2(칸)]}]
var places: Array[Dictionary] = []
var _kind := PackedByteArray()
var _h := PackedFloat32Array()  # 칸 높이(칸 — 단 · 계단 · 수로, 3/4 화면에서 위로 올려 그린다)
var _set_h: Dictionary = {}
var _max_h: float = 0.0  # 영역이 높이를 따로 정한 칸(h)
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
	_h.resize(width * height)
	_h.fill(0.0)
	var st := JsonUtil.get_array(def, "start")
	start = Vector2i(int(st[0]), int(st[1])) if st.size() == 2 else Vector2i(width / 2, height / 2)
	for a: Variant in JsonUtil.get_array(def, "areas"):
		_paint_area(a as Dictionary)
	_heights(JsonUtil.get_array(def, "bands"))
	var rng := Rng.new(maxi(1, JsonUtil.get_int(def, "seed", 7)))
	for e: Variant in JsonUtil.get_array(def, "houses"):
		_explicit_house(e as Dictionary, rng)
	for b: Variant in JsonUtil.get_array(def, "buildings"):
		_building(b as Dictionary, rng)
	for b: Variant in JsonUtil.get_array(def, "blocks"):
		_block(b as Array, rng)
	for p: Variant in JsonUtil.get_array(def, "props"):
		_props(p as Dictionary)
	for pl: Variant in JsonUtil.get_array(def, "places"):
		var at: Array[Vector2] = []
		for v: Variant in JsonUtil.get_array(pl as Dictionary, "at"):
			at.append(Vector2(float((v as Array)[0]), float((v as Array)[1])))
		places.append({"id": JsonUtil.get_str(pl as Dictionary, "id"), "name_ko": JsonUtil.get_str(pl as Dictionary, "name_ko"), "at": at})
	_close_pockets()
	for h in houses:  # 집이 선 땅 높이(3/4 화면에서 위로 올려 그린다)
		var hc: Vector2 = h["center"] if h.has("center") else Vector2(float(h["circle"][0]), float(h["circle"][1]))
		h["elev"] = height_at(Vector2i(hc.floor()))
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


## 칸 높이(칸 — 단 · 계단 · 수로). 지도 밖은 0.
func height_at(c: Vector2i) -> float:
	if c.x < 0 or c.y < 0 or c.x >= width or c.y >= height:
		return 0.0
	return _h[c.y * width + c.x]


## 가장 높은 땅(칸 — 카메라가 위로 얼마나 더 갈 수 있나).
func max_height() -> float:
	return _max_h


## 몸 자리(칸 좌표)의 높이 — 계단에서는 칸 사이를 이어 부드럽게.
func elevation(pos: Vector2) -> float:
	var c := Kinematics.cell_of(pos)
	var h := height_at(c)
	if kind_at(c) == "stairs":
		var t: float = pos.y - floorf(pos.y) - 0.5
		var n := c + (Vector2i.DOWN if t > 0.0 else Vector2i.UP)
		if kind_at(n) in WALK:
			h = lerpf(h, height_at(n), absf(t))
	return h


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
	if a.has("poly"):
		cells = poly_cells(_vecs(JsonUtil.get_array(a, "poly")))
	elif a.has("line"):
		cells = line_cells(_vecs(JsonUtil.get_array(a, "line")), JsonUtil.get_float(a, "width", 3.0))
	elif a.has("circle"):
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
		if a.has("h"):
			_set_h[c] = JsonUtil.get_float(a, "h")
		else:
			_set_h.erase(c)
		if k == "gate":
			gates[c] = {"gate": JsonUtil.get_str(a, "id"), "travel": JsonUtil.get_bool(a, "travel")}


## 덩어리 [x0, y0, x1, y1, 각도(도)] → 그 각도로 기운 줄을 따라 작은 집(폭 W_MIN~W_MAX · 깊이 D_MIN~D_MAX칸)을 붙여 세운다
## (참고 그림처럼 길과 어긋나게 뒤틀린 동네 — 사용자 2026-11-02). 집마다 조금씩 더 비튼다. 덩어리 밖으로 나가는 집은 줄여 보고 안 되면 뺀다.
## 남은 틈은 작은 집으로 한 번 더 메우고, 그래도 남으면 길(걷는다).
func _block(b: Array, rng: Rng) -> void:
	var r := _rect(b.slice(0, 4))
	var ang := deg_to_rad(float(b[4])) if b.size() >= 5 else 0.0
	var c := Vector2(r.position) + Vector2(r.size) * 0.5
	var ax := Vector2(cos(ang), sin(ang))
	var ay := Vector2(-sin(ang), cos(ang))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for k in 4:
		var d := Vector2(r.position) + Vector2(r.size.x * (k % 2), r.size.y * (k / 2)) - c
		var l := Vector2(d.dot(ax), d.dot(ay))
		lo = lo.min(l)
		hi = hi.max(l)
	var v := lo.y
	while v < hi.y - 2.0:
		var dep := rng.randf_range(D_MIN, D_MAX)
		var u := lo.x
		while u < hi.x - 2.0:
			var w := rng.randf_range(W_MIN, W_MAX)
			var jit := deg_to_rad(rng.randf_range(-JITTER, JITTER))
			var ctr := c + ax * (u + w * 0.5) + ay * (v + dep * 0.5)
			if not _try_house(ctr, Vector2(w, dep), ang + jit, r, rng):
				_try_house(ctr, Vector2(w, dep) * 0.7, ang + jit, r, rng)
			u += w
		v += dep
		if rng.randf() < ALLEY_CHANCE:
			v += 1.6  # 줄 사이 골목
	for y in range(r.position.y, r.end.y - 2):  # 틈 메우기
		for x in range(r.position.x, r.end.x - 2):
			if kind_at(Vector2i(x, y)) == "street":
				var s := Vector2(rng.randf_range(2.6, 3.4), rng.randf_range(2.6, 3.2))
				_try_house(Vector2(x, y) + s * 0.5 + Vector2(0.1, 0.1), s, ang + deg_to_rad(rng.randf_range(-JITTER, JITTER)), r, rng)


## 기운 사각 필지에 집 하나(칸 가운데가 필지 안인 칸을 집으로). 덩어리 밖·이미 찬 칸이면 세우지 않는다.
func _try_house(ctr: Vector2, size: Vector2, ang: float, r: Rect2i, rng: Rng) -> bool:
	var ax := Vector2(cos(ang), sin(ang))
	var ay := Vector2(-sin(ang), cos(ang))
	var box := Rect2(Vector2(r.position), Vector2(r.size)).grow(0.35)
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-1, -1)
	for k in 4:
		var p := ctr + ax * size.x * (0.5 if k % 2 == 1 else -0.5) + ay * size.y * (0.5 if k >= 2 else -0.5)
		if not box.has_point(p):
			return false
		lo = Vector2i(mini(lo.x, int(floor(p.x))), mini(lo.y, int(floor(p.y))))
		hi = Vector2i(maxi(hi.x, int(floor(p.x))), maxi(hi.y, int(floor(p.y))))
	var cells: Array[Vector2i] = []
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1):
			var d := Vector2(x + 0.5, y + 0.5) - ctr
			if absf(d.dot(ax)) <= size.x * 0.5 and absf(d.dot(ay)) <= size.y * 0.5:
				if kind_at(Vector2i(x, y)) != "street" or not r.has_point(Vector2i(x, y)):
					return false
				cells.append(Vector2i(x, y))
	if cells.size() < 4:
		return false
	for cc in cells:
		_put(cc, "house")
	var styles := ["stone", "timber", "plaster"]
	houses.append({"id": "h%d" % houses.size(), "center": ctr, "size": size, "angle": ang, "rect": Rect2i(lo, hi - lo + Vector2i.ONE),
		"floors": rng.randi_range(FLOORS_MIN, FLOORS_MAX), "roof": "hip" if rng.randf() < HIP_CHANCE else "gable",
		"ridge_long": rng.randf() < 0.7, "style": styles[rng.randi_range(0, 2)], "look": rng.randi_range(0, 999),
		"facility": "", "door": Vector2i(-1, -1)})
	return true


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
		h["id"] = "h%d" % houses.size()
		houses.append(h)
	else:
		var rc := _rect(JsonUtil.get_array(b, "rect"))
		h["rect"] = rc
		h["center"] = Vector2(rc.position) + Vector2(rc.size) * 0.5
		h["size"] = Vector2(rc.size)
		h["angle"] = 0.0
		h["roof"] = JsonUtil.get_str(b, "roof", "hip")
		h["ridge_long"] = true
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


static func _vecs(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v: Variant in a:
		out.append(Vector2(float((v as Array)[0]), float((v as Array)[1])))
	return out


## 다각형 안의 칸(칸 가운데가 안).
func poly_cells(poly: PackedVector2Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	for y in range(maxi(0, int(floor(lo.y))), mini(height, int(ceil(hi.y)) + 1)):
		for x in range(maxi(0, int(floor(lo.x))), mini(width, int(ceil(hi.x)) + 1)):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), poly):
				out.append(Vector2i(x, y))
	return out


## 굽은 길(꺾은선 둘레 width/2 안의 칸).
func line_cells(line: PackedVector2Array, w: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var seen := {}
	var r := w * 0.5
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		for y in range(maxi(0, int(floor(minf(a.y, b.y) - r))), mini(height, int(ceil(maxf(a.y, b.y) + r)) + 1)):
			for x in range(maxi(0, int(floor(minf(a.x, b.x) - r))), mini(width, int(ceil(maxf(a.x, b.x) + r)) + 1)):
				var c := Vector2i(x, y)
				if seen.has(c):
					continue
				var q := Geometry2D.get_closest_point_to_segment(Vector2(x + 0.5, y + 0.5), a, b)
				if q.distance_to(Vector2(x + 0.5, y + 0.5)) <= r:
					seen[c] = true
					out.append(c)
	return out


## 단 높이: bands = [{h, line(그 단의 남쪽 경계)}…, {h}] 북→남. 경계가 지나는 칸은 옹벽(길·계단·물·다리는 그대로).
## 계단 칸은 위(북)에서 아래(남)로 이어지게 높이를 나눈다. 영역이 h를 정한 칸(수로 물)은 그 값.
func _heights(bands: Array) -> void:
	if bands.is_empty():
		return
	var lines: Array[PackedVector2Array] = []
	var hs: Array[float] = []
	for b: Variant in bands:
		lines.append(_vecs(JsonUtil.get_array(b as Dictionary, "line")))
		hs.append(JsonUtil.get_float(b as Dictionary, "h"))
	for y in height:
		for x in width:
			var h := hs[hs.size() - 1]
			for i in range(lines.size() - 1, -1, -1):
				if lines[i].size() >= 2 and float(y) + 0.5 < _z_on(lines[i], float(x) + 0.5):
					h = hs[i]
			_h[y * width + x] = h
	for i in lines.size():  # 옹벽: 경계가 지나는 칸(위 단 높이)
		if lines[i].size() < 2:
			continue
		for x in width:
			var c := Vector2i(x, int(floor(_z_on(lines[i], float(x) + 0.5))))
			if kind_at(c) in ["street", "avenue", "paving", "yard", "plaza"]:
				_put(c, "retain")
				_h[c.y * width + c.x] = hs[i]
	var stairs := {}
	for y in height:
		for x in width:
			if kind_at(Vector2i(x, y)) == "stairs":
				stairs[Vector2i(x, y)] = true
	for c: Vector2i in stairs:  # 계단: 같은 열에서 계단 칸 위아래 끝의 높이를 잇는다
		var top := c
		while stairs.has(top + Vector2i.UP):
			top += Vector2i.UP
		var bot := c
		while stairs.has(bot + Vector2i.DOWN):
			bot += Vector2i.DOWN
		var hi := height_at(top + Vector2i.UP)
		var lo := height_at(bot + Vector2i.DOWN)
		var n := float(bot.y - top.y + 2)
		_h[c.y * width + c.x] = lerpf(hi, lo, float(c.y - top.y + 1) / n)
	for c: Vector2i in _set_h:
		_h[c.y * width + c.x] = float(_set_h[c])
	for v in _h:
		_max_h = maxf(_max_h, v)


## 꺾은선(동서로 이어진 경계)이 x에서 지나는 z.
static func _z_on(line: PackedVector2Array, x: float) -> float:
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		if a.x <= x and x <= b.x and b.x > a.x:
			return lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
	return line[line.size() - 1].y if x > line[line.size() - 1].x else line[0].y


## 목록으로 준 집 하나(구상 배치 — 가운데 · 폭 · 깊이 · 각도(도) · 층 · place). 칸 가운데가 필지 안인 칸을 집으로(길 칸도 덮는다).
func _explicit_house(e: Dictionary, rng: Rng) -> void:
	var ctr := Vector2(_vecs([JsonUtil.get_array(e, "center")])[0])
	var sz := JsonUtil.get_array(e, "size")
	var size := Vector2(float(sz[0]), float(sz[1]))
	var ang := deg_to_rad(JsonUtil.get_float(e, "angle"))
	var ax := Vector2(cos(ang), sin(ang))
	var ay := Vector2(-sin(ang), cos(ang))
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-1, -1)
	for k in 4:
		var p := ctr + ax * size.x * (0.5 if k % 2 == 1 else -0.5) + ay * size.y * (0.5 if k >= 2 else -0.5)
		lo = Vector2i(mini(lo.x, int(floor(p.x))), mini(lo.y, int(floor(p.y))))
		hi = Vector2i(maxi(hi.x, int(floor(p.x))), maxi(hi.y, int(floor(p.y))))
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1):
			var d := Vector2(x + 0.5, y + 0.5) - ctr
			if absf(d.dot(ax)) <= size.x * 0.5 and absf(d.dot(ay)) <= size.y * 0.5 and kind_at(Vector2i(x, y)) != "void":
				_put(Vector2i(x, y), "house")
	var styles := ["stone", "timber", "plaster"]
	houses.append({"id": "h%d" % houses.size(), "center": ctr, "size": size, "angle": ang, "rect": Rect2i(lo, hi - lo + Vector2i.ONE),
		"floors": clampi(JsonUtil.get_int(e, "floors", rng.randi_range(FLOORS_MIN, FLOORS_MAX)), 1, 5),
		"roof": "hip" if rng.randf() < HIP_CHANCE else "gable", "ridge_long": rng.randf() < 0.7, "style": styles[rng.randi_range(0, 2)],
		"look": rng.randi_range(0, 999), "facility": "", "place": JsonUtil.get_str(e, "place"), "door": Vector2i(-1, -1)})


## 들어온 자리에서 걸어 닿지 않는 걷는 칸(집 사이에 갇힌 틈)은 정원(court — 걷지 않는다)으로 — 이동할 수 없는 빈 길이 남지 않게(CT98).
func _close_pockets() -> void:
	var seen := PackedByteArray()
	seen.resize(width * height)
	var todo: Array[Vector2i] = [start]
	seen[start.y * width + start.x] = 1
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := c + d
			if n.x < 0 or n.y < 0 or n.x >= width or n.y >= height or seen[n.y * width + n.x] != 0:
				continue
			if KINDS[_kind[n.y * width + n.x]] in WALK:
				seen[n.y * width + n.x] = 1
				todo.append(n)
	for i in width * height:
		if seen[i] == 0 and KINDS[_kind[i]] in WALK:
			_kind[i] = KINDS.find("court")
