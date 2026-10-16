class_name FloorArtCheck
extends RefCounted
## 탐험 맵 "그림 층" 검사(docs/PROMPT_ART_MAP.md §5.4). 그림 층 = 고정 지형 위에 얹는 바닥 변형·장식·데칼 — 지형(걷기 가능 여부)은 바꾸지 않는다.
## 그림 층 art = {
##   "variants": PackedInt32Array(칸마다 바닥 변형 번호, -1 = 변형 없음/벽 — 길이 width×height. 없으면 검사 안 함),
##   "decor": Array[{"pos": Vector2i, "blocks": bool}](장식·데칼 자리)
## }
## 규칙: 같은 변형이 가로·세로로 max_run칸을 넘게 이어지지 않는다 · 장식은 걷는 칸을 막지 않는다 · 장식은 동굴 요소 칸과 겹치지 않는다.
## 도구(floor_map.gd)·테스트에서만 부른다 — 지도 전체를 훑으므로 그리기 중에 부르지 않는다.

const MAX_RUN := 2  ## 같은 변형이 이어져도 되는 칸 수(3칸부터 문제)


## 그림 층이 아직 없는 지도의 빈 그림 층(A0 — 그림 작업 전). A2부터 실제 그림 층을 만드는 쪽이 같은 모양으로 넘긴다.
static func empty_art() -> Dictionary:
	return {"variants": PackedInt32Array(), "decor": []}


static func problems(map: FloorMap, art: Dictionary, max_run: int = MAX_RUN) -> PackedStringArray:
	var out := PackedStringArray()
	var variants: PackedInt32Array = art.get("variants", PackedInt32Array())
	if not variants.is_empty():
		if variants.size() != map.width * map.height:
			out.append("바닥 변형 개수 %d ≠ 칸 수 %d" % [variants.size(), map.width * map.height])
		else:
			out.append_array(_run_problems(map, variants, max_run))
	var feature_cells := {}
	for f: Dictionary in map.features:
		feature_cells[f["pos"]] = str(f["id"])
	var decor: Array = art.get("decor", [])
	var blocked := 0
	var on_feature := 0
	var first := ""
	for d: Dictionary in decor:
		var p: Vector2i = d["pos"]
		if bool(d.get("blocks", false)) and map.is_walkable(p):
			blocked += 1
			first = first if not first.is_empty() else "막음 %s" % p
		if feature_cells.has(p):
			on_feature += 1
			first = first if not first.is_empty() else "동굴 요소 %s %s" % [feature_cells[p], p]
	if blocked > 0:
		out.append("걷는 칸을 막는 장식 %d곳 (%s)" % [blocked, first])
	if on_feature > 0:
		out.append("동굴 요소와 겹친 장식 %d곳 (%s)" % [on_feature, first])
	return out


## 같은 변형이 가로·세로로 max_run칸을 넘게 이어진 곳(걷는 칸만, -1은 끊김).
static func _run_problems(map: FloorMap, v: PackedInt32Array, max_run: int) -> PackedStringArray:
	var count := 0
	var first := Vector2i(-1, -1)
	for axis: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
		for y in map.height:
			for x in map.width:
				var i := y * map.width + x
				if v[i] < 0:
					continue
				var prev := Vector2i(x, y) - axis
				if map.in_bounds(prev) and v[prev.y * map.width + prev.x] == v[i]:
					continue  # 이어지는 줄의 첫 칸에서만 센다
				var n := 1
				var q := Vector2i(x, y) + axis
				while map.in_bounds(q) and v[q.y * map.width + q.x] == v[i]:
					n += 1
					q += axis
				if n > max_run:
					count += 1
					if first.x < 0:
						first = Vector2i(x, y)
	if count == 0:
		return PackedStringArray()
	return PackedStringArray(["같은 바닥 변형이 %d칸 넘게 이어진 줄 %d곳 (처음 %s)" % [max_run, count, first]])
