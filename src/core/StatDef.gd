class_name StatDef
extends RefCounted
## 스탯 정의(data/stats.json 한 항목). 값 계산은 StatBlock이 한다.
## parent/coef: 이 스탯 1당 부모 스탯이 coef만큼 오른다(세부 스탯 → 핵심 스탯).

var id: String = ""
var name_ko: String = ""
var group: String = "body"      ## body(육체) / mind(정신) / ability(이능) / special(특수)
var tier: String = "sub"        ## core(핵심 5종) / sub(세부)
var rarity: String = "common"
var parent: String = ""
var coef: float = 0.0
var visible: bool = true        ## false = 투명 스탯
var implemented: bool = false   ## 효과가 게임 규칙에 연결됐는지(진행 추적용)
var default_value: float = 0.0
var has_min: bool = false
var min_value: float = 0.0
var has_max: bool = false
var max_value: float = 0.0


static func from_dict(d: Dictionary) -> StatDef:
	var s := StatDef.new()
	s.id = JsonUtil.get_str(d, "id")
	s.name_ko = JsonUtil.get_str(d, "name_ko", s.id)
	s.group = JsonUtil.get_str(d, "group", "body")
	s.tier = JsonUtil.get_str(d, "tier", "sub")
	s.rarity = JsonUtil.get_str(d, "rarity", "common")
	s.parent = JsonUtil.get_str(d, "parent")
	s.coef = JsonUtil.get_float(d, "coef")
	s.visible = JsonUtil.get_bool(d, "visible", true)
	s.implemented = JsonUtil.get_bool(d, "implemented")
	s.default_value = JsonUtil.get_float(d, "default")
	s.has_min = JsonUtil.is_number(d.get("min"))
	s.min_value = JsonUtil.get_float(d, "min")
	s.has_max = JsonUtil.is_number(d.get("max"))
	s.max_value = JsonUtil.get_float(d, "max")
	return s


func clamp_value(v: float) -> float:
	if has_min:
		v = maxf(v, min_value)
	if has_max:
		v = minf(v, max_value)
	return v
