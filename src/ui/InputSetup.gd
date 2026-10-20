class_name InputSetup
extends RefCounted
## data/input.json의 "액션 → 키 이름 목록"을 InputMap에 등록한다(키 재설정의 기반).
## 물리 키 위치(physical_keycode)로 등록하므로 한글 입력 상태에서도 같은 자리 키가 동작한다.


## 등록하고, 해석하지 못한 키 이름 목록을 돌려준다(비면 성공). "unbind" 목록의 액션은 키를 모두 뗀다(엔진 기본 Tab 포커스 이동 등).
static func apply(input_cfg: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	for action: Variant in JsonUtil.get_array(input_cfg, "unbind"):
		if InputMap.has_action(str(action)):
			InputMap.action_erase_events(str(action))
	var actions := JsonUtil.get_dict(input_cfg, "actions")
	for action: String in actions:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action)
		for key_name: Variant in (actions[action] if actions[action] is Array else []):
			var code := OS.find_keycode_from_string(str(key_name))
			if code == KEY_NONE:
				problems.append("%s: '%s'" % [action, key_name])
				continue
			var ev := InputEventKey.new()
			ev.physical_keycode = code
			InputMap.action_add_event(action, ev)
	return problems


## 액션에 묶인 첫 키 이름(도움말 표시용).
static func key_label(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	for ev: InputEvent in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string((ev as InputEventKey).physical_keycode)
	return "?"


## 마우스·터치 입력인가(게임은 키보드로만 다룬다 — 사용자 결정 2026-10-19, Main이 모두 막는다).
static func is_pointer(event: InputEvent) -> bool:
	return event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventGesture
