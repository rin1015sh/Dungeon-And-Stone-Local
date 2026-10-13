class_name RiftRules
extends RefCounted
## 검사 규칙: 균열(rifts/*.json, RiftRun 형식) — 개방 마석·모양(타일)·챕터·조우·수호자·드롭,
## 수수께끼(RiftRiddle)·탐험 위험과 함정(RiftHazards)·히든 피스와 벽화(RiftHidden)·출구 조건(exit_requires).

const KINDS := ["battle", "chain", "waves", "guardian"]


static func run(v: ValidatorBase) -> void:
	for id: String in v.entries("rifts"):
		_rift(v, id, v.db.get_entry("rifts", id))


static func _rift(v: ValidatorBase, id: String, r: Dictionary) -> void:
	var w := "rifts/" + id
	if JsonUtil.get_int(r, "host_floor") < 1:
		v.err(w, "host_floor는 1 이상")
	if JsonUtil.get_float(r, "weight", 1.0) <= 0.0:
		v.err(w, "weight는 양수")
	var fo := JsonUtil.get_dict(r, "force_open")
	if not fo.is_empty():
		v.ref(w + ".force_open", "items", fo.get("item"))
	for k in ["floor", "wall", "exit"]:
		v.ref(w + ".look.tiles", "tiles", JsonUtil.get_dict(JsonUtil.get_dict(r, "look"), "tiles").get(k))
	v.ref(w + ".guardian", "monsters", r.get("guardian"))
	var va: Variant = r.get("variant")
	if va is Dictionary:
		v.ref(w + ".variant", "monsters", (va as Dictionary).get("monster"))
		v.check_chance(w + ".variant", (va as Dictionary).get("chance"))
	for d: Variant in JsonUtil.get_array(r, "guardian_drops"):
		v.ref(w + ".guardian_drops", "items", (d as Dictionary).get("item") if d is Dictionary else d)
		v.check_chance(w + ".guardian_drops", (d as Dictionary).get("chance") if d is Dictionary else null)
	for n: Variant in JsonUtil.get_array(r, "numbers"):
		v.ref(w + ".numbers", "items", n)
	var has_riddle := r.has("riddle")
	if has_riddle:
		_riddle(v, w + ".riddle", JsonUtil.get_dict(r, "riddle"))
	var chapters := JsonUtil.get_array(r, "chapters")
	if chapters.is_empty():
		v.err(w, "chapters가 비었다")
	for i in chapters.size():
		var ch: Dictionary = chapters[i] if chapters[i] is Dictionary else {}
		var cw := "%s.chapters[%d]" % [w, i]
		var encs := JsonUtil.get_array(ch, "encounters")
		if encs.is_empty():
			v.err(cw, "encounters가 비었다")
		var guardians := 0
		for e: Variant in encs:
			var ed: Dictionary = e if e is Dictionary else {}
			var kind := JsonUtil.get_str(ed, "kind", "battle")
			if not kind in KINDS:
				v.err(cw, "조우 kind '%s'는 %s 중 하나" % [kind, KINDS])
			if kind == "guardian":
				guardians += 1
			for spec: Variant in [ed.get("monsters", []), ed.get("start", []), ed.get("with", [])] + JsonUtil.get_array(ed, "battles"):
				_composition(v, cw, spec)
			_composition(v, cw, JsonUtil.get_dict(ed, "reinforce").get("monsters", []))
			if kind == "waves" and JsonUtil.get_int(ed, "survive_rounds") < 1:
				v.err(cw, "waves: survive_rounds는 1 이상")
			if ed.has("riddle") and not (ed["riddle"] is bool and has_riddle):
				v.err(cw, "조우 riddle은 true/false이고 균열에 riddle 정의가 있어야 한다")
		if (i == chapters.size() - 1) != (guardians == 1):
			v.err(cw, "수호자 조우(guardian)는 마지막 챕터에 정확히 하나")
		for st: Variant in JsonUtil.get_array(ch, "field_effects"):
			v.ref(cw + ".field_effects", "statuses", st)
		EffectRules.check(v, cw + ".on_enter", JsonUtil.get_array(ch, "on_enter"), true)
		for h: Variant in JsonUtil.get_array(ch, "hazards"):
			_hazard(v, cw + ".hazards", h if h is Dictionary else {})
		for h: Variant in JsonUtil.get_array(ch, "hidden"):
			_hidden(v, cw + ".hidden", h if h is Dictionary else {}, has_riddle)
		if ch.has("exit_requires"):
			var req := JsonUtil.get_dict(ch, "exit_requires")
			v.ref(cw + ".exit_requires", "items", req.get("item"))
			if req.has("bypass"):
				_stat_at_least(v, cw + ".exit_requires.bypass", JsonUtil.get_dict(req, "bypass"))
		var size := JsonUtil.get_array(JsonUtil.get_dict(ch, "map"), "size")
		if size.size() != 2 or int(size[0]) < 20 or int(size[1]) < 12:
			v.err(cw, "map.size는 [20 이상, 12 이상]")
		if JsonUtil.get_int(JsonUtil.get_dict(ch, "map"), "rooms", 0) < encs.size() + 1:
			v.err(cw, "map.rooms는 조우 수 + 1 이상(첫 방은 시작)")


