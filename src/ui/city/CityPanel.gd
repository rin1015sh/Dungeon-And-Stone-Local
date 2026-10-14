class_name CityPanel
extends VBoxContainer
## 시설 안의 패널형 활동(상점·은행·정수 제거) 기반. 거래마다 결과(CityContext)를 result로 알리고 다시 그린다.

signal result(ctx: CityContext)

var state: CityState
var pc: PlayerCharacter
var activity_id: String = ""


func setup(p_state: CityState, p_pc: PlayerCharacter, p_activity: String) -> void:
	state = p_state
	pc = p_pc
	activity_id = p_activity


func _ready() -> void:
	add_theme_constant_override("separation", UiTheme.metric("spacing", 8) / 2)
	rebuild()


## 내용을 지우고 다시 만든다(하위 클래스가 build를 채운다).
func rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	build()


func build() -> void:
	pass


## 거래 결과를 알리고 패널을 새로 그린다.
func done(ctx: CityContext) -> void:
	result.emit(ctx)
	rebuild()


## 스크롤 목록 상자(높이 제한). 안쪽 VBox를 돌려준다.
func scroll_list(max_h: float) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size.y = max_h
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	return v


## 한 줄: 왼쪽 글자 + 오른쪽 버튼.
static func row(parent: Control, text: String, button_text: String, cb: Callable, enabled: bool = true) -> Button:
	var h := HBoxContainer.new()
	parent.add_child(h)
	var l := UiTheme.label(text, "small", "text")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	h.add_child(l)
	var b := UiTheme.button(button_text, cb)
	b.disabled = not enabled
	h.add_child(b)
	return b
