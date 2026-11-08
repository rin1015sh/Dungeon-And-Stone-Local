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
signal fx(kind: String, at: Vector2i, group_id: int)  ## 지도 위 짧은 움직임(FieldFx — bang · rings · burst · snap · stars). 글 대신 화면으로(2026-11-08)
signal sound(key: String, at: Vector2i)  ## 들리는 소리(비명·싸움 — FieldParties). 글이 아니라 소리로만(data/audio.json sfx)
signal tiles_changed(cells: Rect2i)  ## 원정 중에 타일이 바뀌었다(새 시체 등) — 화면이 그 칸을 다시 그린다
signal party_met(group: FieldMonsters.Group)  ## 탐험가 무리에 닿았다(FieldParties) — 화면이 FieldPartyMeet 선택지를 띄우고 act를 부른다
signal monument_choice(at: Vector2i)  ## 기념비에서 할 일이 있다(Monument — 마석·계층석 바치기·계층군주 부르기) — 화면이 고르게 하고 Monument.act를 부른다
signal feature_choice(at: Vector2i)  ## 동굴 요소의 행동이 여럿이다(맑은 샘 등) — 화면이 고르게 하고 features.act를 부른다
signal lord_rising(group: FieldMonsters.Group, then: Callable)  ## 계층군주 소환(LordWatch): 화면이 연출(LordRiseFx)을 보인 뒤 then을 부른다
signal coin_guess(then: Callable)  ## 동전 앞뒤 고르기(상자 — RiftChest): 화면이 W/S 선택 창을 띄우고 then(0 앞면 · 1 뒷면 · -1 그만둠)을 부른다
signal coin_toss(heads: bool, then: Callable)  ## 동전 던지기(CoinToss — 상자 등): 화면이 동전 연출(CoinFlip)을 보인 뒤 then을 부른다

var coin_can_back := true  ## 지금 묻는 동전 고르기에서 Esc(그만둠)를 받는가(guess가 정한다 — 화면이 본다)
var db: GameDatabase
var floor_def: Dictionary
var map: FloorMap
var player: PlayerCharacter
var companions: Array[PlayerCharacter] = []  ## 함께 싸우는 동료(사용자 2026-10-25) — 시간·걸음·휴식·전투로 허기·피로가 플레이어와 같이 변한다(2026-10-27, C19)
var clock: GameClock
var rng: Rng
var effects: EffectRegistry
var lights: LightField
var monsters: FieldMonsters
var lord: LordWatch  ## 계층군주 소환 감시(층 JSON "lord")
var rifts: RiftWatch = RiftWatch.new()  ## 균열 포탈(자연·강제 개방)
var gates := BossGates.new()  ## 보스 방 문 닫힘(V23) — 깨어난 보스 무리 id → 막은 칸
var rift_run: RiftRun = null            ## 균열 챕터 세션이면 그 균열
var scavenged: Dictionary = {}          ## 뒤진 균열 장식 칸 Vector2i → true(RiftScavenge)
var loot: Dictionary = {}               ## 균열에 놓인 물건 칸 Vector2i → {item, count}(RiftLoot)
var below: ExploreSession = null       ## 아래층 세션(이 층으로 올라온 곳 — FloorTravel). 위층만 아래층을 붙잡는다
var below_at: Vector2i = Vector2i(-1, -1)  ## 아래층에서 올라온 포탈 칸(내려가면 여기 선다)
var blades: GrooveBlades = null
var maws: MawTraps = null                ## 아귀 입 함정(층 JSON maws — FL15)
var goal: FloorGoal = null              ## 층 목표(층 JSON goal — 종 셋 → 고개 쇠문, FL18)
var ambush: RouteAmbush = null          ## 길목 매복(route_spots.ambush — FL18)
var first_side: int = -1  ## 다음 전투에서 먼저 움직이는 쪽(Battle.FIRST_NONE = 정정당당 — 숨어 기다린 매복이면 플레이어, CB3). 화면이 읽고 되돌린다
var _was_cover: bool = false
var desert: DesertRules = null            ## 바위사막 열기 · 모래 바다 진동(층 JSON desert — LD14)
var forks: RouteForks = null              ## 갈림길 규칙(route_spots.forks — 야수의 소굴, LD11)
var watch: RouteWatch = null            ## 망대 경보(route_spots.watch — 고블린 숲, FL22)
var traits: MonsterTraits = MonsterTraits.new()  ## 몬스터 지도 행동(덫 깔기 · 망대로 달리기 · 돌진 · 까마귀 · 따라다니기 · 밤 지역 — 2층 새 몬스터)
var terrain: FieldTerrain = null         ## 변하는 지형(층 JSON terrain — 물때 · 밤 안개 · 무른 땅 · 넋불 · 장례 행렬, FL14)
var grave: GraveWake = null             ## 망자의 땅 비석(층 JSON grave_wake — 원정 5일 차에 데스나이트)         ## 칼날 홈을 오가는 칼날(강철의 묘 — 챕터 "groove_blades", RiftRun이 놓는다)
var ambushes: Array = []                ## 균열 매복 중 아직 터지지 않은 것(RiftAmbush — 조우 정의)
var kills: Dictionary = {}              ## 이번 원정에서 잡은 몬스터 id → 마리 수(기념비 마석 바치기 — Monument)
var parties: FieldParties = FieldParties.new()  ## 다른 탐험가 무리·약탈자·새로 생기는 시체(층 JSON explorers)
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
var fade_in: bool = false  ## 화면이 붙을 때 검은 화면에서 밝아진다(균열 길목을 지나왔다 — RiftRun._go)

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
	monsters.alerted.connect(_on_monster_alerted)
	lord = LordWatch.new(JsonUtil.get_dict(floor_def, "lord"))
	features.setup(self)
	parties.setup(self)
	realtime = RealtimeDriver.new()
	player.pool.set_context("dungeon", true)
	player.died.connect(_on_player_died)
	player.status_changed.connect(_on_status_changed)
	player.light.went_out.connect(_on_light_out)


