class_name ExploreAudio
extends Node
## 탐험 화면 소리(ExploreScreen의 자식): 걸음 고리(바닥 갈래 — StepSounds, 몬스터가 쫓는 동안은 달리기) · 층 분위기 효과음
## (AmbientCues — 층 art.ambience.loop 키, 균열은 "rift") · 문구 소리(MessageSounds) · 생명력이 낮으면 심장 박동. 전투 중엔 걸음을 멈춘다.

const CHASE_EVERY := 0.5  ## 쫓기는지 다시 보는 초(무리 목록을 매 프레임 훑지 않게)
const STEP_HOLD := 0.15   ## 몸이 마지막으로 움직인 뒤 걸음 소리를 이어 두는 실제 초(프레임 사이 끊김 없게)

var _s: ExploreSession
var _cues := AmbientCues.new()
var _chased := false
var _chase_t := 0.0
var _last_pos := Vector2.INF
var _step_t := 0.0  ## 남은 걸음 소리 시간(실제 초) — 몸이 실제로 움직일 때만 채운다(사용자 2026-11-07 "WASD를 누른 채 상호작용하면 발소리가 계속")


func setup(s: ExploreSession, ambience_key: String) -> void:
	_s = s
	_cues.setup(s.db, ambience_key if not ambience_key.is_empty() else ("rift" if s.rift_run != null else ""))
	s.message.connect(_on_message)


func _on_message(key: String, _args: Dictionary, _kind: String) -> void:
	AudioBus.play_sfx(MessageSounds.key_for(_s.db, key))


func _process(delta: float) -> void:
	if _s == null or _s.ended:
		return
	if _s.in_combat:
		AudioBus.set_loop("steps", "steps", "")
		return
	_chase_t -= delta
	if _chase_t <= 0.0:
		_chase_t = CHASE_EVERY
		_chased = _s.monsters.groups.any(func(g: FieldMonsters.Group) -> bool: return g.state == FieldMonsters.STATE_CHASE)
	if _last_pos == Vector2.INF or _s.fpos.distance_to(_last_pos) > 0.01:  # 게임 시간이 아니라 몸의 실제 위치로 — 대화 · 메뉴로 시간이 멈춰도 · 벽에 막혀도 발소리가 이어지지 않게
		_step_t = STEP_HOLD if _last_pos != Vector2.INF else 0.0
		_last_pos = _s.fpos
	else:
		_step_t = maxf(0.0, _step_t - delta)
	var key := StepSounds.key_for(_s.db, _s.map.tile_id_at(_s.pos), _step_t > 0.0, _chased)
	AudioBus.set_loop("steps", "steps", key, JsonUtil.get_float(SoundData.section(_s.db, "step_sounds"), "db", 0.0))
	for c: Dictionary in _cues.tick(delta):
		AudioBus.play_sfx(str(c["key"]), float(c["db"]))
	var low := _s.player.pool.get_ratio("hp") < JsonUtil.get_float(SoundData.section(_s.db, "combat"), "heart_below", 0.3)
	AudioBus.set_loop("heart", "sfx", JsonUtil.get_str(SoundData.section(_s.db, "combat"), "heart") if low else "")


func _exit_tree() -> void:
	AudioBus.set_loop("steps", "steps", "")
	AudioBus.set_loop("heart", "sfx", "")
