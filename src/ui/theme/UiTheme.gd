class_name UiTheme
extends RefCounted
## render.json(팔레트·폰트·UI 수치)으로 어두운 기본 테마를 코드로 만든다(.tres 없음).
## 위젯 생성 도우미(label/button/section)도 여기 둔다 — 화면 코드에 색·크기 숫자를 쓰지 않기 위해.

const FONT_EXTENSIONS := ["ttf", "otf", "woff", "woff2"]

static var _render: Dictionary = {}
static var _font: Font = null


static func build(render: Dictionary) -> Theme:
	_render = render
	_font = resolve_font(JsonUtil.get_dict(render, "font"))
	var th := Theme.new()
	th.default_font = _font
	th.default_font_size = metric("font_size", 16)
	var r := metric("corner_radius", 2)
	var pad := metric("padding", 8)
	var panel := box(color("panel"), color("panel_border"), r, pad)
	for t: String in ["PanelContainer", "Panel"]:
		th.set_stylebox("panel", t, panel)
	th.set_stylebox("panel", "PopupMenu", box(color("panel"), color("panel_border"), r, pad))
	th.set_stylebox("panel", "TooltipPanel", box(color("panel"), color("accent_dim"), r, pad))
	th.set_color("font_color", "TooltipLabel", color("text"))
	for t: String in ["Button", "OptionButton", "CheckButton"]:
		th.set_stylebox("normal", t, box(color("button"), color("panel_border"), r, pad))
		th.set_stylebox("hover", t, box(color("button_hover"), color("accent_dim"), r, pad))
		th.set_stylebox("pressed", t, box(color("button_pressed"), color("accent"), r, pad))
		th.set_stylebox("disabled", t, box(color("button_disabled"), color("panel_border"), r, pad))
		th.set_stylebox("focus", t, box(Color.TRANSPARENT, color("select"), r, pad))  # 키보드 커서 = 뼈빛(UI43)
	for t: String in ["Label", "Button", "OptionButton", "CheckButton", "CheckBox", "PopupMenu"]:
		th.set_color("font_color", t, color("text"))
	for t: String in ["Button", "OptionButton", "CheckButton"]:
		th.set_color("font_hover_color", t, color("text_title"))
		th.set_color("font_pressed_color", t, color("text_title"))
		th.set_color("font_focus_color", t, color("text_title"))
		th.set_color("font_disabled_color", t, color("text_disabled"))
	th.set_color("font_hover_color", "PopupMenu", color("text_title"))
	th.set_color("default_color", "RichTextLabel", color("text"))
	th.set_stylebox("background", "ProgressBar", box(color("bar_bg"), Color.TRANSPARENT, r, 0))
	th.set_stylebox("fill", "ProgressBar", box(color("accent"), Color.TRANSPARENT, r, 0))
	th.set_constant("separation", "VBoxContainer", metric("spacing", 8))
	th.set_constant("separation", "HBoxContainer", metric("spacing", 8))
	th.set_constant("h_separation", "GridContainer", metric("spacing", 8))
	th.set_constant("v_separation", "GridContainer", metric("spacing", 8) / 2)
	return th


## 팝업·툴팁처럼 테마 상속이 끊길 수 있는 곳까지 같은 폰트를 쓰게 한다.
static func apply_global_font() -> void:
	if _font == null:
		return
	ThemeDB.fallback_font = _font
	var dt := ThemeDB.get_default_theme()
	if dt != null:
		dt.default_font = _font


## 폰트 결정: render.font.path → assets/fonts의 첫 폰트 파일 → 시스템 한글 폰트(SystemFont).
## 웹 내보내기에는 시스템 폰트가 없으므로 OFL 한글 폰트를 assets/fonts에 넣어야 한다.
## font.fallbacks = 본 폰트에 없는 글자(기호·드문 한글)를 채울 폰트, spacing_top/bottom = 줄 위아래 여백(px) — 송명 본문 + Noto 대신(UI45).
static func resolve_font(cfg: Dictionary) -> Font:
	var path := JsonUtil.get_str(cfg, "path")
	if not path.is_empty() and ResourceLoader.exists(path):
		var f := load(path) as Font
		if f != null:
			return _dressed(f, cfg)
	var dir := JsonUtil.get_str(cfg, "dir", "res://assets/fonts")
	if DirAccess.dir_exists_absolute(dir):
		for file: String in DirAccess.get_files_at(dir):
			var name := file.trim_suffix(".import").trim_suffix(".remap")
			if name.get_extension().to_lower() in FONT_EXTENSIONS:
				var p := dir.path_join(name)
				if ResourceLoader.exists(p):
					var f := load(p) as Font
					if f != null:
						return f
	var sys := SystemFont.new()
	var names := PackedStringArray()
	for n: Variant in JsonUtil.get_array(cfg, "system_fallbacks"):
		names.append(str(n))
	sys.font_names = names
	return sys


