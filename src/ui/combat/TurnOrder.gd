class_name TurnOrder
extends PanelContainer
## 행동 순서(사용자 2026-11-07 "누가 행동할지 보이게 — 게임 전략에 더 도움", CB7 — UI7의 "순서 표시 없음"을 바꿈):
## 무대 왼쪽 위에 앞으로의 차례 n개(Battle.preview — CTB 게이지 그대로, 스킬 delay_cost는 모른다)를 번호와 이름으로.
## 아군 = 뼈빛(palette.select), 적 = 보통 글자. 큰 몸짓(예고 — BattleDelayed)이 터질 그 적의 차례에는 붉은 별 아이콘.
## 같은 이름 무리는 무대 이름 앞의 번호(BattlerView.set_order)로 가린다. 문구 없이 번호 · 이름만(부연설명 금지).
## 수치(줄 수 · 자리 · 아이콘 크기)는 render.json ui.turn_order.

var _battle: Battle
var _rows: VBoxContainer
var _cfg: Dictionary = {}


func setup(b: Battle) -> void:
	_battle = b
	_cfg = UiTheme.ui_dict("turn_order")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UiTheme.translucent_panel())
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	offset_left = JsonUtil.get_float(_cfg, "x", 20)
	offset_top = JsonUtil.get_float(_cfg, "y", 20)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", int(JsonUtil.get_float(_cfg, "gap", 2)))
	add_child(_rows)


## 앞으로의 차례 n개.
func order() -> Array[Combatant]:
	if _battle == null or not _battle.result.is_empty():
		var none: Array[Combatant] = []
		return none
	return _battle.preview(int(JsonUtil.get_float(_cfg, "count", 6)))


## 차례 목록에서 큰 몸짓이 터지는 자리(목록 번호 → true). 예고는 그 적의 차례 시작을 left번 지나면 터진다 —
## 지금 행동 중인 적(목록 맨 앞 · 이미 차례가 시작됨)은 그 다음 차례부터 센다.
func fires(list: Array[Combatant]) -> Dictionary:
	var out := {}
	var seen := {}
	for i in list.size():
		var u := list[i]
		var q: Array = u.memo.get("delayed", [])
		if q.is_empty():
			continue
		var started := i == 0 and u == _battle.current
		if started and not seen.has(u):
			seen[u] = 0
			continue
		seen[u] = int(seen.get(u, 0)) + 1
		for item: Dictionary in q:
			if int(item.get("left", 0)) == int(seen[u]):
				out[i] = true
	return out


func refresh() -> void:
	if _rows == null:
		return
	for c in _rows.get_children():
		c.queue_free()
	var list := order()
	visible = not list.is_empty()
	var boom := fires(list)
	var icon := StatusIcons.texture(_battle.db, BattleDelayed.WINDUP)
	var px := JsonUtil.get_float(_cfg, "icon_px", 18)
	for i in list.size():
		var u := list[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var color := "select" if u.side == Combatant.SIDE_PARTY else ("text_title" if i == 0 else "text")
		var lab := UiTheme.label(Strings.t("combat.order_row", {"n": i + 1, "name": u.label()}), "small", color)
		if i > 0:
			lab.modulate.a = JsonUtil.get_float(_cfg, "later_alpha", 0.8)
		row.add_child(lab)
		if boom.has(i) and icon != null:
			var tr := TextureRect.new()
			tr.texture = icon
			tr.custom_minimum_size = Vector2(px, px)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(tr)
		_rows.add_child(row)


## 적마다 다음 차례 번호(무대 이름 앞 — 같은 이름 무리를 가린다). 목록에 없으면 0.
func first_index() -> Dictionary:
	var out := {}
	var list := order()
	for i in list.size():
		if not out.has(list[i]):
			out[list[i]] = i + 1
	return out
