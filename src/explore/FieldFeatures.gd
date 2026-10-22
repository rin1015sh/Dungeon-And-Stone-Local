class_name FieldFeatures
extends RefCounted
## 동굴 요소(data/events — 자리는 FloorMap.features, 1층은 고정 지도에 구워 둔다)의 입장 한 번 동안의 상태와 규칙.
##   살피기(E): 서 있는 칸·옆 칸(4방향)의 요소. 할 수 있는 행동이 하나면 바로 하고, 여럿이면 choice(화면이 고르게 한 뒤 act).
##   near {radius, line}: 반경 안에 처음 들어서면 문구 한 번.   hidden {stat, dc}: 옆(8방향)에 처음 오면 탐지 판정 한 번 —
##   성공해야 tile이 드러나고 살필 수 있다.   hazard: RiftHazards 묶음(함정·미끄러운 비탈)으로 깔고 밟으면 판정.
##   guard {monster}: 입장 때 그 자리에 지키는 무리(마릿수는 FieldMonsters.pack_count — 날짜별).   rest {radius, fatigue_per_hour}: 근처 휴식 보너스.
## 행동 하나의 실행은 FieldFeatureAct. 입장마다 새로(층이 입장마다 리셋되므로 다시 채워진다).

var list: Array[Dictionary] = []   ## {"id", "pos", "def", "found", "used": {행동 id: 날짜 | true}, "cleared", "noticed"}
var hazards: RiftHazards = RiftHazards.new()
var _by_cell: Dictionary = {}       ## 칸 -> list 원소
var _near: Array[Dictionary] = []   ## near가 있는 요소


## 세션이 만들어질 때(지도·플레이어가 정해진 뒤) 한 번.
func setup(s: ExploreSession) -> void:
	var floor_tile := JsonUtil.get_str(JsonUtil.get_dict(JsonUtil.get_dict(s.floor_def, "gen"), "tiles"), "floor", "cave_floor")
	for f: Dictionary in s.map.features:
		var def := s.db.get_entry("events", str(f["id"]))
		if def.is_empty():
			continue
		if def.has("hazard"):
			var hd := JsonUtil.get_dict(def, "hazard").duplicate(true)
			hazards.add_group(s, hd, f["pos"], floor_tile)
			continue
		var e := {"id": str(f["id"]), "pos": f["pos"], "def": def, "found": not def.has("hidden"), "used": {}, "cleared": false,
			"noticed": false}
		list.append(e)
		_by_cell[f["pos"]] = e
		if def.has("near"):
			_near.append(e)


## 원정 중에 새로 생긴 요소(갓 죽은 탐험가·쓰러진 약탈자 — FieldParties). at이 맨바닥이 아니거나 이미 요소가 있으면
## 둘레에서 맨바닥 칸을 찾는다. 놓았으면 그 요소, 자리가 없으면 {}.
func add_runtime(s: ExploreSession, id: String, at: Vector2i) -> Dictionary:
	var def := s.db.get_entry("events", id)
	var floor_tile := JsonUtil.get_str(JsonUtil.get_dict(JsonUtil.get_dict(s.floor_def, "gen"), "tiles"), "floor", "cave_floor")
	var cell := Vector2i(-1, -1)
	for r in 4:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := at + Vector2i(dx, dy)
				if cell.x < 0 and s.map.tile_id_at(q) == floor_tile and not _by_cell.has(q) and s.map.portal_at(q).is_empty():
					cell = q
	if def.is_empty() or cell.x < 0:
		return {}
	var e := {"id": id, "pos": cell, "def": def, "found": true, "used": {}, "cleared": false, "noticed": false}
	list.append(e)
	_by_cell[cell] = e
	s.map.features.append({"id": id, "pos": cell})
	var tile := JsonUtil.get_str(def, "tile")
	if not tile.is_empty():
		s.map.set_tile(cell, tile)
		s.tiles_changed.emit(Rect2i(cell, Vector2i.ONE))
	return e


## 입장 직후(몬스터가 나타난 뒤): 지키는 무리를 세운다.
func spawn_guards(s: ExploreSession) -> void:
	for e in list:
		var guard := JsonUtil.get_dict(e["def"], "guard")
		var mid := JsonUtil.get_str(guard, "monster")
		if mid.is_empty() or not s.db.has_entry("monsters", mid):
			continue
		var ids: Array = []
		for i in s.monsters.pack_count(mid, true):  # 날짜별 마릿수(spawn.pack_by_day)
			ids.append(mid)
		s.monsters.add_fixed(ids, e["pos"])


