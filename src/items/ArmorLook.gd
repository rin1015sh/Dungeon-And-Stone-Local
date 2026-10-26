class_name ArmorLook
extends RefCounted
## 갑옷 겹 그림 고르기(render.json view.armor_art, ASSUMPTIONS AM43): 장착한 장비(칸 = order)의 소재 종류가 sets에 있으면
## 그 벌의 겹 이름 "<벌>_<칸>"(예: leather_body · iron_head)을 얹는 순서대로 돌려준다. 그림 파일은 화면 쪽이 찾는다(없으면 건너뜀).


static func cfg(render: Dictionary) -> Dictionary:
	return JsonUtil.get_dict(JsonUtil.get_dict(render, "view"), "armor_art")


static func layers(db: GameDatabase, equipment: Equipment, render: Dictionary) -> Array[String]:
	var c := cfg(render)
	var sets := JsonUtil.get_dict(c, "sets")
	var out: Array[String] = []
	for slot: Variant in JsonUtil.get_array(c, "order"):
		var item_id := equipment.item_in(str(slot))
		if item_id.is_empty():
			continue
		var forged := JsonUtil.get_dict(db.get_entry("items", item_id), "forged")
		var kind := JsonUtil.get_str(db.get_entry("materials", JsonUtil.get_str(forged, "material")), "kind")
		if sets.has(kind):
			out.append("%s_%s" % [sets[kind], slot])
	return out


## 탐험 맵 겹 시트 경로들(그림이 있는 것만).
static func map_paths(db: GameDatabase, equipment: Equipment, render: Dictionary, race: String) -> Array[String]:
	var dir := JsonUtil.get_str(cfg(render), "map_dir").path_join(race)
	return _existing(dir, layers(db, equipment, render))


## 전투 그림 겹 경로들(view = back|side, 그림이 있는 것만).
static func party_paths(db: GameDatabase, equipment: Equipment, render: Dictionary, race: String, view: String) -> Array[String]:
	var dir := JsonUtil.get_str(cfg(render), "party_dir").path_join(race + "_" + view)
	return _existing(dir, layers(db, equipment, render))


static func _existing(dir: String, names: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for n in names:
		var path := dir.path_join(n + ".webp")
		if ResourceLoader.exists(path):
			out.append(path)
	return out
