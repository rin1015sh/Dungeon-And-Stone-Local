class_name RiftRules
extends RefCounted
## 검사 규칙: 균열(rifts/*.json, RiftRun 형식) — 개방 마석·모양(타일)·챕터·조우·수호자·드롭.

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
		if (i == chapters.size() - 1) != (guardians == 1):
			v.err(cw, "수호자 조우(guardian)는 마지막 챕터에 정확히 하나")
		for st: Variant in JsonUtil.get_array(ch, "field_effects"):
			v.ref(cw + ".field_effects", "statuses", st)
		v.check_effects(cw + ".on_enter", JsonUtil.get_array(ch, "on_enter"), true)
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
