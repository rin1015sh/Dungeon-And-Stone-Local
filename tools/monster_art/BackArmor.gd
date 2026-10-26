extends RefCounted
## 부위별 갑옷 겹(사용자 2026-10-26 "갑옷만 따로 그려 캐릭터 위에 얹기 — 가죽 한 벌, 쇠 한 벌, 파츠별로"): 탐험가 몸(Back)에
## 한 부위만 입혀 그리고(tools/paint_armor.gd), 그 부위 재질이 보이는 픽셀만 남겨 투명 겹 그림으로 저장한다 — 게임은 장착한 장비에 맞는 겹을
## 몸 그림 위에 PARTS 순서로 얹는다(ArmorLayers). 같은 3D 몸·걸음에서 그리므로 걷기 칸마다 꼭 맞고, 몸에 가려지는 곳은 이미 빠져 있다.
##   armor = {부위: 벌} — 부위 feet(장화·정강이) · body(몸통·어깨·허리 아래 자락) · hands(장갑·아래팔) · head(투구·목), 벌 leather · iron.
## 밑옷은 고른 옷차림(MapLooks.CHOSEN — 인간 누빔 갑옷) 그대로라 갑옷은 그보다 두껍게(grow) 씌운다.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const BackKit := preload("res://tools/monster_art/BackKit.gd")

const RACES := ["human"]  ## 갑옷 겹을 그리는 종족(바바리안은 체형이 달라 나중에)
const SETS := ["leather", "iron"]
const PARTS := ["feet", "body", "hands", "head"]  ## 얹는 순서(아래 → 위)
const LEATHER := Color("#5e3c24")
const LEATHER_DARK := Color("#3a2416")
const GLOVE := Color("#7a5434")  ## 장갑(밑옷 팔목 가죽과 구분되게 밝게)
const IRON := Color("#4c5256")
const MAIL := Color("#3c4044")
const F := Vector3(0, 0, -1)  ## 앞(보는 사람 쪽 — 앞모습)
const B := Vector3(0, 0, 1)   ## 등


static func wear(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, hd: Dictionary, armor: Dictionary) -> void:
	for part: String in PARTS:
		if not armor.has(part):
			continue
		match "%s_%s" % [armor[part], part]:
			"leather_feet":
				_leather_feet(cl, pr, j)
			"leather_body":
				_leather_body(cl, pr, j, bd)
			"leather_hands":
				_leather_hands(cl, pr, j)
			"leather_head":
				_leather_head(cl, pr, hd)
			"iron_feet":
				_iron_feet(cl, pr, j)
			"iron_body":
				_iron_body(cl, pr, j, bd)
			"iron_hands":
				_iron_hands(cl, pr, j)
			"iron_head":
				_iron_head(cl, pr, j, hd)


static func _leather(cl: Clay, c: Color = LEATHER) -> int:
	return cl.mat(c, "leather", {"mottle": c.darkened(0.35), "mottle_amt": 0.35})


static func _iron(cl: Clay, c: Color = IRON) -> int:
	return cl.mat(c, "metal", {"mottle": c.darkened(0.45), "mottle_amt": 0.3, "spec": 0.22})  # 반사를 줄인다(기본 0.55면 작은 맵 그림에서 하얗게 날아갔다)


## 가죽 장화: 무릎 아래까지 오는 목 긴 장화 · 접은 목 · 발등과 정강이를 두른 끈 두 줄.
static func _leather_feet(cl: Clay, pr: Dictionary, j: Dictionary) -> void:
	var m := _leather(cl)
	var strap := _leather(cl, LEATHER_DARK)
	var g := cl.group()
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var kn: Vector3 = j["knee_" + t]
		var an: Vector3 = j["ankle_" + t]
		var top := kn.lerp(an, 0.12).y
		BackKit.shell(cl, pr, ["shin_" + t, "foot_" + t], 0.024, m, g, BackKit.band(cl, pr, top, 0.06), 0.01)
		BackKit.shell(cl, pr, ["shin_" + t], 0.032, m, g, BackKit.band(cl, pr, top - 0.008, top + 0.03), 0.006)  # 접은 목
		for k in 2:  # 끈
			var y := kn.lerp(an, 0.45 + k * 0.32).y
			BackKit.shell(cl, pr, ["shin_" + t], 0.029, strap, cl.group(), BackKit.band(cl, pr, y, y + 0.012), 0.004)
		Back.groove(cl, pr, g, [an + Vector3(-0.025, -0.02, -0.035), an + Vector3(0.025, -0.02, -0.035)], F, 0.004, 0.006)


