class_name RiftRun
extends RefCounted
## 균열 한 번(인스턴스, 명세 §8.2·§8.3). 챕터마다 작은 맵(생성기 rift_chapter) + 고정 조우를 가진 ExploreSession을 만든다.
## 균열 데이터 chapters[]: {id, name_ko, desc_ko, map {size, rooms, room_size}, encounters[], field_effects[], on_enter[효과]}
## 조우(encounters[]):
##   {"kind": "battle", "monsters": [..]}                       한 번 싸움
##   {"kind": "chain", "battles": [구성, 구성, …]}               연전 — 이기면 쉬지 않고 다음 구성과 바로 싸운다
##   {"kind": "waves", "survive_rounds": 6, "start": [..], "reinforce": {"monsters": [..], "count": [1, 2]}}  생존
##   {"kind": "guardian", "with": [..]}                          수호자(5% 미만 확률로 변종 수호자 — variant.chance)
##   구성 = 몬스터 id 배열 또는 {"pick": [..], "count": [최소, 최대]}(무작위)
## 챕터의 조우를 다 치우면 출구(rift_exit)가 열리고, 마지막 챕터에서 수호자를 쓰러뜨리면 출구가 탈출 포탈이 된다.
## 탈출하면 1층(outer)의 포탈 자리로 돌아간다. 다른 탈출 방법은 없다.
## 챕터 "exit_requires": {"item", "message", "bypass": {stat, at_least, message}} — 출구를 지나려면 그 아이템이 있어야 하고 쓰인다
##   (핏빛성채 뿔피리, 녹색 탄광 폭약). bypass 스탯이 넘으면 아이템 없이 지난다.
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
	var old := session
	if old != null:
		_leave_field_effects()
		old.detach()
	chapter = i
	var ch: Dictionary = chapters()[i]
	var fdef := chapter_floor_def(i)
	var gen := RiftChapterGenerator.new()
	var map := gen.generate(db, fdef, Rng.new(outer.rng.randi_range(1, 1 << 30)))
	var cs := ExploreSession.new(db, fdef, map, outer.player, outer.clock, outer.rng, outer.effects)
	_session_ref = weakref(cs)
	cs.rift_run = self
	cs.start()
	remaining.clear()
	var encs := JsonUtil.get_array(ch, "encounters")
	for k in encs.size():
		var g := _place(cs, encs[k], map.slots[mini(k, map.slots.size() - 1)] if encs[k] is Dictionary and JsonUtil.get_str(encs[k], "kind") != "guardian" else map.slots[-1])
		if g != null:
			remaining.append(g)
	for st: Variant in JsonUtil.get_array(ch, "field_effects"):
		outer.player.statuses.apply(str(st))
	hidden.place(cs, ch, outer.rng)
	hazards.place(cs, ch, _floor_tile(), outer.rng)
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


## 챕터의 가짜 층 정의(이름·밝기·타일·폐쇄 시각은 바깥 층과 균열 look에서).
func chapter_floor_def(i: int) -> Dictionary:
	var ch: Dictionary = chapters()[i]
	var look := JsonUtil.get_dict(def, "look")
	var gen := JsonUtil.get_dict(ch, "map").duplicate(true)
	gen["tiles"] = JsonUtil.get_dict(look, "tiles")
	return {"id": "%s_%s" % [rift_id, JsonUtil.get_str(ch, "id")], "floor": 0, "generator": "rift_chapter",
		"name_ko": "%s · %s" % [JsonUtil.get_str(def, "name_ko"), JsonUtil.get_str(ch, "name_ko")],
		"close_hours": outer.close_hours(), "visibility_cap_m": JsonUtil.get_float(look, "visibility_cap_m", 9.0),
		"ambient_light_m": JsonUtil.get_float(look, "ambient_light_m", 6.0), "ambient_color": JsonUtil.get_str(look, "ambient_color", "#ffffff"),
		"art": JsonUtil.get_dict(look, "art"),
		"gen": gen, "regions": [], "spawn": {"groups_per_region": [0, 0], "max_extra_groups": 0}}


