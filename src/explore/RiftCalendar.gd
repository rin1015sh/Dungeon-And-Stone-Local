class_name RiftCalendar
extends RefCounted
## 균열 자연 개방 달력(명세 §8.1). 1달 = 원정 1회(1~5층은 달마다 포탈이 열린다). 도시 달력(M4)이 생기면 거기에 붙인다.
## 직전 자연 개방 뒤 지난 달 수에 따라 이번 달 열릴 확률(balance rift.open_chance_by_months, 표 끝값 이후는 마지막 값)
## — 2달 미만 0, 대부분 4~5달, 8달이면 확정. 열리면 open_after_hours ~ (폐쇄 − open_before_close_hours) 사이 무작위 시각.
## 강제 개방(마석)은 달력에 영향이 없다.

var months_since_open: int = 0


func _init(db: GameDatabase = null) -> void:
	if db != null:
		months_since_open = int(db.bal("rift.start_months_since_open", 4))


static func chance(db: GameDatabase, months: int) -> float:
	var table: Dictionary = db.bal("rift.open_chance_by_months", {})
	var best := -1
	for k: Variant in table:
		var m := int(str(k))
		if m <= months and m > best:
			best = m
	return float(table.get(str(best), 0.0)) if best >= 0 else 0.0


## 이번 달(원정)을 굴린다. 열리면 열리는 게임 시각(시간), 아니면 -1.
func roll_month(db: GameDatabase, rng: Rng, close_hours: float) -> float:
	if not rng.chance(chance(db, months_since_open)):
		months_since_open += 1
		return -1.0
	months_since_open = 0
	var lo := float(db.bal("rift.open_after_hours", 48))
	var hi := maxf(lo, close_hours - float(db.bal("rift.open_before_close_hours", 24)))
	return rng.randf_range(lo, hi)


func to_dict() -> Dictionary:
	return {"months_since_open": months_since_open}


func load_dict(d: Dictionary) -> void:
	months_since_open = JsonUtil.get_int(d, "months_since_open")
