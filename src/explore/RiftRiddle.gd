class_name RiftRiddle
extends RefCounted
## 수수께끼 문지기(강철의 묘 — 명세 §12.3). 균열 정의 "riddle": {"set", "weakened_status", "empowered_status", "essence_mult"}.
## 입장할 때 data/riddles의 그 set에서 문항 하나를 고른다. 문항: {id, set, question_ko, choices_ko[3], answer, hints_ko[]}.
## 조우 {"riddle": true}(문지기)와 마주치면 전투 대신 수수께끼(ExploreSession.riddle_asked → 화면 RiddleDialog).
##   정답 → "pass"(전투 없이 통과) 또는 "weaken"(문지기 약화 상태로 전투, 처치 시 정수 드롭률 ×essence_mult)
##   오답 → "wrong"(문지기 강화 상태로 전투)
## 벽화(RiftHidden mural)를 읽으면 힌트를 하나씩 알게 된다(캐릭터 Knowledge 사실 "riddle:<문항>:<번호>" — 다음 균열에도 남는다).
## 힌트는 선택지를 지우지 않는다 — 대화창에 아는 벽화 장면이 보이고, 문제와 맞춰 보며 플레이어가 직접 고른다
## (사용자 결정 2026-10-23: 벽화만 보면 저절로 정답만 남아 너무 쉬웠다). 선택지 5개는 입장 때 섞인 순서로 보인다.

const PASS := "pass"
const WEAKEN := "weaken"
const WRONG := "wrong"

var spec: Dictionary = {}
var data: Dictionary = {}     ## 고른 문항
var resolved: bool = false
var outcome: String = ""      ## 답한 결과(PASS/WEAKEN/WRONG) — 히든 피스 조건(맞혔는가 — 강철의 묘 봉인된 관)
var _order: Array[int] = []   ## 보여 줄 선택지 순서(입장 때 섞는다 — 자리로 답을 외우지 못하게)
var _mural_hint: Dictionary = {}  ## 벽화 칸 -> 그 벽화가 보여 준 힌트 번호


func _init(db: GameDatabase, p_spec: Dictionary, rng: Rng) -> void:
	spec = p_spec
	var pool: Array = []
	for id: Variant in db.get_collection("riddles").keys():
		var r := db.get_entry("riddles", str(id))
		if JsonUtil.get_str(r, "set") == JsonUtil.get_str(spec, "set"):
			pool.append(r)
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
	if not pool.is_empty():
		data = rng.pick(pool)
	for i in JsonUtil.get_array(data, "choices_ko").size():
		_order.append(i)
	rng.shuffle(_order)


func is_ready() -> bool:
	return not data.is_empty()


## 이 조우가 수수께끼로 막혀 있는가.
func blocks(g: FieldMonsters.Group) -> bool:
	return is_ready() and not resolved and g != null and g.tag == "riddle"


func hints() -> Array:
	return JsonUtil.get_array(data, "hints_ko")


## 캐릭터가 아는 이 문항 힌트 수.
func known(pc: PlayerCharacter) -> int:
	var n := 0
	for i in hints().size():
		if pc.knowledge.knows_fact(_fact(i)):
			n += 1
	return n


## 벽화를 읽는다: 그 벽화가 이미 보여 준 힌트, 아니면 아직 모르는 다음 힌트(모두 알면 마지막 것).
func read_mural(pc: PlayerCharacter, at: Vector2i) -> String:
	if hints().is_empty():
		return ""
	if not _mural_hint.has(at):
		var i := 0
		while i < hints().size() - 1 and pc.knowledge.knows_fact(_fact(i)):
			i += 1
		_mural_hint[at] = i
		pc.knowledge.learn_fact(_fact(i))
	return str(hints()[int(_mural_hint[at])])


## 보여 줄 선택지 번호들(전부, 섞인 순서).
func choices() -> Array[int]:
	return _order.duplicate()


## 캐릭터가 벽화에서 본 힌트 글(번호 순서).
func known_hints(pc: PlayerCharacter) -> Array[String]:
	var out: Array[String] = []
	for i in hints().size():
		if pc.knowledge.knows_fact(_fact(i)):
			out.append(str(hints()[i]))
	return out


func is_correct(choice: int) -> bool:
	return choice == JsonUtil.get_int(data, "answer")


## 결과를 조우에 반영한다. pass면 조우를 치운 것으로(RiftRun.on_battle_end 승리), 아니면 전투 규칙에 문지기 상태를 넣는다.
## 전투를 시작해야 하면 true.
func apply(cs: ExploreSession, g: FieldMonsters.Group, p_outcome: String) -> bool:
	resolved = true
	outcome = p_outcome
	match outcome:
		PASS:
			cs.message.emit("explore.riddle_pass", {}, "good")
			cs.rift_run.on_battle_end(cs, g, Battle.RESULT_VICTORY)
			return false
		WEAKEN:
			g.battle_rules["enemy_statuses"] = [JsonUtil.get_str(spec, "weakened_status")]
			g.battle_rules["essence_mult"] = JsonUtil.get_float(spec, "essence_mult", 2.0)
			cs.message.emit("explore.riddle_weaken", {}, "good")
		_:
			g.battle_rules["enemy_statuses"] = [JsonUtil.get_str(spec, "empowered_status")]
			cs.message.emit("explore.riddle_wrong", {}, "danger")
	return true


## 수수께끼를 맞혔는가(그냥 지나갔든 약하게 하고 싸웠든).
func answered_right() -> bool:
	return outcome == PASS or outcome == WEAKEN


func _fact(i: int) -> String:
	return "riddle:%s:%d" % [JsonUtil.get_str(data, "id"), i]