## 가죽 흉갑: 몸통에 붙는 가죽(가장자리 단·앞뒤 솔기 땀) + 팔을 따라 감싼 어깨 판 + 허리 아래 가죽 띠 자락.
## 처음에 두껍게(0.038)·둥근 어깨받이 공으로 했더니 상자 같은 몸에 공 어깨(로봇 같다 — 사용자 2026-10-26) → 몸에 붙게, 어깨는 팔 모양 그대로.
static func _leather_body(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary) -> void:
	var m := _leather(cl)
	var dark := _leather(cl, LEATHER_DARK)
	var g := cl.group()
	var nk: Vector3 = j["neck"]
	var pv: Vector3 = j["pelvis"]
	var bw: float = bd["back_w"]
	var bot := pv.y - 0.03
	BackKit.shell(cl, pr, ["torso", "pelvis"], 0.029, m, g, BackKit.band(cl, pr, nk.y + 0.05, bot), 0.03, 0.0)
	BackKit.shell(cl, pr, ["torso", "pelvis"], 0.032, dark, g, BackKit.band(cl, pr, bot - 0.012, bot), 0.01)  # 아래 단
	BackKit.shell(cl, pr, ["torso"], 0.032, dark, g, BackKit.band(cl, pr, nk.y + 0.05, nk.y + 0.062), 0.01)  # 위 단
	for n: Vector3 in [F, B]:  # 가운데 솔기 + 양옆 땀
		var z := -0.15 if n == F else bw + 0.05
		Back.groove(cl, pr, g, [Vector3(0, nk.y + 0.06, z), Vector3(0, bot - 0.02, z * 0.9)], n, 0.004, 0.008)
		for s: float in [-1.0, 1.0]:
			Back.groove(cl, pr, g, [Vector3(s * 0.085, nk.y + 0.07, z * 0.92), Vector3(s * 0.08, bot - 0.02, z * 0.82)], n, 0.003, 0.005)
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var shp: Vector3 = j["shoulder_" + t]
		var ga := cl.group()  # 어깨 판: 어깨·위팔을 따라 두 겹(아래 겹이 조금 안쪽)
		BackKit.shell(cl, pr, ["shoulder_" + t, "upper_" + t], 0.03, m, ga, BackKit.band(cl, pr, shp.y - 0.045, shp.y + 0.035), 0.01)
		BackKit.shell(cl, pr, ["upper_" + t], 0.03, m, ga, BackKit.band(cl, pr, shp.y + 0.035, shp.y + 0.07), 0.008)
		BackKit.shell(cl, pr, ["upper_" + t], 0.036, dark, ga, BackKit.band(cl, pr, shp.y + 0.028, shp.y + 0.036), 0.004)
	var gs := cl.group()
	BackKit.shell(cl, pr, ["pelvis"], 0.038, m, gs, BackKit.band(cl, pr, bot - 0.004, pv.y + 0.07), 0.02, 0.0)  # 허리 아래 띠 자락(허벅지는 따르지 않는다 — 엉덩이 모양이 드러났다)
	for n: Vector3 in [F, B]:
		var z := -0.14 if n == F else bw + 0.04
		for x: float in [-0.105, -0.035, 0.035, 0.105]:
			Back.groove(cl, pr, gs, [Vector3(x, bot + 0.01, z), Vector3(x * 1.15, pv.y + 0.07, z)], n, 0.004, 0.01)
		for x: float in [-0.07, 0.0, 0.07]:
			Back.bump(cl, pr, gs, Vector3(x, bot + 0.012, z), n, 0.006, 0.006, 0.004, dark)


## 가죽 장갑: 손을 덮고 아래팔 중간까지 넓게 벌어진 목 + 끈.
static func _leather_hands(cl: Clay, pr: Dictionary, j: Dictionary) -> void:
	var m := _leather(cl, GLOVE)
	var dark := _leather(cl, LEATHER_DARK)
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var el: Vector3 = j["elbow_" + t]
		var wr: Vector3 = j["wrist_" + t]
		var g := cl.group()
		var a := el.lerp(wr, 0.4)
		BackKit.shell(cl, pr, ["fore_" + t], 0.026, m, g, BackKit.band(cl, pr, minf(a.y, wr.y) - 0.004, maxf(a.y, wr.y) + 0.004), 0.008)
		BackKit.shell(cl, pr, ["hand_" + t], 0.008, m, g, BackKit.band(cl, pr, wr.y - 0.06, wr.y + 0.2), 0.004)
		for k in 2:
			var q := a.lerp(wr, 0.3 + k * 0.4)
			BackKit.shell(cl, pr, ["fore_" + t], 0.03, dark, cl.group(), BackKit.band(cl, pr, q.y - 0.005, q.y + 0.005), 0.003)


