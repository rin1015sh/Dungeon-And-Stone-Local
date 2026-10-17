extends RefCounted
## 아군 전투 그림(전투 무대 아래 앞줄, 적을 향해 등을 보인다): 탐험가(종족 × back 뒷모습 · side 오른쪽을 보며 비스듬히 돌아선 옆모습)
## 와 아군으로 소환되는 몬스터의 뒷모습. id: <종족>_back|_side → assets/party/, <몬스터>_back → assets/monsters/.
## 탐험가 복장은 종족 특징만 드러내고 장비와 상관없이 늘 같은 모습(장비를 바꾸거나 레벨이 올라도 그대로 — ASSUMPTIONS UI11).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Render := preload("res://tools/monster_art/Render.gd")
const Fur := preload("res://tools/monster_art/Fur.gd")
const Finish := preload("res://tools/monster_art/Finish.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const BackKit := preload("res://tools/monster_art/BackKit.gd")
const BackHair := preload("res://tools/monster_art/BackHair.gd")
const BackGear := preload("res://tools/monster_art/BackGear.gd")
const Things := preload("res://tools/monster_art/Things.gd")
const Monsters := preload("res://tools/monster_art/Specs.gd")

const RACES := ["human", "barbarian"]
const VIEWS := ["back", "side"]
const SIDE_TURN := 1.1  ## 옆모습 돌림(라디안)
const REF_H := 540.0  ## 사람 키(px) — 바바리안은 더 크게 그려 무대에서도 더 크게 보인다
## 아군으로 소환될 수 있는 몬스터(정수 스킬 summon · 정수 패시브 low_hp_summons — tests/test_monster_art.gd가 데이터와 맞춰 본다)
const SUMMONS := ["soldier_deadman", "mummy", "iron_cavalry", "ghoul", "elder_ghoul", "slime"]


static func C(hex: String) -> Color:
	return Color(hex)


static func ids() -> Array:
	var out: Array = []
	for r: String in RACES:
		for v: String in VIEWS:
			out.append(r + "_" + v)
	for m: String in SUMMONS:
		out.append(m + "_back")
	return out


static func out_dir(id: String) -> String:
	return "res://assets/party" if RACES.has(id.trim_suffix("_back").trim_suffix("_side")) else "res://assets/monsters"


static func spec_of(id: String) -> Dictionary:
	var base := id.trim_suffix("_back").trim_suffix("_side")
	var turn := SIDE_TURN if id.ends_with("_side") else 0.0
	var sp := {}
	match base:
		"human":  # 여행자: 걷어 올린 아마 셔츠 · 가죽 조끼 · 두건 달린 어깨 망토 · 허리 주머니와 단검 · 가죽 장화
			sp = {"height": REF_H, "build": "normal", "sh": 0.108, "skin": C("#c49a78"), "mottle": C("#9a6a52"), "mottle_amt": 0.3,
				"hair": "short", "hair_c": C("#3a2a1e"), "pose": {"stance": 0.08, "knee": 0.15, "arm_l": "hang", "arm_r": "ready"}, "side_pose": {"arm_l": "rest", "arm_r": "rest"},
				"kit": {"pants": C("#4a4236"), "shirt": C("#b8a888"), "sleeves": "rolled", "vest": C("#5a3e28"), "mantle": C("#5a3028"),
					"belt": C("#2e2018"), "pouch": true, "knife": true, "boots": C("#3a2a1e"), "bracers": C("#4a3424")}, "blood": 0.0, "grime": 0.3}
		"barbarian":  # 거구: 땋은 긴 머리와 수염 · 털 어깨 망토 · 맨팔(위팔 쇠띠·팔목 가죽) · 가죽 조끼 · 감은 종아리 · 털 단 장화
			sp = {"height": REF_H * 1.14, "build": "brute", "bulk": 1.08, "sh": 0.132, "skin": C("#b88866"), "mottle": C("#8a5a42"), "mottle_amt": 0.35,
				"hair": "long", "hair_c": C("#4a2e1c"), "braids": 2, "hair_len": 0.14, "hair_over": 0.06, "beard": C("#4a2e1c"),
				"pose": {"stance": 0.1, "knee": 0.18, "arm_l": "hang", "arm_r": "hang"},
				"kit": {"pants": C("#5a4430"), "leg_wraps": C("#8a7a60"), "vest": C("#6a4a30"), "pelt": C("#6e5e4a"), "belt": C("#3a2818"), "pouch": true,
					"boots": C("#4a3424"), "boots_fur": C("#7a6a54"), "bracers": C("#3e2c1c"), "armband": C("#6a5a3a")}, "blood": 0.0, "grime": 0.3, "fur_len": 1.7}
		"soldier_deadman":
			sp = {"height": 560, "build": "thin", "sh": 0.115, "skin": C("#a8a88c"), "mottle": C("#4e5040"), "mottle_amt": 0.5, "blood": 0.5,
				"hair": "ragged", "hair_c": C("#2a241c"), "pose": {"hunch": 0.25, "knee": 0.2, "arm_l": "shield", "arm_r": "spear"},
				"kit": {"pants": C("#3a3a30"), "shirt": C("#4a4a3a"), "sleeves": "short", "torn": 0.7, "belt": C("#2a2016"), "boots": C("#2e261e"),
					"helm": C("#5a5446"), "weapon": "spear", "weapon_c": C("#6a5a48"), "shield": C("#5a4c3a")}}
		"mummy":
			sp = {"height": 560, "build": "thin", "sh": 0.11, "skin": C("#3a3024"), "pose": {"hunch": 0.2, "arm_l": "ready", "arm_r": "ready"},
				"hair": "none", "kit": {"wraps": C("#c8b890"), "wraps_amt": 0.92, "loin": C("#8a7a5a")}}
		"iron_cavalry":
			sp = {"height": 600, "canvas_h": 1.3, "build": "normal", "sh": 0.13, "skin": C("#8a7a6a"), "hair": "none",
				"pose": {"arm_l": "shield", "arm_r": "spear"},
				"kit": {"pants": C("#3a3430"), "armor": C("#70787f"), "boots": C("#3a3430"), "cape": C("#3a2420"), "helm": C("#6a7078"), "closed": true,
					"plume": C("#6a1a18"), "weapon": "lance", "weapon_c": C("#8a9098"), "shield": C("#5a6068"), "shield_kind": "kite", "shield_mat": "metal"}}
		"ghoul":
			sp = {"kind": "crawler_back", "height": 420, "color": C("#8a947c"), "blood": 0.5}
		"elder_ghoul":
			sp = {"kind": "crawler_back", "height": 480, "color": C("#6e7a66"), "bulk": 1.15, "blood": 0.8, "hair": "ragged", "hair_c": C("#2a2a24")}
		"slime":
			sp = Monsters.More.spec_of("slime").duplicate()
			sp["back"] = true
	if not sp.is_empty():
		sp["turn"] = turn
		if turn > 0.0 and sp.has("side_pose"):  # 옆모습만 다른 자세(인간: 앞으로 든 팔을 몸에 붙여 내림)
			sp["pose"] = (sp["pose"] as Dictionary).merged(sp["side_pose"], true)
	return sp


static func paint(id: String, seed_value: int) -> Variant:
	var sp := spec_of(id)
	if sp.is_empty():
		return null
	match str(sp.get("kind", "figure")):
		"figure":
			return figure(sp, seed_value)
		"crawler_back":
			return _crawler(sp, seed_value)
	return Things.paint(str(sp["kind"]), sp, seed_value)


## 몸 높이(px, 무대 키 기준): 탐험가 = 사람 키(바바리안도 같은 값이라 그림이 큰 만큼 크게 보인다), 사람형 = 설계 키, 나머지 = 정면 그림과 같은 비율.
static func body_height(id: String, crop_h: float) -> float:
	var sp := spec_of(id)
	match str(sp.get("kind", "figure")):
		"figure":
			return REF_H if RACES.has(id.trim_suffix("_back").trim_suffix("_side")) else float(sp.get("height", 560))
		"crawler_back":
			return crop_h / 0.7
	return crop_h / 0.78


static func figure(sp: Dictionary, seed_value: int) -> Paint:
	var H := float(sp.get("height", 560))
	var w := int(H * float(sp.get("width", 1.2)))
	var h := int(H * float(sp.get("canvas_h", 1.12)))
	var p := Paint.new(w, h, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cl := Clay.new(w, h)
	var pr := Back.proj(Vector2(w * 0.5, h - H * 0.03), H, float(sp.get("turn", 0.0)), float(sp.get("pitch", 0.0)))
	var j := Back.skeleton(sp)
	if sp.has("walk"):  # 탐험 맵 걷기 그림(tools/paint_actors.gd)
		j = Back.stride(j, float(sp["walk"]), float(sp.get("step", 0.085)) * float(sp.get("legs", 1.0)))
	var skin_c: Color = sp.get("skin", Color("#c49a78"))
	var opts := {"mottle": sp.get("mottle", skin_c.darkened(0.35)), "mottle_amt": float(sp.get("mottle_amt", 0.35))}
	if sp.has("shade"):
		opts["shade"] = sp["shade"]
	var skin := cl.mat(skin_c, "skin", opts)
	var mats := {"dark": cl.mat(Color("#1a0d0b"), "glow")}
	var bd := Back.body(cl, pr, j, sp, skin, cl.mat(Color("#3a2e24"), "bone"))
	var hd := Back.head(cl, pr, j, skin, mats)
	var kit: Dictionary = sp.get("kit", {})
	BackKit.dress(cl, pr, j, bd, kit, rng)
	BackHair.hair(cl, pr, j, bd, hd, sp, rng)
	BackGear.gear(cl, pr, j, bd, hd, kit, rng)
	Render.render(cl, p, H, sp.get("light", Render.LIGHT))
	Fur.comb(cl, p, H, float(sp.get("fur_len", 1.0)))
	if sp.get("map_face", false) or sp.get("socket_eyes", false):  # 탐험 맵 얼굴(피어 앤 헝거 맵 그림) — 입은 그리지 않는다
		var side: bool = (hd["eyes"] as Array).size() < 2
		var r := float(hd["hh"]) * H * float(sp.get("eye_r", 0.055))
		var cx := 0.0
		for e: Vector2 in hd["eyes"]:
			cx += e.x / (hd["eyes"] as Array).size()
		for e: Vector2 in hd["eyes"]:
			_map_eye(p, e, r, -1.0 if e.x < cx else 1.0, 0.65 if side else 1.0)
		Finish.done(p, sp, Back.screen_joints(pr, j), H)
		return p
	for e: Vector2 in hd["eyes"]:  # 옆얼굴 눈: 짧은 눈꺼풀 선 + 어두운 눈동자
		Ink.line(p, e + Vector2(-0.008, -0.002) * H, e + Vector2(0.008, 0.001) * H, maxf(1.2, H / 380.0), Ink.INK, 0.85, 0.4)
		for yy in range(int(e.y - 0.003 * H), int(e.y + 0.006 * H)):
			for xx in range(int(e.x - 0.002 * H), int(e.x + 0.007 * H)):
				p.blend(xx, yy, Color("#140c0a"), 0.7)
	Finish.done(p, sp, Back.screen_joints(pr, j), H)
	return p


## 탐험 맵 눈 하나(참고: 피어 앤 헝거 맵 그림을 원본 픽셀로 본 것): 가로로 긴 아몬드꼴, 위 눈꺼풀은 굵고 짙은 선·아래는 가는 선,
## 안은 흰자가 아닌 흐린 회색에 가운데 짙은 눈동자, 바깥 끝이 조금 처지고, 둘레(특히 위)에 옅은 눈구멍 그늘. side = 바깥쪽(-1 왼쪽, +1 오른쪽).
static func _map_eye(p: Paint, e: Vector2, r: float, side: float, narrow: float) -> void:
	var rx := r * 1.45 * narrow
	var tilt := 0.14 * side  # 바깥 끝이 아래로
	for yy in range(int(e.y - r * 2.2), int(e.y + r * 1.8) + 1):
		for xx in range(int(e.x - rx * 1.5), int(e.x + rx * 1.5) + 1):
			var u := (xx - e.x) / rx
			var v := (yy - e.y) / r - u * tilt * 1.4
			var w := 1.0 - u * u
			if absf(u) < 1.35 and v > -1.9 and v < 1.2:  # 눈구멍 그늘(위로 더 넓게)
				var sd := Vector2(u / 1.35, (v + 0.35) / 1.55).length()
				if sd < 1.0:
					p.blend(xx, yy, Color("#2a1a14"), 0.4 * smoothstep(1.0, 0.4, sd))
			if absf(u) >= 1.0:
				continue
			var top := -0.85 * w
			var bot := 0.6 * w
			if v < top - 0.42 or v > bot + 0.22:
				continue
			if v < top + 0.3:
				p.blend(xx, yy, Color("#120a08"), 0.95)  # 위 눈꺼풀
			elif v > bot - 0.12:
				p.blend(xx, yy, Color("#1e1310"), 0.8)  # 아래 눈꺼풀
			elif Vector2(u * 1.45 * narrow, v).length() < 0.62:
				p.blend(xx, yy, Color("#2e2620"), 0.92)  # 눈동자
			else:
				p.blend(xx, yy, Color("#8e8576"), 0.9)  # 흐린 흰자


## 기는 구울 뒷모습: 가까이 솟은 엉덩이와 개구리처럼 벌린 뒷다리, 앞으로 멀어지는 굽은 등(척추 마디·갈비), 높이 솟은 팔꿈치와
## 멀리 땅을 짚은 손, 어깨 너머로 보이는 정수리.
static func _crawler(sp: Dictionary, seed_value: int) -> Paint:
	var H := float(sp.get("height", 420))
	var w := int(H * 1.25)
	var h := int(H * 0.82)
	var p := Paint.new(w, h, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cl := Clay.new(w, h)
	var pr := Back.proj(Vector2(w * 0.5, h - H * 0.04), H, 0.0)
	var col: Color = sp.get("color", Color("#8a947c"))
	var skin := cl.mat(col, "skin", {"mottle": col.darkened(0.4), "mottle_amt": 0.5})
	var nail := cl.mat(Color("#2a221c"), "bone")
	var bk := float(sp.get("bulk", 1.0))
	var B := Vector3(0, 0, 1)
	var g := cl.group()
	cl.tag = "torso"
	var rump := Vector3(0, -0.3, 0.05)
	var sh := Vector3(0, -0.45, -0.24)
	Back.chain(cl, pr, g, [rump, rump.lerp(sh, 0.5) + Vector3(0, -0.06, 0.02), sh], [0.085 * bk, 0.08 * bk, 0.092 * bk], skin, 0.03)
	for s: int in [-1, 1]:
		Back.ell(cl, pr, g, rump + Vector3(s * 0.045, 0.03, 0.02), 0.06 * bk, 0.065, 0.05, skin, 0.02)
		Back.ell(cl, pr, g, sh + Vector3(s * 0.08 * bk, 0.0, 0.0), 0.06 * bk, 0.06, 0.06, skin, 0.03)
	cl.tag = ""
	var bw := 0.085 * bk
	for k in 7:  # 척추 마디 · 갈비
		var q := rump.lerp(sh, 0.08 + k * 0.13)
		Back.bump(cl, pr, g, q + Vector3(0, -bw, 0), Vector3(0, -1, 0.6), 0.012, 0.01, 0.008, skin)
		if k > 1 and k < 6:
			for s: int in [-1, 1]:
				Back.groove(cl, pr, g, [q + Vector3(s * 0.02, -bw * 0.8, 0), q + Vector3(s * 0.07, -bw * 0.3, 0.0), q + Vector3(s * 0.085, bw * 0.2, 0.0)], Vector3(s, -0.5, 0.4), 0.005, 0.007)
	for s: int in [-1, 1]:
		Back.bump(cl, pr, g, sh + Vector3(s * 0.05, -0.07 * bk, 0.02), Vector3(s * 0.3, -1, 0.5), 0.035, 0.03, 0.012, skin)  # 견갑골
	# 머리(어깨 너머 정수리)
	var hg := cl.group()
	var hc := sh + Vector3(0, -0.02, -0.12)
	Back.ell(cl, pr, hg, hc, 0.06, 0.068, 0.07, skin, 0.01)
	if sp.has("hair"):
		var hm := cl.mat(sp.get("hair_c", Color("#2a2a24")), "hair")
		for k in 8:
			var a := hc + Vector3(rng.randf_range(-0.05, 0.05), -0.05, rng.randf_range(-0.02, 0.04))
			Back.chain(cl, pr, hg, [a, a + Vector3(rng.randf_range(-0.03, 0.03), 0.06, 0.03), a + Vector3(rng.randf_range(-0.05, 0.05), 0.11, 0.04)], [0.012, 0.008, 0.003], hm, 0.004)
	# 뒷다리(개구리처럼 무릎을 바깥 위로) · 팔(팔꿈치를 높이, 손은 멀리 땅에)
	for s: int in [-1, 1]:
		var gl := cl.group()
		var hip := rump + Vector3(s * 0.06, 0.01, -0.01)
		var kn := Vector3(s * 0.22, -0.2, 0.06)
		var an := Vector3(s * 0.13, -0.04, 0.07)
		Back.chain(cl, pr, gl, [hip, kn, an], [0.055 * bk, 0.036 * bk, 0.024 * bk], skin, 0.012)
		Back.ell(cl, pr, gl, kn, 0.032, 0.032, 0.03, skin, 0.008)
		Back.ell(cl, pr, gl, an + Vector3(0, 0.02, 0.01), 0.03, 0.02, 0.03, skin, 0.006)  # 발뒤꿈치
		var ga := cl.group()
		var sp3 := sh + Vector3(s * 0.11 * bk, 0.0, 0.0)
		var el := Vector3(s * 0.26, -0.56, -0.3)
		var wr := Vector3(s * 0.17, -0.04, -0.42)
		Back.chain(cl, pr, ga, [sp3, el, wr], [0.04 * bk, 0.03 * bk, 0.02 * bk], skin, 0.01)
		Back.ell(cl, pr, ga, el, 0.03, 0.03, 0.03, skin, 0.006)
		for f in 4:  # 땅을 움켜쥔 손가락 + 손톱
			var b := wr + Vector3(s * (f - 1.5) * 0.016, 0.0, -0.01)
			var t := b + Vector3(s * (f - 1.5) * 0.02, 0.03, -0.04)
			Back.chain(cl, pr, ga, [b, b.lerp(t, 0.6) + Vector3(0, -0.012, 0), t], [0.008, 0.007, 0.005], skin, 0.003)
			Back.cap(cl, pr, ga, t, t + Vector3(s * 0.006, 0.014, -0.012), 0.004, 0.001, nail, 0.002)
		Back.groove(cl, pr, gl, [hip.lerp(kn, 0.3) + Vector3(0, -0.03, 0.04), kn + Vector3(0, -0.02, 0.03)], B, 0.004, 0.005)
	Render.render(cl, p, H)
	var j := Back.screen_joints(pr, {"chest": sh, "waist": rump, "elbow_l": Vector3(-0.26, -0.56, -0.3), "elbow_r": Vector3(0.26, -0.56, -0.3), "wrist_l": Vector3(-0.17, -0.04, -0.42), "wrist_r": Vector3(0.17, -0.04, -0.42), "hand_l": Vector3(-0.17, -0.03, -0.44), "hand_r": Vector3(0.17, -0.03, -0.44)})
	Finish.done(p, sp, j, H)
	return p
