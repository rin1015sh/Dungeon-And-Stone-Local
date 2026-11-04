extends RefCounted
## 다시 그린 거리 소품(CT111 — 2026-11-04 사용자 "수레·우물 안이 안 보이고 가로등이 각지다 · 차원문 테두리와 단이 구분되지 않는다"):
##   가로등 = 둥근 기둥(받침 단 · 고리 띠) + 굽은 팔(호를 짧은 토막으로) + 여섯모 유리 등(쇠살 · 지붕 · 꼭지),
##   우물 = 뚜껑 없이 안벽 · 물낯이 보인다(갓돌 고리 · 도르래 축 · 손잡이 · 밧줄 · 두레박),
##   손수레 · 짐마차 = 짐칸이 열린 상자(안 바닥 · 짐), 바퀴 = 테 · 바퀴살 · 굴대통,
##   돌 단 = 단마다 갓돌 테 + 단 면 · 포탈 고리는 검은 쇠 띠 테두리와 밝은 고리 돌로 단과 다르게.
## Props3D · Deco3D의 build가 이 KINDS를 여기로 넘긴다. 좌표: 칸(X 동, Y 위, Z 남), 발자리 가운데가 원점.

const Kit := preload("res://tools/town_kit/Kit.gd")
const Props3D := preload("res://tools/town_kit/Props3D.gd")

const KINDS := ["lamp", "well", "cart", "wagon", "dais", "dais_ring", "citywall", "citygate"]
const ONLY := ["dais_ring", "citywall", "citygate"]  # 여기에만 있는 것(돌 단에서 떼어 낸 선 돌 고리 — 앞뒤 순서가 사람과 맞게)
const IRON := Color("#2a2622")
const BRASS := Color("#6a5a3a")


static func build(kind: String, k: Kit) -> void:
	match kind:
		"lamp": _lamp(k)
		"well": _well(k)
		"cart": _cart(k)
		"wagon": _wagon(k)
		"dais": _dais(k, false)
		"dais_ring": _dais(k, true)
		"citywall": _citywall(k, false)
		"citygate": _citywall(k, true)


static func _p(c: Color, mat: String = "", ink: float = 1.2) -> Callable:
	return Props3D.paint(c, mat, ink)


## 둥근 기둥 토막(옆만 — 윗면 없이).
static func tube(k: Kit, cx: float, cz: float, r: float, y0: float, y1: float, painter: Callable, segs: int = 12) -> void:
	k.cylinder(cx, cz, r, y0, y1, segs, func(_i: int) -> Callable: return painter)


## 원판(윗면 한 장).
static func disk(k: Kit, cx: float, cz: float, r: float, y: float, painter: Callable, segs: int = 16) -> void:
	var cap := PackedVector3Array()
	for i in segs:
		var a := TAU * i / segs
		cap.append(Vector3(cx + cos(a) * r, y, cz + sin(a) * r))
	k.face(cap, Vector3.UP, painter)


## 고리 윗면(바깥 r0 · 안 r1) — 조각마다(갓돌).
static func annulus(k: Kit, cx: float, cz: float, r0: float, r1: float, y: float, segs: int, painter: Callable) -> void:
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		k.face(Kit._pts([Vector3(cx + cos(a0) * r0, y, cz + sin(a0) * r0), Vector3(cx + cos(a1) * r0, y, cz + sin(a1) * r0),
			Vector3(cx + cos(a1) * r1, y, cz + sin(a1) * r1), Vector3(cx + cos(a0) * r1, y, cz + sin(a0) * r1)]), Vector3.UP, painter)


## 안벽(안쪽을 보는 원통 — 우물 속).
static func inner_wall(k: Kit, cx: float, cz: float, r: float, y0: float, y1: float, segs: int, painter: Callable) -> void:
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var am := (a0 + a1) * 0.5
		k.face(Kit._pts([Vector3(cx + cos(a0) * r, y1, cz + sin(a0) * r), Vector3(cx + cos(a1) * r, y1, cz + sin(a1) * r),
			Vector3(cx + cos(a1) * r, y0, cz + sin(a1) * r), Vector3(cx + cos(a0) * r, y0, cz + sin(a0) * r)]), Vector3(-cos(am), 0.0, -sin(am)), painter)


