class_name NoticeRoute
extends RefCounted
## 알림을 보일지(사용자 결정 2026-10-19 "화면으로 알 수 있는 건 글로 알리지 않는다 — 피어 앤 헝거식 간접 체험"): 문구 키로 나눈다(render.json ui.notice).
##   silent = 보이지 않는다(기록에만) — 횃불·포션·식사·상태·대기·안전지대·어둠·피해 숫자처럼 화면에 이미 보이는 것,
##   그 밖 = 하단 대화창(Enter로 넘김 — 아이템 획득·발견·경고·못 하는 이유·장면).
## 동굴 요소의 근처 문구(events near.line)는 kind가 warn일 때만(냄새처럼 화면으로 알 수 없는 경고) 대화창, 나머지는 보이지 않는다.

const SILENT := "silent"
const DIALOG := "dialog"

var _silent: Dictionary = {}


func _init(db: GameDatabase) -> void:
	for k: Variant in JsonUtil.get_array(UiTheme.ui_dict("notice"), "silent"):
		_silent[str(k)] = true
	if db == null:
		return
	for e: Variant in db.get_collection("events").values():
		var near := JsonUtil.get_dict(e as Dictionary, "near")
		var line := JsonUtil.get_str(near, "line")
		if not line.is_empty() and JsonUtil.get_str(near, "kind", "info") != "warn":
			_silent[line] = true


func of(key: String) -> String:
	var base := key.get_slice(".", 0) + "." + key.get_slice(".", 1) if key.count(".") >= 2 else key  # 번호 변형(field.x.2)은 앞 두 마디로
	return SILENT if _silent.has(key) or _silent.has(base) else DIALOG


func silent(key: String) -> bool:
	return of(key) == SILENT
