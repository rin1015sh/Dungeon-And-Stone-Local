class_name TownHouse
extends Node2D
## 도시 동네 지도의 집 한 채(CT82): 기운 필지(가운데·폭·깊이·각도)에 벽 네 면과 지붕(박공·모임)을 3D로 세워 게임 시점으로 그린다(TownSolid).
##   카메라 쪽 벽 두 면이 보이고(각도가 틀어져 있으면), 지붕은 처마가 벽 밖으로 나오고 가파르다(render.json city.town.roof_pitch).
##   벽: 밑단 돌 · 층마다 창(불 켠 창 · 덧문) · 앞쪽 벽 1층 문 · 반목조 집은 위층에 들보 · 처마 밑 그늘. 지붕: 지붕창 · 굴뚝.
##   시설 꾸밈(큰 문·기둥·간판·차양·화덕)과 신전·원형 도서관은 TownLandmark.
## 노드 위치 = (0, 필지 가장 남쪽 끝 y) — 발 높이로 앞뒤를 정한다(y_sort). 구운 그림(assets/town/houses — CT85)이 있으면 그것을, 없으면 선 그림(TownBrush).

var house: Dictionary
var render: Dictionary
var tile: float = 32.0
## 그린 범위(세계 px — 가림 판정에 쓴다).
var bounds: Rect2
## 짓는 동안: 앞쪽 벽(문이 나는 벽 — TownLandmark.dress가 쓴다) {face, a: Vector2, b: Vector2}.
var front: Dictionary = {}
## 선 땅 높이(세계 px — 단 위의 집은 3/4 화면에서 그만큼 위로, 앞뒤 순서는 발 그대로, CT95).
var lift: float = 0.0
var _fade: float = 1.0
var _goal: float = 1.0
## 구운 그림(tools/paint_town_houses.gd — 횡스크롤 건물 붓으로 그린 집, CT85): 그림판 경로 · 영역 · 그릴 자리(노드 기준). 없으면 선 그림(TownSolid).
var _page: String = ""
var _tex: Texture2D  # 그림판(노드가 붙잡아 둔다 — 그리기 명령은 RID만 들고 있어 놓으면 풀려 하얗게 나온다)
var _region := Rect2()
var _dest := Rect2()
static var _index: Dictionary = {}
static var _index_loaded := false
const INDEX := "res://assets/town/houses/index.json"


func setup(h: Dictionary, p_render: Dictionary, p_tile: float) -> void:
	house = h
	render = p_render
	tile = p_tile
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	position = Vector2(0, front_y_of(h) * tile)
	lift = float(h.get("elev", 0.0)) * tile
	var e := baked(h)
	if not e.is_empty():
		var r: Array = e["rect"]
		var o: Array = e["off"]
		var k := float(_index.get("scale", 1.5))
		_page = "res://assets/town/houses/p%d.webp" % int(e["page"])
		_region = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
		_dest = Rect2(Vector2(float(o[0]), float(o[1])) * tile / 32.0 - Vector2(0, lift), _region.size / k * tile / 32.0)
		bounds = Rect2(_dest.position + position, _dest.size)
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	else:
		bounds = _build().measure()
		bounds.position.y -= lift


## 이 집의 구운 그림 자리(index.json — 모양 값이 같을 때만, 아니면 {}).
static func baked(h: Dictionary) -> Dictionary:
	if not _index_loaded:
		_index_loaded = true
		if ResourceLoader.exists(INDEX) or FileAccess.file_exists(INDEX):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
			_index = d if d is Dictionary else {}
	var e: Dictionary = JsonUtil.get_dict(JsonUtil.get_dict(_index, "houses"), str(h.get("id", "")))
	return e if str(e.get("key", "")) == bake_key(h) else {}


