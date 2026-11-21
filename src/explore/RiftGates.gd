class_name RiftGates
extends RefCounted
## 2층 균열 여는 문(plans/expansion_f1_3_B §1-1): 마석이 아니라 "그 길에서 해낸 일"로 그 층 균열 하나를 연다(사용자 FL4).
##   층 JSON "rift_gates": [{"rift": 균열 id, "flag": 이름, "need": 수, "until_day": 원정 날(이 날까지 — 넘기면 late_line),
##     "at": "here"(마지막으로 센 요소 자리 곁 — 기본) | RouteSpots 자리 키 사전, "line": 열릴 때 문구 키, "sound": 소리 키, "late_line"}]
##   동굴 요소 행동 "goal": 이름(FieldFeatureAct — FloorGoal과 같은 키)이 하나씩 센다. 다 차면 RiftWatch.force_open으로 포탈 하나.
## 한 원정에 문 하나 한 번. 순수 로직(오토로드 비의존).

var _gates: Array[Dictionary] = []  ## {def, count, opened}


static func setup(s: ExploreSession) -> RiftGates:
	var list := JsonUtil.get_array(s.floor_def, "rift_gates")
	if list.is_empty():
		return null
	var rg := RiftGates.new()
	for v: Variant in list:
		if v is Dictionary:
			rg._gates.append({"def": v, "count": 0, "opened": false})
	return rg


## 그 이름의 일을 하나 해냈다(at = 그 요소 자리). 문이 열렸으면 true.
func advance(s: ExploreSession, what: String, at: Vector2i) -> bool:
	for g in _gates:
		var d: Dictionary = g["def"]
		if bool(g["opened"]) or JsonUtil.get_str(d, "flag") != what:
			continue
		var day := floori(s.clock.total_hours / 24.0) + 1
		if day > JsonUtil.get_int(d, "until_day", 7):
			if d.has("late_line"):
				s.message.emit(JsonUtil.get_str(d, "late_line"), {}, "info")
			continue
		g["count"] = int(g["count"]) + 1
		if int(g["count"]) < maxi(1, JsonUtil.get_int(d, "need", 1)):
			continue
		var near := at
		var ad: Variant = d.get("at", "here")
		if ad is Dictionary:
			var c := RouteSpots._anchor(s, ad)
			if c.x >= 0:
				near = c
		if not s.rifts.force_open(s, JsonUtil.get_str(d, "rift"), near):
			continue
		g["opened"] = true
		if d.has("sound"):
			s.sound.emit(JsonUtil.get_str(d, "sound"), near)
		if d.has("line"):
			s.message.emit(JsonUtil.get_str(d, "line"), {}, "danger")
		return true
	return false


func count(flag: String) -> int:
	for g in _gates:
		if JsonUtil.get_str(g["def"], "flag") == flag:
			return int(g["count"])
	return 0


func opened(rift_id: String) -> bool:
	return _gates.any(func(g: Dictionary) -> bool: return bool(g["opened"]) and JsonUtil.get_str(g["def"], "rift") == rift_id)


## 계층석으로 조건 없이 열 수 있는 문이 있는가(아직 안 열린 첫 문 — 날짜 무관).
func can_force() -> bool:
	return _gates.any(func(g: Dictionary) -> bool: return not bool(g["opened"]))


## 후회의 계층석(제단 행동 force_rift_gate): 아직 안 열린 첫 문의 균열을 at 곁에 연다. 열었으면 true.
func force(s: ExploreSession, at: Vector2i) -> bool:
	for g in _gates:
		if bool(g["opened"]):
			continue
		if not s.rifts.force_open(s, JsonUtil.get_str(g["def"], "rift"), at):
			return false
		g["opened"] = true
		return true
	return false
