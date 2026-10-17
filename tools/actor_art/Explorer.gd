extends RefCounted
## 탐험가 맵 몸 그림 한 장(피어 앤 헝거 맵 그림 — 사용자 2026-10-17 첨부): 곧게 선 약 3.3등신, 큰 머리카락, 눈 점만 있는 얼굴(입 없음),
## 붙어 선 두 다리, 몸 옆에 붙인 팔, 진한 바깥선과 4단 명암. 옷 색·구성은 전투 그림 설계(Party.spec_of)를 그대로 읽는다.
## 설계 좌표: 키 84(0 = 머리 꼭대기, 84 = 발바닥) × 가로(가운데 0). dir: down(앞) · up(뒤) · left(왼쪽을 본 옆모습).
## phase: 걸음(+1 = 화면 왼쪽 다리/앞다리가 나감, 0 = 섬, -1 = 반대).

const Pix := preload("res://tools/actor_art/Pix.gd")
const Party := preload("res://tools/monster_art/Party.gd")

const EYE := Color("#1a0f10")
const SIDE_STEP := 0.26  ## 옆모습 걸음 다리 각도(라디안)
const LEG := 29.0        ## 엉덩이 → 발목 길이

var px: Pix
var cx: float
var foot: float
var su: float = 1.0
var sv: float = 1.0
var bob: float = 0.0
var k: Dictionary = {}


## race의 한 장: cell 크기 그림, 발바닥 = 아래에서 foot_px 위.
func paint(race: String, dir: String, phase: float, cell: Vector2i, foot_px: int) -> Image:
	px = Pix.new(cell.x, cell.y)
	cx = cell.x * 0.5
	foot = cell.y - foot_px
	k = _look(race)
	sv = float(k["tall"])
	su = sv * float(k["broad"])
	match dir:
		"up":
			_back(phase)
		"left":
			_side(phase)
		_:
			_front(phase)
	return px.image()


## 전투 그림 설계에서 색을 읽어 맵 그림 설정으로.
func _look(race: String) -> Dictionary:
	var sp := Party.spec_of(race + "_back")
	var kit: Dictionary = sp.get("kit", {})
	var brute := str(sp.get("build", "")) == "brute"
	return {
		"skin": sp.get("skin", Color("#c49a78")), "hair": sp.get("hair_c", Color("#3a2a1e")), "long": str(sp.get("hair", "")) == "long",
		"braids": int(sp.get("braids", 0)), "beard": sp.get("beard", null), "top": kit.get("shirt", null), "sleeves": kit.has("shirt"),
		"vest": kit.get("vest", null), "mantle": kit.get("mantle", null), "pelt": kit.get("pelt", null), "belt": kit.get("belt", Color("#2e2018")),
		"pouch": kit.get("pouch", false), "knife": kit.get("knife", false), "pants": kit.get("pants", Color("#4a4236")), "wraps": kit.get("leg_wraps", null),
		"boots": kit.get("boots", Color("#3a2a1e")), "boots_fur": kit.get("boots_fur", null), "bracers": kit.get("bracers", null), "band": kit.get("armband", null),
		"tall": 1.08 if brute else 1.0, "broad": 1.14 if brute else 1.0, "arm_r": 4.2 if brute else 3.5,
	}


## 설계 좌표 → 그림 좌표. ground = 걸음 들썩임을 받지 않는다(땅에 닿은 발).
func V(dx: float, y: float, ground: bool = false) -> Vector2:
	return Vector2(cx + dx * su, foot - (84.0 - y) * sv + (0.0 if ground else bob))


func E(dx: float, y: float, rx: float, ry: float, col: Color, opt: Dictionary = {}) -> void:
	px.ell(V(dx, y), Vector2(rx * su, ry * sv), col, opt)


func C(a: Vector2, b: Vector2, ra: float, rb: float, col: Color, opt: Dictionary = {}) -> void:
	var s := (su + sv) * 0.5
	px.cap(a, b, ra * s, rb * s, col, opt)


func _skin_or(key: String) -> Color:
	return k[key] if k[key] != null else k["skin"]


# ── 앞모습 ─────────────────────────────────────────────

