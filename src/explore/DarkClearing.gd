class_name DarkClearing
extends RefCounted
## 암흑지대를 트인 굴로(사용자 결정 2026-11-01, CR26 — "암흑지대 미로 없애기, 벽을 걷어내라"):
## 팔 끝 암흑지대 사각형 안의 바위벽을 바닥으로 바꾼다. 바깥 세 변(팔 양옆·팔 끝)은 border + 물결(0..wobble)칸 벽을 남기고,
## 밝은 쪽 경계(안쪽 변)도 물결 폭만큼 남겨 곧은 절벽이 되지 않게 한다. 호수·바위·포탈·동굴 요소는 그대로.
## 벽을 바닥으로만 바꾸므로 원래 이어진 길은 그대로 이어진다. 무작위를 쓰지 않는다(좌표로 정한 물결) —
## 생성 끝 무렵에 불러도 그 뒤 단계의 무작위가 바뀌지 않는다. 층 JSON gen.dark_open {border, wobble}(없으면 하지 않음).


## 걷어냈으면 true(생성기가 이어서 통로 폭을 다시 맞춘다).
static func apply(map: FloorMap, lay: CrossLayout, g: Dictionary, tiles: Dictionary) -> bool:
	var spec := JsonUtil.get_dict(g, "dark_open")
	if spec.is_empty():
		return false
	var border := JsonUtil.get_int(spec, "border", 3)
	var wobble := JsonUtil.get_float(spec, "wobble", 2.0)
	var wall_index := map.index_of(JsonUtil.get_str(tiles, "wall"))
	var floor_index := map.index_of(JsonUtil.get_str(tiles, "floor"))
	for dir in CrossLayout.ARMS:
		var a := CrossLayout.axis(dir)
		var l := CrossLayout.lateral(dir)
		var r := lay.dark_rect(dir)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var i := y * map.width + x
				if map.tiles[i] != wall_index:
					continue
				var d := Vector2i(x, y) - map.center
				var u := d.x * a.x + d.y * a.y - lay.core_half          # 팔 깊이(dark_start+1 .. arm_length)
				var v := d.x * l.x + d.y * l.y                          # 옆 거리(-arm_half .. arm_half)
				var inner := u - lay.dark_start()                       # 밝은 쪽 경계에서 몇 칸
				var outer := lay.arm_length - u                         # 팔 끝 벽까지
				var side := lay.arm_half - absi(v)                      # 팔 옆 벽까지
				if inner <= _wave(v, 0.0, wobble):
					continue
				if outer < border + _wave(v, 1.7, wobble) or side < border + _wave(u, 3.1, wobble):
					continue
				map.tiles[i] = floor_index
	return true


## 좌표 t에 따른 0..amp 물결(두 사인의 합 — 무작위 없이 같은 지도에서 늘 같다).
static func _wave(t: int, phase: float, amp: float) -> int:
	var s := 0.5 + 0.3 * sin(t * 0.19 + phase) + 0.2 * sin(t * 0.47 + phase * 2.3)
	return int(round(clampf(s, 0.0, 1.0) * amp))


## 지형을 만들 때 쓰는 gen(CR27 — 사용자 2026-11-07 "암흑지대 2/3, 옛 지도를 잘라 붙여"): terrain_dark_depth가 있으면
## 그 깊이로 굴 · 수정 · 요소를 만들어(옛 지도와 같은 무작위 흐름) 지금 dark_depth보다 바깥 띠는 걷어내지 않은 옛 미로로 남는다.
static func terrain_gen(g: Dictionary) -> Dictionary:
	if not g.has("terrain_dark_depth"):
		return g
	var d := g.duplicate()
	d["dark_depth"] = JsonUtil.get_int(g, "terrain_dark_depth")
	return d


## 옛 경계에 놓인 경계 요소(층 JSON features spot "dark_edge" — 타다 남은 횃불 · 썩은 고기 무더기)를 팔 바깥쪽으로 경계가 옮겨 간 만큼 밀어
## 새 경계 안쪽 5칸의 가장 가까운 빈 바닥에 둔다(무작위 없음). 자리가 없으면 그대로.
static func shift_edge_features(db: GameDatabase, map: FloorMap, old_lay: CrossLayout, lay: CrossLayout, floor_def: Dictionary, tiles: Dictionary) -> void:
	var ids := {}
	for s: Variant in JsonUtil.get_array(floor_def, "features"):
		if s is Dictionary and JsonUtil.get_str(s, "spot") == "dark_edge":
			ids[JsonUtil.get_str(s, "event")] = true
	var floor_index := map.index_of(JsonUtil.get_str(tiles, "floor"))
	var taken := {}
	for f: Dictionary in map.features:
		taken[f["pos"]] = true
	var shift := lay.dark_start() - old_lay.dark_start()
	for f: Dictionary in map.features:
		var p: Vector2i = f["pos"]
		var dir := lay.zone_of(p)
		if not ids.has(str(f["id"])) or not CrossLayout.ARMS.has(dir):
			continue
		var want := p + CrossLayout.axis(dir) * shift
		var best := Vector2i(-1, -1)
		var best_d := INF
		for dy in range(-8, 9):
			for dx in range(-8, 9):
				var q := want + Vector2i(dx, dy)
				if not map.in_bounds(q) or map.tiles[map.idx(q)] != floor_index or taken.has(q) or not map.portal_at(q).is_empty():
					continue
				var depth := lay.arm_depth(q) - lay.dark_start()
				if depth < 1 or depth > 5 or FieldFeaturePlacer.hidden_by_wall(map, q):
					continue
				var d := float((q - want).length_squared())
				if d < best_d:
					best = q
					best_d = d
		if best.x < 0:
			continue
		var tile := map.tiles[map.idx(p)]
		map.tiles[map.idx(p)] = floor_index
		map.tiles[map.idx(best)] = tile
		taken.erase(p)
		taken[best] = true
		f["pos"] = best
