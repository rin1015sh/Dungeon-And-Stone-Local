extends SceneTree
## 전투 뒷그림 생성기(피어 앤 헝거식 전투 배경 — 소실점으로 빨려 드는 어두운 통로, 손으로 칠한 듯한 붓결·잉크·빗금·그레인):
## 층·균열마다 한 장(1280×720)을 그려 assets/battle/<id>.webp로 저장한다. 층 JSON art.battleback · 균열 look.art.battleback이 가리킨다.
##   godot --headless --path . --script res://tools/paint_battlebacks.gd [-- --only=<id,id>] [--out=<폴더>]
## 공간은 Room(시선을 쏘는 원근 공간), 재질 Mats, 소품·마감 Kit, 장면은 tools/battle_art/Scene*.gd(장소마다 하나).

const SCENES := {
	"f1_crystal_cave": "res://tools/battle_art/SceneCave.gd",
	"blood_fortress": "res://tools/battle_art/SceneFortress.gd",
	"glacier_cave": "res://tools/battle_art/SceneGlacier.gd",
	"green_mine": "res://tools/battle_art/SceneMine.gd",
	"iron_tomb": "res://tools/battle_art/SceneTomb.gd",
}
const SEED := 4417
const W := 1280
const H := 720


func _init() -> void:
	var only := PackedStringArray()
	var out := "res://assets/battle"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	var i := 0
	for id: String in SCENES:
		i += 1
		if not only.is_empty() and not only.has(id):
			continue
		var t0 := Time.get_ticks_msec()
		var p: RefCounted = load(str(SCENES[id])).paint(W, H, SEED + i * 131)
		p.call("save", "%s/%s.webp" % [out, id], 0.88)
		print("그림: 전투 뒷그림 %s (%.1f초)" % [id, (Time.get_ticks_msec() - t0) / 1000.0])
	quit()
