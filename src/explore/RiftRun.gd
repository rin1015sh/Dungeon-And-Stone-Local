class_name RiftRun
extends RefCounted
## 균열 한 번(인스턴스, 명세 §8.2·§8.3). 챕터마다 작은 맵(생성기 rift_chapter) + 고정 조우를 가진 ExploreSession을 만든다.
## 균열 데이터 chapters[]: {id, name_ko, desc_ko, map {size, rooms, room_size}, encounters[], field_effects[], on_enter[효과]}
## 조우(encounters[]):
##   {"kind": "battle", "monsters": [..], "guard": true}         한 번 싸움(guard = 순찰하지 않고 그 자리를 지킨다)
##   {"kind": "chain", "battles": [구성, 구성, …]}               여러 무리 — 구성마다 따로 돌아다니는 무리(보스가 낀 구성은 조우 자리 방에,
##                                                                  나머지는 그 둘레 balance rift.chain_spread_tiles 안에 서로 chain_gap_tiles 넘게 떨어져).
##                                                                  예전엔 한 무리가 이기면 바로 다음 구성과 싸우는 연전이라 맵에 한 마리인데 줄줄이 나왔다(사용자 2026-10-26)
##   {"kind": "waves", "survive_rounds": 6, "start": [..], "reinforce": {"monsters": [..], "count": [1, 2]}}  생존
##   {"kind": "guardian", "with": [..]}                          수호자(5% 미만 확률로 변종 수호자 — variant.chance)
##   {"kind": "posts", "count": n, "packs": [구성, …]}            대기 무리 n개 — 지도의 빈 곳(시작·출구·다른 조우에서 가장 먼 칸)에
##                                                                  구성 하나씩 골라 세운다. 순찰하지 않고 서서 둘러본다(RiftPosts — 조우 자리를 쓰지 않는다)
##   {"kind": "roam", "count": n, "packs": [구성, …]}             떠도는 무리 n개 — posts처럼 빈 곳에 세우되 순찰한다(사용자 2026-10-30 "균열 몬스터 빈도 늘려", RF26)
##   {"kind": "ambush", "trigger": [x, y, w, h], "packs": [..], "from": [[x, y], ..]}  매복 — 그 칸에 들어서면 나타나 쫓는다(RiftAmbush)
##   구성 = 몬스터 id 배열 또는 {"pick": [..], "count": [최소, 최대]}(무작위)
## 조우를 다 치우지 않아도 길목으로 다음 챕터에 갈 수 있다(사용자 2026-10-26). 마지막 챕터에는 처음엔 출구가 없고,
## 수호자를 쓰러뜨리면 그 자리에 바깥으로 돌아가는 탈출 포탈(rift_exit)이 생긴다(_open_escape).
## 챕터 사이는 이어진 길목(RiftPassage — 걸어 들어가면 넘어간다)이고 지나온 챕터로 돌아갈 수 있다(사용자 요청 2026-10-20).
##   떠난 챕터 세션은 상태(치운 무리·탐험·히든 피스·함정)째 보관했다가(_kept) 돌아오면 다시 붙인다.
## 탈출하면 1층(outer)의 포탈 자리로 돌아간다. 다른 탈출 방법은 없다.
## 챕터 "exit_requires": {"item", "message", "bypass": {stat, at_least, message}} — 출구를 지나려면 그 아이템이 있어야 하고 쓰인다
##   (녹색 탄광 폭약). bypass 스탯이 넘으면 아이템 없이 지난다.
## 챕터 "features": [{"id": 동굴 요소 id, "at": [x, y]}] — 그 칸에 동굴 요소(FieldFeatures — 선택지가 있는 히든 피스: 핏빛 우물).
## 챕터 "hidden"(히든 피스·벽화)은 RiftHidden, "hazards"(탐험 위험·함정)는 RiftHazards, 균열 "riddle"(수수께끼 문지기)은 RiftRiddle.
## 조우 {"riddle": true}는 태그 "riddle" — 마주치면 전투 대신 수수께끼.
## 아이템 "rift_bound": "<균열 id>" — 그 균열 밖으로 가져갈 수 없다(나갈 때 사라진다: 여신의 눈물).