## 구성: 몬스터 id 배열 또는 {"pick": [..], "count": [최소, 최대]}.
static func _composition(v: ValidatorBase, where: String, spec: Variant) -> void:
	var ids: Array = spec if spec is Array else JsonUtil.get_array(spec if spec is Dictionary else {}, "pick")
	for m: Variant in ids:
		v.ref(where, "monsters", m)


## 수수께끼 문지기: data/riddles에 그 set 문항이 있어야 하고, 약화·강화 상태가 있어야 한다.
static func _riddle(v: ValidatorBase, w: String, rd: Dictionary) -> void:
	var set_id := JsonUtil.get_str(rd, "set")
	var found := false
	for qid: String in v.entries("riddles"):
		if JsonUtil.get_str(v.db.get_entry("riddles", qid), "set") == set_id:
			found = true
			break
	if not found:
		v.err(w, "set '%s'의 문항이 data/riddles에 없다" % set_id)
	for key in ["weakened_status", "empowered_status"]:
		v.ref(w + "." + key, "statuses", rd.get(key))
	if rd.has("essence_mult") and JsonUtil.get_float(rd, "essence_mult", -1.0) <= 0.0:
		v.err(w, "essence_mult는 양수")


## 탐험 위험·함정: tile, 판정 {stat, dc}(check·detect·disarm), bypass {stat, at_least}, fail [효과].
static func _hazard(v: ValidatorBase, w: String, hd: Dictionary) -> void:
	v.ref(w + ".tile", "tiles", hd.get("tile"))
	for key in ["check", "detect", "disarm"]:
		if hd.has(key):
			var ck := JsonUtil.get_dict(hd, key)
			if not v.db.stats.has(JsonUtil.get_str(ck, "stat", "agi")):
				v.err(w + "." + key, "스탯 '%s' 없음" % ck.get("stat"))
			if ck.has("dc") and not JsonUtil.is_number(ck["dc"]):
				v.err(w + "." + key, "dc는 숫자")
	if hd.has("bypass"):
		_stat_at_least(v, w + ".bypass", JsonUtil.get_dict(hd, "bypass"))
	if hd.has("hidden") and not hd["hidden"] is bool:
		v.err(w, "hidden은 true/false")
	EffectRules.check(v, w + ".fail", JsonUtil.get_array(hd, "fail"), true)


## 히든 피스(item) 또는 벽화(mural: true — 균열에 riddle이 있어야 한다).
static func _hidden(v: ValidatorBase, w: String, hd: Dictionary, has_riddle: bool) -> void:
	v.ref(w + ".tile", "tiles", hd.get("tile"))
	if JsonUtil.get_bool(hd, "mural"):
		if not has_riddle:
			v.err(w, "벽화(mural)는 균열에 riddle 정의가 있어야 한다")
	else:
		v.ref(w + ".item", "items", hd.get("item"))


static func _stat_at_least(v: ValidatorBase, w: String, d: Dictionary) -> void:
	if not v.db.stats.has(JsonUtil.get_str(d, "stat")):
		v.err(w, "스탯 '%s' 없음" % d.get("stat"))
	if not JsonUtil.is_number(d.get("at_least")):
		v.err(w, "at_least는 숫자")
