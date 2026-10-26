extends SceneTree
## 몬스터 전투 일러스트 생성기: data/monsters의 몬스터마다 tools/monster_art/Specs.gd 설계대로 그려 assets/monsters/<id>.webp(투명 배경).
## 아군 그림(tools/monster_art/Party.gd)도 함께: 탐험가 <종족>_back·_side → assets/party/, 아군 소환수 <id>_back → assets/monsters/.
##   godot --headless --path . --script res://tools/paint_monsters.gd [-- --only=<id,id…>] [--index](그리지 않고 색인만 다시)
##   --only=party(아군 그림만) · --only=human_side,slime_back(그 그림만)
##   --armor: 탐험가 갑옷 겹(BackArmor.RACES × back·side × 벌 × 부위) → assets/party/armor/<종족>_<back|side>/<벌>_<부위>.webp
##     (몸 그림과 같은 크기·자리 — 몸 그림도 같이 다시 그린다. 탐험가 그림은 갑옷이 들어갈 자리만큼 둘레를 더 남긴다: ARMOR_PAD)
## 그림체 = 피어 앤 헝거 몬스터 그림(사용자 첨부 참고, ASSUMPTIONS UI8): 3D 덩어리로 빚은 몸(Clay) → 3~4단 붓 칠·적갈색 그늘 ·
## 잉크 윤곽·골 · 펜 빗금(Render) → 털 붓결·피·때(Fur·Finish). 한 장에 2~10초, 전부 약 5분.
## 그림은 둘레만 남겨 자르고(발 = 아래 끝), index.json에 그림마다 몸 높이 px를 적는다(들어 올린 무기·뿔은 키에서 빼고,
## 네발짐승·덩어리는 사람 키에 견준 비율로 — Specs.body_height · Party.body_height).
## 전투 화면(BattlerView → MonsterArt)은 그림이 있으면 그것을, 없으면 CombatFigure 도형을 쓴다.

const Specs := preload("res://tools/monster_art/Specs.gd")
const Party := preload("res://tools/monster_art/Party.gd")
const BackArmor := preload("res://tools/monster_art/BackArmor.gd")
const ARMOR_PAD := [16, 24, 16, 0]  ## 탐험가 그림 둘레에 더 남기는 px(왼·위·오른·아래) — 어깨받이·투구가 몸 그림 밖으로 나온다
const SEED := 2026
const OUT_DIR := "res://assets/monsters"

var _index := {}  ## 폴더 → 색인


func _init() -> void:
	var only := PackedStringArray()
	var index_only := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		index_only = index_only or a == "--index"
		if a == "--armor":
			only = PackedStringArray(["armor"])
	var db := GameDatabase.new()
	db.load_all("res://data")
	var n := 0
	for id: String in db.get_collection("monsters"):
		if only.is_empty() or only.has(id):
			n += _one(OUT_DIR, id, index_only, func(s: int) -> Variant: return Specs.paint(id, db.get_entry("monsters", id), s), func(c: float) -> float: return Specs.body_height(id, c))
	if only.has("armor"):
		for race: String in BackArmor.RACES:
			for view: String in Party.VIEWS:
				n += _armor(race + "_" + view)
	for id: String in Party.ids():
		if only.is_empty() or only.has(id) or only.has("party"):
			n += _one(Party.out_dir(id), id, index_only, func(s: int) -> Variant: return Party.paint(id, s), func(c: float) -> float: return Party.body_height(id, c))
	for dir: String in _index:
		var f := FileAccess.open(dir.path_join("index.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(_index[dir], "\t", true))
		f.close()
	print("몬스터 그림 %d장" % n)
	quit(0)


## 그림 하나: 그려서 둘레만 남겨 자르고(발 = 아래 끝) 몸 높이를 색인에 적는다. index_only면 있는 그림으로 색인만.
func _one(dir: String, id: String, index_only: bool, painter: Callable, body: Callable) -> int:
	if not _index.has(dir):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		_index[dir] = {}
		var path := dir.path_join("index.json")
		if FileAccess.file_exists(path):
			var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if old is Dictionary:
				_index[dir] = old
	var idx: Dictionary = _index[dir]
	if index_only:
		var old_img := Image.load_from_file(ProjectSettings.globalize_path(dir.path_join(id + ".webp")))
		if old_img != null:
			idx[id] = int(body.call(float(old_img.get_height() - 12)))
		return 0
	var t := Time.get_ticks_msec()
	var p: Variant = painter.call(SEED + id.hash() % 9973)
	if p == null:
		print("그림 없음(설계 없음): " + id)
		return 0
	var img: Image = p.to_image()
	var used := _crop(id, img)
	img.get_region(used).save_webp(dir.path_join(id + ".webp"), true, 0.9)
	idx[id] = int(body.call(float(img.get_used_rect().size.y)))
	print("그림: %s (%d ms)" % [id, Time.get_ticks_msec() - t])
	return 1


## 남길 둘레: 그린 곳 + 6px(탐험가는 갑옷 자리 ARMOR_PAD만큼 더).
func _crop(id: String, img: Image) -> Rect2i:
	var used := img.get_used_rect().grow(6)
	if Party.RACES.has(id.trim_suffix("_back").trim_suffix("_side")):
		used = used.grow_individual(ARMOR_PAD[0], ARMOR_PAD[1], ARMOR_PAD[2], ARMOR_PAD[3])
	return used.intersection(Rect2i(Vector2i.ZERO, img.get_size()))


## 탐험가 한 그림(id = <종족>_<back|side>)의 갑옷 겹: 벌 × 부위마다 그 부위만 입혀 그려 갑옷 픽셀만 남기고, 몸 그림과 같은 자리로 자른다.
func _armor(id: String) -> int:
	var t := Time.get_ticks_msec()
	var seed_value := SEED + id.hash() % 9973
	var base: Image = (Party.paint(id, seed_value) as Variant).to_image()
	var used := _crop(id, base)
	var dir := Party.out_dir(id).path_join("armor").path_join(id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var n := 0
	for set_id: String in BackArmor.SETS:
		for part: String in BackArmor.PARTS:
			var sp := Party.spec_of(id)
			sp["armor"] = {part: set_id}
			var out := {}
			var img := Party.figure(sp, seed_value, out).to_image()
			BackArmor.cut(img, out["mask"], 2)
			img.get_region(used).save_webp(dir.path_join("%s_%s.webp" % [set_id, part]), true, 0.9)
			n += 1
	print("갑옷 겹: %s %d장 (%d ms)" % [id, n, Time.get_ticks_msec() - t])
	return n
