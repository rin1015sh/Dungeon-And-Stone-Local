class_name ResourceDef
extends RefCounted
## 자원 정의(data/resources.json 한 항목). 생명력·영혼력·허기 등 '소모하고 회복하는 게이지'.
## 스탯과 완전히 분리된다. 새 자원 = resources.json에 한 항목.

const ON_ZERO_NONE := "none"
const ON_ZERO_KILL := "kill"
const ON_ZERO_STATUS := "status"
const ON_ZERO_EVENT := "event"

var id: String = ""
var name_ko: String = ""
var color: Color = Color.GRAY
var max_value: Variant = 0.0      ## 숫자 또는 수식 문자열(max_formula / max)
var start: Variant = "full"       ## "full" / "empty" / 0~1 비율
var regen: Array[Dictionary] = [] ## [{trigger: turn|time|rest, basis: max_ratio|flat, rate: 숫자|수식}]
var scope: String = "always"      ## always / dungeon_only / combat_only
var thresholds: Array[Dictionary] = []  ## [{at_ratio, direction: down|up, apply_status? , event?}]
var on_zero_kind: String = ON_ZERO_NONE
var on_zero_id: String = ""       ## 상태 id 또는 이벤트 id
var recover_at_ratio: float = 0.0 ## 고갈 후 이 비율 이상이면 '회복'으로 본다(0 = 0보다 크면)
var visible: bool = true
var enabled: bool = true          ## false = 예약 자원(정의만)
var display_inverted: bool = false  ## 화면에는 최대치 − 값(허기: 속값은 포만도, 보이는 건 허기 — 0 = 배부름 · 100 = 굶주림, UI35)
var cost_strict: bool = false     ## true면 코스트로 0까지 깎을 수 없다(생명력)


static func from_dict(d: Dictionary) -> ResourceDef:
	var r := ResourceDef.new()
	r.id = JsonUtil.get_str(d, "id")
	r.name_ko = JsonUtil.get_str(d, "name_ko", r.id)
	r.color = Color.from_string(JsonUtil.get_str(d, "color"), Color.GRAY)
	r.max_value = d.get("max_formula", d.get("max", 0.0))
	r.start = d.get("start", "full")
	var rg: Variant = d.get("regen", [])
	if rg is Dictionary:
		r.regen.append(rg)
	elif rg is Array:
		for x: Variant in rg:
			if x is Dictionary:
				r.regen.append(x)
	for t: Variant in JsonUtil.get_array(d, "thresholds"):
		if t is Dictionary:
			r.thresholds.append(t)
	r.scope = JsonUtil.get_str(d, "scope", "always")
	var oz: Variant = d.get("on_zero")
	if oz is String:
		r.on_zero_kind = oz
	elif oz is Dictionary:
		var od: Dictionary = oz
		if od.has("status"):
			r.on_zero_kind = ON_ZERO_STATUS
			r.on_zero_id = JsonUtil.get_str(od, "status")
		elif od.has("event"):
			r.on_zero_kind = ON_ZERO_EVENT
			r.on_zero_id = JsonUtil.get_str(od, "event")
		r.recover_at_ratio = JsonUtil.get_float(od, "recover_at_ratio")
	r.visible = JsonUtil.get_bool(d, "visible", true)
	r.enabled = JsonUtil.get_bool(d, "enabled", true)
	r.display_inverted = JsonUtil.get_bool(d, "display_inverted")
	r.cost_strict = JsonUtil.get_bool(d, "cost_strict")
	return r


## 화면에 보일 값: display_inverted면 최대치 − 지금 값(막대도 이 값만큼 찬다).
func shown(current: float, maximum: float) -> float:
	return maxf(0.0, maximum - current) if display_inverted else current
