class_name PlayerCharacter
extends Actor
## 플레이어 캐릭터: 종족·시작 템플릿·이름. 시작 소지품은 템플릿의 start_items.

var race_id: String = ""
var class_id: String = ""


## 종족·템플릿 범위에서 굴린 기본 스탯(bases)으로 캐릭터를 만든다.
static func create(p_db: GameDatabase, p_race: String, p_class: String, p_name: String,
		bases: Dictionary) -> PlayerCharacter:
	var level := int(p_db.bal("char_creation.start_level", 1))
	var pc := PlayerCharacter.new(p_db, bases, level)
	pc.id = "player"
	pc.race_id = p_race
	pc.class_id = p_class
	pc.display_name = p_name
	for item: Variant in JsonUtil.get_array(p_db.get_entry("classes", p_class), "start_items"):
		if item is Dictionary:
			pc.inventory.add(JsonUtil.get_str(item, "id"), JsonUtil.get_int(item, "count", 1))
	return pc


func race_name() -> String:
	return JsonUtil.get_str(db.get_entry("races", race_id), "name_ko", race_id)


func template_name() -> String:
	return JsonUtil.get_str(db.get_entry("classes", class_id), "name_ko", class_id)
