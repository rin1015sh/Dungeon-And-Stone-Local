extends SceneTree
## 전투 뒷그림 생성기(피어 앤 헝거식 전투 배경 — 소실점으로 빨려 드는 어두운 통로, 손으로 칠한 듯한 붓결·잉크·빗금·그레인):
## 층·균열·균열 챕터마다 한 장(1280×720)을 그려 assets/battle/<id>.webp로 저장한다. 층 JSON art.battleback · 균열 look.art.battleback ·
## 챕터 battleback이 가리킨다(챕터 그림이 없는 챕터는 균열 그림 — 수정동굴 1장·성채 5장·빙하굴 1장·탄광 1장·묘 1장이 균열 그림).
##   godot --headless --path . --script res://tools/paint_battlebacks.gd [-- --only=<id,id>] [--out=<폴더>]
## 공간은 Room(시선을 쏘는 원근 공간), 재질 Mats, 소품·마감 Kit·Kit2, 장면은 tools/battle_art/Scene*.gd(장면마다 하나).

const SCENES := {
	"f1_crystal_cave": "res://tools/battle_art/SceneCave.gd",
	"f2_land_of_dead": "res://tools/battle_art/SceneDead.gd",
	"f2_goblin_forest": "res://tools/battle_art/SceneForest.gd",
	"f2_beast_den": "res://tools/battle_art/SceneCanyon.gd",
	"f2_rock_desert": "res://tools/battle_art/SceneDesert.gd",
	"blood_fortress": "res://tools/battle_art/SceneFortress.gd",
	"glacier_cave": "res://tools/battle_art/SceneGlacier.gd",
	"green_mine": "res://tools/battle_art/SceneMine.gd",
	"iron_tomb": "res://tools/battle_art/SceneTomb.gd",
	"blood_fortress_ch1": "res://tools/battle_art/SceneBf1.gd",
	"blood_fortress_ch2": "res://tools/battle_art/SceneBf2.gd",
	"blood_fortress_ch3": "res://tools/battle_art/SceneBf3.gd",
	"blood_fortress_ch4": "res://tools/battle_art/SceneBf4.gd",
	"glacier_cave_ch2": "res://tools/battle_art/SceneGc2.gd",
	"glacier_cave_ch3": "res://tools/battle_art/SceneGc3.gd",
	"glacier_cave_ch4": "res://tools/battle_art/SceneGc4.gd",
	"green_mine_ch2": "res://tools/battle_art/SceneGm2.gd",
	"green_mine_ch3": "res://tools/battle_art/SceneGm3.gd",
	"green_mine_ch4": "res://tools/battle_art/SceneGm4.gd",
	"iron_tomb_ch2": "res://tools/battle_art/SceneIt2.gd",
	"iron_tomb_ch3": "res://tools/battle_art/SceneIt3.gd",
	"iron_tomb_ch4": "res://tools/battle_art/SceneIt4.gd",
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
		if not ResourceLoader.exists(str(SCENES[id])):
			continue
		var t0 := Time.get_ticks_msec()
		var p: RefCounted = load(str(SCENES[id])).paint(W, H, SEED + i * 131)
		p.call("save", "%s/%s.webp" % [out, id], 0.88)
		print("그림: 전투 뒷그림 %s (%.1f초)" % [id, (Time.get_ticks_msec() - t0) / 1000.0])
	quit()
