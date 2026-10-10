class_name WorldRules
extends RefCounted
## 검사 규칙: 타일·랜드마크·층·입력 설정.

const TILE_KINDS := ["floor", "wall"]
## 원작: 대부분의 층은 광원이 있어도 가시거리가 10m에 못 미친다(하늘이 열린 층은 open_sky로 예외).
const VISIBILITY_CAP_LIMIT_M := 10.0


static func run(v: ValidatorBase) -> void:
	_tiles(v)
	_landmarks(v)
	_floors(v)
	_input(v)


static func _tiles(v: ValidatorBase) -> void:
	for id: String in v.entries("tiles"):
		var t := v.db.get_entry("tiles", id)
		var w := "tiles/" + id
		if not JsonUtil.get_str(t, "kind") in TILE_KINDS:
			v.err(w, "kind는 %s 중 하나" % [TILE_KINDS])
		var colors := JsonUtil.get_dict(t, "colors")
		for key: String in colors:
			v.check_color(w + ".colors." + key, JsonUtil.get_str(colors, key))
		var light := JsonUtil.get_dict(t, "light")
		if not light.is_empty():
			if JsonUtil.get_float(light, "radius_m") <= 0.0:
				v.err(w, "light.radius_m은 0보다 커야 한다")
			v.check_color(w + ".light", JsonUtil.get_str(light, "color"))
	if v.entries("tiles").is_empty():
		v.err("tiles", "타일 정의가 하나도 없다")


static func _landmarks(v: ValidatorBase) -> void:
	for id: String in v.entries("landmarks"):
		var lm := v.db.get_entry("landmarks", id)
		var w := "landmarks/" + id
		var stamp := JsonUtil.get_array(lm, "stamp")
		var legend := JsonUtil.get_dict(lm, "legend")
		if stamp.is_empty():
			v.err(w, "stamp가 비었다")
		var width := -1
		for row: Variant in stamp:
			var s := str(row)
			if width >= 0 and s.length() != width:
				v.err(w, "stamp 줄 길이가 서로 다르다")
			width = s.length()
			for ch in s:
				if not legend.has(ch):
					v.err(w, "stamp 글자 '%s'가 legend에 없다" % ch)
		for ch: String in legend:
			if legend[ch] != null:
				v.ref(w + ".legend", "tiles", legend[ch])
		var anchor := JsonUtil.get_str(lm, "anchor")
		if not anchor.is_empty() and not "".join(PackedStringArray(stamp)).contains(anchor):
			v.err(w, "anchor '%s'가 stamp에 없다" % anchor)


static func _floors(v: ValidatorBase) -> void:
	var dirs := v.db.tag_ids("directions")
	for id: String in v.entries("floors"):
		var f := v.db.get_entry("floors", id)
		var w := "floors/" + id
		var gen := JsonUtil.get_str(f, "generator")
		if not v.generator_ids.is_empty() and not v.generator_ids.has(gen):
			v.err(w, "generator '%s' 없음(src/explore/generators/)" % gen)
		elif v.generator_checker.is_valid():
			for problem: String in v.generator_checker.call(f, v.db):
				v.err(w, problem)
		if JsonUtil.get_float(f, "close_hours") <= 0.0:
			v.err(w, "close_hours는 0보다 커야 한다")
		var cap := JsonUtil.get_float(f, "visibility_cap_m")
		if cap <= 0.0:
			v.err(w, "visibility_cap_m은 0보다 커야 한다")
		elif cap >= VISIBILITY_CAP_LIMIT_M and not JsonUtil.get_bool(f, "open_sky"):
			v.warn(w, "visibility_cap_m이 10m 이상 — 원작상 대부분의 층은 10m 미만(하늘이 열린 층은 open_sky: true)")
		if JsonUtil.get_float(f, "ambient_light_m") < 0.0:
			v.err(w, "ambient_light_m은 0 이상")
		v.check_color(w + ".ambient_color", JsonUtil.get_str(f, "ambient_color"))
		for lm: Variant in JsonUtil.get_array(f, "landmarks"):
			v.ref(w + ".landmarks", "landmarks", (lm as Dictionary).get("id") if lm is Dictionary else lm)
		for region: Variant in JsonUtil.get_array(f, "regions"):
			var rd: Dictionary = region if region is Dictionary else {}
			if not dirs.has(JsonUtil.get_str(rd, "dir")):
				v.err(w, "regions.dir '%s' 미등록(tags.directions)" % rd.get("dir"))
			for m: Variant in JsonUtil.get_array(rd, "monsters"):
				v.ref(w + ".regions", "monsters", m)
		for portal: Variant in JsonUtil.get_array(f, "portals"):
			var pd: Dictionary = portal if portal is Dictionary else {}
			if not dirs.has(JsonUtil.get_str(pd, "dir")):
				v.err(w, "portals.dir '%s' 미등록(tags.directions)" % pd.get("dir"))


static func _input(v: ValidatorBase) -> void:
	var actions := JsonUtil.get_dict(JsonUtil.get_dict(v.db.singletons, "input"), "actions")
	for action: String in actions:
		var keys: Variant = actions[action]
		if not keys is Array or (keys as Array).is_empty():
			v.err("input/" + action, "키 목록이 비었다")
			continue
		for key_name: Variant in keys:
			if OS.find_keycode_from_string(str(key_name)) == KEY_NONE:
				v.err("input/" + action, "알 수 없는 키 이름 '%s'" % key_name)
