extends TestCase
## 전투 뒷그림(BattleStage — 층 art.battleback · 균열 look.art.battleback, 그림 도구 tools/paint_battlebacks.gd):
## 모든 층·균열에 그림이 있고, 챕터 battleback이 균열 그림을 덮는다.


func _check(where: String, path: String) -> void:
	assert_false(path.is_empty(), "%s: battleback이 없다" % where)
	assert_true(ResourceLoader.exists(path), "%s: 그림 파일 없음 %s — tools/paint_battlebacks.gd" % [where, path])
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		assert_eq(Vector2i(tex.get_size()), Vector2i(1280, 720), "%s: 1280×720" % where)


func test_every_floor_has_battleback() -> void:
	for id: String in db.get_collection("floors"):
		_check(id, FloorArt.resolve(db.render, db.get_entry("floors", id)).battleback)


func test_every_rift_has_battleback() -> void:
	for id: String in db.get_collection("rifts"):
		var look := JsonUtil.get_dict(db.get_entry("rifts", id), "look")
		_check(id, JsonUtil.get_str(JsonUtil.get_dict(look, "art"), "battleback"))


func test_chapter_battleback_overrides_rift() -> void:
	var look := {"art": {"battleback": "res://a.webp", "palette": {"tone": "#ffffff"}}}
	assert_eq(JsonUtil.get_str(RiftRun._chapter_art(look, {}), "battleback"), "res://a.webp")
	var art := RiftRun._chapter_art(look, {"battleback": "res://b.webp"})
	assert_eq(JsonUtil.get_str(art, "battleback"), "res://b.webp")
	assert_true(art.has("palette"), "나머지 그림 설정은 그대로")
	assert_eq(JsonUtil.get_str(look["art"], "battleback"), "res://a.webp", "균열 정의는 건드리지 않는다")
