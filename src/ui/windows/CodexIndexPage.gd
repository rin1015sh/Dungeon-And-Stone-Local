class_name CodexIndexPage
extends MenuPage
## 도감(B) 왼쪽 쪽(UI32): 몬스터 · 서적 분야들(city.json library.fields — 읽은 대목 수). W/S로 옮기면 오른쪽 쪽이 바로 바뀐다(picked).

signal picked(section: String)

const MONSTERS := "monsters_book"  ## 몬스터 도감 칸(서적 분야 id와 겹치지 않게)

var sections: Array[String] = []
var _rows: Array[PanelContainer] = []
var _cursor: int = 0


func _init() -> void:
	super(Strings.t("bestiary.title"))


func setup(db: GameDatabase, known: Array[String]) -> void:
	custom_minimum_size.x = MenuPage.cfg("codex_index_width", 250.0)
	sections.clear()
	sections.append(MONSTERS)
	sections.append_array(CityInfo.field_ids(db))
	for id in sections:
		var row := PanelContainer.new()
		var text := Strings.t("codex.monsters") if id == MONSTERS \
			else Strings.t("codex.section", {"name": CityInfo.field_name(db, id), "n": CityInfo.known_in(db, known, id).size()})
		row.add_child(UiTheme.label(text, "body", "text_title" if id == MONSTERS else "text"))
		content.add_child(row)
		_rows.append(row)
	_paint_rows()


func current() -> String:
	return sections[_cursor] if _cursor < sections.size() else MONSTERS


func select(section: String) -> void:
	_cursor = maxi(0, sections.find(section))
	_paint_rows()


func on_active(_on: bool) -> void:
	_paint_rows()


func nav(d: Vector2i) -> bool:
	if d.y == 0:
		return false
	var n := clampi(_cursor + d.y, 0, sections.size() - 1)
	if n != _cursor:
		_cursor = n
		_paint_rows()
		picked.emit(current())
	return true


func _paint_rows() -> void:
	for i in _rows.size():
		var cur := i == _cursor
		var bg := UiTheme.color("slot_hover") if cur and active else Color(0, 0, 0, 0)
		var border := UiTheme.color("select") if cur else Color(0, 0, 0, 0)
		_rows[i].add_theme_stylebox_override("panel", UiTheme.box(bg, border, 2, UiTheme.metric("combat_roster_pad", 6)))
