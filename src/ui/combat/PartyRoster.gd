class_name PartyRoster
extends VBoxContainer
## 전투 아래 오른쪽 파티 창(피어 앤 헝거의 이름·체력·이성 줄처럼): 아군 한 줄씩 — 추가 턴 작은 창 자리(C14 — 늘 비워 둔 칸이라 떠도 이름이 밀리지 않는다)
## · 이름 · 기세 삼각형(RevPips — C20) · 상태 아이콘(3개씩 깜빡이며 넘김 — StatusIcons, UI25) · 계측값 · 생명력 막대 · 영혼력 막대(+ 전투 게이지).
## 누가 누구를 치는지(정해 둔 행동)는 보이지 않는다(사용자 2026-11-02). 지금 차례인 사람의 줄은 뼈빛으로 빛나고, 아군을 대상으로 고르는 중이면 그 줄에 뼈빛 테두리.
## 줄 높이·간격 = 왼쪽 명령 칸과 같다(combat_cmd_slot_height·combat_slot_gap — 두 창의 줄이 나란하다, 사용자 요청 2026-10-24).

const RES := ["hp", "soul"]

var _rows: Dictionary = {}  # Combatant -> {panel, name, extra, rev, icons, status, bars: {res: [bar, label]}}
var _db: GameDatabase
var _current: Combatant = null
var _target: Combatant = null
var _battle: Battle = null
var _rev_pick: Dictionary = {}  # Combatant -> 이번 행동에 얹을 기세(행동 정하기 · 정해 둔 행동)


func setup(db: GameDatabase, battle: Battle = null) -> void:
	_db = db
	_battle = battle
	add_theme_constant_override("separation", UiTheme.metric("combat_slot_gap", 4))


func add_unit(u: Combatant) -> void:
	if _rows.has(u) or u.side != Combatant.SIDE_PARTY:
		return
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = UiTheme.metric("combat_cmd_slot_height", 40)
	add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UiTheme.metric("spacing", 8) + 4)
	panel.add_child(h)
	var slot := CenterContainer.new()  # 추가 턴 작은 창 자리(이름 왼쪽 — 사용자 2026-10-24·2026-11-02): 늘 비워 둔다
	slot.custom_minimum_size.x = UiTheme.metric("combat_roster_extra_width", 64)
	h.add_child(slot)
	var name_box := HBoxContainer.new()  # 이름 + 기세 삼각형
	name_box.custom_minimum_size.x = UiTheme.metric("combat_roster_name_width", 170)
	name_box.add_theme_constant_override("separation", 6)
	name_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(name_box)
	var extra := PanelContainer.new()
	var ebox := UiTheme.box(UiTheme.color("panel_bg"), UiTheme.color("select"), 2, 0)
	ebox.content_margin_left = 5
	ebox.content_margin_right = 5
	extra.add_theme_stylebox_override("panel", ebox)
	extra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	extra.visible = false
	extra.add_child(UiTheme.label(Strings.t("combat.extra_turn"), "small", "select"))
	slot.add_child(extra)
	var nm := UiTheme.label(u.label(), "body", "text")
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.custom_minimum_size.x = 1
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_box.add_child(nm)
	var rev := RevPips.new()
	name_box.add_child(rev)
	var icons := StatusIcons.new(true)
	h.add_child(icons)
	var status := UiTheme.label("", "small", "warn")
	status.custom_minimum_size.x = UiTheme.metric("combat_roster_status_width", 130)
	status.clip_text = true
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(status)
	var bars := {}
	for r: String in RES:
		if not u.actor.pool.has_resource(r) or u.actor.pool.get_max(r) <= 0.0:
			continue
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 0)
		box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(box)
		var top := HBoxContainer.new()
		box.add_child(top)
		var rl := UiTheme.label(_db.resources[r].name_ko, "small", "text_dim")
		rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(rl)
		var val := UiTheme.label("", "body", "text")
		top.add_child(val)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size.y = UiTheme.metric("combat_roster_bar_height", 5)
		bar.add_theme_stylebox_override("fill", UiTheme.box(_db.resources[r].color, Color.TRANSPARENT, 1, 0))
		bar.add_theme_stylebox_override("background", UiTheme.box(Color(0, 0, 0, 0.5), Color.TRANSPARENT, 1, 0))
		box.add_child(bar)
		bars[r] = [bar, val]
	_rows[u] = {"panel": panel, "name": nm, "extra": extra, "rev": rev, "icons": icons, "status": status, "bars": bars}
	refresh()


