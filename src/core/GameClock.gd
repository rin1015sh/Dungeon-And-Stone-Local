class_name GameClock
extends RefCounted
## 미궁 안 경과 시간(입장할 때 0). 이동·전투·휴식이 시간을 쓴다.
## 도시 달력(포탈 개방일, 귀환은 항상 입장 다음 날 정오)은 M4에서 따로 둔다.

signal advanced(hours: float, total_hours: float)

var total_hours: float = 0.0


func advance(hours: float) -> void:
	if hours <= 0.0:
		return
	total_hours += hours
	advanced.emit(hours, total_hours)


## 1일차부터 센다.
func day() -> int:
	return floori(total_hours / 24.0) + 1


func hour_of_day() -> float:
	return fmod(total_hours, 24.0)


## "07:30" 형식.
func hhmm() -> String:
	var minutes := floori(total_hours * 60.0) % (24 * 60)
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]


func to_dict() -> Dictionary:
	return {"total_hours": total_hours}


func load_dict(d: Dictionary) -> void:
	total_hours = JsonUtil.get_float(d, "total_hours")