var db: GameDatabase
var rift_id: String
var def: Dictionary
var outer: ExploreSession
## 지금 챕터 세션(약한 참조 — 챕터 세션이 rift_run으로 이 객체를 붙잡으므로 순환을 피한다. 화면이 세션을 붙잡는다).
var session: ExploreSession:
	get:
		return _session_ref.get_ref() as ExploreSession if _session_ref != null else null
var chapter: int = -1
var variant: bool = false            ## 변종 수호자
var remaining: Array = []            ## 이 챕터에서 아직 치우지 않은 조우 무리
var guardian_down: bool = false
var finished: bool = false
var held: Dictionary = {}              ## 출구에 필요한데 가방에 자리가 없어 손에 쥔 물건(아이템 id -> 개수). 출구에서 가방보다 먼저 쓴다
var _session_ref: WeakRef = null
var hidden: RiftHidden = RiftHidden.new()
var hidden_at: Dictionary:  ## 이 챕터의 살필 수 있는 물체 칸 -> 정의
	get:
		return hidden.at
var hazards: RiftHazards = RiftHazards.new()
var riddle: RiftRiddle = null
## 떠난 챕터: 번호 -> {"session", "remaining", "hidden_at", "hidden_under", "hazards_at"}.
## 보관한 세션의 rift_run은 비운다(이 객체 → 세션만 남아 순환 참조가 생기지 않게). 돌아오면 다시 단다.
var _kept: Dictionary = {}
var _opened: Dictionary = {}  ## exit_requires(폭약)를 이미 치른 챕터 번호 -> true(되돌아왔다 다시 지날 때 또 쓰지 않는다)


func _init(p_outer: ExploreSession, p_rift_id: String) -> void:
	outer = p_outer
	db = outer.db
	rift_id = p_rift_id
	def = db.get_entry("rifts", rift_id)
	var v: Variant = def.get("variant")
	variant = v is Dictionary and outer.rng.chance(JsonUtil.get_float(v, "chance"))
	if def.has("riddle"):
		riddle = RiftRiddle.new(db, JsonUtil.get_dict(def, "riddle"), outer.rng)


## 첫 챕터 세션을 만들어 돌려준다(받은 쪽이 붙잡아야 한다).
func start() -> ExploreSession:
	var cs := build_chapter(0)
	cs.pending_messages.push_front({"key": "explore.rift_enter", "args": {"name": JsonUtil.get_str(def, "name_ko", rift_id)}, "kind": "danger"})
	return cs


func chapters() -> Array:
	return JsonUtil.get_array(def, "chapters")


func is_last_chapter() -> bool:
	return chapter >= chapters().size() - 1


func guardian_id() -> String:
	if variant:
		return JsonUtil.get_str(JsonUtil.get_dict(def, "variant"), "monster")
	return JsonUtil.get_str(def, "guardian")