## 앞을 보는 바퀴(z 앞면): 테(고리) · 바퀴살 · 굴대통. 뒤 바퀴는 같은 것을 z만 달리.
static func wheel(k: Kit, x: float, r: float, z: float, wood: Color) -> void:
	var c := Vector2(x, r)
	var segs := 16
	var tw := r * 0.16
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		Props3D.plate(k, [c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r,
			c + Vector2(cos(a1), sin(a1)) * (r - tw), c + Vector2(cos(a0), sin(a0)) * (r - tw)], z, _p(wood.darkened(0.15), "", 0.9))
	for i in 8:  # 바퀴살
		var a := TAU * i / 8.0 + 0.2
		var d := Vector2(cos(a), sin(a))
		var n := Vector2(-d.y, d.x) * r * 0.045
		Props3D.plate(k, [c + n + d * r * 0.18, c - n + d * r * 0.18, c - n + d * (r - tw), c + n + d * (r - tw)], z + 0.005, _p(wood, "", 0.7))
	var hub := []
	for i in 10:
		hub.append(c + Vector2.from_angle(TAU * i / 10.0) * r * 0.2)
	Props3D.plate(k, hub, z + 0.012, _p(IRON.lightened(0.1), "", 1.0))


# ---------- 가로등 ----------

static func _lamp(k: Kit) -> void:
	var stone := Props3D.STONE
	tube(k, 0.0, 0.0, 0.2, 0.0, 0.1, _p(stone, "stone"), 12)  # 받침 돌 두 단
	disk(k, 0.0, 0.0, 0.2, 0.1, _p(stone.lightened(0.08)), 12)
	tube(k, 0.0, 0.0, 0.14, 0.1, 0.24, _p(IRON), 12)  # 쇠 밑동
	disk(k, 0.0, 0.0, 0.14, 0.24, _p(IRON.lightened(0.1)), 12)
	tube(k, 0.0, 0.0, 0.05, 0.24, 2.2, _p(IRON, "", 1.0), 10)  # 둥근 기둥
	for y: float in [0.5, 1.4]:  # 고리 띠
		tube(k, 0.0, 0.0, 0.075, y, y + 0.06, _p(IRON.lightened(0.12), "", 0.9), 10)
	var pts: Array[Vector2] = []  # 굽은 팔(기둥 꼭대기에서 동쪽으로 휘어 내려간다)
	for i in 7:
		var t := float(i) / 6.0
		pts.append(Vector2(sin(t * PI * 0.5) * 0.42, 2.2 + sin(t * PI) * 0.12 - t * 0.04))
	for i in 6:
		var a := pts[i]
		var b := pts[i + 1]
		k.box(minf(a.x, b.x) - 0.02, -0.025, maxf(a.x, b.x) + 0.02, 0.025, minf(a.y, b.y) - 0.02, maxf(a.y, b.y) + 0.02, {}, _p(IRON, "", 0.8))
	var lx := 0.42
	k.box(lx - 0.02, -0.02, lx + 0.02, 0.02, 1.98, 2.18, {}, _p(IRON, "", 0.8))  # 매단 고리
	var y0 := 1.62
	var y1 := 1.94
	tube(k, lx, 0.0, 0.12, y0 - 0.04, y0, _p(IRON, "", 1.0), 6)  # 등 바닥
	tube(k, lx, 0.0, 0.15, y0, y1, Props3D.glow(), 6)  # 여섯모 유리
	for i in 6:  # 쇠살
		var a := TAU * i / 6.0
		var q := Vector2(lx + cos(a) * 0.152, sin(a) * 0.152)
		k.box(q.x - 0.012, q.y - 0.012, q.x + 0.012, q.y + 0.012, y0, y1, {}, _p(IRON, "", 0.6))
	k.cone(lx, 0.0, 0.2, y1, 0.16, 6, _p(IRON, "", 1.0))  # 지붕
	tube(k, lx, 0.0, 0.025, y1 + 0.14, y1 + 0.24, _p(IRON, "", 0.8), 6)  # 꼭지
	disk(k, lx, 0.0, 0.045, y1 + 0.24, _p(IRON.lightened(0.15)), 6)


# ---------- 우물 ----------

