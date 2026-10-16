class_name EndScreen
extends Control
## 탐험이 끝났을 때의 짧은 결과 화면: 층 폐쇄로 강제 귀환 / 사망 / 탐험 포기.
## 살아 있으면 도시로(Main), 죽었으면 타이틀로 돌아간다(저장은 사망 때 지운다 — 묘비 목록은 아직 없다).

signal done

var _kind: String = "closed"
var _info: Dictionary = {}


func setup(kind: String, info: Dictionary) -> void:
	_kind = kind
	_info = info


func _ready() -> void:
	var died := _kind == "died"
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTheme.metric("spacing", 8) * 2)
	v.custom_minimum_size.x = UiTheme.metric("menu_button_width", 260) * 2
	center.add_child(v)
	var kind := _kind if _kind in ["died", "closed", "abandoned"] else "closed"
	var title := UiTheme.label(Strings.t("end." + kind + "_title"), "title", "bad" if died else "text_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var body_key := "end." + kind + "_body"
	var body := UiTheme.label(Strings.t(body_key, {"name": _info.get("name", ""), "floor": _info.get("floor", ""),
		"cause": describe_cause(DataRegistry.db, str(_info.get("cause", "")))}), "subtitle", "text")
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	for line: String in [
			Strings.t("end.summary_time", {"day": _info.get("day", 1), "hours": roundi(float(_info.get("hours", 0.0)))}),
			Strings.t("end.summary_steps", {"steps": _info.get("steps", 0)}),
			Strings.t("end.summary_found", {"landmarks": _info.get("landmarks", 0), "landmarks_total": _info.get("landmarks_total", 0),
				"portals": _info.get("portals", 0), "portals_total": _info.get("portals_total", 0)})]:
		var l := UiTheme.label(line, "small", "text_dim")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var back := UiTheme.button(Strings.t("end.to_title" if died else "end.to_city"), func() -> void: done.emit())
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(back)
	back.grab_focus.call_deferred()


## 사망 원인 문자열("status:starvation" 등)을 읽을 수 있는 말로.
static func describe_cause(db: GameDatabase, cause: String) -> String:
	if cause.begins_with("status:"):
		return DataNames.entry(db, "statuses", cause.trim_prefix("status:"))
	if cause.begins_with("attack:"):
		return DataNames.entry(db, "monsters", cause.trim_prefix("attack:"))
	if cause == "debug":
		return Strings.t("cause.debug")
	for k: String in ["reflect", "counter"]:  # "reflect:<몬스터 id>" — 상대의 반사·반격
		if cause.begins_with(k + ":"):
			return Strings.t("cause." + k, {"name": DataNames.entry(db, "monsters", cause.trim_prefix(k + ":"))})
	if cause.begins_with("self:") or cause.begins_with("skill:"):
		return Strings.t("cause.self")
	if cause.begins_with("effect:") or cause.begins_with("hazard"):
		return Strings.t("cause.hazard")
	return Strings.t("cause.unknown")
