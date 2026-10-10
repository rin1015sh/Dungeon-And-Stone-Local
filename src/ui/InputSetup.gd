class_name InputSetup
extends RefCounted
## data/input.json의 "액션 → 키 이름 목록"을 InputMap에 등록한다(키 재설정의 기반).
## 물리 키 위치(physical_keycode)로 등록하므로 한글 입력 상태에서도 같은 자리 키가 동작한다.


## 등록하고, 해석하지 못한 키 이름 목록을 돌려준다(비면 성공).
static func apply(input_cfg: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
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
