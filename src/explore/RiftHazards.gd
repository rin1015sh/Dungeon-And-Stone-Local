class_name RiftHazards
extends RefCounted
## 균열 챕터의 탐험 위험(빙하굴 3챕터 미끄러운 얼음·급경사·로프 구간 — 명세 §10.1 "탐험 이벤트로 처리").
## 챕터 "hazards": [{"id", "tile", "count", "check": {"stat": "agi", "dc": 14}, "fail": [효과], "pass_message", "fail_message"}]
## 통로 칸(방 안쪽이 아닌 칸)에 3×3 묶음으로 tile을 깔고, 처음 밟으면 한 번 판정한다:
##   성공 확률 = clamp(rift.hazard_base + (스탯 − dc) × rift.hazard_per_point, hazard_min, hazard_max). 실패면 fail 효과.
## 판정이 끝난 묶음은 더 판정하지 않지만 그림(tile)은 그 자리에 남는다 — 해제·부숨·발동 모두(사용자 요청 2026-10-23).
##   못 알아챈 숨은 함정도 발동하면 드러나 남는다. 타일이 바뀌면 tiles_changed로 화면이 그 칸을 다시 그린다.
## RiftRun이 챕터를 만들 때 place, ExploreSession이 칸에 들어설 때 on_step.
## 함정(강철의 묘 — 명세 §12.1 "탐지와 해제는 손재주·육감" → 이 게임은 주 스탯으로: 탐지 = 정신력, 해제 = 민첩, ASSUMPTIONS ST3):
##   "hidden": true — 바닥처럼 보이다가 옆 칸에 오면 detect {stat, dc}로 한 번 탐지(성공하면 tile이 드러난다)
##   "disarm": {stat, dc} — 드러난 함정을 밟으면 해제 판정(성공 = 무사, 실패 = 발동). 드러나지 않았으면 check(피하기)
##   "bypass": {stat, at_least} — 그만큼 단단하면 밟아 부순다(고렙). 살아 있는 조우에 패시브 trap_watcher(수호자의 눈)가
##   있으면 발동 확률 × (1 + 그 값).

var at: Dictionary = {}  ## 칸 -> 아직 판정하지 않은 묶음 정의(같은 묶음은 같은 Dictionary)


func place(cs: ExploreSession, ch: Dictionary, rng: Rng) -> void:
	at.clear()
	var used: Array[Vector2i] = []
	var spots: Array = cs.map.anchors.get("hazards", [])  # 설계도 지도: 정해진 자리(묶음 순서 = hazards × count)
	for h: Variant in JsonUtil.get_array(ch, "hazards"):
		var hd: Dictionary = h if h is Dictionary else {}
		for n in JsonUtil.get_int(hd, "count", 1):
			if used.size() < spots.size():
				var sp: Vector2i = spots[used.size()]
				add_group(cs, hd, sp)
				used.append(sp)
				continue
			var cells := _corridor_cells(cs, used)
			if cells.is_empty():
				return
			var c: Vector2i = rng.pick(cells)
			add_group(cs, hd, c)
			used.append(c)


## 칸 c 둘레 3×3(걸을 수 있는 칸)에 위험 묶음 하나를 깐다(1층 동굴 요소의 함정도 이것을 쓴다 — FieldFeatures).
func add_group(cs: ExploreSession, hd: Dictionary, c: Vector2i) -> void:
	var group := hd.duplicate()
	group["cells"] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var p := c + Vector2i(dx, dy)
			if cs.map.in_bounds(p) and cs.map.is_walkable(p) and cs.map.portal_at(p).is_empty() and not at.has(p):
				if not JsonUtil.get_bool(hd, "hidden"):  # 숨은 함정은 원래 바닥처럼 보인다
					cs.map.set_tile(p, JsonUtil.get_str(hd, "tile"))
				at[p] = group
				(group["cells"] as Array).append(p)


## 칸에 들어섰다. 위험이 있었으면 판정 결과(true = 무사히 지남), 없으면 null.
func on_step(cs: ExploreSession, p: Vector2i) -> Variant:
	_detect_near(cs, p)
	if not at.has(p):
		return null
	var hd: Dictionary = at[p]
	for q: Variant in hd["cells"]:
		at.erase(q)
	_show(cs, hd)  # 판정이 끝나도 함정·위험은 보이는 채로 남는다
	var ok := true
	var key := JsonUtil.get_str(hd, "pass_message", "explore.hazard_pass")
	var strong := JsonUtil.get_dict(hd, "bypass")
	if not strong.is_empty() and cs.player.stats.get_value(JsonUtil.get_str(strong, "stat")) >= JsonUtil.get_float(strong, "at_least"):
		key = JsonUtil.get_str(strong, "message", "explore.trap_crushed")
	else:
		var disarming := bool(hd.get("detected", false)) and hd.has("disarm")
		var chance := success_chance(cs.db, cs.player, JsonUtil.get_dict(hd, "disarm" if disarming else "check"))
		chance = 1.0 - minf(1.0, (1.0 - chance) * (1.0 + watcher_bonus(cs)))
		ok = cs.rng.chance(chance)
		if ok and disarming:
			key = JsonUtil.get_str(hd, "disarm_message", "explore.trap_disarmed")
	if ok:
		cs.message.emit(key, {}, "good")
	else:
		var ctx := EffectContext.new(cs.db, null, cs.player, cs.rng)
		ctx.registry = cs.effects
		cs.effects.apply_all(ctx, JsonUtil.get_array(hd, "fail"))
		cs.message.emit(JsonUtil.get_str(hd, "fail_message", "explore.hazard_fail"), {}, "danger")
		for m: Dictionary in ctx.messages:
			cs.message.emit(str(m["key"]), m["args"], str(m["kind"]))
	cs.refresh_view()
	return ok


## 이 챕터에 남은 조우 중 trap_watcher 패시브의 합(수호자의 눈이 살아 있으면 함정이 더 잘 발동한다).
func watcher_bonus(cs: ExploreSession) -> float:
	var v := 0.0
	if cs.rift_run == null:
		return v
	for g: FieldMonsters.Group in cs.rift_run.remaining:
		for id: Variant in g.monster_ids:
			for p: Variant in JsonUtil.get_array(cs.db.get_entry("monsters", str(id)), "passives"):
				v += JsonUtil.get_float(p if p is Dictionary else {}, "trap_watcher")
	return v


## 숨은 함정 옆(8방향 1칸)에 처음 오면 탐지 판정 한 번. 성공하면 함정이 드러난다.
func _detect_near(cs: ExploreSession, p: Vector2i) -> void:
	var seen: Array = []
	for q: Vector2i in at:
		var hd: Dictionary = at[q]
		if seen.has(hd) or not JsonUtil.get_bool(hd, "hidden") or hd.has("rolled") or maxi(absi(q.x - p.x), absi(q.y - p.y)) > 1:
			continue
		seen.append(hd)
		hd["rolled"] = true
		if cs.rng.chance(success_chance(cs.db, cs.player, JsonUtil.get_dict(hd, "detect"))):
			hd["detected"] = true
			_show(cs, hd)
			cs.message.emit(JsonUtil.get_str(hd, "detect_message", "explore.trap_detected"), {}, "warn")
			cs.refresh_view()


## 묶음의 칸을 함정 타일로 칠하고(이미 그렇다면 그대로) 화면에 다시 그리라고 알린다.
func _show(cs: ExploreSession, hd: Dictionary) -> void:
	var tile := JsonUtil.get_str(hd, "tile")
	var box := Rect2i()
	for c: Vector2i in hd["cells"]:
		if cs.map.tile_id_at(c) == tile:
			continue
		cs.map.set_tile(c, tile)
		box = Rect2i(c, Vector2i.ONE) if box.size == Vector2i.ZERO else box.merge(Rect2i(c, Vector2i.ONE))
	if box.size != Vector2i.ZERO:
		cs.tiles_changed.emit(box)


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
