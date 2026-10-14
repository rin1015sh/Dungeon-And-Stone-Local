class_name CityInfo
extends RefCounted
## 소문·정보 항목(data/city_info): {id, kind: rumor|lore, name_ko, text_ko, test_only}. 얻은 것은 CityState.known_info.

const KINDS := ["rumor", "lore"]


static func known_of(state: CityState, kind: String) -> Array[String]:
	var out: Array[String] = []
	for id in state.known_info:
		if JsonUtil.get_str(state.db.get_entry("city_info", id), "kind") == kind:
			out.append(id)
	return out
