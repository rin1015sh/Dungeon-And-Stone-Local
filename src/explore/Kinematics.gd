class_name Kinematics
extends RefCounted
## 부드러운 이동의 충돌 처리(순수 로직). 좌표 단위 = 칸(1.0 = 한 칸), 칸 (x, y)의 중심 = (x + 0.5, y + 0.5).
## 몸은 반폭 half의 정사각형(AABB)으로 본다 — 격자 벽과 미끄러지듯 맞닿고, 대각선으로 맞붙은 벽 틈은 못 지나간다.
##
## Godot 물리 엔진(CharacterBody2D·TileMap 충돌)을 쓰지 않는 이유와 여기서 막는 문제:
##   - 규칙(ExploreSession·FieldMonsters)은 씬 트리 없이 도는 순수 로직이라 헤드리스 테스트·시드 재현이 된다.
##     물리 서버는 노드·고정 60Hz 물리 틱에 묶여 게임 시간(전투 중 정지, 몬스터는 게임 시간으로 이동)과 따로 논다.
##   - 터널링: 한 번에 max_substep(기본 0.25칸)보다 크게 움직이지 않도록 쪼갠다.
##   - 축 분리: x → y 순서로 따로 움직여 벽을 따라 미끄러진다(벽에 비스듬히 부딪혀도 멈추지 않는다).
##   - 모서리 걸림: 한 축으로만 갈 때 몸이 통로 입구 모서리에 살짝 걸리면 옆으로 밀어 통로 중심에 맞춘다(corner assist).
##   - 대각선 속도: 입력 방향을 정규화하는 것은 호출하는 쪽(세션) 몫.

const EPS := 0.0005


## pos에서 delta만큼 움직인 결과(벽에 막히면 미끄러지거나 멈춘다).
static func move(map: FloorMap, pos: Vector2, delta: Vector2, half: float, assist: float = 0.0,
		max_substep: float = 0.25) -> Vector2:
	var n := maxi(1, ceili(delta.length() / maxf(0.01, max_substep)))
	var step := delta / n
	var p := pos
	for i in n:
		var before := p
		p = _axis(map, p, Vector2(step.x, 0.0), half)
		p = _axis(map, p, Vector2(0.0, step.y), half)
		if assist > 0.0:
			p = _corner_assist(map, before, p, step, half, assist)
	return p


## 몸(중심 pos, 반폭 half)이 걸을 수 없는 칸과 겹치는가.
static func blocked(map: FloorMap, pos: Vector2, half: float) -> bool:
	var x0 := floori(pos.x - half + EPS)
	var x1 := floori(pos.x + half - EPS)
	var y0 := floori(pos.y - half + EPS)
	var y1 := floori(pos.y + half - EPS)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if not map.is_walkable(Vector2i(x, y)):
				return true
	return false


static func cell_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.y))


static func center_of(cell: Vector2i) -> Vector2:
	return Vector2(cell) + Vector2(0.5, 0.5)


## 한 축으로 움직인다. 막히면 막은 칸의 경계에 붙인다.
static func _axis(map: FloorMap, pos: Vector2, d: Vector2, half: float) -> Vector2:
	if d == Vector2.ZERO:
		return pos
	var np := pos + d
	if not blocked(map, np, half):
		return np
	if d.x > 0.0:
		np.x = floorf(np.x + half - EPS) - half - EPS
	elif d.x < 0.0:
		np.x = floorf(np.x - half + EPS) + 1.0 + half + EPS
	elif d.y > 0.0:
		np.y = floorf(np.y + half - EPS) - half - EPS
	else:
		np.y = floorf(np.y - half + EPS) + 1.0 + half + EPS
	# 붙인 자리가 원래보다 뒤로 가거나 여전히 막히면 제자리.
	if (np - pos).dot(d) < 0.0 or blocked(map, np, half):
		return pos
	return np


## 한 축으로만 가려다 막혔을 때: 진행 방향 앞이 트인 줄(또는 열)의 중심 쪽으로 옆걸음해 통로에 맞춘다.
static func _corner_assist(map: FloorMap, before: Vector2, after: Vector2, step: Vector2, half: float, assist: float) -> Vector2:
	var horizontal := absf(step.x) > 0.0 and absf(step.y) < 0.0001
	var vertical := absf(step.y) > 0.0 and absf(step.x) < 0.0001
	if not (horizontal or vertical):
		return after
	var main := absf(step.x) if horizontal else absf(step.y)
	var progressed := absf(after.x - before.x) if horizontal else absf(after.y - before.y)
	if progressed >= main * 0.5:
		return after
	var lateral := after.y if horizontal else after.x
	var lead := after.x + signf(step.x) * (half + 0.5) if horizontal else after.y + signf(step.y) * (half + 0.5)
	var best := INF
	var target := lateral
	for lane: int in [floori(lateral - half + EPS), floori(lateral + half - EPS)]:
		var ahead := Vector2i(floori(lead), lane) if horizontal else Vector2i(lane, floori(lead))
		var c := lane + 0.5
		if map.is_walkable(ahead) and absf(c - lateral) <= assist and absf(c - lateral) < best:
			best = absf(c - lateral)
			target = c
	if is_inf(best) or is_equal_approx(target, lateral):
		return after
	var slide := clampf(target - lateral, -main, main)
	return _axis(map, after, Vector2(0.0, slide) if horizontal else Vector2(slide, 0.0), half)
