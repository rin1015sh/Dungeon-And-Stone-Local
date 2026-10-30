extends RefCounted
## 새 플레이어블 종족 후보(사용자 2026-10-30 "엘프·드워프·수인 — 종족별로 여러 복장·외형을 뽑아 줘, 게임에 바로 적용하지는 말고"):
## 몸 설계(BODIES — Party.spec_of가 <종족>_back으로 쓴다, Party.RACES에는 없다 = 게임은 아직 모른다)와 몸 부품.
##   female(true) 여성 체형 — 둥근 엉덩이·가슴(옷 겹이 따라 덮도록 pelvis·torso 기록), 체격은 build "slender"(Back.BUILDS)
##   ears: elf(뒤로 솟은 뾰족한 귀) · fox · cat · wolf(머리 위 짐승 귀 — 털색 hair_c, 안쪽 ear_in)
##   fluff_tail {kind: fox|cat|wolf, c, tip} 털 꼬리(꼬리뼈에서 — 여우 = 굵고 끝이 밝음, 고양이 = 가늘고 끝이 올라감, 늑대 = 굵게 처짐)
##   crest {c, len} 정수리에서 묶어 뒤로 넘겨 어깨까지 흘러내리는 굵은 머리 다발(말꼬리)(드워프 투구 위 — 참고 그림) · map_locks 탐험 맵 짧은 머리 타래 값(paint_actors LOCKS에 덮음) · beard_long {len, braids, c} 가슴까지 내려오는 긴 수염(드워프 — 땋은 가닥 수 braids) · ponytail {len, high} 묶은 머리
## 옷차림 후보는 MapLooks(e* 엘프 · d* 드워프 · k* 수인), 그리기 = paint_actors --look · paint_motions --look.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")

const REF_H := 540.0  ## Party.REF_H와 같게

## 종족 몸(Party 설계 형식 — 옷은 MapLooks가 kit을 통째로 덮는다). 머리색은 모두 어두운 갈색·검정(사용자).
const BODIES := {
	"elf": {"height": REF_H * 1.02, "build": "slender", "bulk": 0.88, "female": true, "sh": 0.088, "skin": Color("#d8b496"), "mottle": Color("#b08a70"), "mottle_amt": 0.2,
		"hair": "long", "hair_c": Color("#2a1c14"), "hair_len": 0.2, "ears": "elf", "pose": {"stance": 0.06, "knee": 0.12, "arm_l": "hang", "arm_r": "ready"},
		"kit": {"pants": Color("#3a3a2e"), "shirt": Color("#5a5a44"), "sleeves": "long", "belt": Color("#2a1c14"), "boots": Color("#2e2418")}, "blood": 0.0, "grime": 0.15},
	"dwarf": {"height": REF_H * 0.8, "build": "brute", "bulk": 1.12, "sh": 0.15, "head": 1.12, "skin": Color("#c08e6c"), "mottle": Color("#946048"), "mottle_amt": 0.35,
		"legs": 0.86, "hair": "short", "map_locks": {"front": 0.3, "temple": 0.25, "side": 0.05, "n": 20}, "hair_c": Color("#2e1e14"), "beard": Color("#2e1e14"), "beard_long": {"len": 0.16, "braids": 2},
		"pose": {"stance": 0.1, "knee": 0.16, "arm_l": "hang", "arm_r": "hang"},
		"kit": {"pants": Color("#4a3e30"), "shirt": Color("#6a5a44"), "sleeves": "rolled", "belt": Color("#2e2018"), "boots": Color("#3a2a1e")}, "blood": 0.0, "grime": 0.3},
	"beastkin": {"height": REF_H * 0.98, "build": "slender", "bulk": 0.92, "female": true, "sh": 0.09, "skin": Color("#cfa282"), "mottle": Color("#a07458"), "mottle_amt": 0.25,
		"hair": "short", "hair_c": Color("#2e2016"), "ears": "fox", "ear_in": Color("#6a4a3c"), "fluff_tail": {"kind": "fox", "c": Color("#3a2618"), "tip": Color("#8a7664")},
		"pose": {"stance": 0.07, "knee": 0.14, "arm_l": "hang", "arm_r": "ready"},
		"kit": {"pants": Color("#3a3228"), "shirt": Color("#5e5040"), "sleeves": "long", "belt": Color("#2a1c14"), "boots": Color("#2e2218")}, "blood": 0.0, "grime": 0.2},
}


