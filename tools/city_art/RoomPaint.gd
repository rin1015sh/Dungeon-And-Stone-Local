extends RefCounted
## 시설 실내 한 지도 그림(탑뷰 3/4 — data/rooms, CT66; tools/paint_rooms.gd 전용): 칸 글자 + 범례 → 바닥 층(floor.webp) · 벽 층(walls.webp).
## 바닥 층 = 재질(RoomMaterials — 건물마다 다른 바닥, 범례 material > regions > 방 floor) · 깔개 · 바닥 장식(RoomDecor) ·
##   계단·사다리·문간·트인 곳·난간 · 벽 밑 그늘 · 가구 그림자 · 때. 벽 층(투명) = 벽 윗면(어두운 돌 머리)·앞면(방 wall 재질) + 벽 장식(RoomWalls).
## 빛: 빛 나는 가구·벽 장식(light) 둘레만 밝히고 나머지는 어둡게(두 층에 같은 빛) → Ink.grade → Ink.finish. 가구는 RoomFurniture가 따로 그린다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const RoomArt := preload("res://tools/city_art/RoomArt.gd")
const RoomWalls := preload("res://tools/city_art/RoomWalls.gd")
const RoomDecor := preload("res://tools/city_art/RoomDecor.gd")
const RoomMaterials := preload("res://tools/city_art/RoomMaterials.gd")

const AMBIENT := 0.84  ## 빛이 닿지 않는 곳 배율 — 라비기온 7구역 거리 그림 밝기쯤(CT67, 예전 0.6)
const WALLISH := ["wall", "walldeco"]


## 두 층을 그린다: {floor: Paint, walls: Paint}. rows·legend는 CityRoom과 같은 것(legend = 공통 + 방).
static func paint(room: Dictionary, rows: PackedStringArray, legend: Dictionary, t: int, seed_value: int) -> Dictionary:
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, r.length())
	var fl := Paint.new(w * t, h * t, seed_value)
	var wl := Paint.new(w * t, h * t, seed_value + 1)
	var kind := func(x: int, y: int) -> String:
		if y < 0 or y >= h or x < 0 or x >= rows[y].length():
			return "void"
		return JsonUtil.get_str(JsonUtil.get_dict(legend, rows[y][x]), "kind", "void")
	var mats := _materials(room, rows, legend, w, h)
	for m: String in mats:
		var sh := RoomMaterials.floor(fl, m, t)
		for c: Vector2i in mats.get(m, []):
			fl.fill_rect(c.x * t, c.y * t, t, t, sh)
	for y in h:
		for x in rows[y].length():
			var k: String = kind.call(x, y)
			if k in ["void", "open"] or k in WALLISH:
				fl.fill_rect(x * t, y * t, t, t, fl.flat(Color("#0c0b0a"), 0.04))
	RoomDecor.rugs(fl, rows, legend, t)
	RoomDecor.decor(fl, rows, legend, t)
	for y in h:
		for x in rows[y].length():
			match str(kind.call(x, y)):
				"stairs":
					RoomDecor.stairs(fl, x, y, t, str(kind.call(x, y - 1)) == "stairs", str(kind.call(x, y + 1)) == "stairs")
				"ladder":
					RoomDecor.ladder(fl, x, y, t, str(kind.call(x - 1, y)) in WALLISH or str(kind.call(x - 1, y)) == "void")
				"open":
					RoomDecor.open_drop(fl, x, y, t, str(kind.call(x, y - 1)) != "open")
				"rail":
					RoomDecor.rail(fl, x, y, t, str(kind.call(x - 1, y)) != "rail", str(kind.call(x + 1, y)) != "rail")
				"door", "doorway", "locked", "entry":
					RoomDecor.threshold(fl, x, y, t, str(kind.call(x, y)) == "entry")
	_shadows(fl, rows, legend, kind, t)
	_walls(wl, room, rows, legend, kind, t)
	var lights := _lights(rows, legend, t)
	var f := _light_field(w * t, h * t, lights, AMBIENT)
	for p: Paint in [fl, wl]:
		for i in p.w * p.h:
			var k := i * 4
			for j in 3:
				p.buf[k + j] *= f[i]
		for L: Array in lights:
			Ink.glow(p, L[0].x, L[0].y, float(L[1]) * 0.35, L[2], float(L[3]) * 0.3)
		Ink.grade(p, 0.12, 1.05)
		Ink.finish(p, 0.035, 0.0)
	return {"floor": fl, "walls": wl}


