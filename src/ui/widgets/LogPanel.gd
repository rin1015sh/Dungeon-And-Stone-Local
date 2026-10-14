class_name LogPanel
extends PanelContainer
## 우측 로그창. EventBus.log_message를 구독해 종류별 색(palette.log_<kind>)으로 쌓는다.
## BBCode를 쓰지 않으므로 "[출혈]" 같은 대괄호 문자열도 그대로 보인다.

var translucent: bool = false  ## 탐험 화면 위에 겹칠 때 반투명 배경
var keeps_history: bool = false  ## 탐험 기록: 받은 줄을 history에 남기고, 새로 열리면 다시 보인다(균열 챕터·출구로 화면이 바뀌어도 이어지게)

static var history: Array[Dictionary] = []  ## {"text", "kind"} — 탐험 하나 동안 이어지는 기록(새 탐험에서 clear_history)

var _text: RichTextLabel


static func clear_history() -> void:
	history.clear()


func _ready() -> void:
	if translucent:
		add_theme_stylebox_override("panel", UiTheme.translucent_panel())
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	add_child(v)
	v.add_child(UiTheme.label(Strings.t("log.header"), "header", "text_title"))
	_text = RichTextLabel.new()
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.scroll_following = true
	_text.bbcode_enabled = false
	v.add_child(_text)
	if keeps_history:
		for h: Dictionary in history:
			_put(str(h["text"]), str(h["kind"]))
	EventBus.log_message.connect(add_line)


func add_line(text: String, kind: String = "info") -> void:
	if is_queued_for_deletion():
		return  # 화면이 바뀌는 중 — 새 화면의 기록창이 받는다(두 번 남지 않게)
	if keeps_history:
		history.append({"text": text, "kind": kind})
		while history.size() > UiTheme.metric("log_max_lines", 200):
			history.pop_front()
	_put(text, kind)


func _put(text: String, kind: String) -> void:
	_text.push_color(UiTheme.color("log_" + kind, UiTheme.color("text")))
	_text.add_text(text)
	_text.pop()
	_text.newline()
	var limit := UiTheme.metric("log_max_lines", 200)
	while _text.get_paragraph_count() > limit:
		_text.remove_paragraph(0)
