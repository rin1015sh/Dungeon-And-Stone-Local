class_name CityUi
extends RefCounted
## 도시 화면 카드 스타일(피어 앤 헝거 2풍): 거의 검은 반투명 판 · 뼈빛 가는 테두리 · 호박색/핏빛 강조. 색·여백은 render.json city.ui.


static func c(key: String, fallback: Color = Color.MAGENTA) -> Color:
	return UiTheme.render_color("city.ui." + key, fallback)


static func card_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c("bg")
	sb.set_border_width_all(1)
	sb.border_color = c("border")
	sb.set_content_margin_all(UiTheme.render_float("city.ui.card_padding", 12.0))
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	return sb


static func plate_box(lit: bool) -> StyleBoxFlat:
	var sb := card_box()
	sb.shadow_size = 3
	sb.border_color = c("border_lit") if lit else c("border")
	sb.set_border_width_all(2 if lit else 1)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 3
	sb.content_margin_bottom = 4
	return sb


static func card() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", card_box())
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	return p


static func label(text: String, style: String = "body", color_key: String = "bone") -> Label:
	var l := UiTheme.label(text, style)
	l.add_theme_color_override("font_color", c(color_key))
	return l


## 카드 안 버튼: 어두운 판 + 뼈빛 테두리, 올리면 호박색 테두리. accent = 핏빛 바탕(미궁 입장).
static func button(text: String, cb: Callable, accent: bool = false) -> Button:
	var b := UiTheme.button(text, cb)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", UiTheme.metric("small_font_size", 14))
	var base := c("blood").darkened(0.2) if accent else Color(0.09, 0.085, 0.08, 0.95)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = base.lightened(0.12) if state == "hover" else (base.darkened(0.3) if state == "pressed" else base)
		sb.set_border_width_all(1)
		sb.border_color = c("border_lit") if state == "hover" else c("border")
		sb.set_content_margin_all(6)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", c("bone"))
	b.add_theme_color_override("font_hover_color", c("accent"))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


## 가는 막대(생명력 등).
static func bar(fill: Color) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size.y = UiTheme.metric("bar_height", 14) - 4
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.03, 0.03, 0.9)
	bg.set_border_width_all(1)
	bg.border_color = c("border").darkened(0.3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fg)
	return pb
