class_name EssenceSet
extends RefCounted
## 탐험가가 흡수한 정수와, 아직 흡수하지 않은 정수(대기)를 관리한다(docs/PROMPT_FLOOR1_V2.md §3).
##   흡수: 패시브 1개 + 색에 맞는 액티브 1개(수호자 정수 = 무지갯빛 → 액티브 전부) + 굴린 스탯.
##   슬롯 = Progression.essence_slots(레벨). 패시브·액티브가 하나라도 겹치면 흡수 불가
##     (같은 몬스터의 다른 색, 같은 스킬을 쓰는 변이종 정수 포함 — 비교 키는 패시브 id와 스킬의 essence_of).
##   예외: 같은 정수의 일반 → 수호자(무지갯빛) 업그레이드는 그 자리를 바꾼다.
##   제거(삭제)는 비용이 처음 delete_cost_base, 이후 매번 × delete_cost_mult(돈 지불은 시설 몫).
##   효과는 수정자 출처 "essence:<정수 id>"로 붙이고 뗀다. 스킬은 Actor.learn_skill / forget_skill.
##   레벨이 내려가면(§5.1) 흡수한 정수 중 (흡수 수 − 슬롯 수)개가 무작위로 잠긴다("locked": true, 효과 없음, 슬롯은 계속 차지).
##   레벨이 다시 오르면 먼저 흡수한 순서대로 풀린다 — sync_slots.
## 개체를 필드로 들지 않는다(순환 참조 방지) — 바꿀 때만 Actor를 인자로 받는다.

const SOURCE_PREFIX := "essence:"

var absorbed: Array[Dictionary] = []  # 정수 사례 {"essence", "color", "stats"}
var pending: Array[Dictionary] = []   # 떨어졌지만 아직 흡수하지 않은 정수(+ "expires_at" 게임 시각, 없으면 무기한)
var deletions: int = 0


## 흡수할 수 없는 이유(문자열 키). 흡수할 수 있으면 "".
func check_absorb(a: Actor, inst: Dictionary) -> String:
	var db := a.db
	var id := JsonUtil.get_str(inst, "essence")
	if not db.has_entry("essences", id):
		return "essence.reason_unknown"
	var upgrade := upgrade_index(db, inst)
	if upgrade < 0 and absorbed.size() >= Progression.essence_slots(db, a.get_level()):
		return "essence.reason_no_slot"
	var mine := conflict_keys(db, inst)
	for i in absorbed.size():
		if i == upgrade:
			continue
		for k: String in conflict_keys(db, absorbed[i]):
			if mine.has(k):
				return "essence.reason_duplicate"
	return ""


## 흡수한다. 성공하면 "", 아니면 이유 키.
func absorb(a: Actor, inst: Dictionary) -> String:
	var why := check_absorb(a, inst)
	if not why.is_empty():
		return why
	var up := upgrade_index(a.db, inst)
	if up >= 0:
		_detach(a, absorbed[up])
		absorbed[up] = inst.duplicate(true)
		absorbed[up].erase("locked")
	else:
		absorbed.append(inst.duplicate(true))
	_attach(a, inst)
	return ""


## 대기 중인 정수 i를 흡수한다. 성공하면 대기 목록에서 뺀다.
func absorb_pending(a: Actor, i: int) -> String:
	if i < 0 or i >= pending.size():
		return "essence.reason_unknown"
	var why := absorb(a, pending[i])
	if why.is_empty():
		pending.remove_at(i)
	return why


## 흡수한 정수 i를 제거한다(삭제 비용 계산·지불은 부르는 쪽). 제거했으면 true.
func remove(a: Actor, i: int) -> bool:
	if i < 0 or i >= absorbed.size():
		return false
	_detach(a, absorbed[i])
	absorbed.remove_at(i)
	deletions += 1
	sync_slots(a)
	return true


static func is_locked(inst: Dictionary) -> bool:
	return JsonUtil.get_bool(inst, "locked")


func locked_count() -> int:
	var n := 0
	for e in absorbed:
		if is_locked(e):
			n += 1
	return n


## 레벨에 맞춰 정수 슬롯을 잠그거나 푼다. 잠글 정수는 rng로 고른다(rng가 없으면 나중에 흡수한 것부터).
## 바뀐 정수 수(잠금 + 해제).
func sync_slots(a: Actor, rng: Rng = null) -> int:
	var allowed := Progression.essence_slots(a.db, a.get_level())
	var active: Array[int] = []
	var locked: Array[int] = []
	for i in absorbed.size():
		if is_locked(absorbed[i]):
			locked.append(i)
		else:
			active.append(i)
	var changed := 0
	while active.size() > allowed:
		var k := rng.randi_range(0, active.size() - 1) if rng != null else active.size() - 1
		var idx := active[k]
		active.remove_at(k)
		_detach(a, absorbed[idx])
		absorbed[idx]["locked"] = true
		changed += 1
	while active.size() < allowed and not locked.is_empty():
		var idx: int = locked.pop_front()
		absorbed[idx].erase("locked")
		_attach(a, absorbed[idx])
		active.append(idx)
		changed += 1
	return changed


