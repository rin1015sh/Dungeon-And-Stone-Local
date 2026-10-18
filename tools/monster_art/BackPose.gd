extends RefCounted
## 3D 몸(Back)의 쉬는 자세 — 보스·중간보스가 방 가운데서 플레이어를 기다리는 모습(탐험 맵, tools/monster_art/MapMonster.gd BOSSES).
## rest: throne(돌 의자에 앉아 팔걸이에 손) · seat(바위에 걸터앉아 무릎에 팔) · floor(바닥에 주저앉음 — legs_out 다리를 뻗음, 아니면 책상다리)
##       · kneel(한쪽 무릎을 꿇고 칼을 땅에 짚음) · squat(웅크려 주먹으로 바닥을 짚음) · stand(선 채 — plant면 두 손으로 칼을 땅에 짚음)
## 뼈대는 Back.skeleton(+ _chunky) 뒤에 바꾼다. 몸 좌표: y 아래 +(땅 ≈ 0), -z = 얼굴 쪽.

const Clay := preload("res://tools/monster_art/Clay.gd")
const Back := preload("res://tools/monster_art/Back.gd")

const UPPER := ["pelvis", "waist", "chest", "neck", "head", "shoulder_l", "shoulder_r", "elbow_l", "elbow_r", "wrist_l", "wrist_r", "hand_l", "hand_r", "hip_l", "hip_r"]
const GROUND := -0.045  ## 발목 높이


static func apply(j: Dictionary, sp: Dictionary) -> Dictionary:
	var out := j.duplicate()
	var rest := str(sp.get("rest", "stand"))
	var L1 := ((j["hip_l"] as Vector3) - (j["knee_l"] as Vector3)).length()
	var L2 := ((j["knee_l"] as Vector3) - (j["ankle_l"] as Vector3)).length()
	match rest:
		"throne", "seat":  # 허벅지는 앞으로 수평, 정강이는 땅으로
			_lower(out, GROUND - L2 - ((j["hip_l"] as Vector3).y - (j["pelvis"] as Vector3).y) - 0.01, 0.03)
			for s: int in [-1, 1]:
				var t := _t(s)
				var hp: Vector3 = out["hip_" + t]
				var kn := hp + Vector3(s * 0.035, 0.0, -L1 * 0.95)
				_leg(out, t, kn, kn + Vector3(s * 0.01, GROUND - kn.y, -0.02))
				if rest == "throne":  # 팔걸이에 팔뚝을 올림
					_arm(out, t, Vector3(s * 0.05, 0.14, 0.0), Vector3(s * 0.005, 0.0, -0.13))
				elif sp.get("free_hang", false) and t != str((sp.get("kit", {}) as Dictionary).get("weapon_hand", "r")):  # 무기 없는 팔은 옆으로 늘어뜨림
					_arm(out, t, Vector3(s * 0.04, 0.15, 0.01), Vector3(s * 0.015, 0.145, -0.02))
				else:  # 무릎 위에 팔을 걸침
					_arm(out, t, Vector3(s * 0.03, 0.12, -0.08), Vector3(-s * 0.01, 0.03, -0.13))
		"floor":
			_lower(out, -0.075, 0.02)
			for s: int in [-1, 1]:
				var t := _t(s)
				var hp: Vector3 = out["hip_" + t]
				if sp.get("legs_out", false):  # 다리를 앞으로 뻗고 무릎을 조금 세움
					var kn := hp + Vector3(s * 0.05, -0.04, -L1 * 0.95)
					_leg(out, t, kn, Vector3(s * 0.12, GROUND + 0.005, kn.z - L2 * 0.9))
					_arm(out, t, Vector3(s * 0.06, 0.15, 0.02), Vector3(s * 0.03, 0.12, -0.02))  # 늘어뜨린 팔이 바닥에 닿는다
				else:  # 책상다리: 무릎은 바깥으로, 발은 반대편 무릎 아래
					var kn := hp + Vector3(s * L1 * 0.85, 0.01, -L1 * 0.45)
					_leg(out, t, kn, Vector3(-s * 0.05, GROUND + 0.01, kn.z - 0.02))
					_arm(out, t, Vector3(s * 0.04, 0.13, -0.05), Vector3(-s * 0.06, 0.03, -0.09))  # 두 손을 무릎 사이로 모음
		"kneel":  # 왼쪽 무릎은 땅에, 오른발은 앞에 디딤
			_lower(out, GROUND - L1 - 0.02 - ((j["hip_l"] as Vector3).y - (j["pelvis"] as Vector3).y), 0.0)
			var hl: Vector3 = out["hip_l"]
			var kl := Vector3(hl.x - 0.01, GROUND - 0.01, hl.z + 0.02)
			_leg(out, "l", kl, kl + Vector3(0, -0.015, L2 * 0.9))
			var hr: Vector3 = out["hip_r"]
			var kr := hr + Vector3(0.03, -0.02, -L1 * 0.95)
			_leg(out, "r", kr, Vector3(kr.x + 0.01, GROUND, kr.z + 0.02))
			_plant(out)
		"squat":  # 엉덩이를 무릎 높이로, 무릎은 바깥·앞으로, 주먹은 무릎 사이 바닥
			_lower(out, GROUND - L2 * 0.75, 0.04)
			for s: int in [-1, 1]:
				var t := _t(s)
				var hp: Vector3 = out["hip_" + t]
				var kn := hp + Vector3(s * 0.08, -0.06, -L1 * 0.8)
				_leg(out, t, kn, Vector3(s * 0.09, GROUND, kn.z + 0.06))
			_lean(out, 0.1)
			for s: int in [-1, 1]:
				var t := _t(s)
				var sh: Vector3 = out["shoulder_" + t]
				var hand := Vector3(s * 0.07, GROUND - 0.005, sh.z - 0.16)
				out["elbow_" + t] = sh.lerp(hand, 0.5) + Vector3(s * 0.05, 0.0, 0.0)
				out["wrist_" + t] = hand + Vector3(0, -0.03, 0.01)
				out["hand_" + t] = hand
		"stand":
			if sp.get("plant", false):
				_plant(out)
	return out