static func _well(k: Kit) -> void:
	var stone := Props3D.STONE
	var ro := 0.72
	var ri := 0.5
	var top := 0.72
	tube(k, 0.0, 0.0, ro, 0.0, top, _p(stone, "stone"), 18)  # 바깥 돌 벽
	inner_wall(k, 0.0, 0.0, ri, -0.4, top, 18, _p(stone.darkened(0.35), "stone", 0.9))  # 안벽(어두워진다)
	disk(k, 0.0, 0.0, ri, 0.18, _p(Color("#24363c"), "", 0.8), 18)  # 물낯
	annulus(k, 0.0, 0.0, ro + 0.05, ri - 0.02, top, 12, _p(stone.lightened(0.12), "", 1.0))  # 갓돌(조각마다 이음)
	tube(k, 0.0, 0.0, ro + 0.05, top - 0.07, top, _p(stone.lightened(0.05), "", 1.0), 18)
	for x: float in [-0.66, 0.66]:  # 기둥
		k.box(x - 0.07, -0.07, x + 0.07, 0.07, top, 2.0, {"top": _p(Props3D.DARK_WOOD)}, _p(Props3D.DARK_WOOD, "vwood"))
	tube(k, 0.0, 0.0, 0.07, 1.5, 1.64, _p(Props3D.WOOD, "", 0.9), 10)  # 도르래 축(동서) — 짧은 토막을 이어
	k.box(-0.62, -0.05, 0.62, 0.05, 1.52, 1.62, {}, _p(Props3D.WOOD, "vwood", 0.9))
	k.box(0.73, -0.02, 0.78, 0.02, 1.4, 1.62, {}, _p(IRON, "", 0.7))  # 손잡이
	k.box(0.73, -0.02, 0.92, 0.02, 1.36, 1.42, {}, _p(IRON, "", 0.7))
	k.box(-0.012, -0.012, 0.012, 0.012, 0.95, 1.52, {}, _p(Color("#8a7a5a"), "", 0.4))  # 밧줄
	tube(k, 0.0, 0.0, 0.13, 0.72, 0.95, _p(Props3D.WOOD, "vwood", 0.9), 10)  # 매단 두레박(물 위)
	disk(k, 0.0, 0.0, 0.13, 0.95, _p(Color("#3a2a1e")), 10)
	tube(k, 0.0, 0.0, 0.135, 0.78, 0.81, _p(IRON, "", 0.6), 10)
	k.gable_roof(-0.9, -0.5, 0.9, 0.5, 2.0, 0.5, true, 0.12, _p(Color("#4a3a2e"), "wood"), _p(Props3D.DARK_WOOD, "vwood"))
	k.box(0.75, 0.42, 1.05, 0.72, 0.0, 0.3, {"top": _p(Color("#2a3a40"))}, _p(Props3D.WOOD, "vwood", 0.9))  # 옆에 둔 물통


# ---------- 손수레 · 짐마차 ----------

## 열린 짐칸: 바닥판 + 네 옆판(얇게 — 안이 보인다) + 모서리 기둥.
static func bed(k: Kit, x0: float, z0: float, x1: float, z1: float, y: float, h: float, wood: Color) -> void:
	k.box(x0, z0, x1, z1, y - 0.06, y, {"top": _p(wood.lightened(0.06), "wood")}, _p(wood.darkened(0.1), "wood"))
	var t := 0.04
	k.box(x0, z0, x1, z0 + t, y, y + h, {}, _p(wood.darkened(0.05), "wood"))  # 뒤(북)
	k.box(x0, z1 - t, x1, z1, y, y + h * 0.45, {}, _p(wood, "wood"))  # 앞(남 — 낮게, 짐이 보이게)
	k.box(x0, z0, x0 + t, z1, y, y + h, {}, _p(wood.darkened(0.08), "wood"))
	k.box(x1 - t, z0, x1, z1, y, y + h, {}, _p(wood.darkened(0.08), "wood"))
	for q: Vector2 in [Vector2(x0, z0), Vector2(x1, z0), Vector2(x0, z1), Vector2(x1, z1)]:
		k.box(q.x - 0.03, q.y - 0.03, q.x + 0.03, q.y + 0.03, y, y + h + 0.04, {"top": _p(Props3D.DARK_WOOD)}, _p(Props3D.DARK_WOOD, "", 0.8))
	for z: float in [z1 - 0.005]:  # 앞판 쇠띠
		k.box(x0 + 0.1, z, x1 - 0.1, z + 0.005, y + h * 0.35, y + h * 0.45, {}, _p(IRON, "", 0.6))


