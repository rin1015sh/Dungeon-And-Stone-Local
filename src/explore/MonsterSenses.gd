class_name MonsterSenses
extends RefCounted
## 필드 몬스터의 감지(순수 로직, MonsterSteering이 가진다) — 화면이 곧 감지 범위(사용자 2026-10-29 "어그로 범위가 애매 —
## 화면 밖에서 감지하는 일은 없게, 화면 안에 들어오면 어그로", V19):
##   화면 = 플레이어를 가운데 둔 카메라 사각형(칸) — project 뷰포트 크기 ÷ (render.json view.floor_tile_px × camera_zoom) 의 반,
##   가장자리에서 monsters.screen_margin_tiles만큼 안쪽(몸이 보일 만큼 들어와야). 그 안이고 벽에 가리지 않고 바라보는 쪽(시야각
##   monsters.view_cone_deg — 등 돌리고 있으면 모른다, 사용자 2026-10-29 "벽이랑 등 돌리고 있으면 못 알아채게")이면 알아채고,
##   밖이면 무엇으로도(냄새·사냥·소리) 알아채지 않는다. 쫓는 중이면 시야각은 보지 않고 monsters.chase_keep_tiles만큼 더 넓게 놓치지 않는다.
##   숨는·먼저 덤비지 않는 몬스터의 거리 조건은 MonsterSteering._notices.
##   은신(0~1)만큼 사각형이 줄어든다(behavior ignores_stealth면 그대로).
##   의심(V21): 보면 바로 쫓지 않고 monsters.suspect_hours [가까이, 화면 끝] 동안 멈칫해 돌아본 뒤 그래도 보이면 쫓는다.
##   기척(V21): 바로 곁(monsters.hear_tiles)에서 움직이면 등 돌린 몬스터도 hear_hold_hours 멈춰 돌아본다(서 있으면 들리지 않는다).

var half := Vector2(13.3, 7.5)  ## 화면 반 크기(칸, 여유를 뺀 값)
var keep: float = 2.0
var suspect_min: float = 0.03  ## 의심 시간(게임 시간): 바로 앞 ~ 화면 끝
var suspect_max: float = 0.06
var known_mult: float = 0.5    ## 쫓다 놓친 상대를 다시 보면 의심 시간 × 이 값
var hear_tiles: float = 1.6    ## 바로 곁에서 움직이면 돌아본다
var hear_hold: float = 0.05    ## 돌아보며 멈추는 시간
var _cos_half: float = 0.0


func _init(db: GameDatabase) -> void:
	var view := JsonUtil.get_dict(db.render, "view")
	var tile := JsonUtil.get_array(view, "floor_tile_px")
	var tw := float(tile[0]) if tile.size() > 0 else 32.0
	var th := float(tile[1]) if tile.size() > 1 else tw
	var zoom := maxf(0.1, JsonUtil.get_float(view, "camera_zoom", 2.0))
	var vw := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
	var vh := float(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
	var margin := float(db.bal("monsters.screen_margin_tiles", 0.5))
	half = Vector2(vw * 0.5 / (tw * zoom) - margin, vh * 0.5 / (th * zoom) - margin)
	keep = float(db.bal("monsters.chase_keep_tiles", 2.0))
	_cos_half = cos(deg_to_rad(float(db.bal("monsters.view_cone_deg", 180.0)) * 0.5))
	var sus: Array = db.bal("monsters.suspect_hours", [0.03, 0.06])
	suspect_min = float(sus[0])
	suspect_max = float(sus[1])
	known_mult = float(db.bal("monsters.suspect_known_mult", 0.5))
	hear_tiles = float(db.bal("monsters.hear_tiles", 1.6))
	hear_hold = float(db.bal("monsters.hear_hold_hours", 0.05))


## 플레이어에서 to(칸)만큼 떨어진 곳이 화면 안인가. shrink = 은신(0~1), chasing = 쫓는 중(조금 더 넓게).
func on_screen(to: Vector2, shrink: float = 0.0, chasing: bool = false) -> bool:
	var h := half * (1.0 - clampf(shrink, 0.0, 1.0))
	if chasing:
		h += Vector2(keep, keep)
	return absf(to.x) <= h.x and absf(to.y) <= h.y


## 바라보는 쪽 facing(단위 벡터)에서 본 to(플레이어 쪽, 칸)가 시야각 안인가(180도면 앞쪽 반 — 바로 옆까지).
func in_cone(facing: Vector2, to: Vector2) -> bool:
	if to.length_squared() < 0.0001 or facing.length_squared() < 0.0001:
		return true
	return facing.normalized().dot(to.normalized()) >= _cos_half - 0.001
