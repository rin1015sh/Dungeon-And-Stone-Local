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
signal transfer(target: ExploreSession)       ## 다른 세션(균열 챕터 ↔ 바깥 층)으로 넘어간다 — 화면이 바꿔 끼운다
signal riddle_asked(group: FieldMonsters.Group)  ## 수수께끼 문지기(RiftRiddle) — 화면이 문항을 띄우고 answer_riddle을 부른다
signal feature_choice(at: Vector2i)  ## 동굴 요소의 행동이 여럿이다(맑은 샘 등) — 화면이 고르게 하고 features.act를 부른다

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
var rifts: RiftWatch = RiftWatch.new()  ## 균열 포탈(자연·강제 개방)
var rift_run: RiftRun = null            ## 균열 챕터 세션이면 그 균열
var features: FieldFeatures = FieldFeatures.new()  ## 동굴 요소(시체·샘·모닥불·함정 … — data/events, 자리 = map.features)
var battle_drops: Array[Dictionary] = []  ## 전투 장면에서 줍기를 기다리는 드롭(grant_battle_rewards defer_drops — DropPickup)
var pending_messages: Array[Dictionary] = []  ## 화면이 붙기 전에 남긴 메시지(화면이 붙을 때 다시 보여 준다)
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
var _started: bool = false
var _view_dirty: bool = false  # 시간 흐름으로 시야가 바뀌었다(광원 꺼짐·상태이상)
var _rewarded: bool = false  # 이번 전투 보상을 이미 줬다(전투 결과 화면에서 — grant_battle_rewards)


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
	features.setup(self)
	realtime = RealtimeDriver.new()
	player.pool.set_context("dungeon", true)
	player.died.connect(_on_player_died)
	player.status_changed.connect(_on_status_changed)
	player.light.went_out.connect(_on_light_out)


## 입장 직후 한 번 부른다.
## 두 번째부터는(균열에서 돌아와 화면이 다시 붙을 때) 시야만 새로 그린다.
func start() -> void:
	if _started:
		refresh_view()
		return
	_started = true
	_say("explore.enter", {"floor": floor_name()}, "system")
	if rift_run == null:
		rifts.begin(self)
	_was_safe = in_safe_zone()
	if monsters_enabled:
		monsters.spawn_initial(pos)
		features.spawn_guards(self)
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
	player.fatigue.on_dungeon(Fatigue.DUNGEON_STEP, 1.0)  # 피로도 연결 지점(규칙 미정 — null이면 변화 없음)
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
	var bonus := features.rest_bonus(pos)  # 꺼진 모닥불 곁: 시간당 피로가 더 풀린다
	if bonus < 0.0:
		_say("field.rest_campfire", {}, "good")
	if in_safe_zone():
		_say("explore.rest_safe", {"hours": hours}, "good")
		var left := minf(float(hours), hours_until_close())  # 폐쇄 시각에서 잘리면 그만큼만 회복한다
		while left > 0.0 and not ended:
			var h := minf(1.0, left)
			left -= h
			player.pool.tick("rest", h)
			player.fatigue.on_dungeon(Fatigue.DUNGEON_REST_HOUR, h)
			player.fatigue.add(bonus * h, "rest_bonus")
			pass_time(h)
	else:
		_say("explore.rest_unsafe", {"hours": hours}, "warn")
		for i in hours:
			player.fatigue.on_dungeon(Fatigue.DUNGEON_REST_HOUR, 1.0)
			player.fatigue.add(bonus, "rest_bonus")
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
	if ctx.messages.is_empty() and not ctx.success:  # 쓸 효과가 없는 물건(장비 등) — 조용히 끝나지 않게
		_say("explore.cannot_use", {"item": DataNames.entry(db, "items", item_id)}, "info")
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
	if not ended:
		ExploreInteract.run(self)


