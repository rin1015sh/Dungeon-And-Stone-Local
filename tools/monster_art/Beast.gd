extends RefCounted
## 네발짐승(Clay, 3/4 시점 — 머리가 화면 왼쪽 앞을 향함): 몸통 캡슐 줄 + 목 + 머리(늑대·고양이·올빼미·쥐) + 다리 넷 + 꼬리 → 칠 → 털 뭉치.
## spec 키: height(캔버스 높이 px) · color · belly(배 색) · head(wolf|cat|owl|rat) · bulk(몸 굵기) · legs(다리 길이 배율)
##          fur(털 길이 0~1) · tail(bushy|thin|snake|stub) · blades(등 칼날 색) · horns(뿔 색) · stripes(줄무늬 색) · frost · eyes · glow
##          mouth(snarl|shut) · fangs(송곳니 길이)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Render := preload("res://tools/monster_art/Render.gd")
const Fur := preload("res://tools/monster_art/Fur.gd")
const Finish := preload("res://tools/monster_art/Finish.gd")
const BeastHead := preload("res://tools/monster_art/BeastHead.gd")

const FWD0 := Vector3(-0.45, 0.0, 0.89)  ## 전투 그림: 짐승 앞쪽(보는 사람 쪽 + 조금 화면 왼쪽 — 다가오는 3/4 정면)
## 그릴 때 쓰는 방향(spec "face" = 화면에서 본 앞쪽 각도 — 0 = 보는 사람 쪽, -π/2 = 화면 왼쪽, π = 뒤. 없으면 전투 그림 방향).
## spec "pitch" = 위에서 내려다보는 정도(보는 사람 쪽 깊이만큼 화면 아래로 — 탐험 맵), "walk" = 걸음(+1/-1, 대각선 다리 짝이 번갈아).
static var FWD := FWD0
static var SIDE := Vector3(0.89, 0.0, 0.45)  ## 짐승 오른쪽 = (FWD.z, 0, -FWD.x)


