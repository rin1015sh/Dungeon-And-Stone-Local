class_name EffectContext
extends RefCounted
## 효과 하나를 적용할 때의 문맥: 누가(source) 누구에게(target), 무엇으로(item_id), 어떤 난수로.
## 효과는 화면을 모른다 — 하고 싶은 말은 say()로 문자열 키만 남기고 화면이 번역한다.

var db: GameDatabase
var source: Actor
var target: Actor
var rng: Rng
## 효과 레지스트리(전투 중이면 Battle이 넣는다) — 패시브의 적중 시 효과를 적용할 때 쓴다.
var registry: EffectRegistry = null
var item_id: String = ""
var success: bool = false
var messages: Array[Dictionary] = []  # {"key": String, "args": Dictionary, "kind": String}
## 전투 정보(전투 중일 때): {"skill_id", "skill_name", "summons", …}
var info: Dictionary = {}
## 화면 연출·전투 처리용 사건: {"type": "damage"|"flee", …}
var events: Array[Dictionary] = []
## 이 대상에게 피해가 들어갔는가: -1 = 아직 피해 효과 없음, 0 = 빗나감·면역, 1 = 맞힘.
## 0이면 뒤따르는 효과(상태·밀치기)는 걸리지 않는다 — 효과에 "always": true 또는 "to": "self"면 예외(EffectRegistry).
var landed: int = -1


func _init(p_db: GameDatabase, p_source: Actor, p_target: Actor, p_rng: Rng) -> void:
	db = p_db
	source = p_source
	target = p_target
	rng = p_rng


## 대상이 없으면 시전자 자신.
func subject() -> Actor:
	return target if target != null else source


func say(key: String, args: Dictionary = {}, kind: String = "info") -> void:
	messages.append({"key": key, "args": args, "kind": kind})
