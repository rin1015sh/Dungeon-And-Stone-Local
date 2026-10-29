class_name CityUi
extends RefCounted
## 도시 화면 카드 스타일(피어 앤 헝거 2풍): 거의 검은 반투명 판 · 뼈빛 가는 테두리 · 뼈빛/핏빛 강조(돈은 palette.gold — UI43). 색·여백은 render.json city.ui.


static func c(key: String, fallback: Color = Color.MAGENTA) -> Color:
	return UiTheme.render_color("city.ui." + key, fallback)


## 카드 판 = 게임 전체 창 판(UiTheme.panel_box — 전투·대화창과 같은 모양, UI36).
static func card_box() -> StyleBoxFlat:
	return UiTheme.panel_box(UiTheme.render_float("city.ui.card_padding", 12.0))


static func plate_box(lit: bool) -> StyleBoxFlat:
	var sb := card_box()
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
	return p


static func label(text: String, style: String = "body", color_key: String = "bone") -> Label:
	var l := UiTheme.label(text, style)
	l.add_theme_color_override("font_color", c(color_key))
	return l


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