## 필지 가장 남쪽 끝(칸 — 노드 원점 y).
static func front_y_of(h: Dictionary) -> float:
	if h.has("circle"):
		var c: Array = h["circle"]
		return float(c[1]) + float(c[2])
	var c: Vector2 = h.get("center", Vector2.ZERO)
	var s: Vector2 = h.get("size", Vector2.ONE)
	var a := float(h.get("angle", 0.0))
	var ax := Vector2(cos(a), sin(a)) * s.x * 0.5
	var ay := Vector2(-sin(a), cos(a)) * s.y * 0.5
	return c.y + absf(ax.y) + absf(ay.y)


## 구운 그림이 이 집 것인가를 가리는 모양 값(tools/paint_town_houses.gd가 index.json에 적는다).
static func bake_key(h: Dictionary) -> String:
	var c: Vector2 = h.get("center", Vector2.ZERO)
	var s: Vector2 = h.get("size", Vector2.ZERO)
	return "%08x" % (hash([snappedf(c.x, 0.01), snappedf(c.y, 0.01), snappedf(s.x, 0.01), snappedf(s.y, 0.01), snappedf(float(h.get("angle", 0.0)), 0.001),
		int(h.get("floors", 0)), str(h.get("style", "")), str(h.get("roof", "")), bool(h.get("ridge_long", true)), int(h.get("look", 0)),
		str(h.get("facility", "")), str(h.get("circle", "")), str(h.get("zone", ""))]) & 0xffffffff)


func num(key: String, fallback: float) -> float:
	return TownBrush.num(render, key, fallback)


func col(key: String, i: int = 0) -> Color:
	return TownBrush.col(render, key, i)


## 고르는 값(0~999)에서 k번째 선택.
func pick(k: int, n: int) -> int:
	return int(absi(int(house.get("look", 0)) * (k * 7 + 3) + k * 131) / 7) % maxi(1, n)


## 필지 네 모서리(시계 반대 — 북서·북동·남동·남서, 각도만큼 돈다).
func corners() -> PackedVector2Array:
	var c: Vector2 = house.get("center", Vector2.ZERO)
	var s: Vector2 = house.get("size", Vector2.ONE)
	var a := float(house.get("angle", 0.0))
	var ax := Vector2(cos(a), sin(a)) * s.x * 0.5
	var ay := Vector2(-sin(a), cos(a)) * s.y * 0.5
	return PackedVector2Array([c - ax - ay, c + ax - ay, c + ax + ay, c - ax + ay])


## 벽 높이(칸).
func wall_height() -> float:
	return int(house.get("floors", 2)) * num("storey", 1.0) + num("base", 0.2)


func set_fade(on: bool) -> void:
	_goal = num("fade_alpha", 0.3) if on else 1.0
	set_process(not is_equal_approx(_fade, _goal))


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_fade = move_toward(_fade, _goal, delta * num("fade_speed", 4.0))
	modulate.a = _fade
	if is_equal_approx(_fade, _goal):
		set_process(false)


func _draw() -> void:
	if not _page.is_empty():
		if _tex == null:
			_tex = load(_page) as Texture2D
		if _tex != null:
			draw_texture_rect_region(_tex, _dest, _region)
			return
	var b := TownBrush.new()
	_build().flush(b)
	b.flush(self)


func _build() -> TownSolid:
	var s := TownSolid.new(tile, position.y + lift, render)
	match str(house.get("style", "")):
		"rotunda":
			TownLandmark.rotunda(s, self)
		"gothic":
			TownLandmark.gothic(s, self)
		_:
			build_house(s)
			TownLandmark.dress(s, self)
	return s


func wall_color() -> Color:
	match str(house.get("style", "")):
		"stone", "workshop":
			return col("stone", pick(1, 3))
		"timber", "inn", "hall":
			return col("timber_fill", pick(1, 2))
	return col("plaster", pick(1, 5))


func wall_mat() -> String:
	return "ashlar" if str(house.get("style", "")) in ["stone", "workshop"] else "plaster"


func roof_color() -> Color:
	return col("slate", pick(3, 3)) if pick(2, 5) < 3 else col("roofs", pick(3, 3))


