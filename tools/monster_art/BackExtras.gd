extends RefCounted
## 3D 몸(Back)의 몬스터 부품(탐험 맵 몬스터 걷기 그림 — tools/monster_art/MapMonster.gd가 전투 설계를 옮겨 쓴다):
## 뿔 horns · 날개 wings · 꼬리 tail · 긴 옷 robe · 네모 머리 block_head · 한손·양손 무기(검·대검·도끼·곡괭이·지팡이·활).
## 덩어리 판 lumps(골렘 — 어깨·가슴·팔뚝·허벅지에 붙은 돌·쇠 판) · 얼음 결정 crystals · 털 뭉치(skin_kind fur — 작은 그림에서도 털로 보이게 윤곽에 뾰족한 술).
## spec 키: horns(색) · horn_len · wings(색) · wing_span · tail(색) · robe(색) · block_head(true) · lumps(개수) · crystals(색) · kit.weapon(sword|greatsword|axe|pick|staff|bow)

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")

const HAND_WEAPONS := ["sword", "greatsword", "axe", "pick", "staff", "bow", "club", "cleaver", "bomb"]


static func extras(cl: Clay, pr: Dictionary, j: Dictionary, hd: Dictionary, sp: Dictionary, skin: int) -> void:
	if sp.has("robe"):
		_robe(cl, pr, j, sp["robe"])
	if sp.has("tail"):
		_tail(cl, pr, j, sp["tail"])
	if sp.has("wings"):
		_wings(cl, pr, j, sp["wings"], float(sp.get("wing_span", 1.0)))
	if sp.get("block_head", false):
		var g := cl.group()
		var hh: float = hd["hh"]
		var c: Vector3 = hd["c"]
		Back.ell(cl, pr, g, c + Vector3(0, hh * 0.08, 0), hh * 0.6, hh * 0.42, hh * 0.52, skin, 0.004)  # 네모진 돌·쇠 머리(골렘) — 납작하고 모가 선 덩어리
		Back.cap(cl, pr, g, c + Vector3(-hh * 0.5, -hh * 0.12, -hh * 0.42), c + Vector3(hh * 0.5, -hh * 0.12, -hh * 0.42), hh * 0.1, hh * 0.1, skin, 0.003)  # 눈썹 턱
	if sp.has("crown"):
		_crown(cl, pr, hd, sp["crown"])
	if sp.has("lumps") and ["metal", "stone", "slime"].has(str(sp.get("skin_kind", ""))):  # 골렘만(살갗 혹은 판이 아니다)
		_lumps(cl, pr, j, sp, skin)
	if sp.has("crystals"):
		_crystals(cl, pr, j, sp["crystals"])
	if str(sp.get("skin_kind", "")) == "fur":
		_shag(cl, pr, j, skin)
	if sp.has("horns"):
		_horns(cl, pr, hd, sp["horns"], float(sp.get("horn_len", 0.7)))
	var kit: Dictionary = sp.get("kit", {})
	if HAND_WEAPONS.has(str(kit.get("weapon", ""))):
		_hand_weapon(cl, pr, j, kit, sp)


## 뿔: 머리 위 양옆에서 위·바깥·뒤로 휘어 뾰족하게.
static func _horns(cl: Clay, pr: Dictionary, hd: Dictionary, col: Color, length: float) -> void:
	var m := cl.mat(col, "bone")
	var g := cl.group()
	var hh: float = hd["hh"]
	for s: float in [-1.0, 1.0]:
		var b := Back.on_head(hd, 0.75, PI - s * 0.9, -0.004)
		var L := hh * length
		Back.chain(cl, pr, g, [b, b + Vector3(s * L * 0.35, -L * 0.45, L * 0.1), b + Vector3(s * L * 0.55, -L * 0.95, L * 0.3)], [hh * 0.12, hh * 0.08, hh * 0.01], m, 0.005)


