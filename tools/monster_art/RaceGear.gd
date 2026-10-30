extends RefCounted
## 새 종족 후보 소품 2(사용자 2026-10-30 참고 그림 세 장 — 엘프 궁수·드워프 도끼 전사·도적 "이 사진들 복장으로"). RaceKit.wear가 부른다. kit 키:
##   hip_belts {c, n} 엉덩이에 비스듬히 걸친 가죽 띠(n = 1~2, 엇갈려) · sheath {c, hilt} 왼허리에서 뒤로 비스듬한 긴 칼집 + 손잡이
##   pendant(색) 가슴 앞 목걸이 메달 · back_axe {c, wood} 등에 비스듬히 멘 양날 도끼(머리는 오른어깨 위)
##   rope(색) 오른허리에 건 감은 밧줄

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")
const BackKit := preload("res://tools/monster_art/BackKit.gd")
const BackSavage := preload("res://tools/monster_art/BackSavage.gd")


static func wear(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, kit: Dictionary) -> void:
	if kit.has("hip_belts"):
		_hip_belts(cl, pr, j, kit["hip_belts"])
	if kit.has("sheath"):
		_sheath(cl, pr, j, kit["sheath"])
	if kit.has("rope"):
		_rope(cl, pr, j, kit["rope"])
	if kit.has("pendant"):
		_pendant(cl, pr, j, bd, kit["pendant"])
	if kit.has("back_axe"):
		_back_axe(cl, pr, j, bd, kit["back_axe"])


## 엉덩이 띠: 허리에서 반대쪽 엉덩이로 비스듬히(둘이면 서로 엇갈려 X 아래쪽처럼) + 작은 쇠 고리.
static func _hip_belts(cl: Clay, pr: Dictionary, j: Dictionary, d: Dictionary) -> void:
	var col: Color = d["c"]
	var m := cl.mat(col, "leather", {"mottle": col.darkened(0.3), "mottle_amt": 0.3})
	var pv: Vector3 = j["pelvis"]
	var slope := 0.28 * absf(cos(float(pr["turn"]))) + 0.08
	var n := int(d.get("n", 2))
	for i in n:
		var s := 1.0 if i % 2 == 0 else -1.0
		var c := Vector3(pv.x, pv.y - 0.03 + i * 0.03, pv.z)
		BackKit.shell(cl, pr, ["pelvis", "torso", "thigh_l", "thigh_r"], 0.018 + i * 0.006, m, cl.group(), BackSavage._slant(cl, pr, c, s * slope, 0.026))


## 긴 칼집: 왼허리 띠에서 뒤·아래로(옆·뒤에서 보인다) + 위로 솟은 손잡이와 가로막이.
static func _sheath(cl: Clay, pr: Dictionary, j: Dictionary, d: Dictionary) -> void:
	var m := cl.mat(d.get("c", Color("#2a2420")), "leather")
	var metal := cl.mat(d.get("hilt", Color("#8a8478")), "metal")
	var g := cl.group()
	var pv: Vector3 = j["pelvis"]
	var top := Vector3(pv.x - 0.115, pv.y - 0.04, pv.z + 0.01)
	var bot := Vector3(pv.x - 0.17, pv.y + 0.34, pv.z + 0.13)
	Back.cap(cl, pr, g, top, bot, 0.016, 0.011, m, 0.003)
	Back.ell(cl, pr, g, bot, 0.012, 0.014, 0.012, metal, 0.002)  # 칼집 끝 쇠
	var up := (top - bot).normalized()
	Back.cap(cl, pr, g, top + Vector3(-0.025, 0, 0), top + Vector3(0.025, 0, 0), 0.007, 0.007, metal, 0.002)  # 가로막이
	Back.cap(cl, pr, g, top, top + up * 0.08, 0.009, 0.008, cl.mat(Color("#3a2a20"), "leather"), 0.002)  # 손잡이
	Back.ell(cl, pr, g, top + up * 0.085, 0.011, 0.011, 0.011, metal, 0.002)


