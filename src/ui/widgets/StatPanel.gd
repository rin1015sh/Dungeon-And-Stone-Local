class_name StatPanel
extends VBoxContainer
## StatBlock 표시: 핵심 스탯(기본값 → 최종값)과 세부 스탯 등록 현황.
## 최종값이 기본값보다 높으면 good, 낮으면 bad 색.

var _stats: StatBlock = null
var _grid: GridContainer
var _summary: Label


func _init() -> void:
	_grid = GridContainer.new()
	_grid.columns = 3
	add_child(_grid)
	_summary = UiTheme.label("", "small", "text_dim")
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary)


func bind(stats: StatBlock) -> void:
	if _stats != null and _stats.changed.is_connected(refresh):
		_stats.changed.disconnect(refresh)
	_stats = stats
	_stats.changed.connect(refresh)
	refresh()


func refresh() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	_add_row(Strings.t("foundation.col_stat"), Strings.t("foundation.col_base"), Strings.t("foundation.col_value"), "text_dim", "text_dim")
	for id in _stats.ids("core"):
		var def := _stats.get_def(id)
		if not def.visible:
			continue
		var base := _stats.get_base(id)
		var value := _stats.get_value(id)
		var tone := "text"
		if value > base + 0.001:
			tone = "good"
		elif value < base - 0.001:
			tone = "bad"
		_add_row(def.name_ko, UiTheme.num(base), UiTheme.num(value), "text_dim", tone)
	var subs := _stats.ids("sub")
	var hidden_count := 0
	var wired_count := 0
	for id in subs:
		var def := _stats.get_def(id)
		if not def.visible:
			hidden_count += 1
		if def.implemented:
			wired_count += 1
	_summary.text = Strings.t("foundation.sub_stats", {"count": subs.size(), "hidden": hidden_count, "wired": wired_count})


func _add_row(a: String, b: String, c: String, base_tone: String, value_tone: String) -> void:
	_grid.add_child(UiTheme.label(a))
	var lb := UiTheme.label(b, "body", base_tone)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_child(lb)
	var lc := UiTheme.label(c, "body", value_tone)
	lc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_child(lc)