static func _t(s: int) -> String:
	return "l" if s < 0 else "r"


## 위 몸을 엉덩이 높이 py로 내리고(dz = 뒤로 물림).
static func _lower(j: Dictionary, py: float, dz: float) -> void:
	var d := py - (j["pelvis"] as Vector3).y
	for k: String in UPPER:
		j[k] = (j[k] as Vector3) + Vector3(0, d, dz)


## 상체를 앞으로 숙임(가슴 위만 — 허리는 그대로).
static func _lean(j: Dictionary, a: float) -> void:
	for k: String in ["chest", "neck", "head", "shoulder_l", "shoulder_r", "elbow_l", "elbow_r", "wrist_l", "wrist_r", "hand_l", "hand_r"]:
		var v: Vector3 = j[k]
		var up := (j["waist"] as Vector3).y - v.y
		j[k] = v + Vector3(0, up * a * 0.4, -up * a * 2.2)


static func _leg(j: Dictionary, t: String, knee: Vector3, ankle: Vector3) -> void:
	j["knee_" + t] = knee
	j["ankle_" + t] = ankle
	var s := -1.0 if t == "l" else 1.0
	j["toe_" + t] = ankle + Vector3(s * 0.012, 0.03, -0.1)


## 팔: 어깨에서 팔꿈치까지(e) · 팔꿈치에서 손목까지(w).
static func _arm(j: Dictionary, t: String, e: Vector3, w: Vector3) -> void:
	var el: Vector3 = (j["shoulder_" + t] as Vector3) + e
	var wr := el + w
	j["elbow_" + t] = el
	j["wrist_" + t] = wr
	j["hand_" + t] = wr + (wr - el).normalized() * 0.035


## 두 손을 몸 앞 가운데로 모아 칼자루를 쥠(칼끝은 땅 — BackExtras가 plant면 곧게 내린다).
static func _plant(j: Dictionary) -> void:
	var ch: Vector3 = j["chest"]
	var hand := Vector3(0.0, ch.y + 0.2, ch.z - 0.15)
	for s: int in [-1, 1]:
		var t := _t(s)
		var sh: Vector3 = j["shoulder_" + t]
		j["elbow_" + t] = sh + Vector3(s * 0.05, 0.13, -0.06)
		var h := hand + Vector3(s * 0.006, -0.03 if s > 0 else 0.0, 0.0)  # 오른손이 위
		j["wrist_" + t] = h + Vector3(s * 0.015, -0.015, 0.02)
		j["hand_" + t] = h


