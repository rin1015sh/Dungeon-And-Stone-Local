extends RefCounted
## 사람형·네발짐승이 아닌 몬스터(Clay): crawler(네발로 기는 구울) · worm(바위 벌레) · slime(점액 덩어리) · mound(흙더미 노움)
## · eye(촉수 달린 큰 눈) · maggot(구더기). 공통 spec 키: height · color · eyes · glow · blood · crown(색) · horns(색)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Render := preload("res://tools/monster_art/Render.gd")
const Face := preload("res://tools/monster_art/Face.gd")
const FaceInk := preload("res://tools/monster_art/FaceInk.gd")
const Headgear := preload("res://tools/monster_art/Headgear.gd")
const Hair := preload("res://tools/monster_art/Hair.gd")
const Finish := preload("res://tools/monster_art/Finish.gd")
const Things2 := preload("res://tools/monster_art/Things2.gd")


static func paint(kind: String, sp: Dictionary, seed_value: int) -> Paint:
	var H := float(sp.get("height", 420))
	var w := int(H * float(sp.get("width", 1.15)))
	var h := int(H * float(sp.get("canvas_h", 0.9)))
	var p := Paint.new(w, h, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cl := Clay.new(w, h)
	var foot := Vector2(w * 0.5, h - H * 0.05)
	var post := {}
	match kind:
		"crawler":
			post = _crawler(cl, foot, H, sp, rng)
		"worm":
			post = Things2.worm(cl, foot, H, sp, rng)
		"slime":
			post = Things2.slime(cl, foot, H, sp, rng)
		"mound":
			post = Things2.mound(cl, foot, H, sp, rng)
		"eye":
			post = Things2.eye(cl, foot, H, sp, rng)
		"maggot":
			post = Things2.maggot(cl, foot, H, sp, rng)
	Render.render(cl, p, H)
	if post.has("face"):
		FaceInk.ink(p, post["face"], sp.get("eyes", Color("#d8d0b0")), float(sp.get("glow", 0.0)))
	Things2.after(p, cl, post, sp, H, rng)
	Finish.done(p, sp, post.get("j", {}), H)
	return p


## 네발로 기는 구울(정면): 낮게 숙인 머리, 솟은 어깨와 등, 앞으로 짚은 긴 팔(갈고리 손), 뒤로 벌린 다리.
static func _crawler(cl: Clay, foot: Vector2, H: float, sp: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var col: Color = sp.get("color", Color("#9a9a84"))
	var skin := cl.mat(col, "skin", {"mottle": col.darkened(0.4), "mottle_amt": 0.5})
	var nail := cl.mat(Color("#2a221c"), "bone")
	var bulk := float(sp.get("bulk", 1.0))
	var mats := {"skin": skin, "bone": cl.mat(Color("#d8ccb0"), "bone"), "dark": cl.mat(Color("#1a0c0a"), "glow"), "eye": cl.mat(sp.get("eyes", Color("#e0d8b0")), "eye" if float(sp.get("glow", 0.0)) < 0.5 else "glow"), "nail": nail}
	var c := Vector2(foot.x, foot.y - H * 0.36)
	var g_back := cl.group()
	var g_body := cl.group()
	var r := 0.07 * H * bulk
	cl.tag = "torso"
	# 등(뒤로 멀어지는 몸통 — 머리 뒤로 솟은 혹) · 엉덩이
	cl.chain(g_back, [Vector3(c.x, c.y + 0.01 * H, -0.05 * H), Vector3(c.x + 0.01 * H, c.y - 0.02 * H, -0.18 * H), Vector3(c.x + 0.02 * H, c.y + 0.0, -0.32 * H)], [r * 1.1, r * 1.0, r * 0.95], skin, 0.04 * H)
	# 어깨·가슴(앞)
	cl.ell(g_body, Vector3(c.x, c.y + 0.02 * H, 0.0), r * 1.6, r * 1.1, r * 1.0, skin, 0.03 * H)
	for s: float in [-1.0, 1.0]:
		cl.ell(g_body, Vector3(c.x + s * r * 1.4, c.y - 0.01 * H, 0.0), r * 0.8, r * 0.9, r * 0.8, skin, 0.03 * H)
	for k in 4:  # 늑골(가슴 아래)
		var y := c.y + 0.03 * H + k * 0.016 * H
		cl.groove(g_body, Vector2(c.x - r * 1.2, y), Vector2(c.x + r * 1.2, y + 0.004 * H), 0.004 * H, 0.006 * H)
	# 뒷다리(양옆으로 벌려 쪼그림)
	for s: float in [-1.0, 1.0]:
		var g := cl.group()
		var hip := Vector3(c.x + s * 0.06 * H, c.y - 0.02 * H, -0.28 * H)
		var kn := Vector3(c.x + s * 0.26 * H, c.y - 0.08 * H, -0.12 * H)
		var an := Vector3(c.x + s * 0.24 * H, foot.y - 0.04 * H, -0.18 * H)
		cl.chain(g, [hip, kn, an], [0.05 * H * bulk, 0.03 * H * bulk, 0.02 * H * bulk], skin, 0.02 * H)
		cl.ell(g, an + Vector3(-s * 0.02 * H, 0.025 * H, 0.02 * H), 0.04 * H, 0.02 * H, 0.03 * H, skin, 0.01 * H)
	# 앞팔(땅을 짚음)
	var hands: Array = []
	for s: float in [-1.0, 1.0]:
		var g := cl.group()
		var sh := Vector3(c.x + s * r * 1.5, c.y - 0.01 * H, 0.0)
		var el := Vector3(c.x + s * 0.22 * H, c.y + 0.12 * H, 0.04 * H)
		var wr := Vector3(c.x + s * 0.13 * H, foot.y - 0.03 * H, 0.14 * H)
		cl.chain(g, [sh, el, wr], [0.035 * H * bulk, 0.026 * H * bulk, 0.018 * H * bulk], skin, 0.02 * H)
		cl.ell(g, el, 0.03 * H, 0.03 * H, 0.03 * H, skin, 0.01 * H)
		for f in 4:  # 땅을 움켜쥔 긴 손가락 + 손톱
			var b := wr + Vector3(s * (f - 1.5) * 0.016 * H, 0.0, 0.01 * H)
			var t := b + Vector3(s * (f - 1.5) * 0.022 * H, 0.03 * H, 0.04 * H)
			cl.chain(g, [b, b.lerp(t, 0.6) + Vector3(0, -0.012 * H, 0), t], [0.008 * H, 0.007 * H, 0.005 * H], skin, 0.003 * H)
			cl.cap(g, t, t + Vector3(s * 0.006 * H, 0.016 * H, 0.012 * H), 0.004 * H, 0.001 * H, nail, 0.002 * H)
		hands.append(wr)
	# 머리(낮게, 앞으로)
	var j := {"head": Vector3(c.x, c.y + 0.05 * H, 0.14 * H), "head_h": 0.15 * H * float(sp.get("head", 1.0)), "tilt": float(sp.get("tilt", 0.08))}
	var hd := {"type": "gaunt", "mouth": str(sp.get("mouth", "grin")), "eye_style": "glow" if float(sp.get("glow", 0.0)) > 0.5 else "dead", "angry": 0.8}
	if sp.has("horns"):
		hd["horns"] = sp["horns"]
		mats["horn"] = cl.mat(sp["horns"], "bone")
	var face := Face.head(cl, j, hd, skin, mats)
	if sp.has("hair"):
		Hair.grow(cl, face, str(sp["hair"]), sp.get("hair_c", Color("#2a2420")), rng)
	if sp.has("crown"):
		Headgear.gear(cl, face, {"crown": sp["crown"]}, {"shoulder_l": Vector3.ZERO, "shoulder_r": Vector3.ZERO, "chest": Vector3.ZERO}, H)
	return {"face": face, "j": {"chest": Vector3(c.x, c.y + 0.03 * H, 0), "waist": Vector3(c.x, c.y, 0), "elbow_l": Vector3(c.x - 0.2 * H, c.y + 0.06 * H, 0), "elbow_r": Vector3(c.x + 0.2 * H, c.y + 0.06 * H, 0), "wrist_l": hands[0], "wrist_r": hands[1], "hand_l": hands[0], "hand_r": hands[1], "head": j["head"]}}