## i번째 챕터 세션을 만든다(이전 챕터 세션은 떼어 낸다).
func build_chapter(i: int) -> ExploreSession:
	_stash()
	_kept.erase(i)
	chapter = i
	var ch: Dictionary = chapters()[i]
	var fdef := chapter_floor_def(i)
	var gen: FloorGenerator = RiftBlueprintGenerator.new() if fdef["generator"] == "rift_blueprint" else RiftChapterGenerator.new()
	var map := gen.generate(db, fdef, Rng.new(outer.rng.randi_range(1, 1 << 30)))
	var cs := ExploreSession.new(db, fdef, map, outer.player, outer.clock, outer.rng, outer.effects)
	cs.companions = outer.companions
	_session_ref = weakref(cs)
	cs.rift_run = self
	RiftPassage.setup(cs, is_last_chapter(), i > 0, _floor_tile())
	cs.start()
	remaining.clear()
	var encs := JsonUtil.get_array(ch, "encounters")
	var later := {"posts": [], "roam": []}
	for k in encs.size():
		var kind := JsonUtil.get_str(encs[k], "kind") if encs[k] is Dictionary else ""
		if later.has(kind):
			later[kind].append(encs[k])  # 다른 조우를 다 세운 뒤 빈 곳에(대기 무리 다음 떠도는 무리)
			continue
		if kind == "ambush":
			cs.ambushes.append(encs[k])  # 그 칸에 들어설 때 나타난다
			continue
		remaining.append_array(_place(cs, encs[k], map.slots[mini(k, map.slots.size() - 1)] if kind != "guardian" else map.slots[-1]))
	for kind: String in ["posts", "roam"]:
		for e: Dictionary in later[kind]:
			remaining.append_array(RiftPosts.place(cs, e, compose, outer.rng, kind == "roam"))
	_apply_field_effects()
	hidden.place(cs, ch, outer.rng, i)
	RiftLoot.place(cs, ch)
	hazards.place(cs, ch, outer.rng)
	hidden.count_hazards(i, hazards)
	for f: Variant in JsonUtil.get_array(ch, "features"):  # 챕터에 놓는 동굴 요소(핏빛 우물 — 고르는 선택지가 있는 것)
		var fd: Dictionary = f if f is Dictionary else {}
		var fa := JsonUtil.get_array(fd, "at")
		cs.features.add_at(cs, JsonUtil.get_str(fd, "id"), Vector2i(int(fa[0]), int(fa[1])))
	var fx := JsonUtil.get_array(ch, "on_enter")
	if not fx.is_empty():
		var ctx := EffectContext.new(db, null, outer.player, outer.rng)
		ctx.registry = outer.effects
		outer.effects.apply_all(ctx, fx)
		for m: Dictionary in ctx.messages:
			cs.say_later(str(m["key"]), m["args"], str(m["kind"]))
	cs.say_later("explore.rift_chapter", {"rift": JsonUtil.get_str(def, "name_ko"), "chapter": JsonUtil.get_str(ch, "name_ko"),
		"n": i + 1, "total": chapters().size(), "desc": JsonUtil.get_str(ch, "desc_ko")}, "system")
	if variant and is_last_chapter():
		cs.say_later("explore.rift_variant", {}, "danger")
	return cs


## 챕터 그림 설정 = 균열 look.art(+ 챕터 battleback이 있으면 전투 뒷그림만 덮는다).
static func _chapter_art(look: Dictionary, ch: Dictionary) -> Dictionary:
	var art := JsonUtil.get_dict(look, "art")
	if JsonUtil.get_dict(ch, "battleback").is_empty():
		return art
	art = art.duplicate()
	art["battleback"] = JsonUtil.get_dict(ch, "battleback")
	return art


## 챕터의 가짜 층 정의(이름·밝기·타일·폐쇄 시각은 바깥 층과 균열 look에서).
func chapter_floor_def(i: int) -> Dictionary:
	var ch: Dictionary = chapters()[i]
	var look := JsonUtil.get_dict(def, "look").merged(JsonUtil.get_dict(ch, "look"), true)  # 챕터 look(바깥·안 밝기)이 균열 look을 덮는다
	var gen := JsonUtil.get_dict(ch, "map").duplicate(true)
	gen["tiles"] = JsonUtil.get_dict(look, "tiles").duplicate()
	var generator := "rift_blueprint" if gen.has("blueprint") else "rift_chapter"
	if gen.has("blueprint"):  # 기본 바닥(깎은 모서리·소품 밑) = 설계도의 바닥(빙하굴 바깥은 눈밭)
		gen["tiles"]["floor"] = JsonUtil.get_str(FloorMapFile.read(JsonUtil.get_str(gen, "blueprint")), "floor", JsonUtil.get_str(gen["tiles"], "floor"))
	return {"id": "%s_%s" % [rift_id, JsonUtil.get_str(ch, "id")], "floor": 0, "generator": generator,
		"name_ko": "%s · %s" % [JsonUtil.get_str(def, "name_ko"), JsonUtil.get_str(ch, "name_ko")],
		"close_hours": outer.close_hours(), "visibility_cap_m": JsonUtil.get_float(look, "visibility_cap_m", 9.0),
		"ambient_light_m": JsonUtil.get_float(look, "ambient_light_m", 6.0), "ambient_color": JsonUtil.get_str(look, "ambient_color", "#ffffff"),
		"art": _chapter_art(look, ch),
		"gen": gen, "regions": [], "spawn": {"groups_per_region": [0, 0], "max_extra_groups": 0}}


