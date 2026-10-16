extends RefCounted
## 장면 목록 일괄 캡처(screenshot.gd --shots=<목록 json> --out=<폴더>). 한 번 들어간 탐험 화면에서 장면마다
## 순간이동·횃불·안개 걷기를 맞춰 찍고 <폴더>/<name>.png로 남긴다. 탐험 맵 그림 작업의 전후 비교용(docs/screens/).
## 목록 = {"bench": {"at", "steps", "torch"}(선택 — 걸음당 프레임), "shots": [{"name", "at": [x, y], "torch": bool, "reveal": bool, "lord": bool, "wait": 프레임}]}
## 찍는 동안 몬스터는 멈춘다(monsters_enabled = false — 순간이동한 자리에서 전투가 걸리지 않게). 계층군주는 되돌릴 수 없어 마지막 장면에만.


static func run(host: Node, explore: ExploreScreen, list_path: String, out_dir: String) -> int:
	var errors: Array[String] = []
	var data: Variant = JsonUtil.read_file(list_path, errors)
	if not data is Dictionary:
		print("장면 목록을 읽지 못함: %s %s" % [list_path, errors])
		return 1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var s := explore.session
	s.monsters_enabled = false
	var bench := JsonUtil.get_dict(data, "bench")
	if not bench.is_empty():  # 장면보다 먼저(계층군주·횃불이 켜지기 전)
		await _bench(host, s, bench)
	var failed := 0
	for shot: Variant in JsonUtil.get_array(data, "shots"):
		if not shot is Dictionary:
			continue
		var d := shot as Dictionary
		var name := JsonUtil.get_str(d, "name", "shot")
		var at := JsonUtil.get_array(d, "at")
		if at.size() == 2 and not ExploreDebug.teleport(s, Vector2i(int(at[0]), int(at[1]))):
			print("  %s: %s 칸으로 갈 수 없음" % [name, at])
			failed += 1
			continue
		_set_torch(s, JsonUtil.get_bool(d, "torch"))
		if JsonUtil.get_bool(d, "reveal"):
			ExploreDebug.reveal(s)
		if JsonUtil.get_bool(d, "lord"):
			s.lord.summon(s)
		s.refresh_view()
		for i in JsonUtil.get_int(d, "wait", 20):
			await host.get_tree().process_frame
		var path := out_dir.path_join(name + ".png")
		var err := host.get_viewport().get_texture().get_image().save_png(path)
		print("  %s → %s" % [name, ProjectSettings.globalize_path(path) if err == OK else "실패(%d)" % err])
		if err != OK:
			failed += 1
	return 1 if failed > 0 else 0


## 걸음당 프레임 측정(그림 작업 전후 비교 — PROGRESS에 적는다): at에서 동·남으로 번갈아 steps걸음, 걸음마다 한 프레임.
## 값은 이 PC·창 크기 기준이라 같은 PC에서만 비교한다.
static func _bench(host: Node, s: ExploreSession, bench: Dictionary) -> void:
	var at := JsonUtil.get_array(bench, "at")
	if at.size() == 2:
		ExploreDebug.teleport(s, Vector2i(int(at[0]), int(at[1])))
	_set_torch(s, JsonUtil.get_bool(bench, "torch"))
	for i in 10:
		await host.get_tree().process_frame
	var steps := JsonUtil.get_int(bench, "steps", 40)
	var worst := 0
	var t0 := Time.get_ticks_usec()
	for i in steps:
		var t := Time.get_ticks_usec()
		s.pass_time(s.move_hours())
		var dir := Vector2i(1, 0) if i % 2 == 0 else Vector2i(0, 1)
		if not s.try_move(dir):
			s.try_move(-dir)
		await host.get_tree().process_frame
		worst = maxi(worst, Time.get_ticks_usec() - t)
	print("  걸음당 프레임: 평균 %.1fms, 최대 %.1fms (%d걸음, %s)" % [(Time.get_ticks_usec() - t0) / 1000.0 / steps, worst / 1000.0, steps, at])


## 횃불: 켜야 하면 소지품 횃불을 쓰고, 꺼야 하면 남은 시간을 0으로(디버그 캡처 전용 — 규칙에서는 끌 수 없다).
static func _set_torch(s: ExploreSession, on: bool) -> void:
	if on and not s.player.light.is_lit():
		s.use_category("light")
	elif not on and s.player.light.is_lit():
		s.player.light.hours_left = 0.0
