class_name PlayerMotion
extends RefCounted
## 플레이어의 부드러운 이동(순수 로직, ExploreSession에서 분리). 상태는 세션(fpos·pos·facing)에 있다.
## 벽 충돌은 Kinematics, 몬스터 무리에 다가가 닿으면 플레이어가 먼저 건 전투(engage(…, true)).


## 몸을 delta(칸)만큼 옮긴다.
static func move_by(s: ExploreSession, delta: Vector2) -> void:
	if s.ended or s.in_combat:
		return
	s.facing = facing_of(delta)
	var g := s.monsters.touching(s.fpos, delta)
	if g != null:
		s.engage(g, true)
		return
	var half := float(s.db.bal("explore.body_half_extent", 0.3))
	var to := Kinematics.move(s.map, s.fpos, delta, half, float(s.db.bal("explore.corner_assist", 0.45)),
		float(s.db.bal("explore.max_substep_tiles", 0.25)))
	if to.is_equal_approx(s.fpos):
		s.bumped.emit(Kinematics.cell_of(s.fpos + delta.normalized()))
		return
	s.fpos = to
	s.last_move_hours = s.clock.total_hours
	s.body_moved.emit(s.fpos)
	var cell := Kinematics.cell_of(s.fpos)
	if cell != s.pos:
		s.enter_cell(cell)
	g = s.monsters.touching(s.fpos, delta)
	if g != null and not s.ended:
		s.engage(g, true)


## 움직인 방향의 주된 축으로 4방향 얼굴 방향을 정한다.
static func facing_of(d: Vector2) -> Vector2i:
	if absf(d.x) > absf(d.y):
		return Vector2i(int(signf(d.x)), 0)
	return Vector2i(0, int(signf(d.y)))
