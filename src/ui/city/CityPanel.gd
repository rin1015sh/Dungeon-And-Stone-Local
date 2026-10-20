class_name CityPanel
extends VBoxContainer
## 시설 안의 패널형 활동(상점·은행·정수 제거) 기반: 위 머리줄(잔액 등) + 선택판(ChoiceGrid 1열 — W/S·Enter, A/D 쪽 넘기기, 맨 끝 나가기).
## 거래마다 결과(CityContext)를 result로 알리고 다시 그린다(커서 자리는 그대로).

signal result(ctx: CityContext)

var state: CityState
var pc: PlayerCharacter
var activity_id: String = ""
## 나가기(맨 끝 선택지). FacilityView가 넣는다. 도시에서는 Backspace를 쓰지 않는다(사용자 결정 2026-10-20).
var leave: Callable = Callable()
var grid: ChoiceGrid
## 키를 받는가(대화창이 결과를 넘기는 중엔 끈다).
var active: bool = true:
	set(v):
		active = v
		if grid != null:
			grid.active = v


func setup(p_state: CityState, p_pc: PlayerCharacter, p_activity: String) -> void:
	state = p_state
	pc = p_pc
	activity_id = p_activity


func _ready() -> void:
	add_theme_constant_override("separation", UiTheme.metric("spacing", 8) / 2)
	rebuild()


## 내용을 지우고 다시 만든다(하위 클래스가 build를 채운다). cursor ≥ 0이면 커서를 그 칸에(아니면 그대로).
func rebuild(cursor: int = -1) -> void:
	var keep := cursor if cursor >= 0 else (grid.cursor() if grid != null else 0)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	grid = null
	build()
	if grid != null:
		grid.show_choices("", grid_options(), Callable(), keep)  # 뒤로 키 없음 — 나가기·돌아가기는 선택지로만


func build() -> void:
	pass


## 선택판의 선택지(하위 클래스) — 맨 끝 나가기는 choices가 붙인다.
func options() -> Array[Dictionary]:
	return []


## 선택판을 만든다(build 끝에서 부른다).
func choices() -> void:
	grid = ChoiceGrid.new(1, mini(grid_options().size(), int(UiTheme.render_float("city.panel_rows", 6.0))),
		int(UiTheme.render_float("city.interior_slot_height", 40.0)), true)
	grid.active = active
	add_child(grid)


func grid_options() -> Array[Dictionary]:
	var opts := options()
	opts.append({"text": Strings.t("city.leave"), "on_pick": leave})
	return opts


## 거래 결과를 알리고 패널을 새로 그린다.
func done(ctx: CityContext) -> void:
	result.emit(ctx)
	rebuild()


## 머리줄 글자.
func head(text: String) -> void:
	add_child(UiTheme.label(text, "body", "text_title"))