static func _cart(k: Kit) -> void:
	var wood := Color("#6e5034")
	bed(k, -0.8, -0.32, 0.6, 0.32, 0.46, 0.26, wood)
	Props3D._sacks_on(k, -0.42, 0.46)
	Props3D._crate(k, 0.25, 0.0, 0.32)
	for z: float in [-0.08, 0.08]:  # 손잡이 두 대
		k.box(0.6, z - 0.025, 1.25, z + 0.025, 0.4, 0.46, {}, _p(Props3D.DARK_WOOD, "", 0.8))
	k.box(-0.2, -0.36, 0.0, 0.36, 0.28, 0.4, {}, _p(IRON, "", 0.6))  # 굴대
	wheel(k, -0.1, 0.38, 0.38, Color("#5a4030"))
	k.box(0.55, -0.05, 0.6, 0.05, 0.0, 0.46, {}, _p(Props3D.DARK_WOOD, "", 0.8))  # 받침 다리


static func _wagon(k: Kit) -> void:
	var wood := Color("#6e5034")
	bed(k, -1.2, -0.45, 0.9, 0.45, 0.55, 0.32, wood)
	for i in 4:  # 포장 살(활대) — 반쯤만 씌운 천
		var x := -1.15 + i * 0.32
		for j in 8:
			var a0 := PI * j / 8.0
			var a1 := PI * (j + 1) / 8.0
			var za := -cos(a0) * 0.45
			var zb := -cos(a1) * 0.45
			var ya := 0.87 + sin(a0) * 0.55
			var yb := 0.87 + sin(a1) * 0.55
			k.box(x - 0.02, minf(za, zb) - 0.02, x + 0.02, maxf(za, zb) + 0.02, minf(ya, yb) - 0.02, maxf(ya, yb) + 0.02, {}, _p(Props3D.DARK_WOOD, "", 0.5))
	var cloth := Color("#c8bea0")
	for j in 8:  # 천 덮개(뒤쪽 반)
		var a0 := PI * j / 8.0
		var a1 := PI * (j + 1) / 8.0
		k.face(Kit._pts([Vector3(-1.2, 0.87 + sin(a0) * 0.55, -cos(a0) * 0.45), Vector3(-0.2, 0.87 + sin(a0) * 0.55, -cos(a0) * 0.45),
			Vector3(-0.2, 0.87 + sin(a1) * 0.55, -cos(a1) * 0.45), Vector3(-1.2, 0.87 + sin(a1) * 0.55, -cos(a1) * 0.45)]),
			Vector3(0, sin((a0 + a1) * 0.5), -cos((a0 + a1) * 0.5)), _p(cloth.darkened(0.04 * (j % 2)), "", 0.8))
	Props3D._crate(k, 0.1, -0.05, 0.4)  # 짐(앞쪽 열린 칸)
	Props3D._crate(k, 0.55, 0.1, 0.3)
	Props3D._barrel(k, -0.55, 0.05, 0.45)
	for x: float in [-0.85, 0.55]:
		k.box(x - 0.03, -0.5, x + 0.03, 0.5, 0.36, 0.46, {}, _p(IRON, "", 0.6))  # 굴대
		wheel(k, x, 0.44, 0.5, Color("#5a4030"))
	for z: float in [-0.2, 0.2]:  # 끌채
		k.box(0.9, z - 0.03, 1.8, z + 0.03, 0.5, 0.56, {}, _p(Props3D.DARK_WOOD, "", 0.8))
	k.box(1.7, -0.22, 1.74, 0.22, 0.5, 0.56, {}, _p(Props3D.DARK_WOOD, "", 0.8))


# ---------- 차원광장 돌 단 ----------

## ring = false: 세 단만(바닥 위 평평한 그림 — 사람이 위를 걷는다) · true: 선 돌 고리와 받침만(땅 높이 0에 — 게임이 단 높이만큼 올린다).
static func _dais(k: Kit, ring: bool) -> void:
	var stone := Color("#7a7366")
	if ring:
		_ring(k, stone, 0.0)
		return
	for i in 3:  # 세 단 — 단 면(세로 돌) + 갓돌 테(밝게) + 윗면(판석)
		var r := 3.4 - 0.65 * i
		var y0 := 0.3 * i
		var y1 := 0.3 * (i + 1)
		tube(k, 0.0, 0.0, r, y0, y1 - 0.06, _p(stone.darkened(0.18 + 0.04 * i), "stone"), 40)
		tube(k, 0.0, 0.0, r + 0.04, y1 - 0.06, y1, _p(Color("#a39a86").darkened(0.04 * i), "", 1.0), 40)
		annulus(k, 0.0, 0.0, r + 0.04, r - 0.22, y1, 40, _p(Color("#9c937e").darkened(0.04 * i), "", 0.8))
		disk(k, 0.0, 0.0, r - 0.22, y1 - 0.001, _p(Color("#6e6758").darkened(0.05 * i), "rubble", 0.8), 40)


