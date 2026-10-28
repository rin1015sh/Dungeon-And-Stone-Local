extends SceneTree
## 전투 아군 대기(숨쉬기) 스프라이트 시트 미리보기 — 게임에는 아직 넣지 않는다(UI40).
## 피어 앤 헝거 아군 전투 시트의 대기 동작을 본떠: 손그림 3칸(선 자세 → 반쯤 → 무릎 굽혀 가라앉음), 재생은 0-1-2-1.
## 자세는 맨손 겨눔(팔꿈치를 몸 옆에 붙이고 주먹을 허리 위로 — Back.skeleton "guard")에 발을 넓게, 무릎을 굽힌다.
##   godot --headless --path . --script res://tools/paint_idle.gd -- --out=<폴더> [--only=human_back,…] [--keep](지금 자세 그대로 숨만)
## → <폴더>/<id>_idle.png(투명 가로 3칸, 칸 크기 같음 · 발 = 아래 끝)

const Party := preload("res://tools/monster_art/Party.gd")
const SEED := 2026
const FRAMES := [0.0, 0.5, 1.0]
const GUARD := {"stance": 0.12, "knee": 0.4, "arm_l": "guard", "arm_r": "guard"}


func _init() -> void:
	var out := "user://idle"
	var only := PackedStringArray(["human_back", "barbarian_back", "human_side", "barbarian_side"])
	var keep := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		keep = keep or a == "--keep"
	DirAccess.make_dir_recursive_absolute(out)
	for id: String in only:
		var imgs: Array[Image] = []
		var box := Rect2i()
		for b: float in FRAMES:
			var sp := Party.spec_of(id)
			if not keep:
				sp["pose"] = (sp["pose"] as Dictionary).merged(GUARD, true)
			sp["idle"] = b
			var img: Image = Party.figure(sp, SEED + id.hash() % 9973).to_image()
			var used := img.get_used_rect()
			box = used if box.size == Vector2i.ZERO else box.merge(used)
			imgs.append(img)
		box = box.grow(6).intersection(Rect2i(Vector2i.ZERO, imgs[0].get_size()))
		var sheet := Image.create(box.size.x * imgs.size(), box.size.y, false, Image.FORMAT_RGBA8)
		for i in imgs.size():
			sheet.blit_rect(imgs[i], box, Vector2i(i * box.size.x, 0))
		sheet.save_png(out.path_join(id + "_idle.png"))
		print("시트: %s %dx%d ×%d" % [id, box.size.x, box.size.y, imgs.size()])
	quit(0)