func _front(p: float) -> void:
	bob = absf(p)
	if k["long"]:
		C(V(0, 14), V(0, 38), 11.0, 8.0, k["hair"], {"tex": "hair", "dim": true})  # 어깨 뒤로 넘긴 긴 머리
	for s: int in [-1, 1]:
		_leg_front(s, 3.0 if (p > 0 and s < 0) or (p < 0 and s > 0) else 0.0)
	E(0, 53, 10.2, 5.6, k["pants"])
	_torso_front(false)
	for s: int in [-1, 1]:
		_arm_front(s, signf(p) * s)
	_shoulders(false)
	_head_front()


func _back(p: float) -> void:
	bob = absf(p)
	for s: int in [-1, 1]:
		_leg_front(s, 3.0 if (p > 0 and s < 0) or (p < 0 and s > 0) else 0.0)
	E(0, 53, 10.2, 5.6, k["pants"])
	_torso_front(true)
	for s: int in [-1, 1]:
		_arm_front(s, signf(p) * s)
	_shoulders(true)
	E(0, 12.5, 11.4, 12.4, k["hair"], {"tex": "hair"})
	E(0, 20.0, 8.4, 5.0, k["hair"], {"tex": "hair"})  # 목덜미
	if k["long"]:
		C(V(0, 15), V(0, 42), 9.6, 5.6, k["hair"], {"tex": "hair"})
		for s: int in [-1, 1]:  # 땋은 머리
			C(V(s * 6.5, 20), V(s * 7.0, 39), 2.0, 1.4, k["hair"], {"tex": "hair", "dim": true})


## 다리(앞·뒤 모습): 붙어 선 두 다리, lift = 내딛느라 든 발.
func _leg_front(s: int, lift: float) -> void:
	var x := s * 4.9
	var dim := {"dim": true} if s > 0 else {}
	C(V(x, 51), V(x, 78 - lift, true), 4.6, 4.0, k["pants"], dim)
	if k["wraps"] != null:
		C(V(x, 63, true) - Vector2(0, lift * 0.5), V(x, 75 - lift, true), 4.25, 3.95, k["wraps"], dim.merged({"tex": "wrap"}))
	C(V(x, 73 - lift, true), V(x, 80 - lift, true), 4.3, 4.3, k["boots"], dim)
	if k["boots_fur"] != null:
		px.ell(V(x, 72.6 - lift, true), Vector2(5.0 * su, 1.9 * sv), k["boots_fur"], {"tex": "fur"})
	px.ell(V(x + s * 0.4, 81.6 - lift, true), Vector2(4.8 * su, 2.5 * sv), k["boots"], dim)


func _torso_front(back: bool) -> void:
	var top: Color = _skin_or("top")
	E(0, 37, 10.8, 10.0, top)
	E(0, 46, 9.4, 7.0, top)
	if k["vest"] != null:
		if back:
			E(0, 41, 10.4, 10.0, k["vest"])
		else:
			for s: int in [-1, 1]:
				E(s * 6.4, 41, 5.0, 9.6, k["vest"])
	px.rect(V(-10.0, 49.6), V(10.0, 52.6), k["belt"])
	px.dots([Vector2i(V(0, 50.2))], k["belt"].lightened(0.45))
	if k["pouch"]:
		E(-7.6 if back else 7.6, 53.8, 2.8, 3.0, k["belt"].lightened(0.15))
	if k["knife"] and not back:
		C(V(-8.0, 50.5), V(-8.6, 56.5), 1.1, 1.0, Color("#2a201a"))


## 팔(앞·뒤 모습). fwd = +1 앞으로 흔든 팔(손이 내려오고 안쪽으로), -1 뒤로(손이 올라간다).
func _arm_front(s: int, fwd: float) -> void:
	var sh := V(s * 12.2, 31)
	var el := V(s * 12.8, 41 + fwd * 0.4)
	var wr := V(s * 12.8 - s * fwd * 0.6, 50.5 + fwd * 1.5)
	var dim := {"dim": true} if s > 0 else {}
	var r: float = k["arm_r"]
	C(sh, el, r, r * 0.88, k["top"] if k["sleeves"] else k["skin"], dim)
	C(el, wr, 3.0, 2.6, k["skin"], dim)
	if k["band"] != null:
		C(sh.lerp(el, 0.45), sh.lerp(el, 0.62), r + 0.3, r + 0.2, k["band"], dim)
	if k["bracers"] != null:
		C(el.lerp(wr, 0.5), wr, 3.15, 2.9, k["bracers"], dim)
	px.ell(wr + Vector2(0, 2.4 * sv), Vector2(2.5 * su, 2.8 * sv), k["skin"], dim)


