extends RefCounted
## 전투 아군 동작 칸(tools/paint_motions.gd): 참고 스프라이트 시트(피어 앤 헝거 아군 전투 시트 — 사용자 첨부 2026-10-28)의
## 칸마다 잰 2D 관절 위치(tools/monster_art/party_motions.json, 120px 칸 좌표)를 3D 뼈대(Back)로 옮긴다.
## 뼈 길이는 우리 몸 그대로 두고, 화면에 보이는 뼈 방향만 원본을 따른다 — 원본에서 그 뼈가 펴진 길이(REF_LEN, 원본 쉬는 칸에서 잼)보다
## 짧아 보이면 그 비율만큼 보는 사람 쪽/먼 쪽으로 기운다(어느 쪽인지는 쉰 자세에서 그 뼈가 향하던 쪽, 칸에 "d"{끝 관절: "a" 먼 쪽 | "t" 보는 사람 쪽}이 있으면 그것).
## 칸 키: turn(몸 돌림, 라디안 — 그림 돌림에 더한다) · p{H 머리 N 목 P 골반 SL/SR 어깨 EL/ER 팔꿈치 HL/HR 주먹 KL/KR 무릎 AL/AR 발목 TL/TR 발끝 W 칼끝(활 = 활대 위 끝)}
##   · ik{l|r: {hand: [x,y,z], pole: [x,y,z]}}(손을 보는 쪽 3D 자리에 — x·y는 원본 칸 px, z = 보는 사람 쪽 px · 팔꿈치는 pole 쪽으로)
##   · weapon_hand(W를 잴 손, 기본 r) · wlen(원본에서 손 → W가 펴졌을 때 길이 px — 기본 칼 46) · up·aim(무기 위·활 겨눔 방향, 보는 쪽 좌표)
##   · draw(활시위를 당긴 칸)
##   · lie(누움 — 땅 맞추기를 하지 않는다)

const REF_H := 116.0  ## 원본 칸의 사람 키(px)
const REF_GROUND := 117.0  ## 원본 칸의 땅(px)
## 원본 몸의 뼈 길이(px — 화면과 나란히 펴졌을 때): 끝 관절 키 → 길이
const REF_LEN := {"N": 33.0, "H": 10.0, "E": 21.0, "H_": 17.0, "K": 29.6, "A": 24.5, "T": 12.0, "W": 46.0}