## 몬스터가 의심 끝에 쫓기 시작했다: 글이 아니라 소리로(몬스터 behavior alert_sfx, 없으면 monster_alert — V21).
func _on_monster_alerted(g: FieldMonsters.Group) -> void:
	var beh := JsonUtil.get_dict(db.get_entry("monsters", g.leader()), "behavior")
	sound.emit(JsonUtil.get_str(beh, "alert_sfx", "monster_alert"), g.pos)
	fx.emit("bang", g.pos, g.id)


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
	RouteSpots.place_features(self)
	RouteSpots.scatter(self)
	RouteSpots.scatter_hazards(self)
	forks = RouteForks.setup(self)  # 갈림길 규칙(야수의 소굴 — LD11)
	desert = DesertRules.setup(self)  # 바위사막(LD14)
	terrain = FieldTerrain.setup(self)
	maws = MawTraps.build(self)
	goal = FloorGoal.setup(self)
	ambush = RouteAmbush.build(self)
	if floor_def.has("grave_wake"):
		grave = GraveWake.new()
		grave.setup(self, JsonUtil.get_dict(floor_def, "grave_wake"))
	_was_safe = in_safe_zone()
	if monsters_enabled:
		monsters.spawn_initial(pos)
		features.spawn_guards(self)
		RouteSpots.place_guards(self)
		parties.start(self)
	watch = RouteWatch.build(self)
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


## 한 칸을 가는 데 드는 게임 시간 = 기본값(민첩과 무관 — 사용자 결정 2026-10-17). 몬스터도 같은 값으로 움직인다.
func move_hours() -> float:
	return float(db.bal("explore.move_hours_base", 0.02))


## 한곳에 함께 있는 탐험가 수 = 플레이어 + 곁에서 함께 다니는 탐험가 무리(FieldParties).
func party_size() -> int:
	return parties.party_size(self)


func found_count(list: Array[Dictionary]) -> int:
	var n := 0
	for rec: Dictionary in list:
		if bool(rec.get("found", false)):
			n += 1
	return n


# ── 행동 ─────────────────────────────────────────────────

## 실시간 진행: 화면이 매 프레임 실제 경과 초를 넘긴다. 시간 흐름으로 시야가 바뀌었으면 다시 계산한다.
func tick_realtime(real_sec: float) -> void:
	if blades != null:
		blades.tick(self, realtime.frame_sec(self, real_sec))
	if maws != null:
		maws.tick(self, realtime.frame_sec(self, real_sec))
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
	PlayerMotion.move_by(self, dir.normalized() * sec * realtime.hours_per_sec(self) / move_hours() * map.def_at(pos).move_mult)  # 진창은 느리다(타일 move_mult)


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
	_party_fatigue(Fatigue.DUNGEON_STEP, 1.0)  # 피로도 연결 지점(규칙 미정 — null이면 변화 없음)
	moved.emit(from, cell)
	refresh_view()
	_on_enter_cell(from)
	if terrain != null:
		terrain.on_enter(self, from, cell)
	if ambush != null:
		ambush.on_enter(self, cell)
	if watch != null:
		watch.on_enter(self, cell)
	if desert != null:
		desert.on_enter(self, cell)


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
			for mate in companions:
				mate.pool.tick("rest", h)
			_party_fatigue(Fatigue.DUNGEON_REST_HOUR, h, bonus * h)
			pass_time(h)
	else:
		_say("explore.rest_unsafe", {"hours": hours}, "warn")
		for i in hours:
			_party_fatigue(Fatigue.DUNGEON_REST_HOUR, 1.0, bonus)
			pass_time(1.0)
			if ended or in_combat:
				break
			if monsters_enabled and rng.chance(float(db.bal("monsters.rest_ambush_chance_per_hour", 0.04)) * parties.watch_mult(self)):
				var g := monsters.ambush_near(pos)
				if g != null:
					_say("explore.ambush", {}, "danger")
					engage(g, false)
					break
	if not ended:
		refresh_view()