## 어깨 망토(두건 달린 짧은 망토) 또는 털 어깨 망토.
func _shoulders(back: bool) -> void:
	if k["mantle"] != null:
		var m: Color = k["mantle"]
		if back:
			E(0, 30, 14.2, 6.0, m)
			E(0, 27.6, 7.0, 4.4, m, {"lift": true})  # 목 뒤로 젖힌 두건
			C(V(0, 31), V(0, 38.5), 3.8, 1.2, m)
		else:
			E(0, 27.2, 7.4, 3.4, m, {"dim": true})
			C(V(0, 23), V(0, 27.5), 3.5, 3.5, k["skin"])
			for s: int in [-1, 1]:
				E(s * 9.0, 30.2, 7.0, 5.0, m)
	elif k["pelt"] != null:
		var pc: Color = k["pelt"]
		if not back:
			C(V(0, 23), V(0, 27.5), 3.9, 3.9, k["skin"])
		E(0, 29.8, 16.5, 7.0, pc, {"tex": "fur"})
		for i in 9:  # 털 끝자락
			E(-14.0 + i * 3.5, 35.6 + (i % 2) * 0.8, 2.2, 2.4, pc, {"tex": "fur", "noline": true})
	else:
		C(V(0, 23), V(0, 27.5), 3.5, 3.5, k["skin"])


func _head_front() -> void:
	var hair: Color = k["hair"]
	E(0, 12.5, 11.4, 12.4, hair, {"tex": "hair"})
	if k["long"]:  # 얼굴 양옆으로 흘러내린 머리(얼굴은 덮지 않는다)
		for s: int in [-1, 1]:
			C(V(s * 10.6, 12), V(s * 12.0, 28), 2.9, 2.4, hair, {"tex": "hair"})
	E(0, 15, 8.7, 9.3, k["skin"])
	if k["beard"] != null:
		E(0, 22.4, 6.8, 5.2, k["beard"], {"tex": "hair"})
		C(V(-3.4, 19.8), V(3.4, 19.8), 1.1, 1.1, k["beard"], {"noline": true})
	if k["long"]:  # 가르마를 탄 긴 머리: 이마를 덮지 않는다
		E(0, 7.0, 10.9, 5.2, hair, {"tex": "hair"})
	else:
		E(0, 8.2, 10.9, 6.2, hair, {"tex": "hair"})
		for t: Vector3 in [Vector3(-5.6, 11.8, 3.0), Vector3(0.4, 12.4, 3.2), Vector3(5.8, 11.6, 2.8)]:  # 앞머리 끝
			E(t.x, t.y, t.z, t.z, hair, {"tex": "hair", "noline": true})
	for s: int in [-1, 1]:
		E(s * 9.5, 15.2, 2.5, 5.4, hair, {"tex": "hair"})  # 옆머리
	for s: int in [-1, 1]:
		_eye(V(s * 3.6, 16.0), 2)
	px.dots([Vector2i(V(0, 19.2))], Pix.ramp(k["skin"], 1))  # 코 그늘 한 점


func _eye(at: Vector2, wide: int) -> void:
	var p := Vector2i(at.floor())
	var pts: Array = []
	for yy in 2:
		for xx in wide:
			pts.append(p + Vector2i(xx - wide / 2, yy))
	px.dots(pts, EYE)


# ── 옆모습(왼쪽을 본다 — 오른쪽은 좌우 반전) ────────────────