## 몸통에 덧붙이는 체형(Back.body 다음, 옷 전에): 여성 = 넓은 엉덩이·가슴. 옷 겹(shell)이 기록(tag)을 따라 덮는다.
static func body(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, sp: Dictionary, skin: int) -> void:
	if not sp.get("female", false):
		return
	var g: int = bd["torso"]
	var dep: float = bd["dep"]
	var pv: Vector3 = j["pelvis"]
	var ch: Vector3 = j["chest"]
	cl.tag = "pelvis"
	for s: int in [-1, 1]:  # 골반 옆을 둥글게(허리는 slender라 가늘다 → 잘록한 허리 · 뒤로 키우면 엉덩이가 너무 컸다)
		Back.ell(cl, pr, g, pv + Vector3(s * 0.068, 0.025, -0.004), 0.04, 0.062, 0.04 * dep, skin, 0.03)
	cl.tag = "torso"
	for s: int in [-1, 1]:  # 가슴(앞 — 몸 좌표 −w): 겨드랑이 높이로 올려(사용자 "너무 낮게 달려 있다")
		Back.ell(cl, pr, g, ch + Vector3(s * 0.036, -0.03, -0.046 * dep), 0.03, 0.027, 0.026, skin, 0.03)
	cl.tag = ""


## 머리 둘레 부품(BackHair 다음): 귀 · 묶은 머리 · 긴 수염.
static func head(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, hd: Dictionary, sp: Dictionary) -> void:
	var hair_c: Color = sp.get("hair_c", Color("#2a1c14"))
	match str(sp.get("ears", "")):
		"elf":
			_elf_ears(cl, pr, hd, cl.mat(sp.get("skin", Color("#d8b496")), "skin", {"mottle": (sp.get("skin", Color("#d8b496")) as Color).darkened(0.2), "mottle_amt": 0.2}))
		"fox", "cat", "wolf":
			_beast_ears(cl, pr, hd, str(sp["ears"]), cl.mat(hair_c, "hair", {"mottle": hair_c.lightened(0.15), "mottle_amt": 0.3}),
				cl.mat(sp.get("ear_in", hair_c.lightened(0.25)), "skin"))
	if sp.has("ponytail") and str(sp.get("hair", "")) != "none":
		_ponytail(cl, pr, j, bd, hd, sp["ponytail"], cl.mat(hair_c, "hair", {"mottle": hair_c.lightened(0.15), "mottle_amt": 0.3}))
	if sp.has("crest"):
		_crest(cl, pr, hd, sp["crest"])
	if sp.has("beard_long"):
		var bc: Color = (sp["beard_long"] as Dictionary).get("c", sp.get("beard", hair_c))
		_beard_long(cl, pr, j, bd, hd, sp["beard_long"], cl.mat(bc, "hair", {"mottle": bc.lightened(0.15), "mottle_amt": 0.35}))


## 털 꼬리(옷·망토 다음 — 옷 위로 나온다).
static func tail(cl: Clay, pr: Dictionary, j: Dictionary, sp: Dictionary) -> void:
	if not sp.has("fluff_tail"):
		return
	var d: Dictionary = sp["fluff_tail"]
	var col: Color = d.get("c", Color("#3a2618"))
	var kind := str(d.get("kind", "fox"))
	var m := cl.mat(col, "fur" if kind != "cat" else "hair", {"mottle": col.lightened(0.12), "mottle_amt": 0.35})
	var g := cl.group()
	var pv: Vector3 = j["pelvis"]
	var p0 := pv + Vector3(0, 0.03, 0.07)
	var pts: Array
	var rad: Array
	match kind:
		"cat":  # 가늘고 길게 — 아래로 내려갔다가 끝이 올라간다
			pts = [p0, p0 + Vector3(0.02, 0.1, 0.07), p0 + Vector3(0.06, 0.22, 0.1), p0 + Vector3(0.1, 0.24, 0.12), p0 + Vector3(0.12, 0.16, 0.12)]
			rad = [0.02, 0.021, 0.02, 0.019, 0.015]
		"wolf":  # 굵게, 뒤로 처져 오금 높이까지
			pts = [p0, p0 + Vector3(0.02, 0.08, 0.08), p0 + Vector3(0.05, 0.2, 0.11), p0 + Vector3(0.07, 0.3, 0.1)]
			rad = [0.022, 0.048, 0.05, 0.02]
		_:  # 여우: 굵고 끝이 밝게, 바깥으로 살짝 휘어 무릎 높이까지
			pts = [p0, p0 + Vector3(0.03, 0.08, 0.09), p0 + Vector3(0.08, 0.2, 0.12), p0 + Vector3(0.12, 0.29, 0.1)]
			rad = [0.022, 0.056, 0.062, 0.03]
	Back.chain(cl, pr, g, pts, rad, m, 0.014)
	if d.has("tip"):  # 꼬리 끝(밝은 털)
		var tc: Color = d["tip"]
		var tm := cl.mat(tc, "fur" if kind != "cat" else "hair", {"mottle": tc.darkened(0.15), "mottle_amt": 0.3})
		var a: Vector3 = pts[pts.size() - 2]
		var b: Vector3 = pts[pts.size() - 1]
		Back.cap(cl, pr, g, a.lerp(b, 0.55), b + (b - a).normalized() * 0.012, float(rad[rad.size() - 2]) * 0.8, float(rad[rad.size() - 1]) * 1.05, tm, 0.01)


