class_name CharacterRoller
extends RefCounted
## 캐릭터 생성 시 기본 스탯 굴림.
## 종족 stat_ranges + 시작 템플릿 stat_bonus_ranges를 각각 [최소, 최대] 정수 범위에서 굴려 더한다.
## 세부 스탯도 범위에 넣으면 같은 방식으로 굴린다(예: 바바리안 식욕).


static func roll_base_stats(db: GameDatabase, race_id: String, class_id: String, rng: Rng) -> Dictionary:
	var out: Dictionary = {}
	_add_ranges(out, JsonUtil.get_dict(db.get_entry("races", race_id), "stat_ranges"), rng)
	_add_ranges(out, JsonUtil.get_dict(db.get_entry("classes", class_id), "stat_bonus_ranges"), rng)
	return out


## 무작위 동료 탐험가(사용자 2026-10-25 — 파티 동료. 지금은 디버그로만 들인다): 쓸 수 있는 종족·템플릿에서 하나씩, 스탯 굴림,
## 레벨은 level(플레이어와 같게), id = mate_<번호>. 이름은 부르는 쪽이 붙인다(Strings — 이 파일은 오토로드를 쓰지 않는다).
static func random_companion(db: GameDatabase, rng: Rng, level: int, index: int) -> PlayerCharacter:
	var races: Array = db.get_collection("races").values().filter(func(r: Dictionary) -> bool: return JsonUtil.get_bool(r, "enabled", true))
	var classes: Array = db.get_collection("classes").values().filter(func(c: Dictionary) -> bool: return JsonUtil.get_bool(c, "enabled", true))
	var race := JsonUtil.get_str(rng.pick(races) as Dictionary, "id")
	var cls := JsonUtil.get_str(rng.pick(classes) as Dictionary, "id")
	var pc := PlayerCharacter.create(db, race, cls, "", roll_base_stats(db, race, cls, rng))
	pc.id = "mate_%d" % index
	pc.inventory.load_dict({"w": pc.inventory.width, "h": pc.inventory.height, "money": 0, "stacks": []})  # 소지품은 공용 가방(플레이어 것) 하나
	if level > pc.get_level():
		pc.progression.exp_total = Progression.exp_for_level(db, level)
		pc.set_level(level)
	pc.pool.fill_all()
	return pc


## 종족+템플릿을 합친 각 스탯의 가능한 [최소, 최대] (UI 표시·테스트용).
static func stat_bounds(db: GameDatabase, race_id: String, class_id: String) -> Dictionary:
	var out: Dictionary = {}
	for ranges: Dictionary in [
			JsonUtil.get_dict(db.get_entry("races", race_id), "stat_ranges"),
			JsonUtil.get_dict(db.get_entry("classes", class_id), "stat_bonus_ranges")]:
		for id: String in ranges:
			var r: Array = ranges[id]
			var cur: Array = out.get(id, [0, 0])
			out[id] = [int(cur[0]) + int(r[0]), int(cur[1]) + int(r[1])]
	return out


static func _add_ranges(out: Dictionary, ranges: Dictionary, rng: Rng) -> void:
	for id: String in ranges:
		var r: Array = ranges[id]
		out[id] = float(out.get(id, 0.0)) + float(rng.randi_range(int(r[0]), int(r[1])))
