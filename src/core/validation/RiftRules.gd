class_name RiftRules
extends RefCounted
## 검사 규칙: 균열(rifts/*.json, RiftRun 형식) — 개방 마석·모양(타일)·챕터·조우·수호자·드롭,
## 수수께끼(RiftRiddle)·탐험 위험과 함정(RiftHazards)·히든 피스와 벽화(RiftHidden)·출구 조건(exit_requires).

const KINDS := ["battle", "chain", "waves", "guardian", "posts", "roam", "ambush"]
const NO_SLOT := ["posts", "roam", "ambush"]  ## 조우 자리(marks.slots)를 쓰지 않는 조우


static func run(v: ValidatorBase) -> void:
	for id: String in v.entries("rifts"):
		_rift(v, id, v.db.get_entry("rifts", id))


static func _rift(v: ValidatorBase, id: String, r: Dictionary) -> void:
	var w := "rifts/" + id
	if JsonUtil.get_int(r, "host_floor") < 1:
		v.err(w, "host_floor는 1 이상")
	if JsonUtil.get_float(r, "weight", 1.0) <= 0.0:
		v.err(w, "weight는 양수")
	for k in ["floor", "wall", "exit"]:
		v.ref(w + ".look.tiles", "tiles", JsonUtil.get_dict(JsonUtil.get_dict(r, "look"), "tiles").get(k))
	ArtRules.check_art(v, w + ".look.art", JsonUtil.get_dict(JsonUtil.get_dict(r, "look"), "art"))
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
		ArtRules.check_battleback(v, cw + ".battleback", ch.get("battleback"))
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
			if (kind == "posts" or kind == "roam") and (JsonUtil.get_int(ed, "count") < 1 or JsonUtil.get_array(ed, "packs").is_empty()):
				v.err(cw, "%s: count는 1 이상, packs는 구성 하나 이상" % kind)
			if kind == "ambush" and (JsonUtil.get_array(ed, "trigger").size() != 4 or JsonUtil.get_array(ed, "packs").is_empty() \
					or JsonUtil.get_array(ed, "packs").size() != JsonUtil.get_array(ed, "from").size()):
				v.err(cw, "ambush: trigger는 [x, y, w, h], packs와 from은 같은 수(하나 이상)")
			for spec: Variant in [ed.get("monsters", []), ed.get("start", []), ed.get("with", [])] + JsonUtil.get_array(ed, "battles") + JsonUtil.get_array(ed, "packs"):
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
		if ch.has("groove_blades"):  # 칼날 홈을 오가는 칼날(GrooveBlades) — 위험 묶음과 같은 키(tile·bypass·fail)
			_hazard(v, cw + ".groove_blades", JsonUtil.get_dict(ch, "groove_blades"))
		for h: Variant in JsonUtil.get_array(ch, "hidden"):
			_hidden(v, cw + ".hidden", h if h is Dictionary else {}, has_riddle)
		for l: Variant in JsonUtil.get_array(ch, "loot"):
			var ld: Dictionary = l if l is Dictionary else {}
			v.ref(cw + ".loot", "items", ld.get("item"))
			if JsonUtil.get_int(ld, "count", 1) < 1:
				v.err(cw + ".loot", "count는 1 이상")
		if ch.has("exit_requires"):
			var req := JsonUtil.get_dict(ch, "exit_requires")
			v.ref(cw + ".exit_requires", "items", req.get("item"))
			if req.has("bypass"):
				_stat_at_least(v, cw + ".exit_requires.bypass", JsonUtil.get_dict(req, "bypass"))
		var map := JsonUtil.get_dict(ch, "map")
		if map.has("blueprint"):
			_blueprint(v, cw + ".map", ch, encs.filter(func(e: Variant) -> bool: return not (e is Dictionary and JsonUtil.get_str(e, "kind") in NO_SLOT)).size())  # 대기·떠도는 무리·매복은 조우 자리를 쓰지 않는다
		else:
			var size := JsonUtil.get_array(map, "size")
			if size.size() != 2 or int(size[0]) < 20 or int(size[1]) < 12:
				v.err(cw, "map.size는 [20 이상, 12 이상]")
			if JsonUtil.get_int(map, "rooms", 0) < encs.size() + 1:
				v.err(cw, "map.rooms는 조우 수 + 1 이상(첫 방은 시작)")


