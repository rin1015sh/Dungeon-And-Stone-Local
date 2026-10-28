extends SceneTree
## 전투 아군 대기(숨쉬기) 스프라이트 시트 미리보기 — 게임에는 아직 넣지 않는다(UI40).
## 피어 앤 헝거 아군 전투 시트의 대기 동작을 본떠: 손그림 3칸(선 자세 → 반쯤 → 무릎 굽혀 가라앉음), 재생은 0-1-2-1.
## 자세는 지금 전투 그림 그대로, 무릎을 굽혀 몸만 들썩인다(사용자 2026-10-28 "몸만 들썩이는 것만 남겨").
##   godot --headless --path . --script res://tools/paint_idle.gd -- --out=<폴더> [--only=human_back,…]
## → <폴더>/<id>_idle.png(투명 가로 3칸, 칸 크기 같음 · 발 = 아래 끝)

const Party := preload("res://tools/monster_art/Party.gd")
const SEED := 2026
const FRAMES := [0.0, 0.5, 1.0]


func _init() -> void:
	var out := "user://idle"
	var only := PackedStringArray(["human_back", "barbarian_back", "human_side", "barbarian_side"])
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(out)
	for id: String in only:
		var imgs: Array[Image] = []
		var box := Rect2i()
		for b: float in FRAMES:
			var sp := Party.spec_of(id)
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