func roof_mat() -> String:
	return "slate" if pick(2, 5) < 3 else "clay"


## 상자 집: 벽 네 면(+ 창·문·들보) → 지붕(박공 또는 모임, 처마가 나온다) → 지붕창·굴뚝.
func build_house(s: TownSolid) -> void:
	var cs := corners()
	var c: Vector2 = house["center"]
	var hgt := wall_height()
	var fi := 0
	for i in 4:  # 문이 나는 벽 = 가장 남쪽을 보는 벽
		var m := (cs[i] + cs[(i + 1) % 4]) * 0.5 - c
		var mf := (cs[fi] + cs[(fi + 1) % 4]) * 0.5 - c
		if m.normalized().y > mf.normalized().y:
			fi = i
	for i in 4:
		var a := cs[i]
		var b := cs[(i + 1) % 4]
		var out := (a + b) * 0.5 - c
		var f := s.face(PackedVector3Array([Vector3(a.x, a.y, 0), Vector3(b.x, b.y, 0), Vector3(b.x, b.y, hgt), Vector3(a.x, a.y, hgt)]),
			wall_color(), wall_mat(), Vector3(out.x, out.y, 0))
		if i == fi:
			front = {"face": f, "a": a, "b": b}
		if not f.is_empty():
			_wall_details(s, f, a, b, hgt, i == fi and str(house.get("facility", "")).is_empty())
	_roof(s, cs, c, hgt)


func _roof(s: TownSolid, cs: PackedVector2Array, c: Vector2, hgt: float) -> void:
	var size: Vector2 = house["size"]
	var a := float(house.get("angle", 0.0))
	var ax := Vector2(cos(a), sin(a))
	var ay := Vector2(-sin(a), cos(a))
	var along_x := (size.x >= size.y) == bool(house.get("ridge_long", true))
	var r := ax if along_x else ay
	var p := ay if along_x else ax
	var hr := (size.x if along_x else size.y) * 0.5
	var hp := (size.y if along_x else size.x) * 0.5
	var o := num("overhang", 0.28)
	var rise := minf(hp * (num("facility_pitch", 0.8) if not str(house.get("facility", "")).is_empty() else num("roof_pitch", 1.15)),
		num("roof_rise_max", 99.0))  # 깊은 집(v3 — 집 키트 크기)도 지붕이 산처럼 솟지 않게
	var ze := hgt - 0.05
	var zr := hgt + rise
	var rc := roof_color()
	var rm := roof_mat()
	var E := func(i: float, j: float) -> Vector3:
		var q: Vector2 = c + r * (hr + o) * i + p * (hp + o) * j
		return Vector3(q.x, q.y, ze)
	var hip := str(house.get("roof", "gable")) == "hip"
	var rl := maxf(0.0, hr - hp) if hip else hr + o
	var q0 := Vector3(c.x - r.x * rl, c.y - r.y * rl, zr)
	var q1 := Vector3(c.x + r.x * rl, c.y + r.y * rl, zr)
	s.face(PackedVector3Array([E.call(-1.0, 1.0), E.call(1.0, 1.0), q1, q0]), rc, rm, Vector3(p.x, p.y, 1.0))
	s.face(PackedVector3Array([E.call(1.0, -1.0), E.call(-1.0, -1.0), q0, q1]), rc, rm, Vector3(-p.x, -p.y, 1.0))
	if hip:
		s.face(PackedVector3Array([E.call(-1.0, -1.0), E.call(-1.0, 1.0), q0]), rc, rm, Vector3(-r.x, -r.y, 1.0))
		s.face(PackedVector3Array([E.call(1.0, 1.0), E.call(1.0, -1.0), q1]), rc, rm, Vector3(r.x, r.y, 1.0))
	else:
		for k: float in [-1.0, 1.0]:  # 박공 벽(삼각)
			var w0 := c + r * hr * k - p * hp
			var w1 := c + r * hr * k + p * hp
			var top := c + r * hr * k
			var f := s.face(PackedVector3Array([Vector3(w0.x, w0.y, hgt), Vector3(w1.x, w1.y, hgt), Vector3(top.x, top.y, zr - 0.08)]),
				wall_color(), wall_mat(), Vector3(r.x * k, r.y * k, 0))
			if not f.is_empty() and hp > 1.2:
				var g := c + r * hr * k
				s.decal(f, _quad_v(g - p * 0.18, g + p * 0.18, hgt + rise * 0.3, hgt + rise * 0.55), col("glass"), "", false)
	var side := 1.0 if p.y >= 0.0 else -1.0  # 남쪽을 보는 경사면
	if hp >= 1.5 and hr >= 1.4 and pick(4, 3) != 0:
		_dormer(s, c, r, p * side, hp, o, ze, zr, rc, rm)
	if pick(5, 4) != 0:
		var at := c + r * hr * (0.45 if pick(6, 2) == 0 else -0.45) - p * side * hp * 0.25
		_chimney(s, at, r, hgt + rise * 0.5, zr + 0.55)