## 설계도 지도(rift_blueprint): 파일 형식 + 표시 수 = 조우 수 · 히든 피스 수 · 위험 묶음 수(hazards × count) + 표시 칸이 걸을 수 있는가.
static func _blueprint(v: ValidatorBase, w: String, ch: Dictionary, encounters: int) -> void:
	var path := JsonUtil.get_str(JsonUtil.get_dict(ch, "map"), "blueprint")
	var data := FloorMapFile.read(path)
	for msg in RiftBlueprintGenerator.problems(data, v.db):
		v.err(w, "%s: %s" % [path, msg])
	if data.is_empty():
		return
	var marks := JsonUtil.get_dict(data, "marks")
	var hz := 0
	for h: Variant in JsonUtil.get_array(ch, "hazards"):
		hz += JsonUtil.get_int(h if h is Dictionary else {}, "count", 1)
	var pairs: Array = [["slots", encounters], ["hidden", JsonUtil.get_array(ch, "hidden").size()], ["hazards", hz],
		["loot", JsonUtil.get_array(ch, "loot").size()]]
	if marks.has("posts"):  # 대기 무리 고정 자리 = posts packs 하나씩
		var packs := 0
		for e: Variant in JsonUtil.get_array(ch, "encounters"):
			if e is Dictionary and JsonUtil.get_str(e, "kind") == "posts":
				packs += JsonUtil.get_array(e, "packs").size()
		pairs.append(["posts", packs])
	for pair: Array in pairs:
		if JsonUtil.get_array(marks, pair[0]).size() != int(pair[1]):
			v.err(w, "%s: marks.%s %d개 ≠ 데이터 %d개" % [path, pair[0], JsonUtil.get_array(marks, pair[0]).size(), pair[1]])
	for key: String in ["loot", "posts"]:  # 놓인 물건·대기 무리는 걸을 수 있는 칸에
		for p: Variant in JsonUtil.get_array(marks, key):
			if not _walkable(v.db, data, p):
				v.err(w, "%s: marks.%s %s는 걸을 수 있는 칸이어야 한다" % [path, key, p])
	for e: Variant in JsonUtil.get_array(ch, "encounters"):  # 매복: 나타나는 칸은 걸을 수 있고 trigger는 지도 안
		if e is Dictionary and JsonUtil.get_str(e, "kind") == "ambush":
			for p: Variant in JsonUtil.get_array(e, "from"):
				if not _walkable(v.db, data, p):
					v.err(w, "%s: ambush from %s는 걸을 수 있는 칸이어야 한다" % [path, p])
			var r := JsonUtil.get_array(e, "trigger")
			if r.size() == 4 and not (_walkable(v.db, data, [r[0], r[1]]) and _walkable(v.db, data, [int(r[0]) + int(r[2]) - 1, int(r[1]) + int(r[3]) - 1])):
				v.err(w, "%s: ambush trigger %s의 모서리가 걸을 수 있는 칸이 아니다" % [path, r])


static func _walkable(db: GameDatabase, data: Dictionary, p: Variant) -> bool:
	var a: Array = p if p is Array else []
	var rows := JsonUtil.get_array(data, "rows")
	if a.size() != 2 or int(a[1]) < 0 or int(a[1]) >= rows.size() or int(a[0]) < 0 or int(a[0]) >= str(rows[int(a[1])]).length():
		return false
	var ch := str(rows[int(a[1])])[int(a[0])]
	return JsonUtil.get_bool(db.get_entry("tiles", str(JsonUtil.get_dict(data, "legend").get(ch, ""))), "walkable")


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


## 탐험 위험·함정: tile, disarm(true/false), bypass {stat, at_least}, fail [효과]. 판정은 동전(V29 — 스탯 판정 키는 없어졌다).
static func _hazard(v: ValidatorBase, w: String, hd: Dictionary) -> void:
	v.ref(w + ".tile", "tiles", hd.get("tile"))
	FeatureRules._no_stat_check(v, w, hd)
	if hd.has("bypass"):
		_stat_at_least(v, w + ".bypass", JsonUtil.get_dict(hd, "bypass"))
	if hd.has("hidden") and not hd["hidden"] is bool:
		v.err(w, "hidden은 true/false")
	EffectRules.check(v, w + ".fail", JsonUtil.get_array(hd, "fail"), true)


## 히든 피스(item) 또는 벽화(mural: true — 균열에 riddle이 있어야 한다).
static func _hidden(v: ValidatorBase, w: String, hd: Dictionary, has_riddle: bool) -> void:
	v.ref(w + ".tile", "tiles", hd.get("tile"))
	if hd.has("check"):
		v.err(w, "check(스탯 판정)는 없어졌다 — \"coin\": true(V29)")
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