## 가죽 모자: 머리를 덮은 둥근 가죽(정수리에서 모이는 솔기 넷) + 이마 위 말린 테.
static func _leather_head(cl: Clay, pr: Dictionary, hd: Dictionary) -> void:
	var m := _leather(cl)
	var dark := _leather(cl, LEATHER_DARK)
	var g := cl.group()
	var c: Vector3 = hd["c"]
	var rv: float = hd["rv"]
	BackKit.shell(cl, pr, ["skull", "ear"], 0.014, m, g, BackKit.band(cl, pr, c.y - rv * 2.0, c.y + rv * 0.05), 0.01)  # 머리에 붙게(두껍게 하면 둥근 통이 얹힌 것 같았다)
	for k in 4:
		var lon := k * PI * 0.5
		var pts: Array = []
		for i in 5:
			pts.append(Back.on_head(hd, 0.25 + i * 0.3, lon, 0.014))
		Back.ridge(cl, pr, g, pts, Vector3(sin(lon), -0.5, cos(lon)), 0.003, 0.003, dark)
	var rim: Array = []
	for i in 25:
		rim.append(Back.on_head(hd, 0.0, TAU * i / 24.0, 0.016))
	Back.chain(cl, pr, g, rim, rim.map(func(_v: Vector3) -> float: return 0.006), dark, 0.003)


## 쇠 정강이받이 + 쇠 신발: 무릎 덮개 · 정강이 판(이음매) · 발등 겹판.
static func _iron_feet(cl: Clay, pr: Dictionary, j: Dictionary) -> void:
	var m := _iron(cl)
	var dark := _iron(cl, IRON.darkened(0.35))
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var kn: Vector3 = j["knee_" + t]
		var an: Vector3 = j["ankle_" + t]
		var g := cl.group()
		BackKit.shell(cl, pr, ["shin_" + t], 0.02, m, g, BackKit.band(cl, pr, kn.y + 0.02, an.y + 0.01), 0.006)
		BackKit.shell(cl, pr, ["foot_" + t, "shin_" + t], 0.018, m, g, BackKit.band(cl, pr, an.y - 0.01, 0.06), 0.006)
		Back.ell(cl, pr, cl.group(), kn + Vector3(0, 0.005, -0.03), 0.04, 0.036, 0.034, m, 0.004)  # 무릎 덮개
		for k in 3:
			var q := kn.lerp(an, 0.3 + k * 0.25)
			Back.groove(cl, pr, g, [q + Vector3(-0.035, 0, -0.035), q + Vector3(0.035, 0, -0.035)], F, 0.003, 0.004)
		Back.groove(cl, pr, g, [kn + Vector3(0, 0.04, -0.045), an + Vector3(0, -0.02, -0.045)], F, 0.003, 0.004)  # 정강이 능선 옆 골
		for k in 2:  # 발등 겹판
			var q := an + Vector3(0, 0.015 + k * 0.012, -0.03 - k * 0.025)
			Back.groove(cl, pr, g, [q + Vector3(-0.03, 0, 0), q + Vector3(0.03, 0, 0)], Vector3(0, -0.6, -1), 0.003, 0.004)
		Back.bump(cl, pr, g, kn + Vector3(s * 0.03, 0.06, -0.04), F, 0.005, 0.005, 0.003, dark)


