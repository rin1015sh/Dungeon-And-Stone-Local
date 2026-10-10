class_name LightSource
extends RefCounted
## 들고 있는 광원(횃불 등). 한 번 켜면 끌 수 없고 시간이 지나면 꺼진다.
## 유효 시야 계산은 Vision이 한다(광원 반경은 그 입력 중 하나).

signal went_out(item_id: String)

var item_id: String = ""
var radius_m: float = 0.0
var hours_left: float = 0.0


func is_lit() -> bool:
	return hours_left > 0.0


## 켜진 광원의 반경(m). 꺼져 있으면 0.
func radius() -> float:
	return radius_m if is_lit() else 0.0


func ignite(p_item_id: String, p_radius_m: float, p_hours: float) -> void:
	item_id = p_item_id
	radius_m = p_radius_m
	hours_left = p_hours


func burn(hours: float) -> void:
	if not is_lit():
		return
	hours_left -= hours
	if hours_left <= 0.0:
		hours_left = 0.0
		went_out.emit(item_id)


func to_dict() -> Dictionary:
	return {"item": item_id, "radius_m": radius_m, "hours_left": hours_left}


func load_dict(d: Dictionary) -> void:
	item_id = JsonUtil.get_str(d, "item")
	radius_m = JsonUtil.get_float(d, "radius_m")
	hours_left = JsonUtil.get_float(d, "hours_left")