## 엘프 귀: 머리 옆에서 뒤·위로 솟은 길고 뾰족한 귀(머리카락 위로 끝이 나온다).
static func _elf_ears(cl: Clay, pr: Dictionary, hd: Dictionary, m: int) -> void:
	var g: int = hd["g"]
	var c: Vector3 = hd["c"]
	var hh: float = hd["hh"]
	cl.tag = "ear"
	for s: int in [-1, 1]:
		var e0 := c + Vector3(s * float(hd["ru"]) * 0.96, float(hd["rv"]) * 0.08, float(hd["rw"]) * 0.04)
		Back.chain(cl, pr, g, [e0, e0 + Vector3(s * hh * 0.16, -hh * 0.16, hh * 0.08), e0 + Vector3(s * hh * 0.3, -hh * 0.36, hh * 0.14)], [hh * 0.075, hh * 0.055, hh * 0.006], m, 0.008)
	cl.tag = ""


## 짐승 귀: 정수리 양옆에서 위로 선 세모 귀(바깥 털 · 안쪽 살 — 앞에서 보인다). fox = 크고 뾰족, cat = 작고 넓게, wolf = 중간·조금 바깥으로.
static func _beast_ears(cl: Clay, pr: Dictionary, hd: Dictionary, kind: String, m: int, inner: int) -> void:
	var g := cl.group()
	var hh: float = hd["hh"]
	var size: Array = ({"fox": [0.5, 0.16, 0.12], "cat": [0.34, 0.16, 0.08], "wolf": [0.42, 0.14, 0.18]} as Dictionary)[kind]
	var tall := hh * float(size[0])
	var base := hh * float(size[1])
	for s: int in [-1, 1]:
		var b := Back.on_head(hd, 0.9, s * 1.95, -hh * 0.02)
		var up := Vector3(s * float(size[2]), -1.0, 0.08).normalized()
		var tip := b + up * tall
		Back.chain(cl, pr, g, [b, b.lerp(tip, 0.55), tip], [base, base * 0.55, hh * 0.008], m, 0.006)
		if Back.facing(pr, Vector3(s * 0.3, 0, -1)) > 0.1:  # 안쪽(얼굴 쪽 면)
			var f := Vector3(0, 0, -base * 0.45)
			Back.chain(cl, pr, g, [b.lerp(tip, 0.12) + f, b.lerp(tip, 0.6) + f * 0.8, b.lerp(tip, 0.9) + f * 0.5], [base * 0.55, base * 0.3, hh * 0.006], inner, 0.004)


## 묶은 머리: 뒤통수 위에서 묶어 등으로 늘어뜨린 한 다발(끈 + 끝이 가는 타래).
static func _ponytail(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, hd: Dictionary, d: Dictionary, m: int) -> void:
	var g := cl.group()
	var hh: float = hd["hh"]
	var nk: Vector3 = j["neck"]
	var bw: float = bd["back_w"]
	var a := Back.on_head(hd, float(d.get("high", 0.55)), 0.0, hh * 0.02)
	var ln := float(d.get("len", 0.18))
	var pts: Array = [a, a + Vector3(0, hh * 0.18, hh * 0.16), Vector3(nk.x, nk.y + ln * 0.45, bw + 0.03), Vector3(nk.x + 0.006, nk.y + ln, bw + 0.02)]
	Back.chain(cl, pr, g, pts, [hh * 0.12, hh * 0.13, hh * 0.1, hh * 0.02], m, 0.006)
	var mid: Vector3 = (pts[1] as Vector3).lerp(pts[2], 0.5)
	Back.groove(cl, pr, g, [pts[1], mid, pts[3]], Vector3(0, 0, 1), 0.004, 0.006)
	Back.ell(cl, pr, g, a + Vector3(0, hh * 0.06, hh * 0.06), hh * 0.09, hh * 0.06, hh * 0.08, cl.mat(Color("#3a2418"), "leather"), 0.004)  # 끈


