class_name MonsterSight
extends RefCounted
## 필드 몬스터의 감각(순수 로직 — MonsterMind가 가진다, 사용자 2026-11-01 적 AI 전면 개편 V22).
##   본다 = 플레이어 화면 사각형 안(V19 — 화면 밖에서는 무엇으로도 모른다) + 시야각 안(뒤로 완전히 돈 것만 못 본다 — monsters.view_cone_deg)
##          + 눈에서 플레이어 몸까지 막히지 않음. 시선은 몸 가운데와 양 어깨(몸 폭 body_half) 세 줄 — 하나라도 트이면 보인다
##          (예전엔 칸 중심 한 줄이라 모퉁이 칸을 스치기만 해도 놓쳤다). 시선을 막는 것은 벽뿐 — 서 있는 장식(천막·나무·석상·결정 …,
##          타일 art.stand)은 몸을 다 가리지 못해 막지 않는다(사용자 "단순 장식 타일에 가려지면 바로 포기").
##   듣는다 = 플레이어가 움직이고, 열린 칸을 따라 잰 길 거리(벽 너머 직선이 아니라 돌아가는 길)가 r 안.
## 화면 = 플레이어를 가운데 둔 카메라 사각형(칸) — 뷰포트 ÷ (view.floor_tile_px × camera_zoom)의 반, 가장자리에서 monsters.screen_margin_tiles 안쪽.
## 오토로드를 참조하지 않는다.

var half := Vector2(13.3, 7.5)  ## 화면 반 크기(칸, 여유를 뺀 값)
var keep: float = 2.0           ## 쫓는 중엔 화면을 이만큼 더 넓게(끝에서 쫓기·놓치기를 되풀이하지 않게)
var body: float = 0.3           ## 플레이어 몸 반 폭(어깨 시선)
var _cos_cone: float = -0.5     ## 시야각 끝(이 밖 = 등 뒤)
var _cos_front: float = 0.5     ## 정면(이 안 = 바로 알아본다, 밖 = 곁눈 — 느리게)
var _map: FloorMap
var _block := PackedByteArray()  # 타일 번호 → 시선을 막는가(1)


func _init(db: GameDatabase, map: FloorMap) -> void:
	_map = map
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
	body = float(db.bal("explore.body_half_extent", 0.3))
	_cos_cone = cos(deg_to_rad(float(db.bal("monsters.view_cone_deg", 240.0)) * 0.5))
	_cos_front = cos(deg_to_rad(float(db.bal("monsters.ai.front_deg", 120.0)) * 0.5))


## 플레이어에서 to(칸)만큼 떨어진 곳이 화면 안인가. shrink = 은신(0~1), chasing = 쫓는 중(조금 더 넓게).
func on_screen(to: Vector2, shrink: float = 0.0, chasing: bool = false) -> bool:
	var h := half * (1.0 - clampf(shrink, 0.0, 1.0))
	if chasing:
		h += Vector2(keep, keep)
	return absf(to.x) <= h.x and absf(to.y) <= h.y


## 바라보는 쪽 facing에서 본 to 쪽의 보이는 정도: 정면 1 · 곁눈 side · 등 뒤 0.
func cone(facing: Vector2, to: Vector2, side: float) -> float:
	if to.length_squared() < 0.0001 or facing.length_squared() < 0.0001:
		return 1.0
	var c := facing.normalized().dot(to.normalized())
	if c >= _cos_front:
		return 1.0
	return side if c >= _cos_cone - 0.001 else 0.0


## 눈(from)에서 몸(to)이 보이는가: 몸 가운데·양 어깨 세 시선 중 하나라도 벽에 막히지 않으면.
func sees(from: Vector2, to: Vector2) -> bool:
	var d := to - from
	if d.length_squared() < 0.0001:
		return true
	var side := d.orthogonal().normalized() * body
	return clear(from, to) or clear(from, to + side) or clear(from, to - side)


## 점 a에서 b까지 한 시선이 트였는가(¼칸 걸음 — 지나는 칸 중 시선을 막는 칸이 없다, 양 끝 칸은 보지 않는다).
func clear(a: Vector2, b: Vector2) -> bool:
	var ca := Kinematics.cell_of(a)
	var cb := Kinematics.cell_of(b)
	var n := maxi(1, ceili(a.distance_to(b) / 0.25))
	for i in range(1, n):
		var c := Kinematics.cell_of(a.lerp(b, float(i) / n))
		if c != ca and c != cb and blocks(c):
			return false
	return true


## 칸 c가 몬스터 시선을 막는가: 지도 밖 · 시선을 막는 타일(벽) — 서 있는 장식(art.stand)은 빼고.
func blocks(c: Vector2i) -> bool:
	if not _map.in_bounds(c):
		return true
	var t: int = _map.tiles[_map.idx(c)]
	if t >= _block.size():
		_block.resize(_map.defs.size())
		for i in _map.defs.size():
			var d := _map.defs[i]
			_block[i] = 1 if d.blocks_sight and d.stand_sheet.is_empty() else 0
	return _block[t] == 1


## a에서 b까지 열린 칸을 따라 잰 걸음 수(소리는 벽을 돌아간다). limit 걸음 안에 없으면 -1.
func path_steps(a: Vector2i, b: Vector2i, limit: int) -> int:
	if a == b:
		return 0
	if absi(a.x - b.x) + absi(a.y - b.y) > limit:
		return -1
	var dist := {a: 0}
	var queue: Array[Vector2i] = [a]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		var d: int = dist[p]
		if d >= limit:
			continue
		for dir in FloorMap.DIRS4:
			var q := p + dir
			if q == b:
				return d + 1
			if not dist.has(q) and _map.is_walkable(q):
				dist[q] = d + 1
				queue.append(q)
	return -1
