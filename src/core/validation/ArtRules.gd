class_name ArtRules
extends RefCounted
## 검사 규칙: 탐험 맵 그림 설정(층 JSON art · 균열 look.art — FloorArt·FloorDecor·FloorTint).

const ART_COLORS := ["unexplored", "near_black", "tone", "memory_tint"]
const DECOR_KEYS := ["kind", "chance", "dense", "size", "zones", "near_tiles", "wall_north", "near_features", "noise", "orient", "at", "radius"]


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
	check_battleback(v, w + ".battleback", art.get("battleback"))
	_decor(v, w + ".decor", JsonUtil.get_dict(art, "decor"))
	_macro(v, w + ".macro", JsonUtil.get_dict(art, "macro"))
	var loop := JsonUtil.get_str(JsonUtil.get_dict(art, "ambience"), "loop")
	if not loop.is_empty() and not JsonUtil.get_dict(JsonUtil.get_dict(v.db.singletons, "audio"), "ambience").has(loop):
		v.err(w + ".ambience", "'%s'가 data/audio.json ambience에 없다" % loop)


## 전투 뒷그림(BattleStage): 없으면 어둠, 있으면 {image(파일이 있어야), half_width(양수 m)}.
static func check_battleback(v: ValidatorBase, w: String, bb: Variant) -> void:
	if bb == null:
		return
	if not bb is Dictionary:
		v.err(w, "{image, half_width} 사전이어야 한다")
		return
	var path := JsonUtil.get_str(bb, "image")
	if not ResourceLoader.exists(path):
		v.err(w, "그림 파일 없음 '%s' — tools/paint_battlebacks.gd로 그린다" % path)
	if JsonUtil.get_float(bb, "half_width") <= 0.0:
		v.err(w, "half_width(통로 반 폭 m)는 양수")
	for key: String in (bb as Dictionary):
		if not key in ["image", "half_width"]:
			v.err(w, "모르는 키 '%s'" % key)


## 데칼 배치(FloorDecor): 시트·종류·규칙 키·참조.
static func _decor(v: ValidatorBase, w: String, d: Dictionary) -> void:
	if d.is_empty():
		return
	if not ResourceLoader.exists(JsonUtil.get_str(d, "sheet")):
		v.err(w, "sheet 파일 없음 '%s' — tools/paint_floor.gd로 그린다" % JsonUtil.get_str(d, "sheet"))
	var baked := JsonUtil.get_str(d, "baked")
	if not baked.is_empty() and not FileAccess.file_exists(baked):
		v.err(w, "baked 파일 없음 '%s' — tools/bake_decor.gd로 굽는다" % baked)
	var kinds := JsonUtil.get_array(d, "kinds")
	if kinds.is_empty():
		v.err(w, "kinds가 비었다")
	for t: Variant in JsonUtil.get_array(d, "on_tiles"):
		v.ref(w + ".on_tiles", "tiles", t)
	for list_key in ["rules", "spots"]:
		for r: Variant in JsonUtil.get_array(d, list_key):
			var rd: Dictionary = r if r is Dictionary else {}
			var rw := "%s.%s.%s" % [w, list_key, JsonUtil.get_str(rd, "kind", "?")]
			if not kinds.has(JsonUtil.get_str(rd, "kind")):
				v.err(rw, "kind가 kinds에 없다")
			for key: String in rd:
				if not key in DECOR_KEYS:
					v.err(rw, "모르는 키 '%s'" % key)
			var c := JsonUtil.get_float(rd, "chance", 1.0)
			if c <= 0.0 or c > 1.0:
				v.err(rw, "chance는 0 초과 1 이하")
			for t: Variant in JsonUtil.get_array(JsonUtil.get_dict(rd, "near_tiles"), "tiles"):
				v.ref(rw + ".near_tiles", "tiles", t)
			for f: Variant in JsonUtil.get_array(JsonUtil.get_dict(rd, "near_features"), "ids"):
				v.ref(rw + ".near_features", "events", f)
			if list_key == "spots" and JsonUtil.get_array(rd, "at").size() != 2:
				v.err(rw, "spots.at은 [x, y]")


## 거시 색조(FloorTint).
static func _macro(v: ValidatorBase, w: String, m: Dictionary) -> void:
	var zones := JsonUtil.get_dict(m, "zones")
	for z: String in zones:
		v.check_color(w + ".zones." + z, JsonUtil.get_str(zones, z))
	var dim := JsonUtil.get_dict(m, "safe_dim")
	if not dim.is_empty() and (JsonUtil.get_float(dim, "mult", 1.0) <= 0.0 or JsonUtil.get_float(dim, "radius", 1.0) <= 0.0):
		v.err(w + ".safe_dim", "mult·radius는 양수")
