class_name ExploreSession
extends RefCounted
## 탐험 한 판의 규칙(순수 로직, 화면과 분리): 이동·시간·시야·광원·허기·포탈·안전지대·층 폐쇄·몬스터 조우.
## 시간은 실시간으로 흐른다(realtime: RealtimeDriver). 이동은 부드러운 연속 좌표(fpos, 칸 단위)이고
## 충돌은 Kinematics(벽 = 걸을 수 없는 칸). 속도 = 1칸 / move_hours (게임 시간) — 몬스터와 같은 공식.
## 시야·안전지대·포탈·발견은 몸 중심이 있는 칸(pos)으로 판정한다. 이동 자체는 시간을 쓰지 않는다.
## 화면(ExploreScreen)은 시그널을 받아 그린다. 메시지는 문자열 키로만 낸다(번역은 화면 몫).

signal moved(from: Vector2i, to: Vector2i)  ## 몸 중심이 다른 칸으로 넘어갔다
signal body_moved(at: Vector2)              ## 연속 좌표가 바뀌었다(그리기용, 매 프레임)
signal bumped(at: Vector2i)
signal view_changed
signal time_passed(hours: float)
signal message(key: String, args: Dictionary, kind: String)
signal closing_warning(hours_left: float)
signal floor_closed
signal player_died(cause: String)
signal encounter(group: FieldMonsters.Group, party_first: bool)

var db: GameDatabase
var floor_def: Dictionary
var map: FloorMap
var player: PlayerCharacter
var clock: GameClock
var rng: Rng
var effects: EffectRegistry
var lights: LightField
var monsters: FieldMonsters
var lord: LordWatch  ## 계층군주 소환 감시(층 JSON "lord")
var realtime: RealtimeDriver
var monsters_enabled: bool = true  ## false면 몬스터가 나타나지 않는다(규칙 테스트용). start() 전에 정한다.
var in_combat: bool = false
var pos: Vector2i                ## 몸 중심이 있는 칸
var fpos: Vector2 = Vector2.ZERO  ## 몸 중심의 연속 좌표(칸 단위, 칸 (x, y)의 중심 = x + 0.5, y + 0.5)
var facing: Vector2i = Vector2i(0, 1)
var last_move_hours: float = -1.0  ## 마지막으로 움직인 게임 시각(은신 정수의 '정지 중' 판정)
var vision_m: float = 0.0
var ended: bool = false
var steps: int = 0

var _mpt: float = 1.0
var _warned: Dictionary = {}
var _was_safe: bool = false
var _view_dirty: bool = false  # 시간 흐름으로 시야가 바뀌었다(광원 꺼짐·상태이상)


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
	fpos = Kinematics.center_of(pos)
	lights = LightField.build(map, _mpt)
	monsters = FieldMonsters.new(db, map, floor_def, rng)
	lord = LordWatch.new(JsonUtil.get_dict(floor_def, "lord"))
	realtime = RealtimeDriver.new()
	player.pool.set_context("dungeon", true)
	player.died.connect(_on_player_died)
	player.status_changed.connect(_on_status_changed)
	player.light.went_out.connect(_on_light_out)


## 입장 직후 한 번 부른다.
func start() -> void:
	_say("explore.enter", {"floor": floor_name()}, "system")
	_was_safe = in_safe_zone()
	if monsters_enabled:
		monsters.spawn_initial(pos)
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


## 한 칸을 가는 데 드는 게임 시간 = 기본값 / (1 + 민첩 × 계수). 몬스터도 같은 공식으로 움직인다.
func move_hours() -> float:
	var base := float(db.bal("explore.move_hours_base", 0.02))
	var coef := float(db.bal("explore.move_agi_coef", 0.02))
	return base / (1.0 + maxf(0.0, player.stats.get_value("agi")) * coef)


## 한곳에 함께 있는 탐험가 수(계층군주 소환 조건). 동료는 M4 — 지금은 혼자.
func party_size() -> int:
	return 1


func found_count(list: Array[Dictionary]) -> int:
	var n := 0
	for rec: Dictionary in list:
		if bool(rec.get("found", false)):
			n += 1
	return n


# ── 행동 ─────────────────────────────────────────────────

## 실시간 진행: 화면이 매 프레임 실제 경과 초를 넘긴다. 시간 흐름으로 시야가 바뀌었으면 다시 계산한다.
func tick_realtime(real_sec: float) -> void:
	realtime.tick(self, real_sec)
	if _view_dirty and not ended:
		_view_dirty = false
		refresh_view()


## 실시간 이동: 방향 dir(8방향 가능, 길이는 무시)으로 이번 프레임만큼 걷는다. 시간이 멈춰 있으면 걷지 않는다.
## 속도(칸/실제 초) = realtime_hours_per_sec / move_hours.
func move_dir(dir: Vector2, real_sec: float) -> void:
	var sec := realtime.frame_sec(self, real_sec)
	if dir == Vector2.ZERO or sec <= 0.0:
		return
	PlayerMotion.move_by(self, dir.normalized() * sec * realtime.hours_per_sec(self) / move_hours())