## 앉을 자리(throne = 돌 왕좌 · seat = 바위). floor·kneel·squat·stand는 없음.
static func props(cl: Clay, pr: Dictionary, j: Dictionary, sp: Dictionary) -> void:
	var rest := str(sp.get("rest", ""))
	if rest != "throne" and rest != "seat":
		return
	var col: Color = sp.get("seat_c", Color("#5a5652"))
	var m := cl.mat(col, "stone", {"mottle": col.darkened(0.3), "mottle_amt": 0.5})
	var g := cl.group()
	var pv: Vector3 = j["pelvis"]
	var top := pv.y + 0.05  # 앉는 면
	var hw := absf((j["hip_r"] as Vector3).x) + 0.1
	if rest == "seat":  # 울퉁불퉁한 바위 하나
		Back.ell(cl, pr, g, Vector3(0, (top + GROUND) * 0.5 + 0.03, pv.z + 0.02), hw + 0.04, (GROUND - top) * 0.5 + 0.04, 0.14, m, 0.02)
		Back.ell(cl, pr, g, Vector3(-hw * 0.5, top + 0.05, pv.z + 0.08), hw * 0.6, 0.08, 0.12, m, 0.02)
		Back.ell(cl, pr, g, Vector3(hw * 0.6, top + 0.08, pv.z - 0.02), hw * 0.5, 0.07, 0.1, m, 0.02)
		return
	var back_z := pv.z + 0.12
	_box(cl, pr, g, Vector3(-hw, top, pv.z - 0.14), Vector3(hw, 0.0, back_z), m)  # 앉는 단
	var crown := (j["head"] as Vector3).y - 0.05
	_box(cl, pr, g, Vector3(-hw - 0.01, crown, back_z), Vector3(hw + 0.01, 0.0, back_z + 0.06), m)  # 등받이
	Back.ell(cl, pr, g, Vector3(0, crown, back_z + 0.03), hw * 0.75, 0.06, 0.04, m, 0.01)  # 등받이 머리 장식
	for s: float in [-1.0, 1.0]:  # 팔걸이(손목 아래)
		var wr: Vector3 = j["wrist_" + ("l" if s < 0 else "r")]
		var ay := wr.y + 0.03
		_box(cl, pr, g, Vector3(s * hw - 0.035, ay, pv.z - 0.16), Vector3(s * hw + 0.035, top, back_z), m)
		Back.ell(cl, pr, g, Vector3(s * hw, ay, pv.z - 0.16), 0.045, 0.03, 0.03, m, 0.01)  # 팔걸이 끝 둥근 머리


## 상자(몸 좌표 두 모서리): 보이는 앞면 + 윗면(내려다보는 각도).
static func _box(cl: Clay, pr: Dictionary, g: int, a: Vector3, b: Vector3, m: int) -> void:
	var H: float = pr["H"]
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	var fz := lo.z if Back.facing(pr, Vector3(0, 0, -1)) > 0.0 else hi.z  # 보는 사람 쪽 면
	var front := PackedVector2Array([Back.P2(pr, Vector3(lo.x, lo.y, fz)), Back.P2(pr, Vector3(hi.x, lo.y, fz)), Back.P2(pr, Vector3(hi.x, hi.y, fz)), Back.P2(pr, Vector3(lo.x, hi.y, fz))])
	var topf := PackedVector2Array([Back.P2(pr, Vector3(lo.x, lo.y, lo.z)), Back.P2(pr, Vector3(hi.x, lo.y, lo.z)), Back.P2(pr, Vector3(hi.x, lo.y, hi.z)), Back.P2(pr, Vector3(lo.x, lo.y, hi.z))])
	var zf := Back.P(pr, Vector3(0, 0, fz)).z
	cl.slab(g, topf, zf - 0.02 * H, 0.004 * H, m, 1.5, 0.006 * H)
	cl.slab(g, front, zf - 0.004 * H, 0.004 * H, m, 1.5, 0.006 * H)
