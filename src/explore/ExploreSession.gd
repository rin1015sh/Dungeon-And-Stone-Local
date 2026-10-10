class_name ExploreSession
extends RefCounted
## 탐험 한 판의 규칙(순수 로직, 화면과 분리): 그리드 이동·시간·시야·광원·허기·포탈·안전지대·층 폐쇄.
## 화면(ExploreScreen)은 시그널을 받아 그린다. 메시지는 문자열 키로만 낸다(번역은 화면 몫).

signal moved(from: Vector2i, to: Vector2i)
signal bumped(at: Vector2i)
signal view_changed
signal time_passed(hours: float)
signal message(key: String, args: Dictionary, kind: String)
signal closing_warning(hours_left: float)
signal floor_closed
signal player_died(cause: String)

var db: GameDatabase
var floor_def: Dictionary
var map: FloorMap
var player: PlayerCharacter
var clock: GameClock
var rng: Rng
var effects: EffectRegistry
var lights: LightField
var pos: Vector2i
var facing: Vector2i = Vector2i(0, 1)
var vision_m: float = 0.0
var ended: bool = false
var steps: int = 0

var _mpt: float = 1.0
var _warned: Dictionary = {}
var _was_safe: bool = false


func _init(p_db: GameDatabase, p_floor_def: Dictionary, p_map: FloorMap, p_player: PlayerCharacter,
		p_clock: GameClock, p_rng: Rng, p_effects: EffectRegistry) -> void:
	db = p_db
	floor_def = p_floor_def
	map = p_map
	player = p_player
	clock = p_clock
	rng = p_rng
	effects = p_effects
	_mpt = maxf(0.01, float(db.bal("explore.meters_per_tile", 1.0)))
	pos = map.entry
	lights = LightField.build(map, _mpt)
	player.pool.set_context("dungeon", true)
	player.died.connect(_on_player_died)
	player.status_changed.connect(_on_status_changed)
	player.light.went_out.connect(_on_light_out)


## 입장 직후 한 번 부른다.
func start() -> void:
	_say("explore.enter", {"floor": floor_name()}, "system")
	_was_safe = in_safe_zone()
	refresh_view()


func floor_name() -> String:
	return JsonUtil.get_str(floor_def, "name_ko", map.floor_id)


func close_hours() -> float:
	return JsonUtil.get_float(floor_def, "close_hours", 168.0)


func hours_until_close() -> float:
	return maxf(0.0, close_hours() - clock.total_hours)


func in_safe_zone() -> bool:
	return map.in_safe_zone(pos)


func vision_tiles() -> float:
	return vision_m / _mpt


## "torch" / "ambient" / "dark"
func light_kind() -> String:
	return Vision.light_kind(floor_def, map, player, pos)


## 한 칸 이동에 드는 시간 = 기본값 / (1 + 민첩 × 계수)
func move_hours() -> float:
	var base := float(db.bal("explore.move_hours_base", 0.02))
	var coef := float(db.bal("explore.move_agi_coef", 0.02))
	return base / (1.0 + maxf(0.0, player.stats.get_value("agi")) * coef)


func found_count(list: Array[Dictionary]) -> int:
	var n := 0
	for rec: Dictionary in list:
		if bool(rec.get("found", false)):
			n += 1
	return n


# ── 행동 ─────────────────────────────────────────────────

## 4방향 한 칸 이동. 막히면 시간이 흐르지 않는다.
func try_move(dir: Vector2i) -> bool:
	if ended:
		return false
	facing = dir
	var to := pos + dir
	if not map.is_walkable(to):
		bumped.emit(to)
		return false
	var from := pos
	pos = to
	steps += 1
	moved.emit(from, to)
	pass_time(move_hours())
	if ended:
		return true
	refresh_view()
	_on_enter_cell(from)
	return true


func wait(hours: float = -1.0) -> void:
	if ended:
		return
	var h := hours if hours > 0.0 else float(db.bal("explore.wait_hours", 1.0))
	_say("explore.wait", {"hours": roundi(h)})
	pass_time(h)
	if not ended:
		refresh_view()


## 휴식(수면). 안전지대에서만 휴식 회복이 붙는다. (M2: 바깥에서는 습격 위험)
func rest() -> void:
	if ended:
		return
	var hours := float(db.bal("explore.rest_hours", 8.0))
	if in_safe_zone():
		player.pool.tick("rest", hours)
		_say("explore.rest_safe", {"hours": roundi(hours)}, "good")
	else:
		_say("explore.rest_unsafe", {"hours": roundi(hours)}, "warn")
	pass_time(hours)
	if not ended:
		refresh_view()


func use_item(item_id: String) -> bool:
	if ended:
		return false
	var ctx := ItemUser.use(effects, player, item_id, rng)
	if ctx == null:
		_say("explore.no_item", {"item": DataNames.entry(db, "items", item_id)}, "warn")
		return false
	for m: Dictionary in ctx.messages:
		message.emit(str(m["key"]), m["args"], str(m["kind"]))
	if ctx.success:
		refresh_view()
	return ctx.success