static func paint(sp: Dictionary, seed_value: int) -> Paint:
	var H := float(sp.get("height", 420))
	var w := int(H * float(sp.get("width", 1.2)))
	var h := int(H * float(sp.get("canvas_h", 0.8)))
	var p := Paint.new(w, h, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cl := Clay.new(w, h)
	FWD = Vector3(sin(float(sp["face"])), 0.0, cos(float(sp["face"]))) if sp.has("face") else FWD0
	SIDE = Vector3(FWD.z, 0.0, -FWD.x)
	BeastHead.aim(FWD)
	var pitch := float(sp.get("pitch", 0.0))
	var walk := float(sp.get("walk", 0.0))
	var col: Color = sp.get("color", Color("#7c7e82"))
	var kind := "fur" if float(sp.get("fur", 0.7)) > 0.45 else "skin"
	var skin := cl.mat(col, kind, {"mottle": col.darkened(0.3), "mottle_amt": 0.3})
	var belly_c: Color = sp.get("belly", col.lightened(0.18))
	var belly := cl.mat(belly_c, kind)
	var bulk := float(sp.get("bulk", 1.0))
	var legs := float(sp.get("legs", 1.0))
	var L := H * 0.72  # 몸 길이 기준
	var ground := h - H * (0.05 + float(sp.get("pitch", 0.0)) * 0.3)  # 내려다보면 가까운 발이 아래로 내려온다
	var o := Vector3(w * 0.5, ground, 0.0)
	var A := func(f: float, s: float, u: float) -> Vector3: return o + FWD * f * L + SIDE * s * L + Vector3(0, -u * L + (FWD.z * f + SIDE.z * s) * L * pitch, 0)
	var g_far := cl.group()
	var g_body := cl.group()
	var g_near := cl.group()
	var r_chest := 0.165 * L * bulk
	var r_hip := 0.12 * L * bulk
	var sh_u := 0.56 * legs
	var chest: Vector3 = A.call(0.22, 0.0, sh_u - 0.04)
	var mid: Vector3 = A.call(-0.02, 0.0, sh_u - 0.0)
	var hip: Vector3 = A.call(-0.28, 0.0, sh_u - 0.03)
	# 꼬리(몸 뒤)
	_tail(cl, g_far, A, str(sp.get("tail", "bushy")), hip, L, skin, cl.mat(sp.get("tail_c", Color("#4a6a3a")), "skin"), bulk)
	# 다리: 먼 쪽(왼쪽, s<0)은 몸 뒤 그룹, 가까운 쪽은 앞 그룹
	for s: float in [-1.0, 1.0]:
		var g := g_far if s < 0.0 else g_near
		var near := SIDE.z * s >= 0.0
		g = g_near if near else g_far
		_leg(cl, g, A, 0.24, s * 0.085 * bulk, sh_u - 0.05, L, r_chest * 0.42, skin, belly, true, sp, walk * s)  # 대각선 짝: 앞 왼쪽 + 뒤 오른쪽
		_leg(cl, g, A, -0.27, s * 0.08 * bulk, sh_u - 0.04, L, r_hip * 0.6, skin, belly, false, sp, -walk * s)
	# 몸통
	cl.chain(g_body, [hip + Vector3(0, -0.01 * L, 0), mid, chest], [r_hip, r_hip * 0.95, r_chest], skin, 0.06 * L)
	cl.ell(g_body, chest + Vector3(0, r_chest * 0.45, r_chest * 0.3) + FWD * r_chest * 0.3, r_chest * 0.8, r_chest * 0.75, r_chest * 0.8, belly, 0.05 * L)  # 가슴팍
	cl.cap(g_body, hip + SIDE * r_hip * 0.3, hip + SIDE * r_hip * 0.3 + Vector3(0, r_hip * 0.6, 0), r_hip * 0.85, r_hip * 0.7, skin, 0.05 * L)  # 엉덩이 근육
	cl.cap(g_body, chest + SIDE * r_chest * 0.35 + Vector3(0, -r_chest * 0.2, 0), chest + SIDE * r_chest * 0.3 + Vector3(0, r_chest * 0.7, 0) + FWD * 0.02 * L, r_chest * 0.6, r_chest * 0.45, skin, 0.04 * L)  # 어깨
	cl.groove(g_body, Vector2(mid.x, mid.y + r_hip * 0.2), Vector2(chest.x, chest.y + r_chest * 0.3), r_hip * 0.12, r_hip * 0.1)  # 갈비 아래 골
	if sp.has("blades"):
		var bm := cl.mat(sp["blades"], "metal")
		for k in 7:
			var t := k / 6.0
			var b := hip.lerp(chest, t) + Vector3(0, -lerpf(r_hip, r_chest, t) * 0.85, 0)
			var poly: PackedVector2Array
			if sp.has("face"):  # 돌린 그림: 칼날 밑동을 등줄기를 따라(앞·뒤에서 보면 얇은 가시)
				var tip := b + FWD * 0.05 * L + Vector3(0, -(0.13 + sin(t * PI) * 0.08) * L, 0)
				var b0 := b - FWD * 0.035 * L
				var b1 := b + FWD * 0.05 * L
				poly = PackedVector2Array([Vector2(b0.x - 0.004 * L, b0.y), Vector2(tip.x, tip.y), Vector2(b1.x + 0.004 * L, b1.y)])
			else:
				var tip := b + Vector3(0.05 * L, -(0.13 + sin(t * PI) * 0.08) * L, -0.02 * L)
				var side := Vector3(0.035 * L, 0, 0)
				poly = PackedVector2Array([Vector2(b.x - side.x, b.y), Vector2(tip.x, tip.y), Vector2(b.x + side.x * 1.4, b.y)])
			cl.slab(g_body, poly, b.z + 0.01 * L, 0.006 * L, bm, 1.0, 0.012 * L)
	# 목 + 머리
	var head_c: Vector3 = A.call(0.5, 0.0, sh_u - 0.1 + float(sp.get("head_up", 0.0)))
	cl.chain(g_body, [chest + Vector3(0, -r_chest * 0.35, 0) - FWD * 0.03 * L, chest.lerp(head_c, 0.6) + Vector3(0, -0.02 * L, 0), head_c - FWD * 0.04 * L], [r_chest * 0.75, r_chest * 0.5, r_chest * 0.4], skin, 0.04 * L)
	var g_head := cl.group()
	var info := BeastHead.head(cl, g_head, head_c, L * float(sp.get("head_k", 1.6)), str(sp.get("head", "wolf")), sp, skin, rng)
	if sp.has("stripes"):
		var sm: Color = sp["stripes"]
		for k in 7:
			var t := 0.1 + k * 0.13
			var a := hip.lerp(chest, t) + Vector3(0, -r_hip * 0.9, 0)
			cl.grooves(g_body, [Vector2(a.x, a.y), Vector2(a.x + 0.02 * L, a.y + r_hip * 0.6), Vector2(a.x - 0.01 * L, a.y + r_hip * 1.1)], 0.012 * L, 0.006 * L)
		sp["_stripe_c"] = sm
	Render.render(cl, p, H * 1.15)
	var fur := float(sp.get("fur", 0.7))
	if fur > 0.45:
		Fur.comb(cl, p, H * 1.15, 0.5 + fur * 0.9, Vector2(0.55, 1.0))
	BeastHead.ink(p, info, sp)
	if float(sp.get("frost", 0.0)) > 0.0:
		for k in 1400:
			var x := rng.randi_range(0, w - 1)
			var y := rng.randi_range(0, h - 1)
			if p.alpha_at(x, y) > 0.9 and p.nz("mid", x, y) > 0.55:
				p.blend(x, y, Color(0.9, 0.96, 1.0), 0.6)
	Finish.done(p, sp, {"chest": chest, "waist": mid}, H)
	return p


## 다리 하나: 위(어깨·허벅지) → 아래 → 발. front면 곧은 앞다리, 아니면 뒤로 꺾인 뒷다리(발목이 뒤로).
## step: 걸음(+ = 이 다리가 앞으로 나감·발을 듦, - = 뒤로 밀어 디딤).
static func _leg(cl: Clay, g: int, A: Callable, f: float, s: float, top_u: float, L: float, r: float, skin: int, belly: int, front: bool, sp: Dictionary, step: float = 0.0) -> void:
	var top: Vector3 = A.call(f, s, top_u)
	var reach := step * 0.09
	var lift := maxf(0.0, step) * 0.05
	f += reach * 0.5
	var knee: Vector3
	var ankle: Vector3
	var foot: Vector3
	if front:
		knee = A.call(f + 0.01 + reach * 0.4, s, top_u * 0.48 + lift)
		ankle = A.call(f + 0.015 + reach * 0.4, s, 0.06 + lift)
		foot = A.call(f + 0.05 + reach * 0.4, s, 0.018 + lift)
	else:
		knee = A.call(f + 0.07 + reach * 0.4, s, top_u * 0.55 + lift)
		ankle = A.call(f - 0.05 + reach * 0.4, s, 0.13 + lift)
		foot = A.call(f - 0.02 + reach * 0.4, s, 0.018 + lift)
	cl.cap(g, top, knee, r * 1.3, r * 0.6, skin, 0.03 * L)
	cl.cap(g, knee, ankle, r * 0.52, r * 0.34, skin, 0.02 * L)
	cl.cap(g, ankle, foot, r * 0.34, r * 0.38, skin, 0.015 * L)
	var paw := foot + FWD * r * 0.3 + Vector3(0, -r * 0.05, 0)
	cl.ell(g, paw, r * 0.6, r * 0.36, r * 0.55, skin, 0.01 * L)
	var nail := cl.mat(Color("#2a2420"), "bone")
	for k in 4:
		var t := paw + FWD * r * 0.55 + SIDE * (k - 1.5) * r * 0.32 + Vector3(0, r * 0.25, 0)
		cl.cap(g, t, t + FWD * r * 0.3 + Vector3(0, r * 0.2, 0), r * 0.1, r * 0.03, nail, 0.5)


static func _tail(cl: Clay, g: int, A: Callable, kind: String, hip: Vector3, L: float, skin: int, snake: int, bulk: float) -> void:
	var b := hip - FWD * 0.09 * L
	match kind:
		"bushy":
			cl.chain(g, [b, b - FWD * 0.1 * L + Vector3(0, -0.02 * L, 0), b - FWD * 0.2 * L + Vector3(0.02 * L, 0.08 * L, 0), b - FWD * 0.24 * L + Vector3(0.03 * L, 0.2 * L, 0)], [0.04 * L * bulk, 0.055 * L * bulk, 0.05 * L * bulk, 0.012 * L], skin, 0.03 * L)
		"thin":
			cl.chain(g, [b, b - FWD * 0.12 * L + Vector3(0, 0.02 * L, 0), b - FWD * 0.22 * L + Vector3(0.02 * L, 0.12 * L, 0), b - FWD * 0.2 * L + Vector3(0.08 * L, 0.24 * L, 0)], [0.02 * L, 0.014 * L, 0.009 * L, 0.004 * L], skin, 0.01 * L)
		"snake":
			var pts := [b, b - FWD * 0.1 * L + Vector3(0, -0.08 * L, 0), b - FWD * 0.14 * L + Vector3(0.04 * L, -0.2 * L, 0), b - FWD * 0.06 * L + Vector3(0.05 * L, -0.3 * L, 0.02 * L), b - FWD * 0.0 * L + Vector3(0.02 * L, -0.33 * L, 0.04 * L)]
			cl.chain(g, pts, [0.035 * L, 0.03 * L, 0.026 * L, 0.024 * L, 0.03 * L], snake, 0.02 * L)
			var hd: Vector3 = pts[4]
			cl.ell(g, hd + FWD * 0.03 * L, 0.04 * L, 0.028 * L, 0.03 * L, snake, 0.01 * L)
		"stub":
			cl.ell(g, b, 0.04 * L, 0.035 * L, 0.04 * L, skin, 0.02 * L)
