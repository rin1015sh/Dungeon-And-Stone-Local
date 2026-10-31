class_name CityInfo
extends RefCounted
## 도서관 서적 항목(data/city_info — CT52): {id, field, tier, floor, name_ko, text_ko}. 얻은 것은 CityState.known_info(도감 B의 서적에서 다시 읽는다).
##   field = city.json library.fields의 분야 id · floor = 다루는 층(1부터, 층과 무관하면 1) · tier = 예전 거주 등급(2026-10-31 거주 등급을 없애 쓰지 않는다 — CT63).
## 읽을 수 있는 것 = 아직 모르고, 분야가 맞고, floor ≤ 가 본 가장 깊은 층 + 1.
## 오토로드를 참조하지 않는다.

const ANY := "any"


static func fields(db: GameDatabase) -> Array:
	return JsonUtil.get_array(JsonUtil.get_dict(db.singletons.get("city", {}), "library"), "fields")


static func field_ids(db: GameDatabase) -> Array[String]:
	var out: Array[String] = []
	for f: Variant in fields(db):
		if f is Dictionary:
			out.append(JsonUtil.get_str(f, "id"))
	return out


## 분야의 펼친 책 그림(city.json library.fields art — 읽을 때 시설 안을 덮는다, CT57). 없으면 "".
static func field_art(db: GameDatabase, id: String) -> String:
	for f: Variant in fields(db):
		if f is Dictionary and JsonUtil.get_str(f, "id") == id:
			return JsonUtil.get_str(f, "art")
	return ""


static func field_name(db: GameDatabase, id: String) -> String:
	for f: Variant in fields(db):
		if f is Dictionary and JsonUtil.get_str(f, "id") == id:
			return JsonUtil.get_str(f, "name_ko", id)
	return id


## 이 분야(ANY = 모든 분야)에서 지금 읽을 수 있는 항목 id(데이터 순서).
static func readable(state: CityState, field: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in state.db.get_collection("city_info"):
		var e := state.db.get_entry("city_info", id)
		if state.known_info.has(id) or not (field == ANY or JsonUtil.get_str(e, "field") == field):
			continue
		if JsonUtil.get_int(e, "floor", 1) <= state.reached_floor + 1:
			out.append(id)
	return out


## 이 분야에서 아는 항목 id(데이터 순서 — 도감 서적).
static func known_of(state: CityState, field: String = ANY) -> Array[String]:
	return known_in(state.db, state.known_info, field)


static func known_in(db: GameDatabase, known: Array[String], field: String = ANY) -> Array[String]:
	var out: Array[String] = []
	for id: String in db.get_collection("city_info"):
		if known.has(id) and (field == ANY or JsonUtil.get_str(db.get_entry("city_info", id), "field") == field):
			out.append(id)
	return out
