class_name FieldClues
extends RefCounted
## 흔적과 때(레벨 디자인 개선 LD — docs/plans/level_design_review.md). FieldFeatureAct가 부른다. 순수 로직(오토로드 비의존).
##   행동 "point_to": {"event": 요소 id, "within": 칸(기본 60), "radius": 밝힐 반경(기본 6), "none_line": 가리킬 것이 없을 때 문구}
##     가장 가까운(within 안) 아직 다 쓰지 않은 그 요소 둘레의 지도를 밝히고, 숨은 요소면 드러낸다
##     — 늑대 발자국 → 늑대 굴, 노움 긁힌 표식 → 노움 은닉처. 화면(밝혀진 지도)이 알려 주므로 따로 글을 띄우지 않는다.
##   행동 "hours_window": {"from": 시, "to": 시, "missing": 문구}: 그 시각(0~24, from > to면 자정을 넘는다) 안에서만 할 수 있다
##     — 밤에만 우는 종(망자의 땅 듀라한 폐허).
##   행동 "line_day": true: line 대신 line_d<원정 날짜>(없으면 그보다 이른 날 중 가장 늦은 것, 그것도 없으면 line) — 날마다 달라지는 비석.


## 지금이 그 시각 안인가(창이 비었으면 언제나 true).
static func in_window(s: ExploreSession, w: Dictionary) -> bool:
	if w.is_empty():
		return true
	var h := s.clock.hour_of_day()
	var a := JsonUtil.get_float(w, "from", 0.0)
	var b := JsonUtil.get_float(w, "to", 24.0)
	return (h >= a or h < b) if a > b else (h >= a and h < b)


## point_to: 가리킨 요소(없으면 {}). 찾으면 둘레를 밝히고 숨어 있었으면 드러낸다.
static func point_to(s: ExploreSession, from: Vector2i, d: Dictionary) -> Dictionary:
	if d.is_empty():
		return {}
	var target := nearest(s, from, JsonUtil.get_str(d, "event"), JsonUtil.get_float(d, "within", 60.0))
	if target.is_empty():
		FieldFeatureAct.say_line(s, JsonUtil.get_str(d, "none_line"), {"pos": from}, "info")
		return {}
	s.features.reveal(s, target, false)
	reveal_around(s, target["pos"], JsonUtil.get_float(d, "radius", 6.0))
	return target


## from에서 가장 가까운(within칸 안) 아직 다 쓰지 않은 event 요소.
static func nearest(s: ExploreSession, from: Vector2i, event: String, within: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d := within
	for e: Dictionary in s.features.list:
		if str(e["id"]) != event or bool(e["cleared"]) or not (e["used"] as Dictionary).is_empty():
			continue
		var dist := Vector2(from - (e["pos"] as Vector2i)).length()
		if dist <= best_d:
			best_d = dist
			best = e
	return best


## 둘레 radius칸 지도를 밝힌다(망루에 오르기 — FL13, 흔적 따라가기).
static func reveal_around(s: ExploreSession, c: Vector2i, radius: float) -> void:
	var ri := ceili(radius)
	for y in range(c.y - ri, c.y + ri + 1):
		for x in range(c.x - ri, c.x + ri + 1):
			var q := Vector2i(x, y)
			if s.map.in_bounds(q) and Vector2(q - c).length() <= radius:
				s.map.explored[s.map.idx(q)] = 1
	s.view_changed.emit()


## line_day 문구 키: key_d<날>부터 거꾸로 찾아 있는 것, 없으면 key.
static func day_key(s: ExploreSession, key: String) -> String:
	for day in range(s.clock.day(), 0, -1):
		var k := "%s_d%d" % [key, day]
		if Strings.has(k):
			return k
	return key