## 쇠 몸: 허벅지까지 오는 사슬 셔츠(위팔 소매) 위에 몸에 붙는 판 흉갑(가운데 능선 · 가로 겹 · 리벳) + 팔을 따라 감싼 겹판 어깨받이.
## 처음 흉갑 0.05·어깨받이 타원 공은 상자 몸에 공 어깨(로봇 같다 — 사용자 2026-10-26) → 흉갑은 사슬 바로 위, 어깨는 어깨·위팔 모양 띠 겹.
static func _iron_body(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary) -> void:
	var mail := cl.mat(MAIL, "metal", {"mottle": MAIL.darkened(0.45), "mottle_amt": 0.45, "spec": 0.12})
	var m := _iron(cl)
	var dark := _iron(cl, IRON.darkened(0.4))
	var nk: Vector3 = j["neck"]
	var pv: Vector3 = j["pelvis"]
	var bw: float = bd["back_w"]
	var gm := cl.group()
	var hem := pv.y + 0.12
	BackKit.shell(cl, pr, ["torso", "pelvis", "shoulder_l", "shoulder_r", "thigh_l", "thigh_r"], 0.026, mail, gm, BackKit.band(cl, pr, nk.y + 0.02, hem), 0.03, 0.0)
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		BackKit.shell(cl, pr, ["upper_" + t], 0.022, mail, gm, BackKit.band(cl, pr, j["shoulder_" + t].y - 0.06, j["elbow_" + t].y - 0.01), 0.01)
	var y := nk.y + 0.05
	while y < hem:  # 고리 결
		for n: Vector3 in [F, B, Vector3(-1, 0, 0), Vector3(1, 0, 0)]:
			var side := Vector3(n.z, 0, -n.x) * 0.14
			var base := n * 0.13
			Back.groove(cl, pr, gm, [base - side + Vector3(0, y, 0), base + side + Vector3(0, y, 0)], n, 0.0025, 0.004)
		y += 0.016
	var g := cl.group()
	var bot := pv.y - 0.05
	BackKit.shell(cl, pr, ["torso"], 0.034, m, g, BackKit.band(cl, pr, nk.y + 0.055, bot), 0.03, 0.0)
	BackKit.shell(cl, pr, ["torso", "pelvis"], 0.036, m, g, BackKit.band(cl, pr, bot - 0.004, bot + 0.024), 0.01)  # 허리판
	Back.ridge(cl, pr, g, [Vector3(0, nk.y + 0.05, -0.16), Vector3(0, bot - 0.01, -0.15)], F, 0.006, 0.005, m)  # 가슴 능선
	Back.ridge(cl, pr, g, [Vector3(0, nk.y + 0.05, bw + 0.06), Vector3(0, bot - 0.01, 0.1)], B, 0.006, 0.004, m)
	for k in 3:  # 가슴·등판 가로 겹(아래로 갈수록 바깥)
		var yy := lerpf(nk.y + 0.12, bot - 0.02, k / 2.0)
		Back.groove(cl, pr, g, [Vector3(-0.13, yy, -0.12), Vector3(0, yy + 0.006, -0.16), Vector3(0.13, yy, -0.12)], F, 0.003, 0.006)
		Back.groove(cl, pr, g, [Vector3(-0.13, yy, bw + 0.02), Vector3(0, yy + 0.006, bw + 0.06), Vector3(0.13, yy, bw + 0.02)], B, 0.003, 0.006)
	for n: Vector3 in [F, B]:
		var z := -0.15 if n == F else bw + 0.055
		for k in 4:  # 리벳
			Back.bump(cl, pr, g, Vector3((k % 2 - 0.5) * 0.2, nk.y + 0.06 + int(k / 2) * 0.13, z), n, 0.005, 0.005, 0.004, dark)
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var shp: Vector3 = j["shoulder_" + t]
		for k in 3:  # 어깨받이(어깨·위팔을 따라 위에서 아래로 겹친 띠 — 아래 겹이 안쪽)
			var y0 := shp.y - 0.04 + k * 0.03
			BackKit.shell(cl, pr, ["shoulder_" + t, "upper_" + t], 0.032 - k * 0.003, m, cl.group(), BackKit.band(cl, pr, y0, y0 + 0.036), 0.006)


## 쇠 팔: 아래팔 판(팔꿈치 덮개) + 손등 겹판 장갑.
static func _iron_hands(cl: Clay, pr: Dictionary, j: Dictionary) -> void:
	var m := _iron(cl)
	var glove := _leather(cl, LEATHER_DARK)
	for s: int in [-1, 1]:
		var t := "l" if s < 0 else "r"
		var el: Vector3 = j["elbow_" + t]
		var wr: Vector3 = j["wrist_" + t]
		var g := cl.group()
		BackKit.shell(cl, pr, ["fore_" + t], 0.028, m, g, BackKit.band(cl, pr, minf(el.y, wr.y) + 0.015, maxf(el.y, wr.y) + 0.004), 0.006)
		Back.ell(cl, pr, cl.group(), el, 0.036, 0.036, 0.034, m, 0.004)  # 팔꿈치 덮개
		var gh := cl.group()
		BackKit.shell(cl, pr, ["hand_" + t], 0.008, glove, gh, BackKit.band(cl, pr, wr.y - 0.06, wr.y + 0.2), 0.004)
		var hnd: Vector3 = j["hand_" + t]
		BackKit.shell(cl, pr, ["hand_" + t], 0.013, m, gh, BackKit.band(cl, pr, minf(wr.y, hnd.y) - 0.01, maxf(wr.y, hnd.y) + 0.012), 0.004)  # 손등 판
		for k in 2:
			var q := wr.lerp(el, 0.3 + k * 0.35)
			Back.groove(cl, pr, g, [q + Vector3(-0.03, 0, -0.03), q + Vector3(0.03, 0, -0.03)], F, 0.003, 0.004)
			Back.groove(cl, pr, g, [q + Vector3(-0.03, 0, 0.03), q + Vector3(0.03, 0, 0.03)], B, 0.003, 0.004)