## 한 칸 거리만큼 dir로 걷는다(테스트·디버그·캡처용, 시간 정지와 무관). 칸이 바뀌었거나 전투가 시작되면 true.
func try_move(dir: Vector2i) -> bool:
	if ended or in_combat or dir == Vector2i.ZERO:
		return false
	var from := pos
	PlayerMotion.move_by(self, Vector2(dir))
	return pos != from or in_combat


## 몸 중심이 다른 칸으로 넘어갔다(PlayerMotion이 부른다): 시야·발견·구역 알림.
func enter_cell(cell: Vector2i) -> void:
	var from := pos
	pos = cell
	steps += 1
	moved.emit(from, cell)
	refresh_view()
	_on_enter_cell(from)


func wait(hours: float = -1.0) -> void:
	if ended or in_combat:
		return
	var h := hours if hours > 0.0 else float(db.bal("explore.wait_hours", 1.0))
	_say("explore.wait", {"hours": roundi(h)})
	pass_time(h)
	if not ended:
		refresh_view()


## 휴식(수면). 안전지대에서만 휴식 회복이 붙는다. 바깥에서는 시간마다 습격 위험이 있다.
func rest() -> void:
	if ended or in_combat:
		return
	var hours := int(db.bal("explore.rest_hours", 8.0))
	if in_safe_zone():
		player.pool.tick("rest", hours)
		_say("explore.rest_safe", {"hours": hours}, "good")
		pass_time(hours)
	else:
		_say("explore.rest_unsafe", {"hours": hours}, "warn")
		for i in hours:
			pass_time(1.0)
			if ended or in_combat:
				break
			if monsters_enabled and rng.chance(float(db.bal("monsters.rest_ambush_chance_per_hour", 0.04))):
				var g := monsters.ambush_near(pos)
				if g != null:
					_say("explore.ambush", {}, "danger")
					engage(g, false)
					break
	if not ended:
		refresh_view()


func use_item(item_id: String) -> bool:
	if ended or in_combat:
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
		for gone: String in player.essences.expire_pending(clock.total_hours):
			message.emit("essence.expired", {"name": DataNames.entry(db, "essences", gone)}, "warn")
	if not ended:
		_check_closing()
	if monsters_enabled and not ended and not in_combat and h > 0.0:
		lord.update(self, h)
		monsters.set_player_stealth(FieldStealth.of(self))
		var g := monsters.update(fpos, h, clock.total_hours, in_safe_zone())
		if g != null:
			engage(g, false)


## 시야를 다시 계산하고 탐험 기록·발견을 갱신한다.
func refresh_view() -> void:
	vision_m = Vision.radius_m(db, floor_def, map, player, pos)
	if lord.is_active():
		vision_m = minf(vision_m, lord.vision_cap_m())
	map.visible_now = Fov.compute(map, pos, vision_m / _mpt)
	map.remember_visible()
	_discover()
	view_changed.emit()


## 순간이동(디버그·함정 등): 시간 없이 위치만 바꾼다.
func relocate(to: Vector2i) -> bool:
	if not map.is_walkable(to) or monsters.group_at(to) != null:
		return false
	var from := pos
	pos = to
	fpos = Kinematics.center_of(to)
	body_moved.emit(fpos)
	moved.emit(from, to)
	refresh_view()
	_on_enter_cell(from)
	return true


# ── 조우 ─────────────────────────────────────────────────

## 몬스터 무리와 전투를 시작한다(화면이 encounter를 받아 전투 화면을 연다). party_first: 플레이어가 먼저 발견.
func engage(group: FieldMonsters.Group, party_first: bool) -> void:
	if in_combat or ended or group == null:
		return
	in_combat = true
	realtime.tick(self, 0.0)
	encounter.emit(group, party_first)


## 전투가 끝났다. result: victory/fled/defeat. 전투 차례 수만큼 시간이 흐른다.
func resolve_encounter(group: FieldMonsters.Group, result: String, turns: int, killed: Array[String] = []) -> void:
	in_combat = false
	if not killed.is_empty() and not player.dead:
		for m: Dictionary in Rewards.grant(player, killed, rng, clock.total_hours):
			message.emit(str(m["key"]), m["args"], str(m["kind"]))
	if lord.on_battle_end(self, group, result):
		pass
	elif result == Battle.RESULT_VICTORY:
		monsters.remove(group, clock.total_hours)
	elif result == Battle.RESULT_FLED:
		monsters.set_grace(group, clock.total_hours)
	if ended:
		return
	pass_time(turns * float(db.bal("combat.hours_per_turn", 0.01)))
	if not ended:
		refresh_view()


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
	_view_dirty = true
	_say("explore.status_on" if active else "explore.status_off", {"status": DataNames.entry(db, "statuses", status_id)},
		"warn" if active else "good")


func _on_light_out(item_id: String) -> void:
	_view_dirty = true
	_say("explore.light_out", {"item": DataNames.entry(db, "items", item_id)}, "warn")


func _on_player_died(cause: String) -> void:
	ended = true
	_say("explore.died", {}, "danger")
	player_died.emit(cause)


func _say(key: String, args: Dictionary = {}, kind: String = "info") -> void:
	message.emit(key, args, kind)