## on = 먹이거나 쓸 아군(Tab 메뉴에서 고른 아군 — 동료도 먹어야 한다, C19). 빛을 내는 물건은 늘 플레이어(시야는 플레이어 빛).
func use_item(item_id: String, on: Actor = null) -> bool:
	if ended or in_combat:
		return false
	var who: Actor = player if on == null or _gives_light(item_id) else on
	var ctx := ItemUser.use(effects, player, item_id, rng, who)
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


func _gives_light(item_id: String) -> bool:
	for e: Variant in JsonUtil.get_array(db.get_entry("items", item_id), "use_effects"):
		if e is Dictionary and JsonUtil.get_str(e, "type") == "light_source":
			return true
	return false


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
		for mate in companions:
			mate.pool.set_context("dungeon", true)  # 동료는 세션이 생긴 뒤에 붙는다(Main·균열·디버그) — 허기가 미궁에서 돌게
			mate.advance_hours(h)  # 동료도 허기가 줄고 상태·재생이 흐른다
		_party_fatigue(Fatigue.DUNGEON_HOUR, h)
		_bury_starved()
		time_passed.emit(h)
		if terrain != null:
			terrain.update(self)
		if desert != null:
			desert.update(self, h)
	if not ended:
		_check_closing()
	if monsters_enabled and not ended and not in_combat and h > 0.0:
		lord.update(self, h)
		if grave != null:
			grave.update(self)
		rifts.update(self, h)
		parties.update(self, h)
		monsters.set_player_stealth(FieldStealth.of(self))
		var hid := FieldStealth.in_cover(self)
		if hid != _was_cover:  # 엄폐에 들거나 나왔다 — 몸 흐림을 다시 그린다(LD8)
			_was_cover = hid
			refresh_view()
		monsters.set_player_marks(player.statuses.ids())
		monsters.set_player_moving(FieldStealth.moving(self))
		var g := monsters.update(fpos, h, clock.total_hours, in_safe_zone())
		traits.tick(self)
		MonsterSnares.update(self)
		if g != null:
			first_side = Combatant.SIDE_PARTY if FieldStealth.springs_ambush(self, g) else Battle.FIRST_NONE
			engage(g, false)


## 시야를 다시 계산하고 탐험 기록·발견을 갱신한다.
func refresh_view() -> void:
	vision_m = Vision.radius_m(db, floor_def, map, player, pos)
	if lord.is_active():
		vision_m = minf(vision_m, lord.vision_cap_m())
	if terrain != null:
		vision_m = terrain.vision_cap(self, vision_m)
	if desert != null:
		vision_m = desert.vision_cap(self, vision_m)  # 데쓰웜 모래 폭풍(LD15)
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
	var side := first_side
	first_side = Battle.FIRST_NONE  # 매복 선공은 이번 조우에만(CB3)
	if in_combat or ended or group == null:
		return
	if rift_run != null and rift_run.riddle != null and rift_run.riddle.blocks(group):
		riddle_asked.emit(group)
		return
	if parties.meets(self, group):
		return
	first_side = side
	in_combat = true
	_rewarded = false
	realtime.tick(self, 0.0)
	encounter.emit(group, party_first)


## 보스가 깨어났다(등장 연출 — BossReveal): 그 방의 문목을 창살로 막는다(V23). 막은 칸이 있으면 true.
func close_boss_gates(g: FieldMonsters.Group) -> bool:
	var cells := gates.close(map, g, pos, db, monsters.groups)
	_cells_changed(cells)
	if not cells.is_empty():
		sound.emit("boss_gate", g.pos)
	return not cells.is_empty()