func remove_unit(u: Combatant) -> void:
	if _rows.has(u):
		(_rows[u]["panel"] as Node).queue_free()
		_rows.erase(u)


func rev_pick(u: Combatant) -> int:
	return int(_rev_pick.get(u, 0))


## 이번 행동에 얹을 기세(0이면 지운다).
func set_rev_pick(u: Combatant, n: int) -> void:
	if n > 0:
		_rev_pick[u] = n
	else:
		_rev_pick.erase(u)
	refresh()


func set_current(u: Combatant) -> void:
	_current = u
	_style()


func set_target(u: Combatant) -> void:
	_target = u if u != null and _rows.has(u) else null
	_style()


func refresh() -> void:
	for u: Combatant in _rows:
		var row: Dictionary = _rows[u]
		for r: String in row["bars"]:
			var pair: Array = row["bars"][r]
			var mx := u.actor.pool.get_max(r)
			var rd := u.actor.pool.get_def(r)
			var v := rd.shown(u.actor.pool.get_current(r), mx)  # 허기는 차오를수록 배고픔(UI35)
			(pair[0] as ProgressBar).max_value = maxf(1.0, mx)
			(pair[0] as ProgressBar).value = v
			(pair[1] as Label).text = "%d/%d" % [roundi(v) if rd.display_inverted else ceili(v), roundi(mx)]
		(row["icons"] as StatusIcons).show_for(u.actor)
		var uses := _battle != null and BattleRev.uses_rev(_battle, u) and u.is_active()
		(row["rev"] as RevPips).show_rev(BattleRev.cap(_db) if uses else 0, u.rev, int(_rev_pick.get(u, 0)))
		var names := PackedStringArray()  # 상태는 아이콘으로(UI24) — 글은 계측값만
		for m: Dictionary in Meters.list(_db, u.actor):
			names.append("%s %d" % [str(m["name"]), roundi(float(m["value"]))])
		(row["status"] as Label).text = ", ".join(names)
		(row["status"] as Label).visible = not names.is_empty()  # 계측값이 있을 때만 자리를 차지한다(파티 창을 좁게)
		(row["panel"] as Control).modulate.a = 1.0 if u.is_active() else 0.45
	_style()


func _style() -> void:
	for u: Combatant in _rows:
		var row: Dictionary = _rows[u]
		var cur := u == _current
		var tgt := u == _target
		var glow := UiTheme.ui_dict("combat_turn_glow")  # 지금 차례 = 뼈빛 띠(피어 앤 헝거의 빛나는 줄처럼 — 사용자 2026-11-02)
		var sel := UiTheme.color("select")
		var bg := Color(sel, JsonUtil.get_float(glow, "bg_alpha", 0.2)) if cur else Color(0, 0, 0, 0)
		var border := sel if tgt else (Color(sel, JsonUtil.get_float(glow, "border_alpha", 0.6)) if cur else Color(0, 0, 0, 0))
		var box := UiTheme.box(bg, border, 2, UiTheme.metric("combat_roster_pad", 6))
		if cur:
			box.shadow_color = Color(sel, JsonUtil.get_float(glow, "shadow_alpha", 0.3))
			box.shadow_size = int(JsonUtil.get_float(glow, "shadow_size", 8))
			box.set_border_width_all(1)
		box.content_margin_top = 0  # 높이는 명령 칸에 맞춘다(내용은 가운데)
		box.content_margin_bottom = 0
		if tgt:
			box.set_border_width_all(2)
		(row["panel"] as PanelContainer).add_theme_stylebox_override("panel", box)
		(row["name"] as Label).add_theme_color_override("font_color", UiTheme.color("select" if cur else "text"))
		(row["extra"] as Control).visible = cur and u.extra_turn and u.is_active()  # 지금 차례가 추가 차례일 때만
