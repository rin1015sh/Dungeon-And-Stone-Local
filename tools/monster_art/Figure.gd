extends RefCounted
## 사람형 몬스터 한 장: 뼈대(Rig) → 몸(Anatomy) → 머리(Face) · 머리카락(Hair) · 장구 → 옷(Kit) · 무기(Arms) → 칠(Render) → 털·얼굴·빛 → 피·마감.
## spec 키: height(몸 높이 px, 기본 560) · width(캔버스 폭 배율) · pose(Rig) · body(Anatomy) · head(Face) · kit(Kit·Arms)
##          skin(살색) · skin_kind(skin|fur|stone|metal|bone…) · shade(그늘 색) · mottle(얼룩 색) · nail(손톱 색) · eyes(눈 색) · glow(눈 빛 0~1)
##          blood(피 0~1) · hair · hair_c · fur_len(털 길이) · extras(Extras: wings·tail·spikes…)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Render := preload("res://tools/monster_art/Render.gd")
const Rig := preload("res://tools/monster_art/Rig.gd")
const Anatomy := preload("res://tools/monster_art/Anatomy.gd")
const Face := preload("res://tools/monster_art/Face.gd")
const FaceInk := preload("res://tools/monster_art/FaceInk.gd")
const Headgear := preload("res://tools/monster_art/Headgear.gd")
const Hair := preload("res://tools/monster_art/Hair.gd")
const Kit := preload("res://tools/monster_art/Kit.gd")
const Arms := preload("res://tools/monster_art/Arms.gd")
const Extras := preload("res://tools/monster_art/Extras.gd")
const Fur := preload("res://tools/monster_art/Fur.gd")
const Finish := preload("res://tools/monster_art/Finish.gd")


static func paint(spec: Dictionary, seed_value: int) -> Paint:
	var H := float(spec.get("height", 560))
	var w := int(H * float(spec.get("width", 1.15)))
	var h := int(H * float(spec.get("canvas_h", 1.45)))
	var p := Paint.new(w, h, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cl := Clay.new(w, h)
	var foot := Vector2(w * 0.5, h - H * 0.03)
	var pose: Dictionary = spec.get("pose", {})
	var j := Rig.build(foot, H, pose)
	var skin_c: Color = spec.get("skin", Color("#c8b49c"))
	var skin_opts := {"mottle": spec.get("mottle", skin_c.darkened(0.35)), "mottle_amt": float(spec.get("mottle_amt", 0.4))}
	if spec.has("shade"):
		skin_opts["shade"] = spec["shade"]
	var mats := {
		"skin": cl.mat(skin_c, str(spec.get("skin_kind", "skin")), skin_opts),
		"bone": cl.mat(spec.get("bone", Color("#d8cbb0")), "bone"),
		"dark": cl.mat(Color("#1a0d0b"), "glow"),
		"eye": cl.mat(spec.get("eyes", Color("#d8d0b0")), "eye" if float(spec.get("glow", 0.0)) < 0.5 else "glow"),
		"nail": cl.mat(spec.get("nail", Color("#3a2e24")), "bone"),
	}
	if spec.has("horn"):
		mats["horn"] = cl.mat(spec["horn"], "bone")
	var kit: Dictionary = spec.get("kit", {})
	var bd: Dictionary = spec.get("body", {}).duplicate()
	if kit.has("weapon") and not bd.has("hands_" + str(kit.get("weapon_hand", "l"))):
		bd["hands_" + str(kit.get("weapon_hand", "l"))] = "fist"
	Extras.behind(cl, j, H, spec.get("extras", {}), rng)
	var body := Anatomy.body(cl, j, H, bd, mats["skin"], mats["nail"])
	var hd: Dictionary = spec.get("head", {})
	var face := Face.head(cl, body, hd, mats["skin"], mats)
	Hair.grow(cl, face, str(spec.get("hair", "none")), spec.get("hair_c", Color("#2a2420")), rng)
	Headgear.gear(cl, face, hd, body, H)
	Kit.dress(cl, body, H, kit, rng)
	Extras.front(cl, body, H, spec.get("extras", {}), rng)
	var arms := Arms.arm(cl, body, H, kit, pose, rng)
	Render.render(cl, p, H)
	Fur.comb(cl, p, H, float(spec.get("fur_len", 1.0)))
	var glow := float(spec.get("glow", 0.0))
	if face.get("visor", false):
		_visor(p, face, spec.get("eyes", Color("#ffb060")), glow)
	elif not face.get("hood", false) or hd.get("face_lit", false):
		FaceInk.ink(p, face, spec.get("eyes", Color("#d8d0b0")), glow)
	else:
		_hood_shadow(p, face, spec.get("eyes", Color("#d8d0b0")), glow)
	if glow > 0.0 and not face.get("visor", false):
		var gr := 1.6 if str(face["type"]) == "skull" else 3.0
		for e: Vector2 in face["eyes"]:
			Ink.glow(p, e.x, e.y, float(face["eye_r"]) * gr, spec.get("eyes", Color("#ffd080")), glow * 0.8, false)
	for ln: Array in arms["lines"]:
		Ink.line(p, ln[0], ln[1], ln[2], ln[3], 0.9, 0.3)
	for gl: Array in arms["glows"] + face.get("glows", []):
		var gp: Vector2 = gl[0]
		Ink.glow(p, gp.x, gp.y, gl[1], gl[2], 0.8, false)
	Extras.after(p, cl, body, H, spec.get("extras", {}), rng)
	Finish.done(p, spec, body, H)
	return p


## 두건 속 얼굴: 어둠에 묻고 눈만 희미하게.
static func _hood_shadow(p: Paint, f: Dictionary, eye_c: Color, glow: float) -> void:
	var hh: float = f["hh"]
	var c: Vector2 = f["c"]
	for y in range(int(c.y - hh * 0.5), int(c.y + hh * 0.6)):
		for x in range(int(c.x - hh * 0.4), int(c.x + hh * 0.4)):
			var d := Vector2((x - c.x) / (hh * 0.36), (y - c.y - hh * 0.02) / (hh * 0.48)).length()
			if d < 1.0 and p.alpha_at(x, y) > 0.5:
				p.tint(x, y, Color("#0c0807"), clampf((1.0 - d) * 2.2, 0.0, 0.85) * clampf(1.2 - (y - (c.y - hh * 0.5)) / hh, 0.35, 1.0))
	if glow > 0.0:
		for e: Vector2 in f["eyes"]:
			Ink.glow(p, e.x, e.y, hh * 0.12, eye_c, glow, false)


## 투구 눈 틈: 어둡게 + (빛나는 눈이면) 틈 사이로 빛.
static func _visor(p: Paint, f: Dictionary, eye_c: Color, glow: float) -> void:
	var hh: float = f["hh"]
	for e: Vector2 in f["eyes"]:
		for y in range(int(e.y - hh * 0.03), int(e.y + hh * 0.03) + 1):
			for x in range(int(e.x - hh * 0.11), int(e.x + hh * 0.11) + 1):
				if p.alpha_at(x, y) > 0.5:
					p.tint(x, y, Color("#080504"), 0.85)
		if glow > 0.0:
			Ink.glow(p, e.x, e.y, hh * 0.1, eye_c, glow, false)
