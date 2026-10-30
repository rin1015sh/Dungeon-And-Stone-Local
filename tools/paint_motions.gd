extends SceneTree
## 전투 탐험가 동작 시트(종족 뒷모습): tools/monster_art/party_motions.json의 동작마다 3칸(PartyMotion이 참고 시트에서 잰 관절을 3D 뼈대로,
## 대기 = BackPose.idle 들썩임). 게임이 쓴다 — BattlerView가 칸을 넘긴다(render.json ui.combat_party_motion, UI41).
##   godot --headless --path . --script res://tools/paint_motions.gd -- [--only=human_back,…] [--motions=idle,swing] [--out=<폴더> --png](미리보기) [--json=<후보 json>]
##   --look=<MapLooks id,…>: 그 옷차림(종족 몸 + 옷)으로 <폴더>/<id>_back_motions·_dead를 그린다(옷차림 후보·새 종족 후보 — 게임 그림은 안 건드리게 --out과 같이).
## → <폴더>/<id>_motions.webp: 줄 = 선 동작(json 순서, 쓰러짐 빼고 · "동작@종족" 항목이 있으면 그 종족은 그것으로) · 칸 3. 칸 크기는 모두 같고 발 가운데 = 칸 아래 가운데(좌우 대칭으로 자른다 — 모든 칸의 발이 같은 땅에 닿아 아래 끝이 같다).
##   <폴더>/<id>_dead.webp: 쓰러짐 1칸(누운 몸 가운데 = 칸 아래 가운데).
## 고정한 줄: tools/monster_art/pinned/<id>_<동작>.png가 있으면 그 줄은 그리지 않은 그림 그대로(지금 human_back_wait — 사용자가 고른 예전 그림).

const PIN_DIR := "res://tools/monster_art/pinned"  ## 고정한 줄(<id>_<동작>.png) — _pin
const Party := preload("res://tools/monster_art/Party.gd")
const MapLooks := preload("res://tools/monster_art/MapLooks.gd")
const SEED := 2026
const LYING := "dead"


func _init() -> void:
	var out := "res://assets/party"
	var png := false
	var only := PackedStringArray(["human_back", "barbarian_back"])
	var pick := PackedStringArray()
	var looks := {}  # 그릴 id → 옷차림(--look)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		elif a.begins_with("--look="):
			only = PackedStringArray()
			for lk: String in a.trim_prefix("--look=").split(","):
				only.append(lk + "_back")
				looks[lk + "_back"] = lk
		elif a.begins_with("--motions="):
			pick = a.trim_prefix("--motions=").split(",")
		png = png or a == "--png"
	DirAccess.make_dir_recursive_absolute(out)
	var src := "res://tools/monster_art/party_motions.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--json="):  # 후보 자세를 따로 그려 볼 때(같은 꼴의 json)
			src = a.trim_prefix("--json=")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(src))
	var names: Array = []
	for m: String in data:
		if not m.begins_with("_") and m != LYING and not m.contains("@") and (pick.is_empty() or pick.has(m)):
			names.append(m)
	for id: String in only:
		if not names.is_empty():
			var rows: Array = []
			var race := MapLooks.race_of(str(looks[id])) if looks.has(id) else id.trim_suffix("_back")
			var base := Party.spec_of(race + "_back")
			if looks.has(id):
				base = MapLooks.apply(base, str(looks[id]))
			for m: String in names:
				rows.append(_frames(id, base, data.get(m + "@" + race, data[m])))  # 동작@종족 = 그 종족만 다른 칸
			var sheet := _sheet(rows, true)
			for r in names.size():
				_pin(sheet, rows.size(), r, id + "_" + str(names[r]))
			_save(sheet, out.path_join(id + "_motions"), png)
		if data.has(LYING) and (pick.is_empty() or pick.has(LYING)):
			var lie_race := MapLooks.race_of(str(looks[id])) if looks.has(id) else id.trim_suffix("_back")
			var lie := Party.spec_of(lie_race + "_back")
			if looks.has(id):
				lie = MapLooks.apply(lie, str(looks[id]))
			_save(_sheet([[_frames(id, lie, data[LYING])[0]]], false), out.path_join(id + "_dead"), png)
		print("시트: %s · 동작 %s" % [id, ", ".join(names)])
	quit(0)


func _frames(id: String, base: Dictionary, mo: Dictionary) -> Array[Image]:
	var row: Array[Image] = []
	for fr: Dictionary in (mo["frames"] as Array):
		var sp := base.duplicate(true)
		sp["motion_frame"] = fr
		if mo.has("weapon"):
			var kit: Dictionary = (sp.get("kit", {}) as Dictionary).duplicate()
			kit["weapon"] = mo["weapon"]
			kit.merge(mo.get("kit", {}) as Dictionary, true)  # weapon_hand 등
			sp["kit"] = kit
		row.append(Party.figure(sp, SEED + id.hash() % 9973).to_image())
	return row


## 칸들을 한 장으로: 모든 칸의 그림 둘레를 합친 크기, symmetric이면 그림 가운데(발 자리)를 기준으로 좌우 같게 넓힌다.
func _sheet(rows: Array, symmetric: bool) -> Image:
	var first: Image = rows[0][0]
	var box := Rect2i()
	for row: Array in rows:
		for img: Image in row:
			var used := img.get_used_rect()
			box = used if box.size == Vector2i.ZERO else box.merge(used)
	box = box.grow(6)
	if symmetric:
		var cx := first.get_width() / 2
		var half := maxi(cx - box.position.x, box.end.x - cx)
		box = Rect2i(cx - half, box.position.y, half * 2, box.size.y)
	box = box.intersection(Rect2i(Vector2i.ZERO, first.get_size()))
	var cols := 0
	for row: Array in rows:
		cols = maxi(cols, row.size())
	var sheet := Image.create(box.size.x * cols, box.size.y * rows.size(), false, Image.FORMAT_RGBA8)
	for r in rows.size():
		for i in (rows[r] as Array).size():
			sheet.blit_rect(rows[r][i], box, Vector2i(i * box.size.x, r * box.size.y))
	return sheet


## 고정한 줄(tools/monster_art/pinned/<id>_<동작>.png — 사용자가 예전 그림을 그대로 두라고 한 줄)이 있으면 그린 줄 대신 넣는다.
## 칸 크기가 달라졌으면 발 자리(줄 아래 가운데)에 맞춘다.
func _pin(sheet: Image, n_rows: int, r: int, key: String) -> void:
	var path := ProjectSettings.globalize_path(PIN_DIR.path_join(key + ".png"))
	if not FileAccess.file_exists(path):
		return
	var pin := Image.load_from_file(path)
	pin.convert(Image.FORMAT_RGBA8)
	var ch := sheet.get_height() / n_rows
	sheet.fill_rect(Rect2i(0, r * ch, sheet.get_width(), ch), Color(0, 0, 0, 0))
	var at := Vector2i((sheet.get_width() - pin.get_width()) / 2, r * ch + ch - pin.get_height())
	var src := Rect2i(Vector2i(maxi(0, -at.x), maxi(0, r * ch - at.y)), pin.get_size())
	src.size -= src.position
	sheet.blit_rect(pin, src, Vector2i(maxi(at.x, 0), maxi(at.y, r * ch)))
	print("고정한 줄: %s" % key)


func _save(img: Image, base: String, png: bool) -> void:
	if png:
		img.save_png(base + ".png")
	else:
		img.save_webp(base + ".webp", true, 0.9)
