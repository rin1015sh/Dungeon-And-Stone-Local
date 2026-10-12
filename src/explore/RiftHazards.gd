class_name RiftHazards
extends RefCounted
## 균열 챕터의 탐험 위험(빙하굴 3챕터 미끄러운 얼음·급경사·로프 구간 — 명세 §10.1 "탐험 이벤트로 처리").
## 챕터 "hazards": [{"id", "tile", "count", "check": {"stat": "agi", "dc": 14}, "fail": [효과], "pass_message", "fail_message"}]
## 통로 칸(방 안쪽이 아닌 칸)에 3×3 묶음으로 tile을 깔고, 처음 밟으면 한 번 판정한다:
##   성공 확률 = clamp(rift.hazard_base + (스탯 − dc) × rift.hazard_per_point, hazard_min, hazard_max). 실패면 fail 효과.
## 판정이 끝난 묶음은 원래 바닥으로 돌아간다. RiftRun이 챕터를 만들 때 place, ExploreSession이 칸에 들어설 때 on_step.

var at: Dictionary = {}  ## 칸 -> 묶음 정의(같은 묶음은 같은 Dictionary)
var _floor_tile: String = ""


func place(cs: ExploreSession, ch: Dictionary, floor_tile: String, rng: Rng) -> void:
	at.clear()
	_floor_tile = floor_tile
	var used: Array[Vector2i] = []
	for h: Variant in JsonUtil.get_array(ch, "hazards"):
		var hd: Dictionary = h if h is Dictionary else {}
		for n in JsonUtil.get_int(hd, "count", 1):
			var cells := _corridor_cells(cs, used)
			if cells.is_empty():
				return
			var c: Vector2i = rng.pick(cells)
			var group := hd.duplicate()
			group["cells"] = []
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var p := c + Vector2i(dx, dy)
					if cs.map.in_bounds(p) and cs.map.is_walkable(p) and cs.map.portal_at(p).is_empty() and not at.has(p):
						cs.map.set_tile(p, JsonUtil.get_str(hd, "tile"))
						at[p] = group
						(group["cells"] as Array).append(p)
			used.append(c)


## 칸에 들어섰다. 위험이 있었으면 판정 결과(true = 무사히 지남), 없으면 null.
func on_step(cs: ExploreSession, p: Vector2i) -> Variant:
	if not at.has(p):
		return null
	var hd: Dictionary = at[p]
	for q: Variant in hd["cells"]:
		at.erase(q)
		cs.map.set_tile(q, _floor_tile)
	var ok := cs.rng.chance(success_chance(cs.db, cs.player, JsonUtil.get_dict(hd, "check")))
	if ok:
		cs.message.emit(JsonUtil.get_str(hd, "pass_message", "explore.hazard_pass"), {}, "good")
	else:
		var ctx := EffectContext.new(cs.db, null, cs.player, cs.rng)
		ctx.registry = cs.effects
		cs.effects.apply_all(ctx, JsonUtil.get_array(hd, "fail"))
		cs.message.emit(JsonUtil.get_str(hd, "fail_message", "explore.hazard_fail"), {}, "danger")
		for m: Dictionary in ctx.messages:
			cs.message.emit(str(m["key"]), m["args"], str(m["kind"]))
	cs.refresh_view()
	return ok


static func success_chance(db: GameDatabase, a: Actor, check: Dictionary) -> float:
	var v := a.stats.get_value(JsonUtil.get_str(check, "stat", "agi")) - JsonUtil.get_float(check, "dc", 10.0)
	return clampf(float(db.bal("rift.hazard_base", 0.5)) + v * float(db.bal("rift.hazard_per_point", 0.04)),
		float(db.bal("rift.hazard_min", 0.1)), float(db.bal("rift.hazard_max", 0.95)))


## 통로 칸: 걸을 수 있고 사방 8칸 중 벽이 있으며, 시작·조우 자리·이미 고른 자리에서 떨어진 칸.
func _corridor_cells(cs: ExploreSession, used: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var min_gap := float(cs.db.bal("rift.hazard_min_gap", 5))
	for i in cs.map.tiles.size():
		var p := cs.map.pos_of(i)
		if not cs.map.is_walkable(p) or _interior(cs.map, p) or Vector2(p - cs.map.entry).length() < min_gap:
			continue
		var far := true
		for q in used + cs.map.slots:
			if Vector2(p - q).length() < min_gap:
				far = false
		if far and cs.map.portal_at(p).is_empty():
			out.append(p)
	return out


static func _interior(map: FloorMap, p: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if not map.in_bounds(p + Vector2i(dx, dy)) or not map.is_walkable(p + Vector2i(dx, dy)):
				return false
	return true