## 시간을 흘린다. 층 폐쇄 시각을 넘지 않게 자르고, 경고·폐쇄를 판정한다.
func pass_time(hours: float) -> void:
	if ended or hours <= 0.0:
		return
	var h := minf(hours, hours_until_close())
	if h > 0.0:
		clock.advance(h)
		player.advance_hours(h)
		player.fatigue.on_dungeon(Fatigue.DUNGEON_HOUR, h)
		time_passed.emit(h)
	if not ended:
		_check_closing()
	if monsters_enabled and not ended and not in_combat and h > 0.0:
		lord.update(self, h)
		rifts.update(self, h)
		monsters.set_player_stealth(FieldStealth.of(self))
		monsters.set_player_marks(player.statuses.ids())
		var g := monsters.update(fpos, h, clock.total_hours, in_safe_zone())
		if g != null:
			engage(g, false)


## 시야를 다시 계산하고 탐험 기록·발견을 갱신한다.
func refresh_view() -> void:
	vision_m = Vision.radius_m(db, floor_def, map, player, pos)
	if lord.is_active():
		vision_m = minf(vision_m, lord.vision_cap_m())
	var radius := vision_m / _mpt
	map.visible_now = Fov.compute(map, pos, radius)
	var r := ceili(radius) + 1
	map.remember_visible(Rect2i(pos - Vector2i(r, r), Vector2i(r * 2 + 1, r * 2 + 1)))
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
	if rift_run != null and rift_run.riddle != null and rift_run.riddle.blocks(group):
		riddle_asked.emit(group)
		return
	in_combat = true
	_rewarded = false
	realtime.tick(self, 0.0)
	encounter.emit(group, party_first)


## 수수께끼에 답했다(RiftRiddle.PASS/WEAKEN/WRONG). 전투가 필요하면 바로 시작한다.
func answer_riddle(group: FieldMonsters.Group, outcome: String) -> void:
	if rift_run != null and rift_run.riddle != null and rift_run.riddle.apply(self, group, outcome):
		engage(group, false)


## 전투가 끝났다. result: victory/fled/defeat. 전투 차례 수만큼 시간이 흐른다.
## 몇 마리 쓰러뜨리고 도망쳤으면 쓰러뜨린 몬스터는 무리에서 빠진다(다시 만나도 되살아나지 않는다). 다 빠졌으면 승리로 친다.
## 전투 보상(처치 기록·공적·전리품·정수)을 주고 안내를 내보낸다. 낸 안내 목록(전투 결과 칸에도 보인다).
## 한 전투에 한 번 — 이미 줬으면 resolve_encounter는 다시 주지 않는다.
## colors: killed와 같은 순서의 정수 색(타입이 정한 것, 없으면 "" — Battle.killed_colors).
## defer_drops: 전리품·정수는 주지 않고 battle_drops에 담는다(전투 장면이 하나씩 묻고 take_drop·leave_drop으로 준다).
func grant_battle_rewards(group: FieldMonsters.Group, killed: Array[String], colors: Array[String] = [], defer_drops: bool = false) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_rewarded = true
	battle_drops.clear()
	if killed.is_empty() or player.dead:
		return out
	var mult := JsonUtil.get_float(group.battle_rules, "essence_mult", 1.0) if group != null else 1.0
	if defer_drops:
		battle_drops = DropPickup.roll(db, killed, rng, rift_run != null, mult, colors)
	for m: Dictionary in Rewards.grant(player, killed, rng, clock.total_hours, rift_run != null, mult, colors, not defer_drops):
		if str(m["key"]) == "reward.bag_full" and rift_run != null \
				and rift_run.keep_overflow(self, str(m["args"].get("item_id", "")), int(m["args"].get("count", 1))):
			continue  # 출구에 필요한 물건은 손에 쥐었다(RiftRun.held)
		message.emit(str(m["key"]), m["args"], str(m["kind"]))
		out.append(m)
	return out


