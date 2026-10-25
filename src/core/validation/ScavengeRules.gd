class_name ScavengeRules
extends RefCounted
## 균열 장식 잡템(RF19): 표(data/scavenge.json)의 아이템·무게·빈손 확률, 타일 "scavenge"가 있는 표를 가리키는지.


static func run(v: ValidatorBase) -> void:
	for id: String in v.entries("scavenge"):
		var t := v.db.get_entry("scavenge", id)
		var w := "scavenge/" + id
		var e := JsonUtil.get_float(t, "empty_chance")
		if e < 0.0 or e >= 1.0:
			v.err(w, "empty_chance는 0 이상 1 미만")
		var list := JsonUtil.get_array(t, "items")
		if list.is_empty():
			v.err(w, "items가 비었다")
		for it: Variant in list:
			v.ref(w + ".items", "items", (it as Dictionary).get("item") if it is Dictionary else it)
			if it is Dictionary and JsonUtil.get_float(it, "weight", 1.0) <= 0.0:
				v.err(w, "weight는 0보다 커야 한다")
	for id: String in v.entries("tiles"):
		var tile := v.db.get_entry("tiles", id)
		if tile.has("scavenge"):
			v.ref("tiles/" + id + ".scavenge", "scavenge", tile["scavenge"])
			if not JsonUtil.get_str(tile, "interact").is_empty():
				v.err("tiles/" + id, "scavenge와 interact를 함께 두지 않는다(살피기가 하나만)")