## 날개: 어깨뼈에서 위로 꺾인 팔(뼈) → 손목에서 아래로 퍼지는 손가락 뼈 셋, 그 사이 막은 안으로 파인 물결 자락(박쥐 날개).
static func _wings(cl: Clay, pr: Dictionary, j: Dictionary, col: Color, span: float) -> void:
	var m := cl.mat(col, "skin", {"mottle": col.darkened(0.3), "mottle_amt": 0.4})
	var bone := cl.mat(col.darkened(0.35), "bone")
	var g := cl.group()
	var ch: Vector3 = j["chest"]
	var H: float = pr["H"]
	for s: float in [-1.0, 1.0]:
		var root := ch + Vector3(s * 0.05, -0.03, 0.07)
		var wrist := root + Vector3(s * 0.2 * span, -0.2 * span, 0.08)
		var tips: Array = [wrist + Vector3(s * 0.2 * span, 0.04 * span, 0.02), wrist + Vector3(s * 0.15 * span, 0.2 * span, 0.02), wrist + Vector3(s * 0.04 * span, 0.3 * span, 0.01)]
		var tail := root + Vector3(s * 0.04, 0.2 * span, 0.04)
		Back.chain(cl, pr, g, [root, wrist], [0.018, 0.012], bone, 0.004)
		for t: Vector3 in tips:
			Back.cap(cl, pr, g, wrist, t, 0.009, 0.003, bone, 0.003)
		var ring: Array = [root, wrist] + tips + [tail]
		var poly := PackedVector2Array()
		for i in ring.size():
			var a: Vector3 = ring[i]
			poly.append(Back.P2(pr, a))
			if i >= 2 and i < ring.size() - 1:  # 손가락 끝 사이 자락은 손목 쪽으로 파인다
				var b: Vector3 = ring[i + 1]
				poly.append(Back.P2(pr, (a + b) * 0.5 + (wrist - (a + b) * 0.5) * 0.28))
		cl.slab(g, poly, Back.P(pr, root).z - 0.004 * H, 0.004 * H, m, 1.5, 0.006 * H)


## 꼬리: 엉덩이 뒤에서 아래로 늘어져 땅에 끌린다.
static func _tail(cl: Clay, pr: Dictionary, j: Dictionary, col: Color) -> void:
	var m := cl.mat(col, "skin", {"mottle": col.darkened(0.3), "mottle_amt": 0.4})
	var g := cl.group()
	var pv: Vector3 = j["pelvis"]
	Back.chain(cl, pr, g, [pv + Vector3(0, 0.02, 0.06), pv + Vector3(0, 0.18, 0.16), Vector3(0, -0.03, 0.3)], [0.045, 0.03, 0.008], m, 0.01)


## 긴 옷(로브): 허리에서 발목까지 퍼지는 자락 — 두 다리를 덮는다.
static func _robe(cl: Clay, pr: Dictionary, j: Dictionary, col: Color) -> void:
	var m := cl.mat(col, "cloth", {"mottle": col.darkened(0.25), "mottle_amt": 0.3})
	var g := cl.group()
	var pv: Vector3 = j["pelvis"]
	var ch: Vector3 = j["chest"]
	Back.cap(cl, pr, g, ch + Vector3(0, 0.02, 0), pv, 0.1, 0.11, m, 0.02)
	Back.cap(cl, pr, g, pv, Vector3(0, -0.07, pv.z), 0.12, 0.155, m, 0.02)
	for k in 5:  # 자락 주름
		var u := lerpf(-0.11, 0.11, k / 4.0)
		Back.groove(cl, pr, g, [pv + Vector3(u * 0.7, 0.04, 0.0), Vector3(u, -0.08, pv.z)], Vector3(0, 0, 1), 0.004, 0.008)