## 조우 전투가 끝났다. 균열 조우였으면 true(필드 리스폰 처리를 하지 않는다).
## killed: 이번 전투에서 쓰러뜨린 몬스터 — 수호자를 쓰러뜨리고 (동반이 남은 채) 도망쳐도 수호자는 쓰러진 것이다.
func on_battle_end(s: ExploreSession, g: FieldMonsters.Group, result: String, killed: Array[String] = []) -> bool:
	if not remaining.has(g):
		return false
	if g.tag == "guardian" and not guardian_down and killed.has(guardian_id()):
		guardian_down = true
		_guardian_drops(s)
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
	if remaining.is_empty():
		s.message.emit("explore.rift_exit_escape" if is_last_chapter() else "explore.rift_exit_open", {}, "good")
	return true


## 출구에서 E. 다음 챕터 세션 / 탈출이면 바깥 세션 / 아직 잠겼으면 null.
func use_exit(s: ExploreSession) -> ExploreSession:
	if not remaining.is_empty() or (is_last_chapter() and not guardian_down):
		s.message.emit("explore.rift_exit_locked", {"left": remaining.size()}, "warn")
		return null
	var req := JsonUtil.get_dict(chapters()[chapter], "exit_requires")
	var strong := JsonUtil.get_dict(req, "bypass")  # {stat, at_least}: 그만큼 강하면 아이템 없이 지난다(녹색 탄광 — 고렙은 그냥 부순다)
	if not strong.is_empty() and outer.player.stats.get_value(JsonUtil.get_str(strong, "stat")) >= JsonUtil.get_float(strong, "at_least"):
		s.say_later(JsonUtil.get_str(strong, "message", "explore.rift_exit_forced"), {}, "system")
	elif not req.is_empty():
		var item := JsonUtil.get_str(req, "item")
		if outer.player.inventory.count(item) + int(held.get(item, 0)) <= 0:
			s.message.emit("explore.rift_exit_needs", {"item": DataNames.entry(db, "items", item)}, "warn")
			return null
		if int(held.get(item, 0)) > 0:
			held[item] = int(held[item]) - 1
		else:
			outer.player.inventory.remove(item, 1)
		s.say_later(JsonUtil.get_str(req, "message", "explore.rift_exit_used"), {"item": DataNames.entry(db, "items", item)}, "system")
	if not is_last_chapter():
		var next := build_chapter(chapter + 1)
		next.pending_messages.append_array(s.take_pending())
		return next
	finish()
	return outer


## 가방에 들어가지 못한 전리품: 이 균열의 출구에 필요한 물건이면 손에 쥔다(잃어서 균열에 갇히지 않게). 쥐었으면 true.
func keep_overflow(s: ExploreSession, item: String, count: int) -> bool:
	for ch: Variant in chapters():
		if JsonUtil.get_str(JsonUtil.get_dict(ch if ch is Dictionary else {}, "exit_requires"), "item") == item:
			held[item] = int(held.get(item, 0)) + count
			s.message.emit("explore.rift_key_held", {"item": DataNames.entry(db, "items", item)}, "good")
			return true
	return false


## 균열을 나간다(필드 효과를 걷고 챕터 세션을 떼어 낸다).
func finish() -> void:
	finished = true
	held.clear()
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
	for g: FieldMonsters.Group in remaining:
		cs.monsters.groups.erase(g)
		if g.tag == "guardian":
			guardian_down = true
	remaining.clear()
	cs.monsters.changed.emit()


func _place(s: ExploreSession, enc: Variant, cell: Vector2i) -> FieldMonsters.Group:
	var e: Dictionary = enc if enc is Dictionary else {}
	var kind := JsonUtil.get_str(e, "kind", "battle")
	var ids: Array = []
	var waves: Array = []
	match kind:
		"chain":
			for b: Variant in JsonUtil.get_array(e, "battles"):
				waves.append(compose(b))
			ids = waves.pop_front() if not waves.is_empty() else []
		"waves":
			ids = compose(e.get("start", []))
		"guardian":
			ids = [guardian_id()]
			ids.append_array(compose(e.get("with", [])))
		_:
			ids = compose(e.get("monsters", []))
	var g := s.monsters.add_fixed(ids, cell)
	if g == null:
		return null
	g.tag = "riddle" if JsonUtil.get_bool(e, "riddle") else kind
	g.waves = waves
	if kind == "waves":
		g.battle_rules = {"survive_rounds": JsonUtil.get_int(e, "survive_rounds", 6), "reinforce": JsonUtil.get_dict(e, "reinforce")}
	return g


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
			s.message.emit("reward.loot" if got > 0 else "reward.bag_full", {"item": DataNames.entry(db, "items", item), "count": 1},
				"good" if got > 0 else "warn")


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