## 지붕창: 경사면 위에 세운 작은 앞벽(창) + 작은 박공 지붕(뒤로 큰 지붕에 닿을 때까지).
func _dormer(s: TownSolid, c: Vector2, r: Vector2, p: Vector2, hp: float, o: float, ze: float, zr: float, rc: Color, rm: String) -> void:
	var span := hp + o
	var z_at := func(t: float) -> float: return zr - (zr - ze) * t / span
	var t := hp * 0.55
	var hw := 0.38
	var g := c + p * t
	var zb: float = z_at.call(t)
	var zt := zb + 0.55
	var apex := zt + 0.32
	var t2 := (zr - apex) * span / (zr - ze)
	var t3 := (zr - zt) * span / (zr - ze)
	var gl := g - r * hw
	var gr := g + r * hw
	var f := s.face(PackedVector3Array([Vector3(gl.x, gl.y, zb), Vector3(gr.x, gr.y, zb), Vector3(gr.x, gr.y, zt), Vector3(g.x, g.y, apex), Vector3(gl.x, gl.y, zt)]),
		wall_color(), wall_mat(), Vector3(p.x, p.y, 0))
	s.decal(f, _quad_v(g - r * 0.18, g + r * 0.18, zb + 0.08, zt - 0.06), col("glass_lit") if pick(7, 3) == 0 else col("glass"), "", pick(7, 3) != 0)
	var e := hw + 0.1
	var gb := c + p * t2
	var ll := c + p * t3 - r * e
	var lr := c + p * t3 + r * e
	var fl := g - r * e + p * 0.06
	var fr := g + r * e + p * 0.06
	s.face(PackedVector3Array([Vector3(fl.x, fl.y, zt - 0.04), Vector3(g.x + p.x * 0.06, g.y + p.y * 0.06, apex + 0.04), Vector3(gb.x, gb.y, apex + 0.04), Vector3(ll.x, ll.y, zt - 0.04)]),
		rc, rm, Vector3(-r.x, -r.y, 1.0))
	s.face(PackedVector3Array([Vector3(g.x + p.x * 0.06, g.y + p.y * 0.06, apex + 0.04), Vector3(fr.x, fr.y, zt - 0.04), Vector3(lr.x, lr.y, zt - 0.04), Vector3(gb.x, gb.y, apex + 0.04)]),
		rc, rm, Vector3(r.x, r.y, 1.0))


func _chimney(s: TownSolid, at: Vector2, r: Vector2, z0: float, z1: float) -> void:
	var q := Vector2(-r.y, r.x)
	var h := 0.22
	var base := PackedVector2Array([at - r * h - q * h, at + r * h - q * h, at + r * h + q * h, at - r * h + q * h])
	s.box(base, z0, z1, col("brick"), "ashlar", TownBrush.shade(col("brick"), 0.4), "")


