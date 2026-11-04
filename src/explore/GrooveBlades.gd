class_name GrooveBlades
extends RefCounted
## 칼날 홈 함정(강철의 묘 — 사용자 2026-11-04 "칼날함정 진짜 홈에서 칼날이 지나가게"): 홈 타일(it_groove)이 한 줄로
## 이어진 곳마다 칼날 하나가 홈 끝에서 끝까지 실제로 오간다. 칼날이 지나가는 칸에 몸이 있으면 베인다 — 판정 굴림 없이
## 칼날의 때를 보고 건너는 것이 전부다(예전 숨은 "회전 칼날" 함정은 없앴다). 몬스터는 베이지 않는다.
## 챕터 "groove_blades": {"tile": 홈 타일 id, "speed": 칸/실제 초, "pause_sec": 끝에서 멈추는 초, "stagger": 이웃 홈끼리 어긋나는 몫(0~1),
##   "reach": 칼날이 닿는 반경(칸, 몸 반폭 포함), "hit_cooldown_sec": 한 번 베인 뒤 다시 베이기까지, "fail": [효과], "fail_message",
##   "id": 히든 피스 reveal.hazard가 가리키는 이름, "bypass": {stat, at_least, message} — 그만큼 단단하면 칼날이 몸에 부러져 멈춘다}.
## 시간은 실제 초(탐험이 멈추면 칼날도 멈춘다 — ExploreSession.tick_realtime). 그리기는 GrooveBladeView.

var def: Dictionary = {}
var runs: Array[Dictionary] = []  ## {"from": Vector2, "to": Vector2(칸 중심 좌표), "len": 칸 수, "phase": 0~1, "broken": 부러짐}
var t: float = 0.0                ## 흐른 실제 초
var _cool: float = 0.0
var _told: bool = false           ## 첫 번째로 베였을 때만 문구(같은 문구가 대화창을 채우지 않게)


## 챕터 정의 d("groove_blades")로 지도의 홈 줄을 찾는다. 홈이 없으면 null.
static func build(map: FloorMap, d: Dictionary) -> GrooveBlades:
	if d.is_empty():
		return null
	var gb := GrooveBlades.new()
	gb.def = d
	var tile := JsonUtil.get_str(d, "tile", "it_groove")
	var stagger := JsonUtil.get_float(d, "stagger", 0.37)
	var seen := {}
	for y in map.height:
		for x in map.width:
			var c := Vector2i(x, y)
			if seen.has(c) or map.tile_id_at(c) != tile:
				continue
			var down := _run(map, c, Vector2i.DOWN, tile)
			var right := _run(map, c, Vector2i.RIGHT, tile)
			var dir := Vector2i.DOWN if down >= right else Vector2i.RIGHT
			var n := maxi(down, right)
			for k in n:
				seen[c + dir * k] = true
			if n < 2:
				continue
			gb.runs.append({"from": Vector2(c) + Vector2(0.5, 0.5), "to": Vector2(c + dir * (n - 1)) + Vector2(0.5, 0.5),
				"len": n, "phase": fmod(float(gb.runs.size()) * stagger, 1.0)})
	return gb if not gb.runs.is_empty() else null


static func _run(map: FloorMap, c: Vector2i, dir: Vector2i, tile: String) -> int:
	var n := 0
	while map.in_bounds(c + dir * n) and map.tile_id_at(c + dir * n) == tile:
		n += 1
	return n


## i번째 칼날의 지금 자리(칸 단위 연속 좌표). 한쪽 끝에서 pause_sec 멈췄다가 반대쪽으로.
func blade_at(i: int) -> Vector2:
	var r: Dictionary = runs[i]
	if r.has("stop"):
		return r["stop"]
	var travel := maxf(0.1, (float(r["len"]) - 1.0) / maxf(0.1, JsonUtil.get_float(def, "speed", 3.0)))
	var pause := JsonUtil.get_float(def, "pause_sec", 0.6)
	var period := 2.0 * (travel + pause)
	var u := fmod(t / period + float(r["phase"]), 1.0) * period
	var k := 0.0
	if u < pause:
		k = 0.0
	elif u < pause + travel:
		k = (u - pause) / travel
	elif u < 2.0 * pause + travel:
		k = 1.0
	else:
		k = 1.0 - (u - 2.0 * pause - travel) / travel
	return (r["from"] as Vector2).lerp(r["to"], k)


## 칼날이 움직이는 방향(그리기 — 칼날 면을 홈과 나란히).
func axis(i: int) -> Vector2:
	var r: Dictionary = runs[i]
	return ((r["to"] as Vector2) - (r["from"] as Vector2)).normalized()


## 실제 sec초를 흘리고, 칼날에 닿았으면 벤다. 벴으면 true.
func tick(cs: ExploreSession, sec: float) -> bool:
	if sec <= 0.0:
		return false
	t += sec
	_cool = maxf(0.0, _cool - sec)
	if _cool > 0.0 or cs.player.dead:
		return false
	var reach := JsonUtil.get_float(def, "reach", 0.7)
	for i in runs.size():
		if not bool(runs[i].get("broken", false)) and cs.fpos.distance_to(blade_at(i)) <= reach:
			_cut(cs, i)
			return true
	return false


func _cut(cs: ExploreSession, i: int) -> void:
	var strong := JsonUtil.get_dict(def, "bypass")
	if not strong.is_empty() and cs.player.stats.get_value(JsonUtil.get_str(strong, "stat")) >= JsonUtil.get_float(strong, "at_least"):
		runs[i]["stop"] = blade_at(i)  # 몸에 부딪혀 부러진 자리에 멈춘다
		runs[i]["broken"] = true
		cs.message.emit(JsonUtil.get_str(strong, "message", "explore.trap_crushed"), {}, "good")
		if cs.rift_run != null:
			cs.rift_run.hidden.on_hazard(cs, cs.rift_run.chapter, def, "bypass")
		return
	_cool = JsonUtil.get_float(def, "hit_cooldown_sec", 1.2)
	var ctx := EffectContext.new(cs.db, null, cs.player, cs.rng)
	ctx.registry = cs.effects
	cs.effects.apply_all(ctx, JsonUtil.get_array(def, "fail"))
	if not _told:
		_told = true
		cs.message.emit(JsonUtil.get_str(def, "fail_message", "explore.groove_blade_cut"), {}, "danger")
	for m: Dictionary in ctx.messages:
		cs.message.emit(str(m["key"]), m["args"], str(m["kind"]))
	if cs.rift_run != null:  # 히든 피스 "함정 무발동" 조건이 있으면 칼날에 베인 것도 발동으로 친다
		cs.rift_run.hidden.on_hazard(cs, cs.rift_run.chapter, def, "fail")
