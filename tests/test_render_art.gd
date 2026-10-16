extends TestCase
## 탐험 맵 렌더 기반(A1 — docs/PROMPT_ART_MAP.md §3.3): 층 그림 설정(FloorArt), 시야 경계 감쇠 값, 그래픽 품질.


func test_floor_art_overrides_render_defaults() -> void:
	var f1 := FloorArt.resolve(db.render, db.get_entry("floors", "f1_crystal_cave"))
	assert_eq(f1.near_black, Color.from_string("#141018", Color.WHITE), "1층 근흑색 = 보라 섞인 근흑")
	assert_eq(f1.unexplored, Color.BLACK, "미탐험 = 순흑")
	assert_true(f1.has_pulse() and f1.pulse_tiles.has("crystal_wall"), "수정벽이 맥동한다")
	assert_true(f1.particles.size() >= 1 and f1.pulse_depth > 0.0)
	assert_eq(f1.ambience, "f1_cave")
	var bare := FloorArt.resolve(db.render, {})
	var view := JsonUtil.get_dict(db.render, "view")
	assert_eq(bare.near_black, Color.from_string(JsonUtil.get_str(view, "near_black"), Color.WHITE), "art가 없으면 render.json 기본")
	assert_false(bare.has_pulse())
	assert_eq(bare.particles.size(), 0)
	assert_near(float(bare.post["saturation"]), JsonUtil.get_float(JsonUtil.get_dict(db.render, "lighting"), "saturation"))


func test_low_quality_turns_off_motion() -> void:
	var low := FloorArt.resolve(db.render, db.get_entry("floors", "f1_crystal_cave"), "low")
	assert_eq(low.particles.size(), 0, "입자 끔")
	assert_near(float(low.post["grain_strength"]), 0.0, 0.0001, "그레인 끔")
	assert_near(low.pulse_depth, 0.0, 0.0001, "맥동 멈춤(빛 번짐은 남음)")
	assert_true(low.has_pulse() and low.low_quality)


## 균열 챕터는 균열 look.art를 쓴다(장소마다 근흑색이 다르다).
func test_rift_chapter_art() -> void:
	var seen := {}
	for id: String in ["rift_blood_fortress", "rift_glacier_cave", "rift_green_mine", "rift_iron_tomb"]:
		var look := JsonUtil.get_dict(db.get_entry("rifts", id), "look")
		var a := FloorArt.resolve(db.render, {"art": JsonUtil.get_dict(look, "art")})
		seen[a.near_black.to_html(false)] = true
	seen[FloorArt.resolve(db.render, db.get_entry("floors", "f1_crystal_cave")).near_black.to_html(false)] = true
	assert_eq(seen.size(), 5, "다섯 장소의 근흑색이 서로 다르다")


## 꼭짓점 둘레 네 칸의 탐험·보임 수: 경계 꼭짓점은 섞이고, 지도 밖은 미탐험.
func test_fog_counts() -> void:
	var map := FloorMap.new(db, 3, 2, "cave_floor")
	map.explored[0] = 1
	map.explored[1] = 1
	map.visible_now[0] = 1
	var f := FloorView.fog_counts(map, 1, 1)  # 둘레 = (0,0) 보임 · (1,0) 기억 · (0,1)·(1,1) 미탐험
	assert_eq(f & 7, 2, "탐험한 칸 2")
	assert_eq(f >> 3, 1, "보이는 칸 1")
	assert_eq(FloorView.fog_counts(map, 0, 0), 1 | (1 << 3), "모서리 = 지도 밖 3칸은 미탐험")
	assert_eq(FloorView.fog_counts(map, 3, 2), 0, "아무것도 탐험하지 않은 모서리")


func test_graphics_setting_persists() -> void:
	var old_path := GraphicsSettings.path
	GraphicsSettings.path = "user://dungeon_and_stone/test_settings.json"
	GraphicsSettings.set_quality("low")
	assert_eq(GraphicsSettings.quality(), "low")
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(GraphicsSettings.path))
	assert_eq((data as Dictionary).get("quality"), "low", "파일에 남는다")
	assert_eq(GraphicsSettings.toggle(), "high")
	GraphicsSettings.set_quality("ultra")
	assert_eq(GraphicsSettings.quality(), "high", "모르는 값은 무시")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GraphicsSettings.path))
	GraphicsSettings.path = old_path
	GraphicsSettings.reset()
