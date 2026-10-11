class_name RealtimeDriver
extends RefCounted
## 탐험의 실시간 시간 진행(순수 로직). 화면이 매 프레임 실제 경과 초를 넘기면,
## 게임 시간(realtime_hours_per_sec)으로 바꿔 세션에 흘린다(큰 프레임은 realtime_max_step_sec 단위로 쪼갬).
## 플레이어가 가만히 있어도 시간·허기·광원·몬스터가 진행된다(피어 앤 헝거식 압박).
##
## 시간이 멈추는 경우: 전투 중(세션 in_combat) · 탐험 종료 · 정지 사유가 하나라도 있을 때
##   (일시정지 메뉴 "menu", 디버그 패널 "debug", 입력칸 "typing", 창 포커스 잃음 "focus").
## 한 프레임에 반영하는 실제 시간은 realtime_max_frame_sec로 자른다(멈칫한 뒤 시간이 몰아 흐르지 않게).

## 세션을 필드로 들고 있지 않는다(세션이 이 객체를 가지므로 RefCounted 순환 참조가 된다) — 호출마다 받는다.

var _reasons: Dictionary = {}  # 정지 사유 -> true


func set_paused(reason: String, on: bool) -> void:
	if on:
		_reasons[reason] = true
	else:
		_reasons.erase(reason)


func is_paused(reason: String = "") -> bool:
	return not _reasons.is_empty() if reason.is_empty() else _reasons.has(reason)


func is_running(s: ExploreSession) -> bool:
	return _reasons.is_empty() and not s.ended and not s.in_combat


## 실제 1초 = 게임 몇 시간.
func hours_per_sec(s: ExploreSession) -> float:
	return maxf(0.0, float(s.db.bal("explore.realtime_hours_per_sec", 0.1)))


## 이번 프레임에 반영할 실제 시간(초): 정지 중이면 0, 멈칫한 프레임은 realtime_max_frame_sec로 자른다.
func frame_sec(s: ExploreSession, real_sec: float) -> float:
	if not is_running(s) or real_sec <= 0.0:
		return 0.0
	return minf(real_sec, float(s.db.bal("explore.realtime_max_frame_sec", 0.25)))


## 실제 경과 초만큼 게임 시간을 흘린다(매 프레임 → 몬스터가 프레임마다 부드럽게 움직인다).
## 한 번에 흘리는 양은 realtime_max_step_sec 이하로 쪼갠다(몬스터 이동·충돌 안정). 흘린 단계 수를 돌려준다.
func tick(s: ExploreSession, real_sec: float) -> int:
	var sec := frame_sec(s, real_sec)
	if sec <= 0.0:
		return 0
	var max_step := maxf(0.001, float(s.db.bal("explore.realtime_max_step_sec", 0.05)))
	var n := maxi(1, ceili(sec / max_step - 0.000001))
	var steps := 0
	for i in n:
		if not is_running(s):
			break
		steps += 1
		s.pass_time(sec / n * hours_per_sec(s))
	return steps
