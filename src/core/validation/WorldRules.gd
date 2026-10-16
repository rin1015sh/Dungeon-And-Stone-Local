class_name WorldRules
extends RefCounted
## 검사 규칙: 타일·랜드마크·층·입력 설정.

const TILE_KINDS := ["floor", "wall"]
## 원작: 대부분의 층은 광원이 있어도 가시거리가 10m에 못 미친다(하늘이 열린 층은 open_sky로 예외).
const VISIBILITY_CAP_LIMIT_M := 10.0
const ART_COLORS := ["unexplored", "near_black", "tone", "memory_tint"]


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
		var art := JsonUtil.get_dict(t, "art")
		if not art.is_empty():
			var n := JsonUtil.get_int(art, "variants")
			if n < 2 or n % 2 != 0:
				v.err(w + ".art", "variants는 2 이상 짝수(FloorArtLayer — 이웃 칸이 늘 다른 변형)")
			if not ResourceLoader.exists(JsonUtil.get_str(art, "atlas")):
				v.err(w + ".art", "atlas 파일 없음 '%s' — tools/paint_floor.gd로 그린다" % JsonUtil.get_str(art, "atlas"))
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
		check_art(v, w + ".art", JsonUtil.get_dict(f, "art"))
		for lm: Variant in JsonUtil.get_array(f, "landmarks"):
			v.ref(w + ".landmarks", "landmarks", (lm as Dictionary).get("id") if lm is Dictionary else lm)
		for region: Variant in JsonUtil.get_array(f, "regions"):
			var rd: Dictionary = region if region is Dictionary else {}
			if JsonUtil.get_str(rd, "zone").is_empty() and not dirs.has(JsonUtil.get_str(rd, "dir")):
				v.err(w, "regions.dir '%s' 미등록(tags.directions) — zone이 없으면 dir이 필요" % rd.get("dir"))
			for m: Variant in JsonUtil.get_array(rd, "monsters"):
				v.ref(w + ".regions", "monsters", m)
			var weights := JsonUtil.get_dict(rd, "weights")
			for m: String in weights:
				if not JsonUtil.get_array(rd, "monsters").has(m) or JsonUtil.get_float(weights, m) <= 0.0:
					v.err(w, "regions.weights '%s'는 monsters에 있고 양수여야 한다" % m)
			for m: Variant in JsonUtil.get_array(JsonUtil.get_dict(rd, "variants"), "monsters"):
				v.ref(w + ".regions.variants", "monsters", m)
		var lord := JsonUtil.get_dict(f, "lord")
		if not lord.is_empty():
			v.ref(w + ".lord", "monsters", lord.get("monster"))
			for k in ["min_day", "min_party", "stay_radius_m", "hazard_base_per_hour", "hazard_doubling_hours", "respawn_hours", "vision_m"]:
				if JsonUtil.get_float(lord, k, -1.0) <= 0.0:
					v.err(w + ".lord", "%s는 양수" % k)
			v.check_color(w + ".lord.tint", JsonUtil.get_str(lord, "tint", "#ffffff"))
		for portal: Variant in JsonUtil.get_array(f, "portals"):
			var pd: Dictionary = portal if portal is Dictionary else {}
			if not dirs.has(JsonUtil.get_str(pd, "dir")):
				v.err(w, "portals.dir '%s' 미등록(tags.directions)" % pd.get("dir"))


## 탐험 맵 그림 설정(층 JSON art · 균열 look.art — FloorArt). 빈 사전이면 render.json 기본값.
static func check_art(v: ValidatorBase, w: String, art: Dictionary) -> void:
	var pal := JsonUtil.get_dict(art, "palette")
	for key: String in pal:
		if key == "memory_brightness":
			if JsonUtil.get_float(pal, key) < 0.0:
				v.err(w + ".palette", "memory_brightness는 0 이상")
		elif key in ART_COLORS:
			v.check_color(w + ".palette." + key, JsonUtil.get_str(pal, key))
		else:
			v.err(w + ".palette", "모르는 키 '%s'" % key)
	var post := JsonUtil.get_dict(art, "post")
	for key: String in post:
		if not key in FloorArt.POST_KEYS:
			v.err(w + ".post", "모르는 키 '%s'(%s)" % [key, FloorArt.POST_KEYS])
	var pulse := JsonUtil.get_dict(art, "pulse")
	for t: Variant in JsonUtil.get_array(pulse, "tiles"):
		v.ref(w + ".pulse.tiles", "tiles", t)
		var td := v.db.get_entry("tiles", str(t))
		if not td.is_empty() and JsonUtil.get_dict(td, "light").is_empty():
			v.warn(w + ".pulse.tiles", "'%s'는 light가 없어 맥동하지 않는다" % t)
	if not pulse.is_empty():
		if JsonUtil.get_float(pulse, "period_sec", 1.0) <= 0.0 or JsonUtil.get_float(pulse, "radius_m", 1.0) <= 0.0:
			v.err(w + ".pulse", "period_sec·radius_m은 양수")
		var depth := JsonUtil.get_float(pulse, "depth")
		if depth < 0.0 or depth > 1.0:
			v.err(w + ".pulse", "depth는 0~1")
	for e: Variant in JsonUtil.get_array(art, "particles"):
		var pd: Dictionary = e if e is Dictionary else {}
		var pw := w + ".particles." + JsonUtil.get_str(pd, "id", "?")
		if JsonUtil.get_str(pd, "id").is_empty():
			v.err(pw, "id가 없다")
		if JsonUtil.get_int(pd, "amount") <= 0 or JsonUtil.get_float(pd, "lifetime") <= 0.0:
			v.err(pw, "amount·lifetime은 양수")
		v.check_color(pw + ".color", JsonUtil.get_str(pd, "color", "#ffffff"))
		for key in ["scale", "velocity", "direction", "gravity"]:
			if pd.has(key) and JsonUtil.get_array(pd, key).size() != 2:
				v.err(pw, "%s는 [두 수]" % key)
	var loop := JsonUtil.get_str(JsonUtil.get_dict(art, "ambience"), "loop")
	if not loop.is_empty() and not JsonUtil.get_dict(JsonUtil.get_dict(v.db.singletons, "audio"), "ambience").has(loop):
		v.err(w + ".ambience", "'%s'가 data/audio.json ambience에 없다" % loop)


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
