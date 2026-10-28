extends SceneTree
## 전투 탐험가 동작 시트(종족 뒷모습): tools/monster_art/party_motions.json의 동작마다 3칸(PartyMotion이 참고 시트에서 잰 관절을 3D 뼈대로,
## 대기 = BackPose.idle 들썩임). 게임이 쓴다 — BattlerView가 칸을 넘긴다(render.json ui.combat_party_motion, UI41).
##   godot --headless --path . --script res://tools/paint_motions.gd -- [--only=human_back,…] [--motions=idle,swing] [--out=<폴더> --png](미리보기) [--json=<후보 json>]
## → <폴더>/<id>_motions.webp: 줄 = 선 동작(json 순서, 쓰러짐 빼고 · "동작@종족" 항목이 있으면 그 종족은 그것으로) · 칸 3. 칸 크기는 모두 같고 발 가운데 = 칸 아래 가운데(좌우 대칭으로 자른다 — 모든 칸의 발이 같은 땅에 닿아 아래 끝이 같다).
##   <폴더>/<id>_w_<무기 종류>.webp: 무기 덮개(json _weapons — 한손·양손·활): 맨몸 시트와 같은 칸에 무기만(몸에 가린 곳은 빠진다).
##     동작의 kinds가 있으면 그 무기 종류에만 그린다(나머지는 빈 칸). --weapons=<종류,…>로 몇 개만.
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
	var kinds: Dictionary = data.get("_weapons", {})
	var pick_kinds := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--weapons="):
			pick_kinds = a.trim_prefix("--weapons=").split(",")
	for id: String in only:
		if not names.is_empty():
			var race := id.trim_suffix("_back")
			var sheets := {"": []}  # "" = 맨몸, 그 밖 = 무기 종류 덮개
			for k: String in kinds:
				if pick_kinds.is_empty() or pick_kinds.has(k):
					sheets[k] = []
			for m: String in names:
				var mo: Dictionary = data.get(m + "@" + race, data[m])  # 동작@종족 = 그 종족만 다른 칸
				for k: String in sheets:
					var only_kinds: Array = mo.get("kinds", [])
					if k != "" and not only_kinds.is_empty() and not only_kinds.has(k):
						(sheets[k] as Array).append([])  # 이 무기로는 쓰지 않는 동작 — 빈 칸
					else:
						(sheets[k] as Array).append(_frames(id, mo, kinds.get(k, {}) as Dictionary))
			var box := Rect2i()
			for k: String in sheets:
				box = _box_of(sheets[k], box)
			for k: String in sheets:
				_save(_sheet(sheets[k], box, names.size()), out.path_join(id + ("_motions" if k == "" else "_w_" + k)), png)
		if data.has(LYING) and (pick.is_empty() or pick.has(LYING)):
			var lying: Array = [[_frames(id, data[LYING], {})[0]]]
			_save(_sheet(lying, _box_of(lying, Rect2i(), false), 1), out.path_join(id + "_dead"), png)
		print("시트: %s · 동작 %s · 무기 %s" % [id, ", ".join(names), ", ".join(kinds.keys())])
	quit(0)


## 한 동작의 칸들. weapon이 비어 있지 않으면 그 무기만 남긴 덮개 칸(Party.figure layer "weapon").
func _frames(id: String, mo: Dictionary, weapon: Dictionary) -> Array[Image]:
	var row: Array[Image] = []
	for fr: Dictionary in (mo["frames"] as Array):
		var sp := Party.spec_of(id)
		sp["motion_frame"] = fr
		if not weapon.is_empty():
			var kit: Dictionary = (sp.get("kit", {}) as Dictionary).duplicate()
			kit.merge(weapon, true)
			sp["kit"] = kit
			sp["layer"] = "weapon"
		row.append(Party.figure(sp, SEED + id.hash() % 9973).to_image())
	return row


## 칸들의 그림 둘레를 box에 더한다. symmetric이면 그림 가운데(발 자리)를 기준으로 좌우 같게.
func _box_of(rows: Array, box: Rect2i, symmetric: bool = true) -> Rect2i:
	var first: Image = null
	for row: Array in rows:
		for img: Image in row:
			first = img
			var used := img.get_used_rect()
			if used.size != Vector2i.ZERO:
				box = used if box.size == Vector2i.ZERO else box.merge(used)
	if first == null:
		return box
	box = box.grow(6)
	if symmetric:
		var cx := first.get_width() / 2
		var half := maxi(cx - box.position.x, box.end.x - cx)
		box = Rect2i(cx - half, box.position.y, half * 2, box.size.y)
	return box.intersection(Rect2i(Vector2i.ZERO, first.get_size()))


## 칸들을 한 장으로(칸 = box 크기, 줄 nrows · 칸 3). 빈 줄은 투명하게 둔다.
func _sheet(rows: Array, box: Rect2i, nrows: int) -> Image:
	var sheet := Image.create(box.size.x * 3, box.size.y * nrows, false, Image.FORMAT_RGBA8)
	for r in rows.size():
		for i in (rows[r] as Array).size():
			sheet.blit_rect(rows[r][i], box, Vector2i(i * box.size.x, r * box.size.y))
	return sheet


func _save(img: Image, base: String, png: bool) -> void:
	if png:
		img.save_png(base + ".png")
	else:
		img.save_webp(base + ".webp", true, 0.9)
