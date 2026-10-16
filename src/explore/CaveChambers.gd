class_name CaveChambers
extends RefCounted
## 거대한 동굴의 방·공동 놓기와 모양(1층 십자가 — CrossTerrain이 부른다). 잇기는 CaveLinks, 안쪽 꾸밈은 CaveDecor.
## 놓는 순서: 고정 자리(기념비 대공동·포탈 공동) → 구역(중심부·팔)마다 kinds 순서(큰 것부터: 큰 공동 grand → 공동 cavern → 방 room)로,
##            서로 gap칸 이상 떨어지고 구역 가장자리에서 edge_margin칸 안쪽에. 첫 종류 다음에 등뼈 길 위 쉼터 공동(spine_every칸마다).
## 모양: 기울어진 타원(lobe) 1~4개를 겹치고, 각 타원 윤곽에 낮은 주파수 물결(wobble)을 얹는다 → 울퉁불퉁한 자연 동굴.
## 공동 = {"c": Vector2, "kind", "reach": 바깥 반지름, "lobes": [{"c", "rx", "ry", "angle", "harm": [[k, 진폭, 위상] …]}], "zone"}
## 값은 floors/*.json gen.chambers(설명은 그 _comment).

const PLACE_TRIES := 80


## 공동을 놓고 판다. spine_cells = 등뼈 길로 판 칸(판 순서대로 — 쉼터 공동 자리를 고른다).
static func build(carver: CaveCarver, lay: CrossLayout, cfg: Dictionary, spine_cells: Array[int], rng: Rng) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var kinds := _kinds(cfg)
	var hall := JsonUtil.get_dict(cfg, "center_hall")
	out.append(_make(Vector2(lay.center), "hall", hall, CrossLayout.ZONE_CENTER, rng))
	var portal_hall := JsonUtil.get_dict(cfg, "portal_hall")
	for dir in CrossLayout.ARMS:
		out.append(_make(Vector2(lay.portal_pos(dir)), "portal", portal_hall, dir, rng))
	var margin := JsonUtil.get_int(cfg, "edge_margin", 4)
	var gap := JsonUtil.get_float(cfg, "gap", 5.0)
	for ki in kinds.size():
		if ki == 1:
			_place_on_spine(out, carver, lay, cfg, kinds, spine_cells, rng)  # 가장 큰 공동 다음(큰 공동 자리를 뺏지 않게)
		var kind := kinds[ki]
		var counts := JsonUtil.get_dict(kind, "count")
		for zone: String in [CrossLayout.ZONE_CENTER] + Array(CrossLayout.ARMS):
			var rect := lay.core_rect() if zone == CrossLayout.ZONE_CENTER else lay.arm_rect(zone)
			var n := JsonUtil.get_int(counts, "center" if zone == CrossLayout.ZONE_CENTER else "arm")
			for k in n:
				_place_random(out, carver, rect, zone, kind, margin, JsonUtil.get_float(kind, "gap", gap), rng)
	for ch in out:
		carve(carver, ch)
	return out


## 공동 하나를 판다(팔 수 있는 칸만).
static func carve(carver: CaveCarver, ch: Dictionary) -> void:
	var c: Vector2 = ch["c"]
	var r := ceili(float(ch["reach"])) + 1
	for y in range(int(c.y) - r, int(c.y) + r + 1):
		for x in range(int(c.x) - r, int(c.x) + r + 1):
			if inside(ch, Vector2(x, y), 1.0):
				carver.carve(Vector2i(x, y))


## 칸 p가 공동 ch 안인가. scale < 1이면 그만큼 안쪽(가장자리에서 떨어진 곳)만.
static func inside(ch: Dictionary, p: Vector2, scale: float) -> bool:
	for lobe: Dictionary in ch["lobes"]:
		if _lobe_depth(lobe, p) <= scale:
			return true
	return false


## 칸 p가 첫 타원(본체) 중심에서 윤곽까지 몇 할 들어와 있는가(0 = 중심, 1 = 윤곽). 꾸밈을 놓을 깊이에 쓴다.
static func depth(ch: Dictionary, p: Vector2) -> float:
	var best := INF
	for lobe: Dictionary in ch["lobes"]:
		best = minf(best, _lobe_depth(lobe, p))
	return best


## 공동 넓이(대략, 칸) — 꾸밈 개수에 쓴다.
static func area(ch: Dictionary) -> float:
	var a := 0.0
	for lobe: Dictionary in ch["lobes"]:
		a = maxf(a, PI * float(lobe["rx"]) * float(lobe["ry"]))
	return a * (1.0 + 0.4 * (ch["lobes"] as Array).size() - 0.4)


static func _lobe_depth(lobe: Dictionary, p: Vector2) -> float:
	var d := (p - (lobe["c"] as Vector2)).rotated(-float(lobe["angle"]))
	var u := Vector2(d.x / float(lobe["rx"]), d.y / float(lobe["ry"]))
	var t := atan2(u.y, u.x)
	var edge := 1.0
	for h: Array in lobe["harm"]:
		edge += float(h[1]) * sin(float(h[0]) * t + float(h[2]))
	return u.length() / maxf(0.2, edge)