## 밧줄: 오른허리에 건 둥근 고리 두세 바퀴.
static func _rope(cl: Clay, pr: Dictionary, j: Dictionary, col: Color) -> void:
	var m := cl.mat(col, "cloth", {"mottle": col.darkened(0.3), "mottle_amt": 0.5})
	var g := cl.group()
	var pv: Vector3 = j["pelvis"]
	for k in 3:
		var c := Vector3(pv.x + 0.125, pv.y + 0.06 + k * 0.006, pv.z + 0.02 + k * 0.004)
		var pts: Array = []
		var rad: Array = []
		for i in 15:
			var a := i / 14.0 * TAU
			pts.append(c + Vector3(sin(a) * 0.012, -cos(a) * 0.05, cos(a) * 0.035))
			rad.append(0.007)
		Back.chain(cl, pr, g, pts, rad, m, 0.002)


## 목걸이 메달: 목에서 가슴 앞으로 내려온 가는 줄 + 둥근 메달.
static func _pendant(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, col: Color) -> void:
	var m := cl.mat(col, "metal")
	var g := cl.group()
	var nk: Vector3 = j["neck"]
	var fw := (j["chest"] as Vector3).z - 0.066 * float(bd["dep"]) - 0.014
	var low := Vector3(nk.x, nk.y + 0.085, fw)
	for s: float in [-1.0, 1.0]:
		Back.cap(cl, pr, g, Vector3(nk.x + s * 0.035, nk.y + 0.02, fw + 0.03), low, 0.003, 0.003, m, 0.001)
	Back.bump(cl, pr, g, low + Vector3(0, 0.01, 0), Vector3(0, 0, -1), 0.016, 0.018, 0.008, m)


## 등 도끼: 오른어깨 위로 솟은 양날 머리(날 면이 등과 나란해 뒤에서 넓게 보인다) → 왼허리 뒤로 내려간 자루.
static func _back_axe(cl: Clay, pr: Dictionary, j: Dictionary, bd: Dictionary, d: Dictionary) -> void:
	var metal := cl.mat(d.get("c", Color("#3a3e42")), "metal")
	var wood := cl.mat(d.get("wood", Color("#3a2a1e")), "wood")
	var g := cl.group()
	var ch: Vector3 = j["chest"]
	var wa: Vector3 = j["waist"]
	var bw: float = bd["back_w"]
	var bk := float(bd["bulk"])
	var top := Vector3(ch.x + 0.15 * bk, ch.y - 0.25, bw + 0.06)
	var bot := Vector3(wa.x - 0.13 * bk, wa.y + 0.16, bw + 0.05)
	Back.cap(cl, pr, g, top + (top - bot).normalized() * 0.03, bot, 0.013, 0.013, wood, 0.002)
	for k in 3:  # 자루 감은 가죽
		var q := top.lerp(bot, 0.55 + k * 0.08)
		Back.cap(cl, pr, g, q, q + (bot - top).normalized() * 0.02, 0.016, 0.016, cl.mat(Color("#2a1c12"), "leather"), 0.001)
	var dir := (top - bot).normalized()
	var perp := Vector3(dir.y, -dir.x, 0.0).normalized()  # 등과 나란한 면에서 자루에 수직
	var dp := Back.P2(pr, top) - Back.P2(pr, bot)
	var rot := atan2(-dp.x, dp.y)
	var edge := cl.mat((d.get("c", Color("#3a3e42")) as Color).lightened(0.25), "metal")
	for s: float in [-1.0, 1.0]:  # 양날: 자루 쪽은 좁고 바깥 날이 넓게 퍼진 부채꼴(둥근 판 하나면 귀처럼 보였다)
		var neck := top + perp * s * 0.03
		var c := top + perp * s * 0.075
		Back.cap(cl, pr, g, top, neck, 0.024, 0.024, metal, 0.003)
		Back.ell(cl, pr, g, c, 0.04, 0.075, 0.01, metal, 0.004, rot)
		for e: float in [-1.0, 1.0]:  # 날 끝 두 뿔(위·아래로 휜 끝)
			Back.cap(cl, pr, g, c + dir * e * 0.04, c + perp * s * 0.045 + dir * e * 0.11, 0.022, 0.006, metal, 0.003)
		Back.cap(cl, pr, g, c + perp * s * 0.04 + dir * 0.09, c + perp * s * 0.04 - dir * 0.09, 0.008, 0.008, edge, 0.002)  # 벼린 날
	Back.ell(cl, pr, g, top, 0.024, 0.03, 0.022, metal, 0.003)  # 가운데 쇠통
