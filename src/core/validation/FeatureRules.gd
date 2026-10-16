class_name FeatureRules
extends RefCounted
## 검사 규칙: 동굴 요소(data/events, type "feature" — FieldFeatures·FieldFeatureAct)와 층 JSON features 배치.

const LIMITS := ["once", "day", "always"]
const SPOTS := ["room", "wall", "corridor", "crystal", "crystal_room", "dark_edge", "near_portal", "near_monument"]


static func run(v: ValidatorBase) -> void:
	for id: String in v.entries("events"):
		var ev := v.db.get_entry("events", id)
		if JsonUtil.get_str(ev, "type") == "feature":
			_feature(v, "events/" + id, ev)
	for fid: String in v.entries("floors"):
		var w := "floors/" + fid + ".features"
		for s: Variant in JsonUtil.get_array(v.db.get_entry("floors", fid), "features"):
			var sd: Dictionary = s if s is Dictionary else {}
			v.ref(w, "events", sd.get("event"))
			if not JsonUtil.get_str(sd, "spot", "room") in SPOTS:
				v.err(w, "spot '%s'는 %s 중 하나" % [sd.get("spot"), SPOTS])
			if JsonUtil.get_int(sd, "count", 1) < 1:
				v.err(w, "count는 1 이상")
			for z: Variant in JsonUtil.get_array(sd, "zones"):
				if str(z) != CrossLayout.ZONE_CENTER and not CrossLayout.ARMS.has(str(z)):
					v.err(w, "zones '%s'는 center/east/west/south/north" % z)


static func _feature(v: ValidatorBase, w: String, ev: Dictionary) -> void:
	var tile := JsonUtil.get_str(ev, "tile")
	if not tile.is_empty():
		v.ref(w + ".tile", "tiles", tile)
		if v.db.has_entry("tiles", tile) and not JsonUtil.get_bool(v.db.get_entry("tiles", tile), "walkable"):
			v.err(w + ".tile", "동굴 요소 타일은 걸을 수 있어야 한다(길을 막지 않게)")
	var actions := JsonUtil.get_array(ev, "actions")
	if actions.is_empty() and not ev.has("near") and not ev.has("hazard"):
		v.err(w, "actions·near·hazard 중 하나는 있어야 한다")
	if not actions.is_empty() and tile.is_empty():
		v.err(w, "살필 행동이 있으면 tile이 있어야 한다(보이지 않으면 살필 수 없다)")
	for a: Variant in actions:
		_action(v, w + ".actions", a if a is Dictionary else {})
	if ev.has("near"):
		_line(v, w + ".near", JsonUtil.get_str(JsonUtil.get_dict(ev, "near"), "line"), false)
	if ev.has("hidden"):
		var h := JsonUtil.get_dict(ev, "hidden")
		if not v.db.stats.has(JsonUtil.get_str(h, "stat")):
			v.err(w + ".hidden", "stat '%s' 없음" % h.get("stat"))
		if h.has("line"):
			_line(v, w + ".hidden", JsonUtil.get_str(h, "line"), false)
	if ev.has("hazard"):
		var hz := JsonUtil.get_dict(ev, "hazard")
		v.ref(w + ".hazard.tile", "tiles", hz.get("tile"))
		EffectRules.check(v, w + ".hazard.fail", JsonUtil.get_array(hz, "fail"), true)
		for key: String in ["detect_message", "disarm_message", "pass_message", "fail_message"]:
			if hz.has(key):
				_line(v, w + ".hazard." + key, JsonUtil.get_str(hz, key), false)
	var guard := JsonUtil.get_dict(ev, "guard")
	if not guard.is_empty():
		v.ref(w + ".guard", "monsters", guard.get("monster"))


static func _action(v: ValidatorBase, w: String, a: Dictionary) -> void:
	if JsonUtil.get_str(a, "id").is_empty() or JsonUtil.get_str(a, "name_ko").is_empty():
		v.err(w, "행동에 id·name_ko가 필요하다")
	if not JsonUtil.get_str(a, "limit", "once") in LIMITS:
		v.err(w, "limit은 %s 중 하나" % [LIMITS])
	if a.has("needs_status"):
		v.ref(w + ".needs_status", "statuses", a["needs_status"])
	var cost := JsonUtil.get_dict(a, "cost")
	if not cost.is_empty():
		v.ref(w + ".cost", "items", cost.get("item"))
	for g: Variant in JsonUtil.get_array(a, "give"):
		var gd: Dictionary = g if g is Dictionary else {}
		v.ref(w + ".give", "items", gd.get("item"))
		if gd.has("chance"):
			v.check_chance(w + ".give", gd["chance"])
	EffectRules.check(v, w + ".effects", JsonUtil.get_array(a, "effects"), true)
	if a.has("learn_stats"):
		v.ref(w + ".learn_stats", "monsters", a["learn_stats"])
	var al := JsonUtil.get_dict(a, "alert")
	if not al.is_empty():
		v.ref(w + ".alert", "monsters", al.get("monster"))
	_line(v, w + ".line", JsonUtil.get_str(a, "line"), JsonUtil.get_bool(a, "line_zone"))
	for key: String in ["done", "missing"]:
		if a.has(key):
			_line(v, w + "." + key, JsonUtil.get_str(a, key), false)


## 문구 키가 ko.json에 있는가(그 키 또는 번호 변형 .1). zone이면 구역마다.
static func _line(v: ValidatorBase, w: String, key: String, zone: bool) -> void:
	if key.is_empty():
		v.err(w, "문구 키가 비었다")
		return
	var bases: Array[String] = [key]
	if zone:
		bases.clear()
		for z: String in [CrossLayout.ZONE_CENTER] + Array(CrossLayout.ARMS):
			bases.append(key + "." + z)
	for b in bases:
		if not Strings.has(b) and not Strings.has(b + ".1"):
			v.err(w, "문구 키 '%s' 없음(data/strings/ko.json)" % b)