static func pose(j0: Dictionary, fr: Dictionary, turn: float) -> Dictionary:
	var p: Dictionary = fr["p"]
	var hint: Dictionary = fr.get("d", {})
	var c := cos(turn)
	var s := sin(turn)
	var j := j0.duplicate()
	var pv := _u(p["P"])
	j["pelvis"] = Vector3(pv.x * c, pv.y, -pv.x * s)
	var spine := ((j0["neck"] as Vector3) - (j0["pelvis"] as Vector3)).length()
	j["neck"] = _bone(j, j0, "pelvis", "neck", p["P"], p["N"], spine, REF_LEN["N"], hint.get("N", ""), c, s)
	var nk: Vector3 = j["neck"]
	var pl: Vector3 = j["pelvis"]
	for k: String in ["waist", "chest"]:  # 허리·가슴은 골반 → 목 줄 위에 원래 비율로
		var f := ((j0[k] as Vector3).y - (j0["pelvis"] as Vector3).y) / ((j0["neck"] as Vector3).y - (j0["pelvis"] as Vector3).y)
		j[k] = pl.lerp(nk, f) + Vector3(0, 0, (j0[k] as Vector3).z)
	var lean := nk - pl
	var up := lean.normalized()  # 몸통 위 방향(골반 → 목)
	j["head"] = _bone(j, j0, "neck", "head", p["N"], p["H"], ((j0["head"] as Vector3) - (j0["neck"] as Vector3)).length(), REF_LEN["H"], hint.get("H", ""), c, s)
	for sd: int in [-1, 1]:
		var t := "l" if sd < 0 else "r"
		var T := t.to_upper()
		var o: Vector3 = (j0["shoulder_" + t] as Vector3) - (j0["neck"] as Vector3)  # 어깨는 몸통에 붙여(좌우 같은 폭 — 몸통 그림이 어깨 폭을 쓴다)
		j["shoulder_" + t] = nk + Vector3(o.x, 0, o.z) + up * -o.y
		var hp: Vector3 = (j0["hip_" + t] as Vector3) - (j0["pelvis"] as Vector3)
		j["hip_" + t] = pl + hp
		_limb(j, j0, "shoulder_" + t, "elbow_" + t, "hand_" + t, p, "S" + T, "E" + T, "H" + T, hint, c, s)
		var wr_len := ((j0["wrist_" + t] as Vector3) - (j0["elbow_" + t] as Vector3)).length()
		var el: Vector3 = j["elbow_" + t]
		var hd: Vector3 = j["hand_" + t]
		j["wrist_" + t] = el + (hd - el) * (wr_len / maxf(0.001, (hd - el).length()))
		_limb(j, j0, "hip_" + t, "knee_" + t, "ankle_" + t, p, "", "K" + T, "A" + T, hint, c, s)
		if p.has("T" + T):
			j["toe_" + t] = _bone(j, j0, "ankle_" + t, "toe_" + t, p["A" + T], p["T" + T], ((j0["toe_" + t] as Vector3) - (j0["ankle_" + t] as Vector3)).length(), REF_LEN["T"], hint.get("T" + T, ""), c, s)
		else:
			j["toe_" + t] = (j["ankle_" + t] as Vector3) + ((j0["toe_" + t] as Vector3) - (j0["ankle_" + t] as Vector3))
	var ik: Dictionary = fr.get("ik", {})
	for t: String in ik:  # 손을 3D 자리(보는 쪽 좌표)에 두고 팔꿈치는 pole 쪽으로 굽힌다
		var q: Dictionary = ik[t]
		_reach(j, j0, t, _cam(q["hand"], c, s, true), _cam(q.get("pole", [0, 0, 1]), c, s, false))
	var wh := str(fr.get("weapon_hand", "r"))
	if p.has("W"):  # 칼끝 방향(BackExtras 손 무기 — 활은 활대 위 끝)
		var tip := _bone(j, j0, "hand_" + wh, "hand_" + wh, p["H" + wh.to_upper()], p["W"], 0.3, float(fr.get("wlen", REF_LEN["W"])), hint.get("W", "a"), c, s)
		j["weapon_dir"] = (tip - (j["hand_" + wh] as Vector3)).normalized()
	if fr.has("up"):  # 무기 위 방향을 보는 쪽 좌표로 바로
		j["weapon_dir"] = _cam(fr["up"], c, s, false).normalized()
	if fr.has("aim"):  # 활: 화살이 날아갈 쪽(보는 쪽 좌표)
		j["aim"] = _cam(fr["aim"], c, s, false).normalized()
	if fr.get("draw", false):  # 활시위를 당긴 칸
		j["bow_draw"] = true
	if not fr.get("lie", false):  # 맨 아래 발목을 땅에
		var low := maxf((j["ankle_l"] as Vector3).y, (j["ankle_r"] as Vector3).y)
		var d := (j0["ankle_l"] as Vector3).y - low
		for k: String in j:
			if j[k] is Vector3 and k != "weapon_dir" and k != "aim":
				j[k] = (j[k] as Vector3) + Vector3(0, d, 0)
	return j


## 보는 쪽 좌표(원본 칸 px: x 0~120 · 가운데 60, y 땅 117, z = 보는 사람 쪽 px) → 몸 좌표. point면 자리, 아니면 방향.
static func _cam(v: Array, c: float, s: float, point: bool) -> Vector3:
	var X := (float(v[0]) - (60.0 if point else 0.0)) / REF_H
	var Y := (float(v[1]) - (REF_GROUND if point else 0.0)) / REF_H
	var T := float(v[2]) / REF_H
	return Vector3(X * c + T * s, Y, -X * s + T * c)