## 분류(food, light …)가 맞는 첫 소지품을 쓴다.
func use_category(category: String) -> bool:
	var id := player.inventory.first_where(db, "category", category)
	if id.is_empty():
		_say("explore.no_category", {"category": DataNames.tag(db, "item_categories", category)}, "warn")
		return false
	return use_item(id)


## 발밑의 포탈이나 바로 옆의 기념비를 살핀다.
func interact() -> void:
	if ended:
		return
	var portal := map.portal_at(pos)
	if not portal.is_empty():
		_say("explore.portal_locked", {"floor": int(portal["to_floor"])}, "system")
		return
	for d in FloorMap.DIRS4:
		var def := map.def_at(pos + d)
		if def != null and def.interact == "monument":
			_say("explore.monument", {}, "system")
			return
	_say("explore.nothing_here")


## 시간을 흘린다. 층 폐쇄 시각을 넘지 않게 자르고, 경고·폐쇄를 판정한다.
func pass_time(hours: float) -> void:
	if ended or hours <= 0.0:
		return
	var h := minf(hours, hours_until_close())
	if h > 0.0:
		clock.advance(h)
		player.advance_hours(h)
		time_passed.emit(h)
	if not ended:
		_check_closing()


## 시야를 다시 계산하고 탐험 기록·발견을 갱신한다.
func refresh_view() -> void:
	vision_m = Vision.radius_m(db, floor_def, map, player, pos)
	map.visible_now = Fov.compute(map, pos, vision_m / _mpt)
	map.remember_visible()
	_discover()
	view_changed.emit()


# ── 디버그 ───────────────────────────────────────────────

func debug_teleport(to: Vector2i) -> bool:
	if not map.is_walkable(to):
		return false
	var from := pos
	pos = to
	moved.emit(from, to)
	refresh_view()
	_on_enter_cell(from)
	return true


func debug_reveal() -> void:
	map.explored.fill(1)
	view_changed.emit()


## 폐쇄까지 hours_left만 남도록 시계를 돌린다(개체 상태는 흐르지 않는다).
func debug_close_in(hours_left: float) -> void:
	clock.total_hours = maxf(clock.total_hours, close_hours() - hours_left)
	_check_closing()


func nearest_portal() -> Vector2i:
	var best := Vector2i(-1, -1)
	for portal: Dictionary in map.portals:
		var p: Vector2i = portal["pos"]
		if best.x < 0 or (p - pos).length_squared() < (best - pos).length_squared():
			best = p
	return best


# ── 내부 ─────────────────────────────────────────────────

func _check_closing() -> void:
	var left := hours_until_close()
	var newly := false
	for w: Variant in db.bal("explore.closing_warning_hours", []):
		var wh := float(w)
		if left <= wh and not _warned.has(wh):
			_warned[wh] = true
			newly = true
	if newly and left > 0.0:
		closing_warning.emit(left)
		_say("explore.closing_soon", {"hours": ceili(left)}, "danger")
	if left <= 0.0:
		ended = true
		_say("explore.closed", {}, "danger")
		floor_closed.emit()


func _discover() -> void:
	for rec: Dictionary in map.landmarks:
		if not bool(rec["found"]) and map.visible_now[map.idx(rec["pos"])] != 0:
			rec["found"] = true
			var lm := db.get_entry("landmarks", str(rec["id"]))
			_say("explore.landmark_found", {"name": JsonUtil.get_str(lm, "name_ko"), "desc": JsonUtil.get_str(lm, "desc_ko")}, "good")
	for portal: Dictionary in map.portals:
		if not bool(portal["found"]) and map.visible_now[map.idx(portal["pos"])] != 0:
			portal["found"] = true
			_say("explore.portal_found", {"dir": DataNames.tag(db, "directions", str(portal["dir"]))}, "good")


func _on_enter_cell(from: Vector2i) -> void:
	var safe := in_safe_zone()
	if safe != _was_safe:
		_was_safe = safe
		_say("explore.safe_enter" if safe else "explore.safe_leave", {}, "good" if safe else "info")
	if map.is_dark(pos) and not map.is_dark(from):
		_say("explore.dark_enter", {}, "warn")
	if not map.portal_at(pos).is_empty():
		_say("explore.portal_here", {}, "system")


func _on_status_changed(status_id: String, active: bool) -> void:
	_say("explore.status_on" if active else "explore.status_off", {"status": DataNames.entry(db, "statuses", status_id)},
		"warn" if active else "good")


func _on_light_out(item_id: String) -> void:
	_say("explore.light_out", {"item": DataNames.entry(db, "items", item_id)}, "warn")


func _on_player_died(cause: String) -> void:
	ended = true
	_say("explore.died", {}, "danger")
	player_died.emit(cause)


func _say(key: String, args: Dictionary = {}, kind: String = "info") -> void:
	message.emit(key, args, kind)
