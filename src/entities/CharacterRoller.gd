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