## 조우 전투가 끝났다. 균열 조우였으면 true(필드 리스폰 처리를 하지 않는다).
## killed: 이번 전투에서 쓰러뜨린 몬스터 — 수호자를 쓰러뜨리고 (동반이 남은 채) 도망쳐도 수호자는 쓰러진 것이다.
func on_battle_end(s: ExploreSession, g: FieldMonsters.Group, result: String, killed: Array[String] = []) -> bool:
	if not remaining.has(g):
		return false
	if g.tag == "ambush":
		RiftAmbush.clear(s, remaining)  # 매복 무리 하나와 싸웠다 — 이기든 도망치든 모두 사라진다
		return true
	if g.tag == "guardian" and not guardian_down and killed.has(guardian_id()):
		guardian_down = true
		_guardian_drops(s)
		_open_escape(s, g.pos)
		g.tag = "battle"  # 남은 동반은 보통 무리
	if result == Battle.RESULT_FLED:
		s.monsters.set_grace(g, s.clock.total_hours)
		return true
	if result != Battle.RESULT_VICTORY:
		return true
	if not g.waves.is_empty():
		g.monster_ids.assign(g.waves.pop_front())
		s.message.emit("explore.rift_next_wave", {"left": g.waves.size() + 1}, "danger")
		s.engage.call_deferred(g, false)
		return true
	remaining.erase(g)
	s.monsters.groups.erase(g)
	s.monsters.changed.emit()
	if g.tag == "guardian":
		guardian_down = true
		_guardian_drops(s)
		_open_escape(s, g.pos)
	return true


## 출구에서 E. 다음 챕터 세션 / 탈출이면 바깥 세션 / 아직 잠겼으면 null.
func use_exit(s: ExploreSession) -> ExploreSession:
	if s != session or finished:
		return null  # 이미 지나온 챕터 세션(길목을 밟아 넘어간 뒤 같은 자리에서 E 등)
	if not _can_leave(s, false):
		return null
	if not is_last_chapter():
		return _go(s, chapter + 1)
	finish()
	return outer


## 길목 둘레 칸에 들어섰다(ExploreSession._on_enter_cell). 넘어가면 transfer를 내고 true.
## 잠긴 출구는 바깥에서 길목 둘레로 들어설 때만 이유를 알린다(둘레 안에서 걸을 때마다 알리지 않게).
func passage_step(s: ExploreSession, from: Vector2i) -> bool:
	if s != session or finished or s.gates.sealed():  # 깨어난 보스가 길목을 막았다(BossGates — V23)
		return false
	var zone := int(db.bal("rift.passage_zone", 1))
	var d := RiftPassage.dir_at(s.map, s.pos, zone)
	if d == 0:
		return false
	var next: ExploreSession = null
	if d < 0:
		next = _go(s, chapter - 1) if chapter > 0 else null
	elif not is_last_chapter() and _can_leave(s, RiftPassage.dir_at(s.map, from, zone) == d):
		next = _go(s, chapter + 1)
	if next == null:
		return false
	s.transfer.emit(next)
	return true