## 두 마디 팔(IK): 어깨에서 손(target — 닿지 않으면 뻗은 끝)까지, 팔꿈치는 pole 쪽으로.
static func _reach(j: Dictionary, j0: Dictionary, t: String, target: Vector3, pole: Vector3) -> void:
	var sh: Vector3 = j["shoulder_" + t]
	var l1 := ((j0["elbow_" + t] as Vector3) - (j0["shoulder_" + t] as Vector3)).length()
	var l2 := ((j0["hand_" + t] as Vector3) - (j0["elbow_" + t] as Vector3)).length()
	var v := target - sh
	var d := clampf(v.length(), 0.01, (l1 + l2) * 0.999)
	var dir := v.normalized()
	var a := (l1 * l1 + d * d - l2 * l2) / (2.0 * d)
	var h := sqrt(maxf(0.0, l1 * l1 - a * a))
	var pp := pole - dir * pole.dot(dir)
	pp = pp.normalized() if pp.length() > 0.0001 else Vector3(0, 1, 0)
	var el := sh + dir * a + pp * h
	var hd := sh + dir * d
	j["elbow_" + t] = el
	j["hand_" + t] = hd
	var wr_len := ((j0["wrist_" + t] as Vector3) - (j0["elbow_" + t] as Vector3)).length()
	j["wrist_" + t] = el + (hd - el).normalized() * wr_len


## 원본 칸 px → 키 비율(가로는 칸 가운데 기준, 세로는 땅 기준).
static func _u(v: Array) -> Vector2:
	return Vector2((float(v[0]) - 60.0) / REF_H, (float(v[1]) - REF_GROUND) / REF_H)


## 팔·다리 두 마디: a(이미 놓인 관절) → b → c. 원본 화면 점 pa(없으면 a를 그대로)·pb·pc.
static func _limb(j: Dictionary, j0: Dictionary, a: String, b: String, cc: String, p: Dictionary, pa: String, pb: String, pc: String, hint: Dictionary, c: float, s: float) -> void:
	if not p.has(pb) or not p.has(pc):
		return
	var a2: Array = p[pa] if pa != "" and p.has(pa) else _screen(j[a], c, s)
	var l1 := ((j0[b] as Vector3) - (j0[a] as Vector3)).length()
	var arm := pb.begins_with("E")
	j[b] = _bone(j, j0, a, b, a2, p[pb], l1, REF_LEN["E" if arm else "K"], hint.get(pb, ""), c, s)
	var l2 := ((j0[cc] as Vector3) - (j0[b] as Vector3)).length()
	j[cc] = _bone(j, j0, b, cc, p[pb], p[pc], l2, REF_LEN["H_" if arm else "A"], hint.get(pc, ""), c, s)


## 몸 좌표 → 원본 칸 px(어깨처럼 원본 점을 쓰지 않는 관절에서 다음 뼈를 이을 때).
static func _screen(v: Vector3, c: float, s: float) -> Array:
	return [60.0 + (v.x * c - v.z * s) * REF_H, REF_GROUND + v.y * REF_H]


## 뼈 하나: j[a]에서 길이 L로, 화면 방향은 원본 pa → pb. 원본 펴진 길이 ref(px)에 견줘 짧아 보인 비율만큼 보는 사람 쪽(+)/먼 쪽(−)으로.
static func _bone(j: Dictionary, j0: Dictionary, a: String, b: String, pa: Array, pb: Array, L: float, ref: float, hint: String, c: float, s: float) -> Vector3:
	var d := _u(pb) - _u(pa)
	var f := clampf(d.length() * REF_H / ref, 0.0, 1.0)
	d = d.normalized() * L * f if d.length() > 0.0001 else Vector2.ZERO
	var n := L * f
	var sign := 0.0
	match hint:
		"a":
			sign = -1.0
		"t":
			sign = 1.0
		_:
			var r: Vector3 = (j0[b] as Vector3) - (j0[a] as Vector3)
			sign = 1.0 if r.x * s + r.z * c >= 0.0 else -1.0
	var toward := sign * sqrt(maxf(0.0, L * L - n * n))
	return (j[a] as Vector3) + Vector3(d.x * c + toward * s, d.y, -d.x * s + toward * c)