func _cells_changed(cells: Array[Vector2i]) -> void:
	if cells.is_empty():
		return
	var box := Rect2i(cells[0], Vector2i.ONE)
	for c in cells:
		box = box.expand(c).expand(c + Vector2i.ONE)
	tiles_changed.emit(box)


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
	for id in killed:
		kills[id] = int(kills.get(id, 0)) + 1
	var mult := JsonUtil.get_float(group.battle_rules, "essence_mult", 1.0) if group != null else 1.0
	if defer_drops:
		battle_drops = DropPickup.roll(db, killed, rng, rift_run != null, mult, colors, player)
	for m: Dictionary in Rewards.grant(player, killed, rng, clock.total_hours, rift_run != null, mult, colors, not defer_drops):
		if str(m["key"]) == "reward.bag_full" and rift_run != null \
				and rift_run.keep_overflow(self, str(m["args"].get("item_id", "")), int(m["args"].get("count", 1))):
			var held_n := int(m["args"].get("count", 1))  # 출구에 필요한 물건은 손에 쥐었다(RiftRun.held)
			var got_m := DropPickup._m(ItemInfo.got_key(held_n), {"item": m["args"].get("item", ""), "n": held_n}, "good")
			for mm: Dictionary in [got_m, DropPickup._m("explore.rift_key_held", {}, "info")]:
				message.emit(str(mm["key"]), mm["args"], str(mm["kind"]))
				out.append(mm)
			continue
		message.emit(str(m["key"]), m["args"], str(m["kind"]))
		out.append(m)
	return out


## 전투 장면에서 드롭을 pc가 받는다(정수 흡수 · 가방 — 넘친 균열 출구 물건은 손에 쥔다). 안내를 내보내고 돌려준다.
func take_drop(drop: Dictionary, pc: PlayerCharacter) -> Dictionary:
	var to := pc if str(drop.get("kind")) == "essence" else player  # 물건은 공용 가방(플레이어 것)으로
	var m := DropPickup.take(drop, to)
	if int(m.get("left", 0)) > 0 and rift_run != null and rift_run.keep_overflow(self, str(drop.get("id")), int(m["left"])):
		var held_n := int(drop.get("count", 1))
		m = DropPickup._m(ItemInfo.got_key(held_n, true), {"who": to.display_name, "item": DataNames.entry(db, "items", str(drop.get("id"))), "n": held_n}, "good")
		message.emit(str(m["key"]), m["args"], str(m["kind"]))
		message.emit("explore.rift_key_held", {}, "info")
		return m
	if str(drop.get("kind")) == "item" and not m.has("left") and StoneTally.is_stone(db, str(drop.get("id"))):
		m["stone"] = {"id": str(drop.get("id")), "n": int(drop.get("count", 1))}  # 마석은 한 줄로 모아 알린다(CombatDrops → announce_stones)
		return m
	message.emit(str(m["key"]), m["args"], str(m["kind"]))
	return m


## 전투 뒤 모은 마석 획득 한 줄을 기록에 남기고 돌려준다(StoneTally). tally = {id: 개수}.
func announce_stones(tally: Dictionary) -> Dictionary:
	var m := StoneTally.message(db, tally)
	if not m.is_empty():
		message.emit(str(m["key"]), m["args"], str(m["kind"]))
	return m


## 두고 간다(정수는 흩어지고 전리품은 사라진다). reason = 아무도 받을 수 없던 이유 키.
func leave_drop(drop: Dictionary, reason: String = "") -> Dictionary:
	var m := DropPickup.leave(db, drop, reason)
	message.emit(str(m["key"]), m["args"], str(m["kind"]))
	return m


func resolve_encounter(group: FieldMonsters.Group, result: String, turns: int, killed: Array[String] = []) -> void:
	in_combat = false
	_party_fatigue(Fatigue.DUNGEON_COMBAT_TURN, float(turns))
	if result == Battle.RESULT_FLED and group != null and not killed.is_empty():
		for id in killed:
			group.monster_ids.erase(id)
		if group.monster_ids.is_empty():
			result = Battle.RESULT_VICTORY
	var chained := result == Battle.RESULT_VICTORY and group != null and not group.waves.is_empty()  # 연전: 다음 웨이브까지 맵 시간 없이(RF7)
	if not _rewarded:
		grant_battle_rewards(group, killed)
	if desert != null:
		desert.on_kills(self, killed)  # 샌드웜 셋 → 데쓰웜(LD15)
	_rewarded = false
	parties.on_battle_end(self, group, result)
	if lord.on_battle_end(self, group, result) or (rift_run != null and rift_run.on_battle_end(self, group, result, killed)):
		pass
	elif result == Battle.RESULT_VICTORY:
		monsters.remove(group, clock.total_hours)
	elif result == Battle.RESULT_FLED:
		monsters.set_flee_grace(group, clock.total_hours)  # 도주 = 전투 화면을 벗어날 뿐 — 무리는 물러나지 않는다
	if group != null and gates.at.has(group.id) and not monsters.groups.has(group):
		_cells_changed(gates.open(map, group.id))  # 보스를 쓰러뜨렸다 — 창살이 열린다
	if ended:
		return
	if not chained:
		var spent := turns * float(db.bal("combat.hours_per_turn", 0.01))
		monsters.hold_contacts(clock.total_hours + spent + float(db.bal("combat.after_battle_hold_hours", 0.15)))  # 다음 전투 전에 탐험 화면을 한 번 거친다
		pass_time(spent)
	if not ended:
		refresh_view()