## 다음 삭제 비용(스톤).
func next_delete_cost(db: GameDatabase) -> int:
	return int(float(db.bal("essence.delete_cost_base", 5000000)) * pow(float(db.bal("essence.delete_cost_mult", 2)), deletions))


## 대기 정수를 더한다. now_hours ≥ 0이면 expire_hours 뒤에 사라진다.
func add_pending(db: GameDatabase, inst: Dictionary, now_hours: float = -1.0) -> void:
	var p := inst.duplicate(true)
	if now_hours >= 0.0:
		p["expires_at"] = now_hours + float(db.bal("essence.expire_hours", 0.5))
	pending.append(p)


## 시간이 지난 대기 정수를 지운다. 사라진 정수 id 목록.
func expire_pending(now_hours: float) -> Array[String]:
	var gone: Array[String] = []
	for i in range(pending.size() - 1, -1, -1):
		if pending[i].has("expires_at") and now_hours >= float(pending[i]["expires_at"]):
			gone.append(JsonUtil.get_str(pending[i], "essence"))
			pending.remove_at(i)
	return gone


## 정수 사례가 주는 액티브 스킬 id(색 → 하나, 무지갯빛 → 전부, unique 제외).
static func granted_skills(db: GameDatabase, inst: Dictionary) -> Array[String]:
	var def := db.get_entry("essences", JsonUtil.get_str(inst, "essence"))
	var color := JsonUtil.get_str(inst, "color")
	var all := color == str(db.bal("essence.guardian_color", "rainbow"))
	var out: Array[String] = []
	for a: Variant in JsonUtil.get_array(def, "actives"):
		var ad: Dictionary = a if a is Dictionary else {}
		var sid := JsonUtil.get_str(ad, "skill")
		if JsonUtil.get_bool(db.get_entry("skills", sid), "unique"):
			continue
		if all or JsonUtil.get_str(ad, "color") == color:
			out.append(sid)
	return out


## 중복 판정 키: "passive:<id>"와 "skill:<essence_of 또는 스킬 id>".
static func conflict_keys(db: GameDatabase, inst: Dictionary) -> PackedStringArray:
	var def := db.get_entry("essences", JsonUtil.get_str(inst, "essence"))
	var out := PackedStringArray()
	var passive := JsonUtil.get_dict(def, "passive")
	if not passive.is_empty():
		out.append("passive:" + JsonUtil.get_str(passive, "id"))
	for sid: String in granted_skills(db, inst):
		out.append("skill:" + JsonUtil.get_str(db.get_entry("skills", sid), "essence_of", sid))
	return out


## 같은 정수를 일반 → 수호자로 바꾸는 흡수면 바뀔 자리, 아니면 -1.
func upgrade_index(db: GameDatabase, inst: Dictionary) -> int:
	var rainbow := str(db.bal("essence.guardian_color", "rainbow"))
	if JsonUtil.get_str(inst, "color") != rainbow:
		return -1
	for i in absorbed.size():
		if JsonUtil.get_str(absorbed[i], "essence") == JsonUtil.get_str(inst, "essence") \
				and JsonUtil.get_str(absorbed[i], "color") != rainbow:
			return i
	return -1


func has_essence(essence_id: String) -> bool:
	for e in absorbed:
		if JsonUtil.get_str(e, "essence") == essence_id:
			return true
	return false


## 저장한 뒤 다시 붙일 때(불러오기): 효과를 처음부터 다시 단다.
func reattach_all(a: Actor) -> void:
	for e in absorbed:
		_detach(a, e)
		if not is_locked(e):
			_attach(a, e)


func to_dict() -> Dictionary:
	return {"absorbed": absorbed.duplicate(true), "pending": pending.duplicate(true), "deletions": deletions}


func load_dict(a: Actor, d: Dictionary) -> void:
	for e in absorbed:
		_detach(a, e)
	absorbed.clear()
	pending.clear()
	for v: Variant in JsonUtil.get_array(d, "absorbed"):
		if v is Dictionary:
			absorbed.append((v as Dictionary).duplicate(true))
	for v: Variant in JsonUtil.get_array(d, "pending"):
		if v is Dictionary:
			pending.append((v as Dictionary).duplicate(true))
	deletions = JsonUtil.get_int(d, "deletions")
	reattach_all(a)


func _attach(a: Actor, inst: Dictionary) -> void:
	var db := a.db
	var id := JsonUtil.get_str(inst, "essence")
	var def := db.get_entry("essences", id)
	var src := SOURCE_PREFIX + id
	a.stats.add_modifiers_from_data(src, JsonUtil.get_array(JsonUtil.get_dict(def, "passive"), "modifiers"))
	var st := JsonUtil.get_dict(inst, "stats")
	for k: String in st:
		a.stats.add_modifier(Modifier.new(src, k, float(st[k])))
	var res := JsonUtil.get_dict(def, "resource_mods")
	for r: String in res:
		if not is_zero_approx(float(res[r])):
			a.stats.add_modifier(Modifier.new(src, "max:" + r, float(res[r])))
	for sid: String in granted_skills(db, inst):
		a.learn_skill(sid)


func _detach(a: Actor, inst: Dictionary) -> void:
	a.stats.remove_source(SOURCE_PREFIX + JsonUtil.get_str(inst, "essence"))
	for sid: String in granted_skills(a.db, inst):
		a.forget_skill(sid)