## 살필 요소(서 있는 칸 → 옆 칸 4방향). 없으면 {}.
func target(s: ExploreSession) -> Dictionary:
	for p: Vector2i in [s.pos] + FloorMap.DIRS4.map(func(d: Vector2i) -> Vector2i: return s.pos + d):
		var e: Dictionary = _by_cell.get(p, {})
		if not e.is_empty() and bool(e["found"]) and not bool(e["cleared"]) and not JsonUtil.get_array(e["def"], "actions").is_empty():
			return e
	return {}


func target_name(s: ExploreSession) -> String:
	var e := target(s)
	return JsonUtil.get_str(e["def"], "name_ko") if not e.is_empty() else ""


## E: 요소가 있으면 다루고 true. 행동이 여럿이면 세션이 choice_needed를 낸다.
func interact(s: ExploreSession) -> bool:
	var e := target(s)
	if e.is_empty():
		return false
	var actions := JsonUtil.get_array(e["def"], "actions")
	if actions.size() == 1:
		FieldFeatureAct.run(s, e, actions[0])
	else:
		s.feature_choice.emit(e["pos"])
	return true


## 고른 행동(선택창). 그 자리에 요소가 없거나 행동이 없으면 아무것도 하지 않는다.
func act(s: ExploreSession, at: Vector2i, action_id: String) -> void:
	var e: Dictionary = _by_cell.get(at, {})
	if e.is_empty() or bool(e["cleared"]):
		return
	for a: Variant in JsonUtil.get_array(e["def"], "actions"):
		if a is Dictionary and JsonUtil.get_str(a, "id") == action_id:
			FieldFeatureAct.run(s, e, a)
			return


## 선택창에 보일 행동 [{id, name_ko}].
func actions_at(at: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var e: Dictionary = _by_cell.get(at, {})
	if e.is_empty():
		return out
	for a: Variant in JsonUtil.get_array(e["def"], "actions"):
		if a is Dictionary:
			out.append({"id": JsonUtil.get_str(a, "id"), "name_ko": JsonUtil.get_str(a, "name_ko")})
	return out


func name_at(at: Vector2i) -> String:
	var e: Dictionary = _by_cell.get(at, {})
	return JsonUtil.get_str(e["def"], "name_ko") if not e.is_empty() else ""


## 칸에 들어섰다: 숨은 요소 탐지, 근처 문구, 함정.
func on_step(s: ExploreSession, p: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var e: Dictionary = _by_cell.get(p + Vector2i(dx, dy), {})
			if not e.is_empty() and not bool(e["found"]) and not e.has("rolled"):
				_detect(s, e)
	for e in _near:
		var near := JsonUtil.get_dict(e["def"], "near")
		if not bool(e["noticed"]) and Vector2(p - (e["pos"] as Vector2i)).length() <= JsonUtil.get_float(near, "radius", 3.0):
			e["noticed"] = true
			FieldFeatureAct.say_line(s, JsonUtil.get_str(near, "line"), e, JsonUtil.get_str(near, "kind", "info"))
	hazards.on_step(s, p)


## 근처 요소의 휴식 보너스(시간당 피로도 변화 합).
func rest_bonus(p: Vector2i) -> float:
	var v := 0.0
	for e in list:
		var r := JsonUtil.get_dict(e["def"], "rest")
		if not r.is_empty() and Vector2(p - (e["pos"] as Vector2i)).length() <= JsonUtil.get_float(r, "radius", 2.0):
			v += JsonUtil.get_float(r, "fatigue_per_hour")
	return v


func _detect(s: ExploreSession, e: Dictionary) -> void:
	e["rolled"] = true
	var check := JsonUtil.get_dict(e["def"], "hidden")
	if not s.rng.chance(RiftHazards.success_chance(s.db, s.player, check)):
		return
	e["found"] = true
	var tile := JsonUtil.get_str(e["def"], "tile")
	if not tile.is_empty():
		s.map.set_tile(e["pos"], tile)
	FieldFeatureAct.say_line(s, JsonUtil.get_str(check, "line", "field.found_hidden"), e, "good")
	s.refresh_view()
