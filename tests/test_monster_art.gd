extends TestCase
## 몬스터 전투 일러스트(tools/paint_monsters.gd → assets/monsters): 데이터의 몬스터마다 그림과 몸 높이 색인이 있는지.
## 새 몬스터를 추가하면 tools/monster_art/Specs.gd(또는 Specs2)에 설계를 넣고 --only=<id>로 그린다(없으면 도형으로 보인다).


func _dir() -> String:
	return JsonUtil.get_str(JsonUtil.get_dict(db.render, "ui"), "combat_art_dir", "res://assets/monsters")


func test_every_monster_has_art() -> void:
	var missing := PackedStringArray()
	for id: String in db.get_collection("monsters"):
		if not ResourceLoader.exists(_dir().path_join(id + ".webp")):
			missing.append(id)
	assert_eq(missing.size(), 0, "그림 없는 몬스터: " + ", ".join(missing))


func test_index_has_body_heights() -> void:
	var errors: Array[String] = []
	var index: Variant = JsonUtil.read_file(_dir().path_join("index.json"), errors)
	assert_true(index is Dictionary, "index.json 읽기")
	if not index is Dictionary:
		return
	for id: String in db.get_collection("monsters"):
		var tex := load(_dir().path_join(id + ".webp")) as Texture2D
		var body := JsonUtil.get_float(index, id, 0.0)
		assert_true(body > 0.0, "몸 높이: " + id)
		if tex != null:
			assert_true(body < tex.get_height() * 2.0, "몸 높이가 그림에 견줘 터무니없지 않다: " + id)
