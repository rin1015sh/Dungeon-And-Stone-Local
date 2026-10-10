class_name Modifier
extends RefCounted
## 스탯·자원 수정자. 출처(source_id)별로 붙이고 뗀다(정수 삭제, 장비 해제, 버프 만료).
## target: 스탯 id, 또는 접두어 대상
##   "max:<자원>"       자원 최대치
##   "regen:<자원>"     자원 재생량(단위 시간당)
##   "dmg_taken:<유형>" 받는 피해 배율(유형 = 피해 유형 id / physical / magical / all)
##   "dmg_dealt:<유형>" 주는 피해 배율

const PERMANENT := -1.0

var source_id: String = ""
var target: String = ""
var flat: float = 0.0
var percent: float = 0.0          ## 0.1 = +10%
var duration: float = PERMANENT   ## 남은 지속량. 음수면 영구
var unit: String = "turn"         ## 지속 단위: turn(전투 턴) / hour(게임 내 시간)


func _init(p_source: String = "", p_target: String = "", p_flat: float = 0.0, p_percent: float = 0.0,
		p_duration: float = PERMANENT, p_unit: String = "turn") -> void:
	source_id = p_source
	target = p_target
	flat = p_flat
	percent = p_percent
	duration = p_duration
	unit = p_unit


func is_permanent() -> bool:
	return duration < 0.0


func to_dict() -> Dictionary:
	return {"source": source_id, "target": target, "flat": flat, "percent": percent,
		"duration": duration, "unit": unit}


## d의 "source"가 없으면 source_override를 쓴다(데이터 정의의 수정자 목록용).
static func from_dict(d: Dictionary, source_override: String = "") -> Modifier:
	return Modifier.new(
		JsonUtil.get_str(d, "source", source_override),
		JsonUtil.get_str(d, "target"),
		JsonUtil.get_float(d, "flat"),
		JsonUtil.get_float(d, "percent"),
		JsonUtil.get_float(d, "duration", PERMANENT),
		JsonUtil.get_str(d, "unit", "turn"))