## 칸마다 바닥 재질: 범례 material(floor 칸) > regions > 방 floor. {재질: [칸 …]} — 바닥처럼 그 위를 덮는 칸(가구·깔개·장식·계단·문·사람)도 밑바닥을 깐다.
static func _materials(room: Dictionary, rows: PackedStringArray, legend: Dictionary, w: int, h: int) -> Dictionary:
	var out := {}
	var base := JsonUtil.get_str(room, "floor", "wood")
	for y in h:
		for x in rows[y].length():
			var d := JsonUtil.get_dict(legend, rows[y][x])
			var k := JsonUtil.get_str(d, "kind")
			if k in ["void", "open", "wall", "walldeco"]:
				continue
			var m := base
			for rg: Variant in JsonUtil.get_array(room, "regions"):
				var rc := JsonUtil.get_array(rg as Dictionary, "rect")
				if rc.size() == 4 and x >= int(rc[0]) and y >= int(rc[1]) and x < int(rc[0]) + int(rc[2]) and y < int(rc[1]) + int(rc[3]):
					m = JsonUtil.get_str(rg as Dictionary, "floor", m)
			if k == "floor" and d.has("material"):
				m = JsonUtil.get_str(d, "material")
			if not out.has(m):
				out[m] = []
			(out[m] as Array).append(Vector2i(x, y))
	return out


## 벽 밑 그늘(벽 앞면 바로 아래 칸 윗쪽) · 가구 발밑 그림자.
static func _shadows(p: Paint, rows: PackedStringArray, legend: Dictionary, kind: Callable, t: int) -> void:
	for y in rows.size():
		for x in rows[y].length():
			var k: String = kind.call(x, y)
			if k in WALLISH or k in ["void", "open"]:
				continue
			if str(kind.call(x, y - 1)) in WALLISH:
				Ink.shade(p, Paint.rect_poly(x * t, y * t, t, t * 0.6), Vector2(0, y * t), Vector2(0, y * t + t * 0.6), 0.55, 0.0)
			if str(kind.call(x - 1, y)) in WALLISH:
				Ink.shade(p, Paint.rect_poly(x * t, y * t, t * 0.4, t), Vector2(x * t, 0), Vector2(x * t + t * 0.4, 0), 0.4, 0.0)
	for g: Dictionary in CityRoom.groups(rows, legend, ["furniture"]):
		var rc: Rect2i = g["rect"]
		var c := (Vector2(rc.position) + Vector2(rc.size) * Vector2(0.5, 0.7)) * t
		var r := Vector2(rc.size) * t * 0.6
		var x0 := int(c.x - r.x)
		var y0 := int(c.y - r.y)
		for yy in range(y0, int(c.y + r.y)):
			for xx in range(x0, int(c.x + r.x)):
				var dd := Vector2((xx - c.x) / r.x, (yy - c.y) / r.y).length()
				if dd < 1.0:
					p.tint(xx, yy, Color("#080605"), (1.0 - dd) * 0.5)