static func _ring(k: Kit, stone: Color, y0: float) -> void:
	y0 += 0.05
	var r1 := 1.95
	var r0 := 1.5
	var c := Vector2(0, y0 + 0.11 + r1)  # 받침 위에 선다
	for i in 28:  # 선 돌 고리 — 쇠 테(바깥·안 띠, 검다) + 밝은 고리 돌, 두께는 앞뒤 면 + 옆 테
		var a0 := TAU * i / 28.0
		var a1 := TAU * (i + 1) / 28.0
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		for z: float in [0.16, -0.16]:
			Props3D.plate(k, [c + d0 * r1, c + d1 * r1, c + d1 * (r1 - 0.08), c + d0 * (r1 - 0.08)], z, _p(IRON, "", 0.6))
			Props3D.plate(k, [c + d0 * (r1 - 0.08), c + d1 * (r1 - 0.08), c + d1 * (r0 + 0.08), c + d0 * (r0 + 0.08)], z, _p(Color("#b3aa96") if z > 0 else Color("#8a8476"), "stone", 0.7))
			Props3D.plate(k, [c + d0 * (r0 + 0.08), c + d1 * (r0 + 0.08), c + d1 * r0, c + d0 * r0], z, _p(IRON, "", 0.6))
		var o0 := c + d0 * r1  # 바깥 테 면(두께)
		var o1 := c + d1 * r1
		k.face(Kit._pts([Vector3(o0.x, o0.y, -0.16), Vector3(o1.x, o1.y, -0.16), Vector3(o1.x, o1.y, 0.16), Vector3(o0.x, o0.y, 0.16)]),
			Vector3(d0.x + d1.x, d0.y + d1.y, 0.0), _p(IRON.lightened(0.08), "", 0.6))
	for i in 7:  # 고리 돌에 새긴 룬(희미한 빛)
		var a := TAU * (i + 0.5) / 7.0 + 0.2
		var q := c + Vector2(cos(a), sin(a)) * (r0 + r1) * 0.5
		Props3D.plate(k, [q + Vector2(-0.05, -0.08), q + Vector2(0.05, -0.08), q + Vector2(0.05, 0.08), q + Vector2(-0.05, 0.08)], 0.165, _p(Color("#8fa8b8"), "", 0.4))
	k.box(-1.0, -0.34, 1.0, 0.34, y0 - 0.05, y0 + 0.1, {"top": _p(Color("#a39a86"))}, _p(stone.darkened(0.1), "stone"))  # 고리 받침
	k.box(-0.8, -0.3, 0.8, 0.3, y0 + 0.1, y0 + 0.16, {"top": _p(IRON.lightened(0.1))}, _p(IRON, "", 0.8))



# ---------- 남쪽 성벽 · 남문(4칸 한 토막 — 발자리 4×2칸, 앞(남) 끝이 원점 z = 0) ----------

const WALL_STONE := Color("#625b4e")