## 긴 수염: 턱에서 가슴까지 내려오는 넓은 덩어리 + 땋은 가닥(끝에 쇠고리).
static func _beard_long(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, hd: Dictionary, d: Dictionary, m: int) -> void:
	var g := cl.group()
	var c: Vector3 = hd["c"]
	var ru: float = hd["ru"]
	var rv: float = hd["rv"]
	var rw: float = hd["rw"]
	var ch: Vector3 = j["chest"]
	var dep: float = bd["dep"]
	var ln := float(d.get("len", 0.16))
	var chin := c + Vector3(0, rv * 0.95, -rw * 0.7)
	var front_z := ch.z - 0.07 * dep - 0.012  # 가슴 앞 표면 밖
	front_z = lerpf(chin.z, front_z, 0.5)  # 탐험 맵 큰 머리는 턱이 가슴보다 훨씬 앞이다 — 수염이 앞으로 자루처럼 튀어나오지 않게 가운데로
	var low := Vector3(ch.x, chin.y + ln, front_z)
	Back.chain(cl, pr, g, [chin, chin.lerp(low, 0.5) + Vector3(0, 0, -0.004), low], [ru * 0.74, ru * 0.66, ru * 0.3], m, 0.012)
	for s: int in [-1, 1]:  # 양옆으로 퍼지는 수염
		Back.chain(cl, pr, g, [c + Vector3(s * ru * 0.7, rv * 0.6, -rw * 0.45), Vector3(ch.x + s * ru * 0.4, chin.y + ln * 0.5, front_z + 0.006)], [ru * 0.32, ru * 0.22], m, 0.01)
	for k in 7:  # 결
		var u := lerpf(-ru * 0.6, ru * 0.6, k / 6.0)
		Back.groove(cl, pr, g, [chin + Vector3(u, 0, -0.004), Vector3(ch.x + u * 0.6, chin.y + ln * 0.85, front_z - 0.004)], Vector3(0, 0, -1), 0.003, 0.005)
	var ring := cl.mat(Color("#8a8070"), "metal")
	var nb := int(d.get("braids", 0))
	for i in nb:
		var u := 0.0 if nb == 1 else lerpf(-ru * 0.4, ru * 0.4, i / float(nb - 1))
		var top := Vector3(ch.x + u, chin.y + ln * 0.7, front_z - 0.004)
		var end := top + Vector3(u * 0.1, ln * 0.55, -0.004)
		for t in 5:
			var q := top.lerp(end, t / 4.0)
			Back.ell(cl, pr, g, q + Vector3(0.003 * (1 if t % 2 == 0 else -1), 0, 0), ru * 0.13, ru * 0.12, ru * 0.12, m, 0.004)
		Back.ell(cl, pr, g, end + Vector3(0, ru * 0.12, 0), ru * 0.16, ru * 0.1, ru * 0.16, ring, 0.003)


## 머리 다발: 정수리(투구 꼭대기)에서 묶어 위로 솟았다가 뒤로 넘어가며 퍼지는 굵은 타래들 + 묶은 쇠고리.
static func _crest(cl: Clay, pr: Dictionary, hd: Dictionary, d: Dictionary) -> void:
	var col: Color = d.get("c", Color("#4a2a1c"))
	var m := cl.mat(col, "hair", {"mottle": col.lightened(0.18), "mottle_amt": 0.4})
	var ml := cl.mat(col.lightened(0.15), "hair", {"mottle": col.lightened(0.3), "mottle_amt": 0.3})
	var g := cl.group()
	var hh: float = hd["hh"]
	var ln := hh * float(d.get("len", 1.4))
	var root := Back.on_head(hd, 1.45, 0.0, hh * 0.12)
	Back.ell(cl, pr, g, root, hh * 0.13, hh * 0.1, hh * 0.13, cl.mat(Color("#6a6e72"), "metal"), 0.003)  # 묶은 쇠고리
	# 말꼬리처럼 한 다발: 조금 솟았다가 뒤통수 너머로 넘어가 어깨까지 흘러내린다(타래를 부채처럼 펴면 뒤에서 네모 상자, 곧게 세우면 빗자루처럼 보였다)
	var pts: Array = [root, root + Vector3(0, -ln * 0.14, ln * 0.18), root + Vector3(0, ln * 0.2, ln * 0.5), root + Vector3(0, ln * 0.62, ln * 0.55)]
	Back.chain(cl, pr, g, pts, [hh * 0.14, hh * 0.2, hh * 0.17, hh * 0.05], m, hh * 0.03)
	for k in 9:  # 겉 타래(결 · 끝이 흩어짐)
		var f := lerpf(-1.0, 1.0, k / 8.0)
		var off := Vector3(f * hh * 0.13, 0, absf(f) * hh * -0.02)
		var tip := (pts[3] as Vector3) + Vector3(f * hh * 0.22, ln * (0.04 + 0.08 * absf(sin(k * 1.7))), 0)
		Back.chain(cl, pr, g, [(pts[1] as Vector3) + off * 0.8, (pts[2] as Vector3) + off, tip], [hh * 0.06, hh * 0.06, hh * 0.012], ml if k % 3 == 0 else m, hh * 0.015)
		Back.groove(cl, pr, g, [(pts[1] as Vector3) + off, (pts[2] as Vector3) + off, tip], Vector3(0, -0.3, 1), 0.003, 0.005)
