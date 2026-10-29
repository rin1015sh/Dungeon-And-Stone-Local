extends SceneTree
## 어깨 장식 후보(AM50 — 사용자 2026-10-29 "등이 허전 — 어깨 털 목도리·가죽 어깨덮개 여러 개로"): 인간 h6 뒷모습(turn 0)과 비스듬히(turn 0.8)를
## 후보마다 PNG로(게임 그림은 건드리지 않는다). 부품 = tools/monster_art/BackMantle.gd(kit capelet·ruff·pads).
##   godot --headless --path . --script res://tools/paint_shoulder_cands.gd -- --out=<폴더> [--set=pack]  → <폴더>/<후보>_<0|8>.png(--set=pack = 등짐 후보 AM51)
const Party := preload("res://tools/monster_art/Party.gd")

const C := {
	"m0_none": {},
	"m1_ruff": {"ruff": {"c": Color("#4a3e32")}},
	"m2_fur_cape": {"capelet": {"c": Color("#3e3429"), "kind": "fur", "len": 0.55}, "ruff": {"c": Color("#4a3e30")}},
	"m3_leather_cape": {"capelet": {"c": Color("#3a291c"), "kind": "leather", "len": 0.4}},
	"m4_leather_pads": {"pads": {"c": Color("#4a3424"), "kind": "leather", "size": 1.1}},
	"m5_ruff_pads": {"ruff": {"c": Color("#4a3e32")}, "pads": {"c": Color("#3e2c1e"), "kind": "leather", "size": 1.1}},
	"m6_iron_one": {"ruff": {"c": Color("#3e3630")}, "pads": {"c": Color("#46484a"), "kind": "iron", "size": 1.1, "sides": "l"}},
}
## 등짐 후보(AM51 — 사용자 "추천 1번(배낭 + 담요) + 2번(비스듬히 멘 칼집·화살통) 합쳐서"): --set=pack
const P := {
	"p0_none": {},
	"p1_pack_sword": {"pack": {"c": Color("#4a3424"), "roll": Color("#5a5040")}, "sheath": {"c": Color("#2e2016"), "side": "r"}},
	"p2_pack_quiver": {"pack": {"c": Color("#4a3424"), "roll": Color("#5a5040")}, "quiver": {"c": Color("#5a3e28"), "n": 6}},
	"p3_lowroll_sword": {"pack": {"c": Color("#3e2c1e"), "roll": Color("#6a5a44"), "low": true, "size": 0.9}, "sheath": {"c": Color("#2e2016"), "side": "r"}},
	"p4_pack_sword_gear": {"pack": {"c": Color("#4a3424"), "roll": Color("#4a4a3e"), "lantern": Color("#e0a050"), "flask": Color("#5a3a24")}, "sheath": {"c": Color("#2e2016"), "side": "r"}},
	"p5_sword_only": {"sheath": {"c": Color("#2e2016"), "side": "r"}},
	"p6_quiver_only": {"quiver": {"c": Color("#5a3e28"), "n": 6}},
}


func _init() -> void:
	var out := "res://"
	var set := C
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a == "--set=pack":
			set = P
	for id: String in set:
		for turn: float in [0.0, 0.8]:
			var sp := Party.spec_of("human_back").duplicate(true)
			var kit: Dictionary = sp["kit"]
			for k: String in set[id]:
				kit[k] = set[id][k]
			sp["turn"] = turn
			var img: Image = Party.figure(sp, 1234).to_image()
			var used := img.get_used_rect().grow(6).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			img.get_region(used).save_png(out.path_join("%s_%d.png" % [id, int(turn * 10)]))
			print(id, " ", turn)
	quit(0)
