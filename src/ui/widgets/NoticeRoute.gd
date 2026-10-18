class_name NoticeRoute
extends RefCounted
## 탐험 알림을 어디에 보일지(사용자 결정 2026-10-18): 문구 키로 나눈다(render.json ui.notice).
##   silent = 보이지 않는다(횃불 켜기·포션·식사 결과·단축칸 물건 없음·포탈 위에 섬),
##   toast = 잠깐 떴다 사라지는 띠(NoticeToast) — 동굴 요소의 근처 문구(events near.line)도 여기,
##   그 밖 = 하단 대화창(Enter로 넘김 — 아이템 획득·버리기·발견·경고 등).

const SILENT := "silent"
const TOAST := "toast"
const DIALOG := "dialog"

var _silent: Dictionary = {}
var _toast: Dictionary = {}


func _init(db: GameDatabase) -> void:
	var cfg := UiTheme.ui_dict("notice")
	for k: Variant in JsonUtil.get_array(cfg, "silent"):
		_silent[str(k)] = true
	for k: Variant in JsonUtil.get_array(cfg, "toast"):
		_toast[str(k)] = true
	if db == null:
		return
	for e: Variant in db.get_collection("events").values():
		var line := JsonUtil.get_str(JsonUtil.get_dict(e as Dictionary, "near"), "line")
		if not line.is_empty():
			_toast[line] = true


func of(key: String) -> String:
	var base := key.get_slice(".", 0) + "." + key.get_slice(".", 1) if key.count(".") >= 2 else key  # 번호 변형(field.x.2)은 앞 두 마디로
	if _silent.has(key) or _silent.has(base):
		return SILENT
	if _toast.has(key) or _toast.has(base):
		return TOAST
	return DIALOG