## 앞으로 지날 수 있는가(조우는 남아도 된다 — RF21. 마지막 챕터는 수호자가 쓰러져야, 필요한 물건이 있으면 쓴다 — 한 챕터에 한 번). quiet면 못 지나는 이유를 알리지 않는다.
func _can_leave(s: ExploreSession, quiet: bool) -> bool:
	if is_last_chapter() and not guardian_down:
		return false  # 탈출 포탈은 수호자가 쓰러진 뒤에야 생긴다
	if _opened.has(chapter):
		return true
	var req := JsonUtil.get_dict(chapters()[chapter], "exit_requires")
	var strong := JsonUtil.get_dict(req, "bypass")  # {stat, at_least}: 그만큼 강하면 아이템 없이 지난다(녹색 탄광 — 고렙은 그냥 부순다)
	if not strong.is_empty() and outer.player.stats.get_value(JsonUtil.get_str(strong, "stat")) >= JsonUtil.get_float(strong, "at_least"):
		s.say_later(JsonUtil.get_str(strong, "message", "explore.rift_exit_forced"), {}, "system")
	elif not req.is_empty():
		var item := JsonUtil.get_str(req, "item")
		if outer.player.inventory.count(item) + int(held.get(item, 0)) <= 0:
			if not quiet:
				s.message.emit("explore.rift_exit_needs", {"item": DataNames.entry(db, "items", item)}, "warn")
			return false
		if int(held.get(item, 0)) > 0:
			held[item] = int(held[item]) - 1
		else:
			outer.player.inventory.remove(item, 1)
		s.say_later(JsonUtil.get_str(req, "message", "explore.rift_exit_used"), {"item": DataNames.entry(db, "items", item)}, "system")
	_opened[chapter] = true
	return true


## i번째 챕터로 넘어간다: 처음이면 만들고, 지나온 챕터면 보관한 세션을 다시 붙인다.
## 앞으로 가면 그 챕터의 뒤 길목(시작 자리)에서, 돌아가면 앞 길목(출구)에서 몇 걸음 안쪽에 선다. 화면은 어두워졌다 밝아진다(fade_in).
func _go(s: ExploreSession, i: int) -> ExploreSession:
	var forward := i > chapter
	var cs := build_chapter(i) if not _kept.has(i) else _restore(i)
	var gate := cs.map.entry if forward else RiftPassage.exit_portal(cs.map).get("pos", cs.map.entry) as Vector2i
	var at := RiftPassage.arrival(cs, gate, int(db.bal("rift.passage_zone", 1)), int(db.bal("rift.passage_arrive_steps", 2)))
	cs.place_at(at, RiftPassage.facing(gate, at))
	cs.fade_in = true
	cs.pending_messages.append_array(s.take_pending())
	return cs


## 지금 챕터 세션을 보관하고 떼어 낸다(필드 효과를 걷는다).
func _stash() -> void:
	var old := session
	if old == null:
		return
	_leave_field_effects()
	old.detach()
	old.rift_run = null
	_kept[chapter] = {"session": old, "remaining": remaining.duplicate(), "hidden_at": hidden.at.duplicate(),
		"hidden_under": hidden.under.duplicate(), "hazards_at": hazards.at.duplicate()}


## 보관한 i번째 챕터 세션을 다시 붙인다.
func _restore(i: int) -> ExploreSession:
	_stash()
	var k: Dictionary = _kept[i]
	_kept.erase(i)
	chapter = i
	var cs: ExploreSession = k["session"]
	cs.rift_run = self
	cs.reattach()
	_session_ref = weakref(cs)
	remaining = k["remaining"]
	hidden.at = k["hidden_at"]
	hidden.under = k["hidden_under"]
	hazards.at = k["hazards_at"]
	_apply_field_effects()
	return cs


## 가방에 들어가지 못한 전리품: 이 균열의 출구에 필요한 물건이면 손에 쥔다(잃어서 균열에 갇히지 않게). 쥐었으면 true.
## 알리지 않는다 — 부른 쪽이 item.got(_by) 뒤에 explore.rift_key_held("가방에 자리가 없어 손에 쥐었다.")를 낸다.
func keep_overflow(s: ExploreSession, item: String, count: int) -> bool:
	for ch: Variant in chapters():
		if JsonUtil.get_str(JsonUtil.get_dict(ch if ch is Dictionary else {}, "exit_requires"), "item") == item:
			held[item] = int(held.get(item, 0)) + count  # 알림은 부른 쪽이(통일된 획득 문구 + "손에 쥐었다")
			return true
	return false


## 균열을 나간다(필드 효과를 걷고 챕터 세션을 떼어 낸다).
func finish() -> void:
	finished = true
	held.clear()
	_kept.clear()
	_leave_field_effects()
	var cs := session
	if cs != null:
		cs.detach()
	for id: Variant in db.get_collection("items").keys():
		if JsonUtil.get_str(db.get_entry("items", str(id)), "rift_bound") == rift_id and outer.player.inventory.count(str(id)) > 0:
			outer.player.inventory.remove(str(id), outer.player.inventory.count(str(id)))
			outer.say_later("explore.rift_item_lost", {"item": DataNames.entry(db, "items", str(id))}, "warn")
	outer.say_later("explore.rift_left", {"name": JsonUtil.get_str(def, "name_ko")}, "good")
	outer.refresh_view()


## 디버그: 이 챕터의 조우를 모두 치운 것으로 한다(마지막 챕터면 수호자도).
func debug_clear() -> void:
	var cs := session
	cs.ambushes.clear()
	for g: FieldMonsters.Group in remaining:
		cs.monsters.groups.erase(g)
		if g.tag == "guardian":
			guardian_down = true
			_open_escape(cs, g.pos)
	remaining.clear()
	cs.monsters.changed.emit()


func _place(s: ExploreSession, enc: Variant, cell: Vector2i) -> Array[FieldMonsters.Group]:
	var e: Dictionary = enc if enc is Dictionary else {}
	var kind := JsonUtil.get_str(e, "kind", "battle")
	var ids: Array = []
	var out: Array[FieldMonsters.Group] = []
	if kind == "chain":
		return _place_packs(s, e, cell)
	match kind:
		"waves":
			ids = compose(e.get("start", []))
		"guardian":
			ids = [guardian_id()]
			ids.append_array(compose(e.get("with", [])))
		_:
			ids = compose(e.get("monsters", []))
	var g := s.monsters.add_fixed(ids, cell)
	if g == null:
		return out
	g.tag = "riddle" if JsonUtil.get_bool(e, "riddle") else kind
	g.guard = JsonUtil.get_bool(e, "guard")  # 그 자리를 지킨다
	if kind == "waves":
		g.battle_rules = {"survive_rounds": JsonUtil.get_int(e, "survive_rounds", 6), "reinforce": JsonUtil.get_dict(e, "reinforce")}
	out.append(g)
	return out


## 여러 무리(chain): 구성마다 따로 세운다 — 보스가 낀 구성(없으면 첫 구성)은 조우 자리, 나머지는 그 둘레에 흩어서.
func _place_packs(s: ExploreSession, e: Dictionary, cell: Vector2i) -> Array[FieldMonsters.Group]:
	var packs: Array = []
	for b: Variant in JsonUtil.get_array(e, "battles"):
		var ids := compose(b)
		if not ids.is_empty():
			packs.append(ids)
	var ranks: Array = db.bal("monsters.boss_ranks", [])
	var first := 0
	for k in packs.size():
		if (packs[k] as Array).any(func(id: Variant) -> bool: return ranks.has(JsonUtil.get_str(db.get_entry("monsters", str(id)), "rank"))):
			first = k
			break
	var spread := int(db.bal("rift.chain_spread_tiles", 12))
	var gap := float(db.bal("rift.chain_gap_tiles", 4))
	var used: Array[Vector2i] = [cell, s.map.entry]
	var out: Array[FieldMonsters.Group] = []
	for k in [first] + range(packs.size()).filter(func(i: int) -> bool: return i != first):
		var at := cell
		if k != first:
			at = FieldRoutes.random_cell_near(s.map, outer.rng, cell, spread,
				func(q: Vector2i) -> bool: return used.all(func(u: Vector2i) -> bool: return Vector2(q - u).length() >= gap))
			if at.x < 0:
				at = cell
		var g := s.monsters.add_fixed(packs[k], at)
		if g == null:
			continue
		g.tag = "battle"
		used.append(g.pos)
		out.append(g)
	return out


