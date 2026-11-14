class_name SkyLanterns
extends RefCounted
## 강철바위 언덕 밤하늘(3층 — 층 JSON "sky_event", docs/plans/floor3.md §6). 순수 로직(오토로드 비의존).
## 이 층에 든 뒤 after_hours가 지난 첫 밤(from~to 시각)에 한 번 시작해, 실제 duration_sec초 동안 이어진다(일시정지 · 전투 중에는 멈춘다).
## 그림(은빛 구체가 땅에서 떠올라 천장에서 사라짐 · 화면이 서서히 밝아졌다 돌아옴)은 화면(Floor3Overlay)이 progress()로 그린다.
## zones(강철바위 언덕 · 고개)에서는 크게, 다른 곳에서는 far_alpha만큼 멀리 보인다. 시야도 밝아지는 만큼(brighten) 넓어진다.

var started_at_hours: float = -1.0  ## 시작한 게임 시각(< 0 = 아직)
var t: float = -1.0                 ## 시작 뒤 흐른 실제 초(< 0 = 아직 · 끝나면 duration 이상)
var _cfg: Dictionary = {}
var _floor_in: float = 0.0


static func setup(s: ExploreSession) -> SkyLanterns:
	var d := JsonUtil.get_dict(s.floor_def, "sky_event")
	if d.is_empty():
		return null
	var k := SkyLanterns.new()
	k._cfg = d
	k._floor_in = s.clock.total_hours
	return k


func cfg() -> Dictionary:
	return _cfg


func duration() -> float:
	return JsonUtil.get_float(_cfg, "duration_sec", 60.0)


func active() -> bool:
	return t >= 0.0 and t < duration()


func done() -> bool:
	return t >= duration()


## 0~1 진행(연출 안 하면 -1).
func progress() -> float:
	return t / duration() if active() else -1.0


## 밝아지는 정도 0~1(가운데에서 가장 밝다).
func glow() -> float:
	return sin(progress() * PI) if active() else 0.0


## 그 칸이 크게 보이는 구역인가.
func near(s: ExploreSession) -> bool:
	return JsonUtil.get_array(_cfg, "zones").has(s.map.zone_at(s.pos))


func vision_mult(s: ExploreSession) -> float:
	return 1.0 + JsonUtil.get_float(_cfg, "brighten", 0.35) * glow() * (1.0 if near(s) else JsonUtil.get_float(_cfg, "far_alpha", 0.25))


## 게임 시간이 흘렀다: 시작 조건을 본다.
func update(s: ExploreSession) -> void:
	if t >= 0.0:
		return
	if s.clock.total_hours - _floor_in < JsonUtil.get_float(_cfg, "after_hours", 48.0):
		return
	if not FieldClues.in_window(s, _cfg):
		return
	start(s)


## 지금 시작한다(디버그 · 테스트도 부른다).
func start(s: ExploreSession) -> void:
	t = 0.0
	started_at_hours = s.clock.total_hours
	s.sound.emit("f3_sky", s.pos)


## 실제 초가 흘렀다(멈춰 있으면 0).
func tick_real(s: ExploreSession, sec: float) -> void:
	if not active() or sec <= 0.0:
		return
	var was := glow()
	t += sec
	if absf(glow() - was) > 0.02 or not active():
		s.refresh_view()
