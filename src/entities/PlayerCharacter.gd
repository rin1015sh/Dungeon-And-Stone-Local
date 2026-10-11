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
	grant_innate_skills(pc)
	return pc


## 모든 아군(플레이어·동료)이 시작부터 가진 기본 스킬(balance party.innate_skills: 대화·조사)을 준다.
## 이미 있으면 건너뛰므로 불러오기(M4 저장) 뒤에 다시 불러도 안전하다. 동료 생성(M4)도 이 함수를 부른다.
static func grant_innate_skills(a: Actor) -> void:
	for id: Variant in a.db.bal("party.innate_skills", []):
		if a.db.has_entry("skills", str(id)):
			a.learn_skill(str(id))


func race_name() -> String:
	return JsonUtil.get_str(db.get_entry("races", race_id), "name_ko", race_id)


func template_name() -> String:
	return JsonUtil.get_str(db.get_entry("classes", class_id), "name_ko", class_id)


func attack_damage_type() -> String:
	return JsonUtil.get_str(db.get_entry("classes", class_id), "attack_type", "blunt")