## 화면이 아직 없을 때(새 챕터 세션) 남길 메시지. 화면이 붙으면 take_pending으로 꺼내 보여 준다.
func say_later(key: String, args: Dictionary = {}, kind: String = "info") -> void:
	pending_messages.append({"key": key, "args": args, "kind": kind})


func take_pending() -> Array[Dictionary]:
	var out := pending_messages.duplicate()
	pending_messages.clear()
	return out


## 시간 없이 그 칸에 세운다(화면이 붙기 전 — 균열 길목을 지나 도착할 때). 칸에 들어선 일로 치지 않는다.
func place_at(cell: Vector2i, face: Vector2i) -> void:
	pos = cell
	fpos = Kinematics.center_of(cell)
	facing = face
	_was_safe = in_safe_zone()


## 보관했던 균열 챕터 세션을 다시 쓴다(detach를 되돌린다 — RiftRun._restore).
func reattach() -> void:
	ended = false
	player.pool.set_context("dungeon", true)
	if not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
		player.status_changed.connect(_on_status_changed)
		player.light.went_out.connect(_on_light_out)


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
	if rift_run != null and rift_run.passage_step(self, from):
		return  # 길목을 지나 다른 챕터로 넘어갔다
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
		if not ambushes.is_empty():
			rift_run.remaining.append_array(RiftAmbush.on_step(self, rift_run.compose))
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


## 계층군주 소환 연출: 받는 화면이 없으면(테스트·시뮬) 바로 then.
func lord_rise(group: FieldMonsters.Group, then: Callable) -> void:
	if lord_rising.get_connections().is_empty():
		then.call()
	else:
		lord_rising.emit(group, then)


## 동전 앞뒤를 고르게 한다: 받는 화면이 없으면(테스트·시뮬) 앞면(0)을 고른 것으로.
## can_back = 화면이 Esc(그만둠 -1)를 받는가(아귀 입처럼 피할 수 없으면 false — coin_can_back로 화면이 본다).
func guess(then: Callable, can_back: bool = true) -> void:
	coin_can_back = can_back
	if coin_guess.get_connections().is_empty():
		then.call(0)
	else:
		coin_guess.emit(then)


## 동전 결과를 연출과 함께: 화면이 coin_toss를 받으면 동전을 던져 보인 뒤 then(결과 적용)을 부르고, 받는 화면이 없으면(테스트·시뮬) 바로 부른다.
func toss(heads: bool, then: Callable) -> void:
	if coin_toss.get_connections().is_empty():
		then.call()
	else:
		coin_toss.emit(heads, then)


func _on_player_died(cause: String) -> void:
	ended = true
	_say("explore.died", {}, "danger")
	player_died.emit(cause)


## 플레이어와 동료 모두의 피로(미궁 규칙 key × amount, 모닥불 같은 덤 extra).
func _party_fatigue(key: String, amount: float, extra: float = 0.0) -> void:
	for pc: PlayerCharacter in [player] + companions:
		if pc.dead:
			continue
		pc.fatigue.on_dungeon(key, amount)
		if not is_zero_approx(extra):
			pc.fatigue.add(extra, "rest_bonus")


## 전투 밖에서 굶어 쓰러진 동료는 파티에서 빠진다(전투 중 죽음은 ExploreScreen._bury_mates).
func _bury_starved() -> void:
	for mate: PlayerCharacter in companions.duplicate():
		if mate.dead:
			companions.erase(mate)
			_say("party.mate_died", {"name": mate.display_name}, "danger")


func _say(key: String, args: Dictionary = {}, kind: String = "info") -> void:
	message.emit(key, args, kind)
