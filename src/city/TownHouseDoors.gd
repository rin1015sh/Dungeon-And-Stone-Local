class_name TownHouseDoors
extends RefCounted
## 동네 일반 집의 문 자리(CT110 — tools/town_doors.gd가 집 그림 키트에서 뽑은 assets/town/houses/doors.json).
## 칸 → {house: 집 id, design: 바리에이션 함수}. 파일이 없으면 빈 것(문이 없다). 오토로드를 참조하지 않는다.

const PATH := "res://assets/town/houses/doors.json"


static func load_cells() -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(PATH):
		return out
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not d is Dictionary:
		return out
	var houses := JsonUtil.get_dict(d as Dictionary, "houses")
	for hid: String in houses:
		var e := JsonUtil.get_dict(houses, hid)
		var at := JsonUtil.get_array(e, "door")
		if at.size() == 2:
			out[Vector2i(int(at[0]), int(at[1]))] = {"house": hid, "design": JsonUtil.get_str(e, "design")}
	return out


## 그 집 실내 id(city.json interior.house_kinds[바리에이션] — 없으면 "").
static func interior_of(city_interior: Dictionary, design: String) -> String:
	return JsonUtil.get_str(JsonUtil.get_dict(city_interior, "house_kinds"), design)