## 손 무기: 쥔 손에서. 검·대검 = 아래로 늘어뜨린 날, 도끼·곡괭이 = 자루 + 머리, 지팡이 = 긴 막대 + 빛 구슬, 활 = 손에 든 활.
static func _hand_weapon(cl: Clay, pr: Dictionary, j: Dictionary, kit: Dictionary, sp: Dictionary) -> void:
	var kind := str(kit["weapon"])
	var t := str(kit.get("weapon_hand", "r"))
	var hd: Vector3 = j["hand_" + t]
	var metal := cl.mat(kit.get("weapon_c", Color("#8a9098")), "metal")
	var wood := cl.mat(kit.get("staff_c", kit.get("wood", Color("#4a3628"))), "wood")
	var g := cl.group()
	cl.marked.append(g)
	var down := Vector3(0.0, 1.0, -0.25).normalized()
	if sp.get("plant", false) or str(sp.get("rest", "")) == "kneel":  # 두 손으로 칼끝을 땅에 짚음
		down = Vector3(0.0, 1.0, 0.02).normalized()
	if j.has("weapon_dir"):  # 전투 동작 칸이 정한 칼끝 방향(PartyMotion)
		down = j["weapon_dir"]
	match kind:
		"sword", "greatsword":
			var big := kind == "greatsword"
			Back.cap(cl, pr, g, hd - down * 0.04, hd + down * 0.02, 0.01, 0.01, wood, 0.002)
			Back.cap(cl, pr, g, hd + down * 0.02 + Vector3(-0.04 if big else -0.03, 0, 0), hd + down * 0.02 + Vector3(0.04 if big else 0.03, 0, 0), 0.008, 0.008, metal, 0.002)  # 날밑
			Back.cap(cl, pr, g, hd + down * 0.03, hd + down * (0.42 if big else 0.28), 0.022 if big else 0.014, 0.004, metal, 0.002)
		"axe", "pick":
			var up := Vector3(0.0, -1.0, -0.2).normalized()
			var top := hd + up * 0.2
			Back.cap(cl, pr, g, hd - up * 0.12, top, 0.01, 0.009, wood, 0.002)
			if kind == "axe":
				Back.ell(cl, pr, g, top + Vector3(0.05, 0.02, 0), 0.05, 0.06, 0.01, metal, 0.003)
			else:
				Back.cap(cl, pr, g, top + Vector3(-0.09, 0.03, 0), top + Vector3(0.09, 0.03, 0), 0.012, 0.004, metal, 0.002)
		"club":  # 몽둥이: 손에서 아래로, 끝으로 갈수록 굵다
			Back.cap(cl, pr, g, hd - down * 0.04, hd + down * 0.36, 0.014, 0.034, wood, 0.004)
			Back.ell(cl, pr, g, hd + down * 0.34, 0.04, 0.05, 0.04, wood, 0.006)
		"cleaver":  # 큰 식칼: 짧은 자루 + 넓은 네모 날
			Back.cap(cl, pr, g, hd - down * 0.03, hd + down * 0.04, 0.01, 0.01, wood, 0.002)
			var a := hd + down * 0.05
			var poly := PackedVector2Array([Back.P2(pr, a + Vector3(-0.012, 0, 0)), Back.P2(pr, a + Vector3(0.06, 0, 0)), Back.P2(pr, a + down * 0.2 + Vector3(0.07, 0, 0)), Back.P2(pr, a + down * 0.22 + Vector3(-0.012, 0, 0))])
			cl.slab(g, poly, Back.P(pr, a).z, 0.004 * float(pr["H"]), metal, 1.5, 0.004 * float(pr["H"]))
		"bomb":  # 폭탄: 손에 든 검은 공 + 심지
			var c := hd + Vector3(0, -0.02, -0.02)
			Back.ell(cl, pr, g, c, 0.04, 0.04, 0.04, cl.mat(Color("#2a2622"), "metal"), 0.004)
			Back.cap(cl, pr, g, c + Vector3(0, -0.035, 0), c + Vector3(0.015, -0.07, 0), 0.005, 0.003, cl.mat(Color("#8a6a3a"), "cloth"), 0.002)
		"staff":
			var up := Vector3(0.0, -1.0, -0.1).normalized()
			Back.cap(cl, pr, g, hd - up * 0.4, hd + up * 0.38, 0.011, 0.009, wood, 0.002)
			if kit.has("glow"):
				Back.ell(cl, pr, g, hd + up * 0.42, 0.03, 0.03, 0.03, cl.mat(kit["glow"], "glow"), 0.005)
		"bow":  # 활대(손에서 위·아래로, 배가 앞으로) + 시위(bow_draw면 다른 손까지 당김) — 위 방향 = weapon_dir(동작 칸 W)
			var up: Vector3 = j["weapon_dir"] if j.has("weapon_dir") else Vector3(0, -1, 0)
			var fwd := (Vector3(0, 0, -1) - up * up.dot(Vector3(0, 0, -1))).normalized()
			var pts: Array = []
			for k in 7:
				var a := lerpf(-1.1, 1.1, k / 6.0)
				pts.append(hd + fwd * (0.03 + cos(a) * 0.07) + up * (sin(a) * 0.26))
			Back.chain(cl, pr, g, pts, [0.006, 0.009, 0.011, 0.012, 0.011, 0.009, 0.006], wood, 0.002)
			var cord := cl.mat(Color("#d8d0b8"), "cloth")
			var tip_a: Vector3 = pts[0]
			var tip_b: Vector3 = pts[pts.size() - 1]
			if j.get("bow_draw", false):
				var pull: Vector3 = j["hand_" + ("r" if t == "l" else "l")]
				Back.cap(cl, pr, g, tip_a, pull, 0.0028, 0.0028, cord, 0.0)
				Back.cap(cl, pr, g, pull, tip_b, 0.0028, 0.0028, cord, 0.0)
			else:
				Back.cap(cl, pr, g, tip_a, tip_b, 0.0028, 0.0028, cord, 0.0)
	Back.ell(cl, pr, g, hd + Vector3(0, 0, 0.005), 0.022, 0.028, 0.02, cl.mat(sp.get("skin", Color("#8a7a6a")), str(sp.get("skin_kind", "skin"))), 0.003)  # 쥔 손