## 전투 장면에서 드롭을 pc가 받는다(정수 흡수 · 가방 — 넘친 균열 출구 물건은 손에 쥔다). 안내를 내보내고 돌려준다.
func take_drop(drop: Dictionary, pc: PlayerCharacter) -> Dictionary:
	var m := DropPickup.take(drop, pc)
	if int(m.get("left", 0)) > 0 and rift_run != null and rift_run.keep_overflow(self, str(drop.get("id")), int(m["left"])):
		m = DropPickup._m("reward.loot_by", {"who": pc.display_name, "item": DataNames.entry(db, "items", str(drop.get("id"))), "count": int(drop.get("count", 1))}, "good")
	message.emit(str(m["key"]), m["args"], str(m["kind"]))
	return m


## 두고 간다(정수는 흩어지고 전리품은 사라진다). reason = 아무도 받을 수 없던 이유 키.
func leave_drop(drop: Dictionary, reason: String = "") -> Dictionary:
	var m := DropPickup.leave(db, drop, reason)
	message.emit(str(m["key"]), m["args"], str(m["kind"]))
	return m


func resolve_encounter(group: FieldMonsters.Group, result: String, turns: int, killed: Array[String] = []) -> void:
	in_combat = false
	player.fatigue.on_dungeon(Fatigue.DUNGEON_COMBAT_TURN, float(turns))
	if result == Battle.RESULT_FLED and group != null and not killed.is_empty():
		for id in killed:
			group.monster_ids.erase(id)
		if group.monster_ids.is_empty():
			result = Battle.RESULT_VICTORY
	var chained := result == Battle.RESULT_VICTORY and group != null and not group.waves.is_empty()  # 연전: 다음 웨이브까지 맵 시간 없이(RF7)
	if not _rewarded:
		grant_battle_rewards(group, killed)
	_rewarded = false
	if lord.on_battle_end(self, group, result) or (rift_run != null and rift_run.on_battle_end(self, group, result, killed)):
		pass
	elif result == Battle.RESULT_VICTORY:
		monsters.remove(group, clock.total_hours)
	elif result == Battle.RESULT_FLED:
		monsters.set_grace(group, clock.total_hours)
	if ended:
		return
	if not chained:
		pass_time(turns * float(db.bal("combat.hours_per_turn", 0.01)))
	if not ended:
		refresh_view()


## 화면이 아직 없을 때(새 챕터 세션) 남길 메시지. 화면이 붙으면 take_pending으로 꺼내 보여 준다.
func say_later(key: String, args: Dictionary = {}, kind: String = "info") -> void:
	pending_messages.append({"key": key, "args": args, "kind": kind})


func take_pending() -> Array[Dictionary]:
	var out := pending_messages.duplicate()
	pending_messages.clear()
	return out


## 플레이어 시그널 연결을 끊는다(균열 챕터 세션을 버릴 때 — 같은 플레이어에 세션이 쌓이지 않게).
func detach() -> void:
	ended = true
	if player.died.is_connected(_on_player_died):
		player.died.disconnect(_on_player_died)
		player.status_changed.disconnect(_on_status_changed)
		player.light.went_out.disconnect(_on_light_out)


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
			ExploreInteract.portal_found(self, portal)


func _on_enter_cell(from: Vector2i) -> void:
	var safe := in_safe_zone()
	if safe != _was_safe:
		_was_safe = safe
		_say("explore.safe_enter" if safe else "explore.safe_leave", {}, "good" if safe else "info")
	if map.is_dark(pos) and not map.is_dark(from):
		_say("explore.dark_enter", {}, "warn")
	if not map.portal_at(pos).is_empty():
		ExploreInteract.portal_here(self, map.portal_at(pos))
	if rift_run != null:
		rift_run.hazards.on_step(self, pos)
	features.on_step(self, pos)


func _on_status_changed(status_id: String, active: bool) -> void:
	_view_dirty = true
	if in_combat and active:
		return  # 전투 중 걸린 상태는 전투 기록(effect.status_on_named)이 알린다
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