## 성벽 한 토막: 돌 벽(밑동 비탈 · 가운데 띠돌) + 걷는 길(판석) + 바깥(남) 성가퀴 넷(활 구멍) + 안쪽 낮은 난간. gate면 가운데 닫힌 아치 문 + 양옆 탑.
static func _citywall(k: Kit, gate: bool) -> void:
	var h := 1.5
	var z0 := -1.3
	k.box(-2.0, z0 - 0.05, 2.0, 0.14, 0.0, 0.28, {"top": _p(WALL_STONE.darkened(0.1))}, _p(WALL_STONE.darkened(0.12), "stone"))  # 밑동
	if gate:
		for x: float in [-2.0, 1.25]:  # 양옆 탑
			k.box(x, z0 - 0.1, x + 0.75, 0.22, 0.0, h + 0.75, {"top": _p(Color("#8a8270"), "stone")}, _p(WALL_STONE, "stone"))
			for i in 2:
				var mx := x + 0.05 + i * 0.4
				k.box(mx, -0.1, mx + 0.28, 0.22, h + 0.75, h + 1.12, {"top": _p(Color("#9a917c"))}, _p(WALL_STONE.lightened(0.05), "stone"))
			Props3D.plate(k, [Vector2(x + 0.33, 1.0), Vector2(x + 0.42, 1.0), Vector2(x + 0.42, 1.35), Vector2(x + 0.33, 1.35)], 0.225, _p(Color("#141210"), "", 0.6))
		k.box(-1.25, z0, 1.25, 0.0, 1.05, h, {"top": _p(Color("#6e6758"), "stone")}, _p(WALL_STONE, "stone"))  # 문 위 벽
		var arch: Array[Vector2] = []  # 아치 문(남쪽 면에 붙인 판 — 문짝 · 쇠띠 · 반쯤 내린 내리닫이 쇠살)
		for i in 11:
			var a := PI * i / 10.0
			arch.append(Vector2(cos(a) * 0.85, 0.85 + sin(a) * 0.5))
		arch.append(Vector2(-0.85, 0.0))
		arch.append(Vector2(0.85, 0.0))
		var ring: Array[Vector2] = []
		for i in 11:
			var a := PI * i / 10.0
			ring.append(Vector2(cos(a) * 1.05, 0.85 + sin(a) * 0.62))
		ring.append(Vector2(-1.05, 0.0))
		ring.append(Vector2(1.05, 0.0))
		k.box(-1.25, z0, 1.25, -0.02, 0.0, 1.05, {}, _p(WALL_STONE, "stone"))
		Props3D.plate(k, ring, 0.0, _p(Color("#8a8270"), "stone", 1.2))
		Props3D.plate(k, arch, 0.01, _p(Color("#3b2a1e"), "vwood", 1.4))
		Props3D.plate(k, [Vector2(-0.015, 0.0), Vector2(0.015, 0.0), Vector2(0.015, 1.3), Vector2(-0.015, 1.3)], 0.02, _p(Color("#120e0a"), "", 0.0))
		for y: float in [0.3, 0.75]:
			Props3D.plate(k, [Vector2(-0.82, y), Vector2(0.82, y), Vector2(0.82, y + 0.06), Vector2(-0.82, y + 0.06)], 0.025, _p(IRON, "", 0.5))
		for i in 7:  # 내리닫이 쇠살(위쪽만)
			var x := -0.72 + i * 0.24
			Props3D.plate(k, [Vector2(x - 0.025, 0.95), Vector2(x + 0.025, 0.95), Vector2(x + 0.025, 1.3), Vector2(x - 0.025, 1.3)], 0.04, _p(IRON, "", 0.6))
		Props3D.plate(k, [Vector2(-0.8, 1.0), Vector2(0.8, 1.0), Vector2(0.8, 1.04), Vector2(-0.8, 1.04)], 0.045, _p(IRON, "", 0.6))
		h = h
	else:
		k.box(-2.0, z0, 2.0, 0.0, 0.28, h, {"top": _p(Color("#6e6758"), "stone")}, _p(WALL_STONE, "stone"))
		for x: float in [-1.0, 1.0]:  # 덧벽(버팀 기둥)
			k.box(x - 0.18, -0.02, x + 0.18, 0.16, 0.0, h - 0.25, {"top": _p(WALL_STONE.lightened(0.05))}, _p(WALL_STONE.darkened(0.05), "stone"))
	k.box(-2.0, -0.04, 2.0, 0.05, 1.2, 1.28, {"top": _p(Color("#9a917c"))}, _p(Color("#8a8270"), "", 1.0))  # 띠돌
	var xs := [-1.25, 0.25] if gate else [-1.75, -0.75, 0.25, 1.25]
	for x: float in xs:  # 바깥 성가퀴
		if gate and x > -1.3 and x < 1.2:
			for j in 2:
				var mx := -1.1 + j * 1.6
				k.box(mx, -0.32, mx + 0.6, 0.0, h, h + 0.42, {"top": _p(Color("#9a917c"))}, _p(WALL_STONE.lightened(0.05), "stone"))
			break
		k.box(x, -0.32, x + 0.5, 0.0, h, h + 0.42, {"top": _p(Color("#9a917c"))}, _p(WALL_STONE.lightened(0.05), "stone"))
		Props3D.plate(k, [Vector2(x + 0.22, h + 0.08), Vector2(x + 0.28, h + 0.08), Vector2(x + 0.28, h + 0.32), Vector2(x + 0.22, h + 0.32)], 0.005, _p(Color("#141210"), "", 0.5))
	k.box(-2.0, z0, 2.0, z0 + 0.14, h, h + 0.16, {"top": _p(Color("#8a8270"))}, _p(WALL_STONE, "", 1.0))  # 안쪽 낮은 난간