## 쇠 투구: 머리에 붙는 쇠 모자 위로 솟은 뾰족한 꼭대기(노르만식 원뿔 투구 — 가운데 능선 · 이마 테 · 코 가리개) + 목을 감싼 사슬.
## 처음 둥근 쇠(0.03)·넓은 테·어깨까지 사슬은 목이 묻힌 둥근 통 머리(로봇 같다 — 사용자 2026-10-26) → 머리에 붙이고 꼭대기를 뾰족하게, 사슬은 목만.
static func _iron_head(cl: Clay, pr: Dictionary, j: Dictionary, hd: Dictionary) -> void:
	var m := _iron(cl)
	var mail := cl.mat(MAIL, "metal", {"mottle": MAIL.darkened(0.45), "mottle_amt": 0.45, "spec": 0.12})
	var c: Vector3 = hd["c"]
	var rv: float = hd["rv"]
	var ru: float = hd["ru"]
	var nk: Vector3 = j["neck"]
	var gm := cl.group()
	BackKit.shell(cl, pr, ["neck"], 0.022, mail, gm, BackKit.band(cl, pr, c.y + rv * 0.15, nk.y + 0.025), 0.01)
	var y := c.y + rv * 0.3
	while y < nk.y + 0.025:  # 고리 결
		for n: Vector3 in [F, B, Vector3(-1, 0, 0), Vector3(1, 0, 0)]:
			var side := Vector3(n.z, 0, -n.x) * 0.1
			Back.groove(cl, pr, gm, [n * 0.07 - side + Vector3(0, y, 0), n * 0.07 + side + Vector3(0, y, 0)], n, 0.0022, 0.0035)
		y += 0.013
	var g := cl.group()
	BackKit.shell(cl, pr, ["skull", "ear"], 0.016, m, g, BackKit.band(cl, pr, c.y - rv * 2.0, c.y + rv * 0.1), 0.01)
	var up := Vector3(0, -1, 0)
	Back.cap(cl, pr, g, c + up * rv * 0.35, c + up * (rv + 0.06), ru * 0.82 + 0.012, 0.004, m, 0.01)  # 뾰족한 꼭대기
	var crest: Array = []
	for i in 9:
		crest.append(Back.on_head(hd, lerpf(0.3, PI - 0.3, i / 8.0), PI, 0.018))  # 이마 → 꼭대기 → 뒤통수
	crest[4] = c + up * (rv + 0.055)
	Back.ridge(cl, pr, g, crest, Vector3(0, -1, 0), 0.004, 0.004, m)
	var rim: Array = []
	for i in 25:
		rim.append(Back.on_head(hd, 0.03, TAU * i / 24.0, 0.018))
	Back.chain(cl, pr, g, rim, rim.map(func(_v: Vector3) -> float: return 0.006), m, 0.003)
	Back.cap(cl, pr, g, Back.on_head(hd, 0.1, PI, 0.02), Back.on_head(hd, -0.4, PI, 0.024), 0.009, 0.007, m, 0.003)  # 코 가리개


## 갑옷 겹 오려 내기: mask(Party.figure out.mask)를 grow px 넓혀(경계 잉크 선까지) 그 밖은 투명으로.
static func cut(img: Image, mask: Image, grow: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := mask.get_data()
	var tmp := PackedByteArray()
	tmp.resize(w * h)
	for y in h:  # 가로로 넓히기
		var row := y * w
		for x in w:
			var on := 0
			for dx in range(-grow, grow + 1):
				var xx := x + dx
				if xx >= 0 and xx < w and src[row + xx] > 0:
					on = 255
					break
			tmp[row + x] = on
	for y in h:  # 세로로 넓히며 잘라 내기
		for x in w:
			var on := false
			for dy in range(-grow, grow + 1):
				var yy := y + dy
				if yy >= 0 and yy < h and tmp[yy * w + x] > 0:
					on = true
					break
			if not on:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
