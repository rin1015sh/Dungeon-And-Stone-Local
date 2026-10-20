class_name CityContext
extends RefCounted
## 도시 활동 한 번의 실행 문맥: 누가(pc) 어느 상태(state)에서 무슨 활동(activity_id)을 했는지 + 결과 문구(문자열 키) 목록.
## 화면은 messages를 번역해 결과 텍스트로 보여 준다. 오토로드를 참조하지 않는다.

var db: GameDatabase
var state: CityState
var pc: PlayerCharacter
var activity_id: String = ""
var ok: bool = true
## [{key, args, kind}] — kind: info/good/warn
var messages: Array[Dictionary] = []


func _init(p_state: CityState, p_pc: PlayerCharacter, p_activity: String = "") -> void:
	state = p_state
	db = p_state.db
	pc = p_pc
	activity_id = p_activity


func rng() -> Rng:
	return state.rng


func say(key: String, args: Dictionary = {}, kind: String = "info") -> void:
	messages.append({"key": key, "args": args, "kind": kind})


## 실패로 끝낸다(아무것도 바뀌지 않았다).
func fail(key: String, args: Dictionary = {}) -> CityContext:
	ok = false
	say(key, args, "warn")
	return self


## 표시용 수: 정수면 정수, 아니면 소수 한 자리.
static func fmt(v: float) -> String:
	return str(int(roundf(v))) if is_equal_approx(v, roundf(v)) else "%.1f" % v


static func signed(v: float) -> String:
	return ("+" if v >= 0.0 else "−") + fmt(absf(v))