func _side(p: float) -> void:
	var a := SIDE_STEP * p
	bob = LEG * (1.0 - cos(a))
	_arm_side(1.4, a * 0.85, true)
	_leg_side(-a, true)
	if k["long"]:
		C(V(4.0, 14), V(6.0, 38), 7.0, 4.6, k["hair"], {"tex": "hair", "dim": true})
	var top: Color = _skin_or("top")
	E(0.4, 37, 7.4, 10.0, top)
	E(0.8, 46, 6.9, 7.0, top)
	if k["vest"] != null:
		E(1.8, 41, 6.4, 10.2, k["vest"])
	px.rect(V(-6.8, 49.6), V(8.0, 52.6), k["belt"])
	if k["pouch"]:
		E(6.6, 53.6, 2.8, 3.0, k["belt"].lightened(0.15))
	E(0.8, 53, 7.4, 5.6, k["pants"])
	_leg_side(a, false)
	if k["long"]:
		C(V(5.0, 16), V(6.4, 40), 5.4, 3.6, k["hair"], {"tex": "hair"})
	if k["mantle"] != null:
		E(1.4, 29.8, 9.4, 5.6, k["mantle"])
		E(6.2, 27.2, 4.4, 4.4, k["mantle"], {"lift": true})
		C(V(7.2, 29), V(8.0, 36.5), 3.0, 1.2, k["mantle"])
	elif k["pelt"] != null:
		E(1.0, 29.8, 11.0, 7.0, k["pelt"], {"tex": "fur"})
		for i in 6:
			E(-8.0 + i * 3.4, 35.6 + (i % 2) * 0.8, 2.2, 2.4, k["pelt"], {"tex": "fur", "noline": true})
	_arm_side(-0.4, -a * 0.85, false)
	C(V(-1.0, 23), V(0.2, 27.5), 3.3, 3.3, k["skin"])
	_head_side()


## 옆모습 다리: 엉덩이에서 각도 ang(+ = 앞(왼쪽)으로)만큼 뻗은 곧은 다리, 발끝은 앞으로.
func _leg_side(ang: float, far: bool) -> void:
	var hip := V(0.6, 52)
	var ank := hip + Vector2(-sin(ang) * su, cos(ang) * sv) * LEG
	var opt := {"dim": true} if far else {}
	C(hip, ank, 4.7, 4.0, k["pants"], opt)
	if k["wraps"] != null:
		C(hip.lerp(ank, 0.42), hip.lerp(ank, 0.86), 4.3, 3.95, k["wraps"], opt.merged({"tex": "wrap"}))
	C(hip.lerp(ank, 0.74), ank, 4.3, 4.3, k["boots"], opt)
	if k["boots_fur"] != null:
		px.ell(hip.lerp(ank, 0.72), Vector2(5.0 * su, 1.9 * sv), k["boots_fur"], {"tex": "fur"})
	px.ell(ank + Vector2(-2.3 * su, 1.7 * sv), Vector2(5.4 * su, 2.4 * sv), k["boots"], opt)


func _arm_side(dx: float, ang: float, far: bool) -> void:
	var sh := V(dx, 31)
	var el := sh + Vector2(-sin(ang) * su, cos(ang) * sv) * 10.0
	var wr := el + Vector2(-sin(ang * 1.3) * su, cos(ang * 1.3) * sv) * 9.5
	var opt := {"dim": true} if far else {}
	var r: float = k["arm_r"]
	C(sh, el, r, r * 0.88, k["top"] if k["sleeves"] else k["skin"], opt)
	C(el, wr, 3.0, 2.6, k["skin"], opt)
	if k["band"] != null:
		C(sh.lerp(el, 0.45), sh.lerp(el, 0.62), r + 0.3, r + 0.2, k["band"], opt)
	if k["bracers"] != null:
		C(el.lerp(wr, 0.5), wr, 3.15, 2.9, k["bracers"], opt)
	px.ell(wr + (wr - el).normalized() * 2.4 * sv, Vector2(2.5 * su, 2.7 * sv), k["skin"], opt)


func _head_side() -> void:
	var hair: Color = k["hair"]
	E(1.8, 12.5, 10.8, 12.4, hair, {"tex": "hair"})
	E(5.0, 19.0, 6.0, 6.0, hair, {"tex": "hair"})  # 뒤통수·목덜미
	E(-3.4, 15.2, 7.0, 9.0, k["skin"])
	E(-10.0, 16.8, 1.4, 1.6, k["skin"], {"noline": true})  # 코
	if k["beard"] != null:
		E(-4.2, 21.2, 5.6, 6.0, k["beard"], {"tex": "hair"})
	E(2.4, 16.0, 1.8, 2.6, k["skin"])  # 귀
	if k["long"]:
		E(-0.4, 7.0, 10.2, 5.0, hair, {"tex": "hair"})
	else:
		E(-1.4, 8.2, 10.2, 6.0, hair, {"tex": "hair"})
		E(-8.0, 11.6, 2.5, 3.4, hair, {"tex": "hair", "noline": true})
	E(4.6, 13.0, 4.0, 4.6, hair, {"tex": "hair", "noline": true})  # 귀 위 옆머리
	_eye(V(-7.2, 16.0), 1)
