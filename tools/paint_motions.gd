extends SceneTree
## 전투 탐험가 동작 시트(종족 뒷모습): tools/monster_art/party_motions.json의 동작마다 3칸(PartyMotion이 참고 시트에서 잰 관절을 3D 뼈대로,
## 대기 = BackPose.idle 들썩임). 게임이 쓴다 — BattlerView가 칸을 넘긴다(render.json ui.combat_party_motion, UI41).
##   godot --headless --path . --script res://tools/paint_motions.gd -- [--only=human_back,…] [--motions=idle,swing] [--out=<폴더> --png](미리보기) [--json=<후보 json>]
## → <폴더>/<id>_motions.webp: 줄 = 선 동작(json 순서, 쓰러짐 빼고 · "동작@종족" 항목이 있으면 그 종족은 그것으로) · 칸 3. 칸 크기는 모두 같고 발 가운데 = 칸 아래 가운데(좌우 대칭으로 자른다 — 모든 칸의 발이 같은 땅에 닿아 아래 끝이 같다).
##   <폴더>/<id>_dead.webp: 쓰러짐 1칸(누운 몸 가운데 = 칸 아래 가운데).

const Party := preload("res://tools/monster_art/Party.gd")
const SEED := 2026
const LYING := "dead"


func _init() -> void:
	var out := "res://assets/party"
	var png := false
	var only := PackedStringArray(["human_back", "barbarian_back"])
	var pick := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
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
			var race := id.trim_suffix("_back")
			for m: String in names:
				rows.append(_frames(id, data.get(m + "@" + race, data[m])))  # 동작@종족 = 그 종족만 다른 칸
			_save(_sheet(rows, true), out.path_join(id + "_motions"), png)
		if data.has(LYING) and (pick.is_empty() or pick.has(LYING)):
			_save(_sheet([[_frames(id, data[LYING])[0]]], false), out.path_join(id + "_dead"), png)
		print("시트: %s · 동작 %s" % [id, ", ".join(names)])
	quit(0)


func _frames(id: String, mo: Dictionary) -> Array[Image]:
	var row: Array[Image] = []
	for fr: Dictionary in (mo["frames"] as Array):
		var sp := Party.spec_of(id)
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


func _save(img: Image, base: String, png: bool) -> void:
	if png:
		img.save_png(base + ".png")
	else:
		img.save_webp(base + ".webp", true, 0.9)
