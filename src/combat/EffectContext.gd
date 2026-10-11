class_name EffectContext
extends RefCounted
## 효과 하나를 적용할 때의 문맥: 누가(source) 누구에게(target), 무엇으로(item_id), 어떤 난수로.
## 효과는 화면을 모른다 — 하고 싶은 말은 say()로 문자열 키만 남기고 화면이 번역한다.

var db: GameDatabase
var source: Actor
var target: Actor
var rng: Rng
var item_id: String = ""
var success: bool = false
var messages: Array[Dictionary] = []  # {"key": String, "args": Dictionary, "kind": String}
## 전투 정보(전투 중일 때): {"aim_weak": bool, …}
var info: Dictionary = {}
## 화면 연출·전투 처리용 사건: {"type": "damage"|"flee", …}
var events: Array[Dictionary] = []


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