static func _dressed(base: Font, cfg: Dictionary) -> Font:
	var fv := FontVariation.new()
	fv.base_font = base
	var fb: Array[Font] = []
	for p: Variant in JsonUtil.get_array(cfg, "fallbacks"):
		if ResourceLoader.exists(str(p)):
			var f := load(str(p)) as Font
			if f != null:
				fb.append(f)
	fv.fallbacks = fb
	fv.spacing_top = JsonUtil.get_int(cfg, "spacing_top")
	fv.spacing_bottom = JsonUtil.get_int(cfg, "spacing_bottom")
	return fv


static func color(key: String, fallback: Color = Color.MAGENTA) -> Color:
	var pal := JsonUtil.get_dict(_render, "palette")
	return Color.from_string(JsonUtil.get_str(pal, key), fallback)


static func metric(key: String, fallback: int = 0) -> int:
	return JsonUtil.get_int(JsonUtil.get_dict(_render, "ui"), key, fallback)


static func ui_float(key: String, fallback: float = 0.0) -> float:
	return JsonUtil.get_float(JsonUtil.get_dict(_render, "ui"), key, fallback)


static func ui_array(key: String) -> Array:
	return JsonUtil.get_array(JsonUtil.get_dict(_render, "ui"), key)


static func ui_dict(key: String) -> Dictionary:
	return JsonUtil.get_dict(JsonUtil.get_dict(_render, "ui"), key)


## render.json의 다른 구역 값("city.pixel_scale"처럼 점 경로).
static func render_float(path: String, fallback: float = 0.0) -> float:
	var v: Variant = GameDatabase.single(_render, path, fallback)
	return float(v) if (v is float or v is int) else fallback


static func render_dict(path: String) -> Dictionary:
	var v: Variant = GameDatabase.single(_render, path, {})
	return v if v is Dictionary else {}


static func render_array(path: String) -> Array:
	var v: Variant = GameDatabase.single(_render, path, [])
	return v if v is Array else []


static func render_str(path: String, fallback: String = "") -> String:
	return str(GameDatabase.single(_render, path, fallback))


static func render_color(path: String, fallback: Color = Color.MAGENTA) -> Color:
	return Color.from_string(str(GameDatabase.single(_render, path, "")), fallback)


## 반투명 패널(탐험 화면 위에 겹치는 HUD·기록창·디버그 패널용).
## 탐험 정보·선택 창·스킬 알림창 판 — 게임 전체 창 판과 같다(UI36).
static func translucent_panel() -> StyleBoxFlat:
	return panel_box(metric("padding", 8))


static func box(bg: Color, border: Color, radius: int, padding: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border.a > 0.0:
		sb.set_border_width_all(1)
		sb.border_color = border
	sb.set_content_margin_all(padding)
	return sb


## 게임 전체가 쓰는 창 판(전투 아래 창·대화창·도시 카드 — 사용자 결정 2026-10-27, UI36): 거의 검은 판 + 2px 테두리.
static func panel_box(padding: float) -> StyleBoxFlat:
	var sb := box(color("panel_bg"), color("slot_border"), 3, 0)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(padding)
	return sb


## 창 판의 바탕만 alpha로(테두리는 그대로) — 전투 아래 창(render.json ui.combat_window_alpha).
static func see_through(sb: StyleBoxFlat, alpha: float) -> StyleBoxFlat:
	sb.bg_color.a = alpha
	return sb


## style: body / small / header / subtitle / title (render.ui.<style>_font_size)
static func label(text: String, style: String = "body", color_key: String = "text") -> Label:
	var l := Label.new()
	l.text = text
	var base := metric("font_size", 16)
	l.add_theme_font_size_override("font_size", base if style == "body" else metric(style + "_font_size", base))
	l.add_theme_color_override("font_color", color(color_key))
	return l


static func button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on_press)
	return b


## 키보드로 다루는 패널(디버그 등): 보이면 첫 버튼에 포커스(W/A/S/D·방향키로 옮기고 Enter), 숨으면 포커스를 놓는다.
static func keyboard_panel(panel: Control) -> void:
	panel.visibility_changed.connect(func() -> void:
		if panel.is_visible_in_tree():
			focus_first.call_deferred(panel)
		else:
			var owner := panel.get_viewport().gui_get_focus_owner() if panel.is_inside_tree() else null
			if owner != null and panel.is_ancestor_of(owner):
				owner.release_focus())


static func focus_first(root: Node) -> void:
	for c in root.find_children("*", "BaseButton", true, false):
		var b := c as BaseButton
		if b.is_visible_in_tree() and not b.disabled and b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus()
			return


## 제목이 달린 패널 상자. 내용을 넣을 VBoxContainer를 돌려준다.
static func section(parent: Node, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	v.add_child(label(title, "header", "text_title"))
	return v


## 정수면 정수로, 아니면 소수 한 자리.
static func num(v: float) -> String:
	if absf(v - roundf(v)) < 0.05:
		return str(roundi(v))
	return "%.1f" % v