## 벽 층: 칸마다 윗면·앞면, 그 위에 벽 장식 무리(RoomWalls).
static func _walls(p: Paint, room: Dictionary, rows: PackedStringArray, legend: Dictionary, kind: Callable, t: int) -> void:
	var face_sh := RoomWalls.material(p, JsonUtil.get_str(room, "wall", "ashlar"), t)
	for y in rows.size():
		for x in rows[y].length():
			var k: String = kind.call(x, y)
			if not k in WALLISH:
				continue
			if k == "walldeco" or is_face(kind, x, y):
				p.fill_rect(x * t, y * t, t, t, face_sh)
				if not str(kind.call(x, y + 1)) in WALLISH:  # 굽도리 + 바닥선
					p.fill_rect(x * t, y * t + t - t * 0.12, t, t * 0.12, p.flat(Color("#2a1f17"), 0.08))
					Ink.line(p, Vector2(x * t, y * t + t), Vector2(x * t + t, y * t + t), 2.0, Ink.INK, 0.8, 0.4)
				if not str(kind.call(x, y - 1)) in WALLISH or not is_face(kind, x, y - 1):
					Ink.line(p, Vector2(x * t, y * t), Vector2(x * t + t, y * t), 2.0, Ink.INK, 0.85, 0.4)
				Ink.shade(p, Paint.rect_poly(x * t, y * t, t, t), Vector2(0, y * t), Vector2(0, y * t + t), 0.25, 0.05)
			else:
				p.fill_rect(x * t, y * t, t, t, RoomWalls.top_shader(p))
				for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
					if not str(kind.call(x + d.x, y + d.y)) in WALLISH:
						var a := Vector2(x * t + (t if d.x > 0 else 0), y * t + (t if d.y > 0 else 0))
						var b := a + (Vector2(0, t) if d.x != 0 else Vector2(t, 0))
						Ink.line(p, a, b, 2.0, Color("#6a645a"), 0.6, 0.3)
	RoomWalls.decorate(p, rows, legend, t)


## 앞면인가: 아래 칸이 벽이 아니거나, 아래가 벽(앞면)이고 그 아래가 벽이 아니며 위도 벽이면(두 칸 높이 뒷벽).
static func is_face(kind: Callable, x: int, y: int) -> bool:
	var below: String = kind.call(x, y + 1)
	if not below in WALLISH:
		return true
	var below2: String = kind.call(x, y + 2)
	return below == "walldeco" or (not below2 in WALLISH and str(kind.call(x, y - 1)) in WALLISH)


## 빛 [자리, 반지름, 색, 세기]: 빛 나는 가구 무리 가운데 · 빛 나는 벽 장식 무리(창 = 서늘한 빛, 불 = 따뜻한 빛).
static func _lights(rows: PackedStringArray, legend: Dictionary, t: int) -> Array:
	var out: Array = []
	for g: Dictionary in CityRoom.groups(rows, legend, ["furniture", "walldeco"]):
		var d := JsonUtil.get_dict(legend, str(g["char"]))
		if not JsonUtil.get_bool(d, "light"):
			continue
		var rc: Rect2i = g["rect"]
		var cool := JsonUtil.get_str(d, "style") == "window"
		var c := (Vector2(rc.position) + Vector2(rc.size) * Vector2(0.5, 0.5)) * t
		if JsonUtil.get_str(d, "kind") == "walldeco":
			c.y = rc.end.y * t + t * 0.6
		var radius := (3.2 + maxf(rc.size.x, rc.size.y) * 0.4) * t
		out.append([c, radius, RoomArt.COOL if cool else RoomArt.WARM, 0.55 if cool else 0.8])
	return out


## 빛 배율 칸(그림 px마다): 바탕 ambient + 빛마다 그 둘레 사각형만 더한다(지도 전체 × 빛 수를 돌지 않는다).
static func _light_field(w: int, h: int, lights: Array, ambient: float) -> PackedFloat32Array:
	var f := PackedFloat32Array()
	f.resize(w * h)
	f.fill(ambient)
	for L: Array in lights:
		var c: Vector2 = L[0]
		var r := float(L[1])
		var s := float(L[3])
		for y in range(maxi(0, int(c.y - r)), mini(h, int(c.y + r))):
			var row := y * w
			for x in range(maxi(0, int(c.x - r)), mini(w, int(c.x + r))):
				var d := Vector2(x, y).distance_to(c) / r
				if d < 1.0:
					f[row + x] = minf(1.3, f[row + x] + (1.0 - d) * (1.0 - d) * s)
	return f
