extends TestCase
## 전투 뒷그림(BattleStage — 층 art.battleback · 균열 look.art.battleback, 그림 도구 tools/paint_battlebacks.gd):
## 모든 층·균열 챕터에 그림이 있고, 챕터 battleback이 균열 그림을 덮는다. 적은 통로 안에 앞뒤 줄로 선다(FoeRows, UI29).


func _check(where: String, path: String) -> void:
	assert_false(path.is_empty(), "%s: battleback이 없다" % where)
	assert_true(ResourceLoader.exists(path), "%s: 그림 파일 없음 %s — tools/paint_battlebacks.gd" % [where, path])
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		assert_eq(Vector2i(tex.get_size()), Vector2i(1280, 720), "%s: 1280×720" % where)


func test_every_floor_has_battleback() -> void:
	for id: String in db.get_collection("floors"):
		var art := FloorArt.resolve(db.render, db.get_entry("floors", id))
		_check(id, art.battleback)
		assert_true(art.battleback_width > 0.0, "%s: half_width" % id)


func test_every_rift_chapter_has_battleback() -> void:
	for id: String in db.get_collection("rifts"):
		var def := db.get_entry("rifts", id)
		var look := JsonUtil.get_dict(def, "look")
		var chapters := JsonUtil.get_array(def, "chapters")
		for i in chapters.size():
			var art := FloorArt.resolve(db.render, {"art": RiftRun._chapter_art(look, chapters[i])})
			_check("%s 챕터 %d" % [id, i + 1], art.battleback)
			assert_true(art.battleback_width > 0.0, "%s 챕터 %d: half_width" % [id, i + 1])


func test_chapter_battleback_overrides_rift() -> void:
	var look := {"art": {"battleback": {"image": "res://a.webp", "half_width": 3.0}, "palette": {"tone": "#ffffff"}}}
	assert_eq(FloorArt.resolve(db.render, {"art": RiftRun._chapter_art(look, {})}).battleback, "res://a.webp")
	var art := FloorArt.resolve(db.render, {"art": RiftRun._chapter_art(look, {"battleback": {"image": "res://b.webp", "half_width": 6.0}})})
	assert_eq(art.battleback, "res://b.webp")
	assert_near(art.battleback_width, 6.0)
	assert_true(RiftRun._chapter_art(look, {"battleback": {"image": "res://b.webp"}}).has("palette"), "나머지 그림 설정은 그대로")
	assert_eq(JsonUtil.get_str(JsonUtil.get_dict(look["art"], "battleback"), "image"), "res://a.webp", "균열 정의는 건드리지 않는다")


## 적 줄(FoeRows): 통로 안에 앞줄부터, 넘치면 뒷줄 — 모든 적이 벽 안(벽보다 넓은 한 마리는 예외).
func test_rows_stay_between_walls() -> void:
	var widths := PackedFloat32Array([0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8])
	var out := FoeRows.arrange(widths, 2.0, 0.2)
	assert_eq(int(out["rows"]), 2, "4m에 1m씩 = 앞줄 4 · 뒷줄 3")
	var front := 0
	for p: Vector2 in out["pos"]:
		var i := (out["pos"] as Array).find(p)
		assert_true(absf(p.x) + widths[i] / 2.0 <= 2.0 + 0.001, "벽 안")
		if int(p.y) == 0:
			front += 1
	assert_eq(front, 4)
	assert_eq(int(FoeRows.arrange(PackedFloat32Array([0.8, 0.8]), 2.0, 0.2)["rows"]), 1, "적으면 한 줄")
	assert_eq(int(FoeRows.arrange(PackedFloat32Array([6.0]), 2.0, 0.2)["rows"]), 1, "벽보다 넓은 보스도 한 줄")


func test_rows_shrink_when_too_deep() -> void:
	var widths := PackedFloat32Array()
	for i in 20:
		widths.append(1.0)
	var out := FoeRows.arrange_fit(widths, 2.0, 0.2, 3)
	assert_true(int(out["rows"]) <= 3)
	assert_true(float(out["k"]) < 1.0, "줄이 넘치면 모두 줄인다")
	assert_true(FoeRows.scale_of(1, 0.5) < FoeRows.scale_of(0, 0.5), "뒷줄은 작다")


func test_new_foe_takes_front_gap_first() -> void:
	var taken: Array[Vector3] = [Vector3(-1.0, 0, 0.8), Vector3(1.0, 0, 0.8)]
	assert_eq(FoeRows.fit_new(taken, 0.8, 2.0, 0.2, 3), Vector2(0.0, 0.0), "앞줄 가운데 빈자리")
	taken.append(Vector3(0.0, 0, 0.8))
	assert_eq(int(FoeRows.fit_new(taken, 0.8, 2.0, 0.2, 3).y), 1, "앞줄이 차면 뒷줄")


## 보스(pinned)는 늘 앞줄 한가운데, 나머지는 양옆 → 넘치면 뒷줄(보스 몸 바로 옆 틈).
func test_boss_pinned_center() -> void:
	var widths := PackedFloat32Array([0.8, 0.8, 3.0, 0.8, 0.8])
	var out := FoeRows.arrange(widths, 2.5, 0.2, 2)
	var pos: Array = out["pos"]
	assert_eq(pos[2], Vector2(0.0, 0.0), "보스 = 앞줄 가운데")
	for i in [0, 1, 3, 4]:
		var p: Vector2 = pos[i]
		assert_true(absf(p.x) + 0.4 <= 2.5 + 0.01, "벽 안")
		if int(p.y) == 1:
			assert_true(absf(p.x) > 1.5, "뒷줄 가운데는 보스 몸 밖 틈(몸 뒤에 숨지 않게)")
	var wide := FoeRows.arrange(PackedFloat32Array([0.8, 6.0]), 2.0, 0.2, 1)
	assert_eq((wide["pos"] as Array)[1], Vector2(0.0, 0.0), "벽보다 넓은 보스도 가운데")
