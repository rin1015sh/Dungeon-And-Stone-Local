extends TestCase
## 소리(사용자 음원 2026-11-07 — data/audio.json · docs/AUDIO.md): 파일이 다 있고, 어디서 부르는 키든 소리로 풀리고,
## 걸음 · 전투 · 문구 · 분위기 소리 고르기가 맞는지.

const CODE_KEY := "(?:sound\\.emit|play_sfx|_say_sound)\\(\\s*\"([a-z0-9_]+)\""


func _audio() -> Dictionary:
	return SoundData.audio(db)


func test_every_file_exists() -> void:
	var n := 0
	for sec: String in ["sfx", "steps", "ambience", "bgm"]:
		var d := JsonUtil.get_dict(_audio(), sec)
		for k: String in d:
			n += 1
			assert_true(ResourceLoader.exists(str(d[k])), "%s.%s 파일 %s" % [sec, k, d[k]])
			var st := load(str(d[k])) as AudioStream
			assert_true(st != null and st.get_length() > 0.1, "%s.%s 읽힌다" % [sec, k])
	assert_true(n > 90, "소리 %d개" % n)


func _known(k: String) -> bool:
	return SoundData.known(db, k)


func test_every_reference_resolves() -> void:
	var a := _audio()
	for k: String in JsonUtil.get_dict(a, "alias"):
		for x: Variant in JsonUtil.get_array(a["alias"], k):
			assert_true(_known(str(x)), "alias %s → %s" % [k, x])
	for k: String in JsonUtil.get_dict(a, "cues"):
		for x: Variant in JsonUtil.get_array(a["cues"], k):
			assert_true(_known(JsonUtil.get_str(x, "sfx")), "cue %s → %s" % [k, x])
	for k: String in JsonUtil.get_dict(a, "on_message"):
		if not k.begins_with("_"):
			assert_true(_known(str(a["on_message"][k])), "문구 %s" % k)
	var c := JsonUtil.get_dict(a, "combat")
	for k: String in c:
		if c[k] is String and not k.begins_with("_"):
			assert_true(_known(str(c[k])), "combat.%s" % k)
		elif c[k] is Dictionary:
			for kk: String in c[k]:
				assert_true(_known(str(c[k][kk])), "combat.%s.%s" % [k, kk])
	for g: String in ["by_id", "by_family"]:
		var m := JsonUtil.get_dict(JsonUtil.get_dict(a, "cries"), g)
		for k: String in m:
			assert_true(_known(str(m[k])), "cries.%s.%s" % [g, k])
	var ac := JsonUtil.get_dict(a, "ambience_cues")
	for k: String in ac:
		if not k.begins_with("_"):
			for x: Variant in JsonUtil.get_array(ac, k):
				assert_true(_known(JsonUtil.get_str(x, "sfx")), "ambience_cues.%s" % k)
	var st := JsonUtil.get_dict(a, "step_sounds")
	for mode: String in ["walk", "run"]:
		for k: String in JsonUtil.get_dict(st, mode):
			assert_true(JsonUtil.get_dict(a, "steps").has(str(st[mode][k])), "걸음 %s.%s" % [mode, k])


## 몬스터 알아챔 소리 · 코드에서 직접 부르는 키도 풀린다.
func test_data_and_code_keys_resolve() -> void:
	for id: String in db.get_collection("monsters"):
		var s := JsonUtil.get_str(JsonUtil.get_dict(db.get_entry("monsters", id), "behavior"), "alert_sfx")
		if not s.is_empty():
			assert_true(_known(s), "%s alert_sfx %s" % [id, s])
	var re := RegEx.create_from_string(CODE_KEY)
	var keys := {}
	_scan("res://src", re, keys)
	assert_true(keys.size() > 15, "코드 속 소리 키 %d개" % keys.size())
	for k: String in keys:
		assert_true(_known(k), "코드 키 %s (%s)" % [k, keys[k]])


func _scan(dir: String, re: RegEx, out: Dictionary) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			var text := FileAccess.get_file_as_string(dir.path_join(f))
			for m in re.search_all(text):
				out[m.get_string(1)] = f
	for d in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(d), re, out)


func test_step_ground_classes() -> void:
	var want := {"f2g_floor": "tallgrass", "gc_snow": "snow", "f2r_sand": "snow", "f2d_mud": "water", "f2r_hardpan": "gravel",
		"f2d_grass": "grass", "f2d_hard": "dirt"}
	for t: String in want:
		if db.has_entry("tiles", t):
			assert_eq(StepSounds.ground(db, t), want[t], t)
	assert_eq(StepSounds.key_for(db, "f2d_hard", false, false), "", "서 있으면 소리 없음")
	assert_eq(StepSounds.key_for(db, "f2d_hard", true, false), "step_dirt")
	assert_eq(StepSounds.key_for(db, "f2d_hard", true, true), "run_dirt", "쫓기면 달린다")


func test_combat_and_message_sounds() -> void:
	var c := SoundData.section(db, "combat")
	assert_eq(CombatSounds.event_keys(db, {"type": "damage", "hit": true, "amount": 10, "damage_type": "slash"}), [JsonUtil.get_str(JsonUtil.get_dict(c, "hit"), "slash")])
	assert_eq(CombatSounds.event_keys(db, {"type": "damage", "hit": false}), [JsonUtil.get_str(c, "miss")])
	assert_eq(CombatSounds.event_keys(db, {"type": "damage", "hit": true, "amount": 30, "crit": true, "damage_type": "blunt"}), [JsonUtil.get_str(c, "crit")])
	assert_true(CombatSounds.event_keys(db, {"type": "damage", "hit": true, "amount": 5, "dot": true}).is_empty(), "지속 피해는 조용히")
	var cast := CombatSounds.event_keys(db, {"type": "act", "action": {"kind": "skill", "skill": "kobold_sling_stone"}})
	assert_eq(cast, [JsonUtil.get_str(c, "ranged")], "돌팔매 = 활시위 · 쏘기")
	assert_eq(MessageSounds.key_for(db, "item.got_n"), "item_pick", "앞부분이 같은 키")
	assert_eq(MessageSounds.key_for(db, "nothing.here"), "")
	var amb := AmbientCues.new()
	amb.setup(db, "f1_cave", 7)
	var heard: Array[Dictionary] = []
	for i in 240:
		heard.append_array(amb.tick(0.5))
	assert_true(heard.size() >= 5, "수정동굴 2분에 분위기 소리 %d번" % heard.size())