## 구성 → 몬스터 id 배열.
func compose(spec: Variant) -> Array:
	if spec is Array:
		return (spec as Array).duplicate()
	var d: Dictionary = spec if spec is Dictionary else {}
	var pool := JsonUtil.get_array(d, "pick")
	var cnt := JsonUtil.get_array(d, "count")
	var out: Array = []
	if pool.is_empty():
		return out
	for i in outer.rng.randi_range(int(cnt[0]), int(cnt[1])) if cnt.size() == 2 else 1:
		out.append(outer.rng.pick(pool))
	return out


## 수호자가 쓰러진 자리(cell)에 바깥으로 돌아가는 탈출 포탈(세로 차원문 — 그 칸 바닥과 같은 바닥의 rift_gate_<바닥 id>)을 세운다
## (이미 있으면 그대로). 화면은 tiles_changed로 그 칸을 다시 그린다.
func _open_escape(s: ExploreSession, cell: Vector2i) -> void:
	if not RiftPassage.exit_portal(s.map).is_empty():
		return
	var at := cell if s.map.is_walkable(cell) and s.map.portal_at(cell).is_empty() else FieldRoutes.random_cell_near(s.map, outer.rng, cell, 2)
	if at.x < 0:
		at = cell
	var tiles := JsonUtil.get_dict(JsonUtil.get_dict(chapter_floor_def(chapter), "gen"), "tiles")
	var under := s.map.tile_id_at(at)
	var gate := "rift_gate_" + under  # 그 바닥 위에 선 차원문(tiles.json rift_gate_<바닥 id>) — 없으면 챕터 출구 타일
	s.map.set_tile(at, gate if db.has_entry("tiles", gate) else JsonUtil.get_str(tiles, "exit", "rift_exit"))
	s.map.portals.append({"id": "rift_exit", "pos": at, "dir": "", "to_floor": 0, "kind": "rift_exit", "found": true, "under": under})
	RiftPassage._glow(s, at)  # 길목처럼 은은한 빛
	s.tiles_changed.emit(Rect2i(at, Vector2i.ONE))


func _guardian_drops(s: ExploreSession) -> void:
	var drops: Array = JsonUtil.get_array(def, "guardian_drops").duplicate()
	var numbers := JsonUtil.get_array(def, "numbers")
	if not numbers.is_empty():
		drops.append({"item": outer.rng.pick(numbers), "chance": JsonUtil.get_float(def, "numbers_chance", 0.33)})
	for d: Variant in drops:
		var dd: Dictionary = d if d is Dictionary else {}
		var item := JsonUtil.get_str(dd, "item")
		if db.has_entry("items", item) and outer.rng.chance(JsonUtil.get_float(dd, "chance")):
			var got := outer.player.inventory.add(item, 1)
			s.message.emit(ItemInfo.got_key(1) if got > 0 else "reward.bag_full", {"item": DataNames.entry(db, "items", item), "n": 1, "count": 1},
				"good" if got > 0 else "warn")


func _apply_field_effects() -> void:
	for st: Variant in JsonUtil.get_array(chapters()[chapter], "field_effects"):
		outer.player.statuses.apply(str(st))


func _leave_field_effects() -> void:
	if chapter < 0:
		return
	for st: Variant in JsonUtil.get_array(chapters()[chapter], "field_effects"):
		outer.player.statuses.remove(str(st))


## 살필 수 있는 물체(옆 칸 at). 무언가 했으면 true.
func take_hidden(cs: ExploreSession, at: Vector2i) -> bool:
	return hidden.take(cs, at, _floor_tile(), riddle)


func _floor_tile() -> String:
	return JsonUtil.get_str(JsonUtil.get_dict(JsonUtil.get_dict(def, "look"), "tiles"), "floor")