## 골렘 판: 어깨·가슴·팔뚝·허벅지·정강이에 붙은 납작한 덩어리(같은 재질, 조금 어둡게 — 이음매가 보이게).
static func _lumps(cl: Clay, pr: Dictionary, j: Dictionary, sp: Dictionary, skin: int) -> void:
	var g := cl.group()
	var col: Color = sp.get("skin", Color("#8a8a8a"))
	var m := cl.mat(col.darkened(0.12), str(sp.get("skin_kind", "stone")), {"mottle": sp.get("mottle", col.darkened(0.3)), "mottle_amt": float(sp.get("mottle_amt", 0.4))})
	var ch: Vector3 = j["chest"]
	var k := 1.5  # 맵 그림에서도 덩어리로 보이게 크게
	for z: float in [-0.07, 0.07]:
		Back.ell(cl, pr, g, ch + Vector3(0, 0.0, z), 0.12, 0.08, 0.035, m, 0.003)  # 가슴판·등판
	for t: String in ["l", "r"]:
		var sh: Vector3 = j["shoulder_" + t]
		Back.ell(cl, pr, g, sh + Vector3(0, -0.015, 0), 0.06 * k, 0.045 * k, 0.06 * k, m, 0.003)  # 어깨 덩어리
		Back.ell(cl, pr, g, ((j["elbow_" + t] as Vector3) + (j["wrist_" + t] as Vector3)) * 0.5, 0.045 * k, 0.06 * k, 0.045 * k, m, 0.003)  # 팔뚝
		Back.ell(cl, pr, g, ((j["hip_" + t] as Vector3) + (j["knee_" + t] as Vector3)) * 0.5, 0.05 * k, 0.06 * k, 0.05 * k, m, 0.003)  # 허벅지
		Back.ell(cl, pr, g, ((j["knee_" + t] as Vector3) + (j["ankle_" + t] as Vector3)) * 0.5, 0.04 * k, 0.05 * k, 0.04 * k, m, 0.003)  # 정강이
		Back.ell(cl, pr, g, j["hand_" + t], 0.04 * k, 0.04 * k, 0.04 * k, m, 0.003)  # 주먹
	Back.ell(cl, pr, g, (j["pelvis"] as Vector3) + Vector3(0, -0.02, 0), 0.1, 0.055, 0.08, m, 0.003)  # 허리 덩어리


