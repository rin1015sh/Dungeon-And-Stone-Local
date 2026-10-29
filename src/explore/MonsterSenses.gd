class_name MonsterSenses
extends RefCounted
## 필드 몬스터의 감지(순수 로직, MonsterSteering이 가진다) — 화면이 곧 감지 범위(사용자 2026-10-29 "어그로 범위가 애매 —
## 화면 밖에서 감지하는 일은 없게, 화면 안에 들어오면 어그로", V19):
##   화면 = 플레이어를 가운데 둔 카메라 사각형(칸) — project 뷰포트 크기 ÷ (render.json view.floor_tile_px × camera_zoom) 의 반,
##   가장자리에서 monsters.screen_margin_tiles만큼 안쪽(몸이 보일 만큼 들어와야). 그 안이면 벽·바라보는 쪽과 상관없이 알아채고,
##   밖이면 무엇으로도(냄새·사냥·소리) 알아채지 않는다. 쫓는 중이면 monsters.chase_keep_tiles만큼 더 넓게 놓치지 않는다.
##   숨는·먼저 덤비지 않는 몬스터의 거리 조건은 MonsterSteering._notices.
##   은신(0~1)만큼 사각형이 줄어든다(behavior ignores_stealth면 그대로).

var half := Vector2(13.3, 7.5)  ## 화면 반 크기(칸, 여유를 뺀 값)
var keep: float = 2.0


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


## 플레이어에서 to(칸)만큼 떨어진 곳이 화면 안인가. shrink = 은신(0~1), chasing = 쫓는 중(조금 더 넓게).
func on_screen(to: Vector2, shrink: float = 0.0, chasing: bool = false) -> bool:
	var h := half * (1.0 - clampf(shrink, 0.0, 1.0))
	if chasing:
		h += Vector2(keep, keep)
	return absf(to.x) <= h.x and absf(to.y) <= h.y
