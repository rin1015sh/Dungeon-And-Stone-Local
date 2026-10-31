extends SceneTree
## 도시 실내 걷기 시뮬레이터(CT71): 방마다 통로 칸(문간·문·계단·사다리 · 양옆 또는 위아래가 막힌 한 칸 길)에
## 옆 칸에서 진짜 이동 규칙(Kinematics + RoomView.walk의 계단·사다리 규칙)으로 들어가 본다 — 칸 가운데서 비껴(±0.3칸) 출발해
## 그 방향 키 하나만 누르고 1.5초 안에 그 칸에 닿는가. 막힌 곳을 줄마다 찍고 끝에 "모두 통과" 또는 실패 수.
##   godot --headless --path . --script res://tools/sim_room_walk.gd [-- --only=<방 id>]

const OFFSETS := [0.0, 0.3, -0.3, 0.45, -0.45]
const STEP := 1.0 / 60.0


func _init() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	var db := GameDatabase.new()
	db.load_all("res://data")
	var s := CityState.new(db, 5)
	s.start()
	s.happenings.assign(["rare_books", "feast_day", "peddler", "inn_special", "lecture"])
	var fails := 0
	var tries := 0
	for f in s.facility_ids():
		var r := CityRoom.load_for(s, f)
		if r == null or (not only.is_empty() and r.id != only):
			continue
		for y in r.height:
			for x in r.width:
				var c := Vector2i(x, y)
				if not _is_passage(r, c):
					continue
				for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var from := c - d
					if not r.map.is_walkable(from) or r.kind_at(from) in ["stairs", "ladder"] and d.x != 0:
						continue
					for off: float in OFFSETS:
						tries += 1
						if not _enter(s, r, from, c, d, off):
							fails += 1
							print("막힘: %s %s → %s (%s, 비낌 %.1f)" % [r.id, from, c, r.kind_at(c), off])
	print("시도 %d · 실패 %d" % [tries, fails])
	print("모두 통과" if fails == 0 else "실패 있음")
	quit(0)


## 통로: 문간·문·계단·사다리, 또는 걷는 칸인데 좌우(또는 위아래) 둘 다 막힌 한 칸 길.
static func _is_passage(r: CityRoom, c: Vector2i) -> bool:
	if not r.map.is_walkable(c):
		return false
	if r.kind_at(c) in ["doorway", "door", "stairs", "ladder"]:
		return true
	var lr := not r.map.is_walkable(c + Vector2i.LEFT) and not r.map.is_walkable(c + Vector2i.RIGHT)
	var ud := not r.map.is_walkable(c + Vector2i.UP) and not r.map.is_walkable(c + Vector2i.DOWN)
	return lr or ud


## from 칸(진행 방향과 수직으로 off만큼 비낌)에서 d 키만 눌러 to 칸 가운데 근처에 닿는가.
static func _enter(s: CityState, r: CityRoom, from: Vector2i, to: Vector2i, d: Vector2i, off: float) -> bool:
	var half := CityRoom.rule(s, "body_half", 0.3)
	var pos := Kinematics.center_of(from) + Vector2(absf(d.y), absf(d.x)) * off
	if Kinematics.blocked(r.map, pos, half):
		pos = Kinematics.center_of(from)  # 비낀 자리가 벽이면 가운데서
	var speed := CityRoom.rule(s, "walk_tiles_per_sec", 4.5)
	for i in 90:
		var dir := Vector2(d)
		var sp := speed
		var cell := Kinematics.cell_of(pos)
		var k := r.kind_at(cell)
		if k == "stairs" or k == "ladder":
			if dir.y == 0.0:
				return Kinematics.cell_of(pos) == to
			pos.x = move_toward(pos.x, cell.x + 0.5, STEP * speed)
			sp *= CityRoom.rule(s, "ladder_speed" if k == "ladder" else "stairs_speed", 0.6)
		pos = Kinematics.move(r.map, pos, dir * sp * STEP, half, CityRoom.rule(s, "corner_assist", 0.45), 0.25)
		if Kinematics.cell_of(pos) == to and (pos - Kinematics.center_of(to)).dot(Vector2(d)) > -0.2:
			return true
	return false