## 얼음 결정: 어깨·등에서 위·바깥으로 솟은 뾰족한 기둥.
static func _crystals(cl: Clay, pr: Dictionary, j: Dictionary, col: Color) -> void:
	var m := cl.mat(col, "slime")
	var g := cl.group()
	var ch: Vector3 = j["chest"]
	var pts := [[Vector3(-0.07, -0.05, 0.06), Vector3(-0.05, -0.12, 0.03)], [Vector3(0.07, -0.05, 0.06), Vector3(0.06, -0.13, 0.03)],
		[Vector3(0.0, -0.02, 0.09), Vector3(0.0, -0.1, 0.1)], [Vector3(-0.04, 0.05, 0.09), Vector3(-0.07, -0.02, 0.12)], [Vector3(0.04, 0.04, 0.09), Vector3(0.08, -0.02, 0.12)]]
	for p: Array in pts:
		var a := ch + (p[0] as Vector3)
		Back.cap(cl, pr, g, a, a + (p[1] as Vector3) * 0.9, 0.02, 0.002, m, 0.002)


## 털 뭉치(예티): 어깨·팔·허벅지·등 둘레에 아래로 처진 뾰족한 술 — 윤곽이 들쭉날쭉해 작은 그림에서도 털짐승으로 보인다.
static func _shag(cl: Clay, pr: Dictionary, j: Dictionary, skin: int) -> void:
	var g := cl.group()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var spots: Array = []
	for t: String in ["l", "r"]:
		var s := -1.0 if t == "l" else 1.0
		spots.append([j["shoulder_" + t], Vector3(s * 0.05, 0.0, 0.0), 0.05])
		spots.append([((j["shoulder_" + t] as Vector3) + (j["elbow_" + t] as Vector3)) * 0.5, Vector3(s * 0.04, 0.0, 0.0), 0.04])
		spots.append([j["elbow_" + t], Vector3(s * 0.035, 0.0, 0.0), 0.035])
		spots.append([((j["hip_" + t] as Vector3) + (j["knee_" + t] as Vector3)) * 0.5, Vector3(s * 0.05, 0.0, 0.0), 0.045])
	spots.append([j["chest"], Vector3(0, 0.02, 0.07), 0.07])
	spots.append([j["waist"], Vector3(0, 0.0, 0.07), 0.07])
	for sp: Array in spots:
		var c: Vector3 = sp[0]
		var off: Vector3 = sp[1]
		var r: float = sp[2]
		for k in 7:
			var a := c + off + Vector3(rng.randf_range(-r, r) * 0.6, rng.randf_range(-r, r) * 0.5, rng.randf_range(-r, r) * 0.5)
			var tip := a + Vector3(off.normalized().x * 0.02 + rng.randf_range(-0.01, 0.01), 0.035 + rng.randf_range(0.0, 0.02), off.normalized().z * 0.015)
			Back.cap(cl, pr, g, a, tip + (tip - a) * 0.6, r * 0.55, 0.003, skin, 0.004)


## 왕관: 머리 위 둘레 띠 + 위로 솟은 뾰족한 날.
static func _crown(cl: Clay, pr: Dictionary, hd: Dictionary, col: Color) -> void:
	var m := cl.mat(col, "metal")
	var g := cl.group()
	var pts: Array = []
	for k in 13:
		pts.append(Back.on_head(hd, 0.75, k * TAU / 12.0, 0.006))
	var radii: Array = []
	for k in 13:
		radii.append(0.012)
	Back.chain(cl, pr, g, pts, radii, m, 0.003)
	for k in 6:
		var b := Back.on_head(hd, 0.78, k * TAU / 6.0 + 0.26, 0.008)
		Back.cap(cl, pr, g, b, b + Vector3(0, -float(hd["hh"]) * 0.28, 0), 0.014, 0.002, m, 0.002)