## 벽 하나의 장식: 밑단 · (반목조) 들보 · 층마다 창 · 1층 문(앞벽) · 처마 밑 그늘.
func _wall_details(s: TownSolid, f: Dictionary, a: Vector2, b: Vector2, hgt: float, with_door: bool) -> void:
	var length := a.distance_to(b)
	var base := num("base", 0.2)
	var storey := num("storey", 1.0)
	var floors := int(house.get("floors", 2))
	var style := str(house.get("style", "plaster"))
	var q := func(d0: float, d1: float, z0: float, z1: float) -> PackedVector3Array:
		return _quad_v(a.lerp(b, d0 / length), a.lerp(b, d1 / length), z0, z1)
	s.decal(f, q.call(0.0, length, 0.0, base), col("plinth"), "ashlar")
	if style == "timber":
		s.decal(f, q.call(0.0, length, base, base + storey), col("stone", pick(1, 3)), "ashlar")  # 1층은 돌
	var n := maxi(1, int((length - 0.25) / 1.1))
	var door_k := pick(8, n) if with_door else -1
	var shutters := style == "plaster" and pick(9, 2) == 0
	for fl in floors:
		var z0 := base + fl * storey
		if style == "timber" and fl > 0:
			var tc := col("timber")
			s.decal(f, q.call(0.0, length, z0 - 0.04, z0 + 0.08), tc)
			for k in n + 1:
				var d := clampf(length * float(k) / n, 0.05, length - 0.05)
				s.decal(f, q.call(d - 0.05, d + 0.05, z0, z0 + storey), tc)
			if pick(10 + fl, 2) == 0 and n >= 2:  # 버팀대
				var d0 := length / n * 0.1
				var p0 := a.lerp(b, d0 / length)
				var p1 := a.lerp(b, (length / n * 0.9) / length)
				s.decal(f, PackedVector3Array([Vector3(p0.x, p0.y, z0 + 0.08), Vector3(p0.x, p0.y, z0 + 0.2), Vector3(p1.x, p1.y, z0 + storey - 0.02), Vector3(p1.x, p1.y, z0 + storey - 0.14)]), tc)
		elif style == "stone" and fl > 0:
			s.decal(f, q.call(0.0, length, z0 - 0.03, z0 + 0.04), TownBrush.shade(wall_color(), 1.2))
		for k in n:
			var d := length * (k + 0.5) / n
			if fl == 0 and k == door_k:
				s.decal(f, q.call(d - 0.32, d + 0.32, base, base + 0.82), col("plinth"), "ashlar")
				s.decal(f, q.call(d - 0.25, d + 0.25, base, base + 0.76), col("door"), "wood")
				continue
			var lit_w := pick(20 + k + fl * 7, 4) == 0
			var wz := z0 + storey * 0.3
			s.decal(f, q.call(d - 0.24, d + 0.24, wz - 0.05, wz + 0.5), col("frame"))
			s.decal(f, q.call(d - 0.18, d + 0.18, wz, wz + 0.45), col("glass_lit") if lit_w else col("glass"), "", not lit_w)
			s.decal(f, q.call(d - 0.02, d + 0.02, wz, wz + 0.45), col("frame"))
			s.decal(f, q.call(d - 0.26, d + 0.26, wz - 0.1, wz - 0.04), col("plinth"))
			if shutters:
				s.decal(f, q.call(d - 0.36, d - 0.2, wz, wz + 0.45), col("shutter", pick(11, 3)), "wood")
				s.decal(f, q.call(d + 0.2, d + 0.36, wz, wz + 0.45), col("shutter", pick(11, 3)), "wood")
	s.decal(f, q.call(0.0, length, hgt - 0.22, hgt), Color(0, 0, 0, 0.45), "", false)


## 벽 위 사각(바닥 두 점 a·b, 높이 z0~z1).
static func _quad_v(a: Vector2, b: Vector2, z0: float, z1: float) -> PackedVector3Array:
	return PackedVector3Array([Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0), Vector3(b.x, b.y, z1), Vector3(a.x, a.y, z1)])