static func _kinds(cfg: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k: Variant in JsonUtil.get_array(cfg, "kinds"):
		if k is Dictionary:
			out.append(k)
	return out


static func _kind(kinds: Array[Dictionary], id: String) -> Dictionary:
	for k in kinds:
		if JsonUtil.get_str(k, "id") == id:
			return k
	return {}


## kind = {"radius": [최소, 최대], "aspect": [최소, 최대], "lobes": [최소, 최대], "wobble"}로 공동 하나를 만든다(파지는 않음).
static func _make(c: Vector2, kind_id: String, kind: Dictionary, zone: String, rng: Rng) -> Dictionary:
	var rr := JsonUtil.get_array(kind, "radius")
	var ar := JsonUtil.get_array(kind, "aspect")
	var lr := JsonUtil.get_array(kind, "lobes")
	var wobble := JsonUtil.get_float(kind, "wobble", 0.2)
	var r := rng.randf_range(float(rr[0]), float(rr[1])) if rr.size() == 2 else 6.0
	var lobes: Array[Dictionary] = [_lobe(c, r, ar, wobble, rng)]
	var extra := rng.randi_range(int(lr[0]), int(lr[1])) if lr.size() == 2 else 0
	var reach := r * (1.0 + wobble)
	for i in extra:
		var at := c + Vector2.from_angle(rng.randf_range(0.0, TAU)) * r * rng.randf_range(0.45, 0.85)
		var lobe := _lobe(at, r * rng.randf_range(0.4, 0.7), ar, wobble, rng)
		lobes.append(lobe)
		reach = maxf(reach, (at - c).length() + float(lobe["rx"]) * (1.0 + wobble))
	return {"c": c, "kind": kind_id, "zone": zone, "reach": reach, "radius": r, "lobes": lobes}


static func _lobe(c: Vector2, r: float, aspect: Array, wobble: float, rng: Rng) -> Dictionary:
	var asp := rng.randf_range(float(aspect[0]), float(aspect[1])) if aspect.size() == 2 else 1.0
	var harm: Array = []
	var left := wobble
	for k: int in [2, 3, 5, 7]:
		var amp := rng.randf_range(0.0, left * 0.6)
		left -= amp
		harm.append([k, amp, rng.randf_range(0.0, TAU)])
	return {"c": c, "rx": r, "ry": maxf(1.5, r * asp), "angle": rng.randf_range(0.0, PI), "harm": harm}


## 등뼈 길을 따라 spine_every칸(직선 거리)마다 쉼터 공동(길 위에 놓이므로 나침반 경로가 공동을 지난다).
static func _place_on_spine(out: Array[Dictionary], carver: CaveCarver, lay: CrossLayout, cfg: Dictionary,
		kinds: Array[Dictionary], spine_cells: Array[int], rng: Rng) -> void:
	var every := JsonUtil.get_array(cfg, "spine_every")
	var picks := JsonUtil.get_array(cfg, "spine_kinds")
	if every.size() != 2 or picks.is_empty() or spine_cells.is_empty():
		return
	var gap := JsonUtil.get_float(cfg, "gap", 5.0)
	var margin := JsonUtil.get_int(cfg, "edge_margin", 4)
	var last := Vector2i(spine_cells[0] % carver.w, spine_cells[0] / carver.w)
	var next := rng.randi_range(int(every[0]), int(every[1]))
	for i in spine_cells:
		var p := Vector2i(i % carver.w, i / carver.w)
		if Vector2(p - last).length() < next:
			continue
		last = p
		next = rng.randi_range(int(every[0]), int(every[1]))
		var zone := lay.zone_of(p)
		if zone.is_empty() or lay.is_dark(p):
			continue
		var kind_id := str(rng.pick(picks))
		var ch := _make(Vector2(p), kind_id, _kind(kinds, kind_id), zone, rng)
		var rect := lay.core_rect() if zone == CrossLayout.ZONE_CENTER else lay.arm_rect(zone)
		if _fits(ch, out, rect, margin, gap):
			out.append(ch)


static func _place_random(out: Array[Dictionary], carver: CaveCarver, rect: Rect2i, zone: String, kind: Dictionary,
		margin: int, gap: float, rng: Rng) -> void:
	for attempt in PLACE_TRIES:
		var c := Vector2(rng.randi_range(rect.position.x, rect.end.x - 1), rng.randi_range(rect.position.y, rect.end.y - 1))
		if not carver.can(Vector2i(c)):
			continue
		var ch := _make(c, JsonUtil.get_str(kind, "id"), kind, zone, rng)
		if _fits(ch, out, rect, margin, gap):
			out.append(ch)
			return


## 구역 사각형 안(가장자리 margin칸 안쪽)이고 다른 공동과 gap칸 이상 떨어졌는가.
static func _fits(ch: Dictionary, others: Array[Dictionary], rect: Rect2i, margin: int, gap: float) -> bool:
	var c: Vector2 = ch["c"]
	var r := float(ch["reach"]) + margin
	if c.x - r < rect.position.x or c.y - r < rect.position.y or c.x + r > rect.end.x or c.y + r > rect.end.y:
		return false
	for o in others:
		if c.distance_to(o["c"]) < float(ch["reach"]) + float(o["reach"]) + gap:
			return false
	return true
