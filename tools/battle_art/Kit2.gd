extends RefCounted
## 전투 뒷그림 부품 2(챕터 장면용): 하늘 · 물 · 낭떠러지 · 창살 · 먼 실루엣 · 떠다니는 빛 · 반짝이는 가루 · 톱날 · 떠다니는 눈.
## Room 재질 함수 안에서 쓰는 것(sky·water·void)은 사전을, 칠하는 것은 Paint에 바로. tools/paint_battlebacks.gd 전용.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Room := preload("res://tools/battle_art/Room.gd")
const Mats := preload("res://tools/battle_art/Mats.gd")
const Kit := preload("res://tools/battle_art/Kit.gd")


## 하늘(빛·안개 없이): 시선의 높이각으로 아래(low)→위(top) + 가로로 번진 구름 띠.
static func sky(m: Mats, room: Room, P: Vector3, top: Color, low: Color, cloud: Color) -> Dictionary:
	var z := maxf(0.1, P.z)
	var elev := (P.y - room.eye) / z
	var az := P.x / z
	var c := low.lerp(top, clampf(elev / 0.32, 0.0, 1.0))
	var band := m.nz("lo", az * 2.5, elev * 9.0) * 0.6 + m.nz("mid", az * 1.2, elev * 14.0) * 0.4
	c = c.lerp(cloud, smoothstep(0.5, 0.75, band) * 0.6)
	return {"c": c, "flat": true}


## 물(해자·강·웅덩이): 검은 거울 + 잔물결에 비친 빛. flow = 흐름 방향 줄무늬(강).
static func water(m: Mats, P: Vector3, base: Color, shine: Color, flow: float = 0.0) -> Dictionary:
	var rip := m.nz("mid", P.x * 1.5, P.z * (4.0 - flow * 3.0) + flow * P.x * 0.3)
	var streak := smoothstep(0.55, 0.85, m.nz("hi", P.x * (0.25 + flow), P.z * (2.5 - flow * 2.0)))
	var c := base.lerp(shine, streak * 0.35 + smoothstep(0.6, 0.9, rip) * 0.15)
	return {"c": c, "h": rip * 0.01, "spec": 0.9, "emit": shine * streak * 0.08}


## 낭떠러지(바닥이 없는 곳): 깊이로 가라앉는 어둠 + 희미한 안개(빛·안개 없이).
static func chasm(m: Mats, P: Vector3, deep: Color, haze: Color) -> Dictionary:
	var v := m.nz("lo", P.x * 0.3, P.z * 0.3)
	return {"c": deep.lerp(haze, v * 0.35 * clampf(P.z / 25.0, 0.0, 1.0)), "flat": true}


## 창살(세로 쇠막대) — x = 막대가 선 면(m), z0~z1 사이 간격 gap, 높이 y0~y1. 둘레는 가로 띠 두 줄.
static func bars(p: Paint, room: Room, x: float, z0: float, z1: float, y0: float, y1: float, gap: float, col: Color) -> void:
	var z := z1
	while z >= z0:
		var a := room.pt(x, y0, z)
		var b := room.pt(x, y1, z)
		var c := room.lit(Vector3(x, (y0 + y1) / 2.0, z), Vector3(-signf(x), 0, -0.3).normalized(), col, 0.4)
		Ink.line(p, a, b, clampf(room.px(0.05, z), 1.0, 9.0), c, 1.0, 0.15)
		Ink.line(p, a + Vector2(room.px(0.025, z), 0), b + Vector2(room.px(0.025, z), 0), clampf(room.px(0.012, z), 0.6, 2.0), Ink.INK, 0.7, 0.15)
		z -= gap
	for yy: float in [y0 + 0.15, y1 - 0.15]:
		var a := room.pt(x, yy, z0)
		var b := room.pt(x, yy, z1)
		Ink.line(p, a, b, clampf(room.px(0.06, (z0 + z1) / 2.0), 1.0, 8.0), room.lit(Vector3(x, yy, z0), Vector3(-signf(x), 0, -0.3).normalized(), col), 1.0, 0.1)


## 먼 실루엣(성벽·탑·지붕 — 화면 다각형): 거의 검은 색 + 아래로 안개.
static func silhouette(p: Paint, poly: PackedVector2Array, col: Color, fog: Color, edge: float = 0.6) -> void:
	var r := Paint.bounds(poly)
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var t := clampf((y - r.position.y) / maxf(1.0, r.size.y), 0.0, 1.0)
		return p.vary(col.lerp(fog, t * t * 0.7), x, y, 0.08))
	Ink.path(p, poly, 1.2, true, Ink.INK, edge, 0.6)


## 떠다니는 빛(영체·도깨비불) — 색 보정 뒤에.
static func wisp(p: Paint, room: Room, P: Vector3, r: float, c: Color) -> void:
	var q := room.pt(P.x, P.y, P.z)
	var rp := room.px(r, P.z)
	Ink.glow(p, q.x, q.y, rp * 4.0, c, 0.35, false)
	Ink.glow(p, q.x, q.y, rp, c.lightened(0.5), 0.8, false)
	for k in 3:  # 꼬리
		var t := q + Vector2(-rp * (1.5 + k * 1.3), rp * (0.6 + k * 0.9))
		Ink.glow(p, t.x, t.y, rp * (0.9 - k * 0.2), c, 0.35 - k * 0.09, false)


## 반짝이는 가루(떨어지는 얼음 가루·먼지): 화면 영역 안에 점 n개 — 색 보정 뒤에.
static func sparkle(p: Paint, rect: Rect2, n: int, c: Color, size_px: float = 1.6) -> void:
	for i in n:
		var x := rect.position.x + p.rng.randf() * rect.size.x
		var y := rect.position.y + p.rng.randf() * rect.size.y
		var s := size_px * p.rng.randf_range(0.5, 1.4)
		Ink.glow(p, x, y, s * 2.5, c, p.rng.randf_range(0.25, 0.7), false)


## 바닥 홈에서 솟은 톱날(세운 원판 — 앞에서 본다): 가운데 c(바닥 위 높이 포함), 반지름 m. 흐린 돌기 자국으로 돌아가는 느낌.
static func saw(p: Paint, room: Room, c: Vector3, r: float, steel: Color) -> void:
	var q := room.pt(c.x, c.y, c.z)
	var rp := room.px(r, c.z)
	var col := room.lit(c, Vector3(0, 0.3, -1).normalized(), steel, 0.25)
	var disc := PackedVector2Array()
	for k in 48:
		var a := TAU * k / 48.0
		var rr := rp * (1.0 if k % 2 == 0 else 0.88)
		disc.append(q + Vector2(cos(a) * rr * 0.32, sin(a) * rr))  # 옆에서 본 원판 = 납작한 타원
	var floor_y := room.pt(c.x, room.floor_at(c.z), c.z).y
	p.fill_poly(disc, func(x: int, y: int) -> Color:
		if y > floor_y:
			return Color(0, 0, 0, 0)
		return p.vary(col.lerp(col.darkened(0.5), clampf((x - q.x) / (rp * 0.32) * 0.5 + 0.5, 0.0, 1.0)), x, y, 0.1))
	Ink.path(p, disc, clampf(rp * 0.03, 0.8, 2.5), true, Ink.INK, 0.85, 0.3)
	for k in 3:  # 돌아가는 자국(흐린 호)
		var arc := PackedVector2Array()
		for i in 9:
			var a := -PI * 0.5 + (k * 0.6 + i * 0.12)
			arc.append(q + Vector2(cos(a) * rp * 0.4, sin(a) * rp * 1.05))
		Ink.path(p, arc, clampf(rp * 0.02, 0.6, 1.8), false, steel.lightened(0.4), 0.35, 0.4)
	Ink.line(p, Vector2(q.x - rp * 0.5, floor_y), Vector2(q.x + rp * 0.5, floor_y), clampf(rp * 0.05, 1.0, 4.0), Color("#0a0a0a"), 0.9, 0.2)
	var hub := PackedVector2Array()
	for k in 12:
		hub.append(q + Vector2(cos(TAU * k / 12.0) * rp * 0.06, sin(TAU * k / 12.0) * rp * 0.18))
	p.fill_poly(hub, p.flat(col.darkened(0.6), 0.1))
	for k in 4:  # 날 끝 피
		var a := TAU * (0.1 + k * 0.23)
		var e := q + Vector2(cos(a) * rp * 0.3, sin(a) * rp * 0.95)
		Ink.line(p, e, e + Vector2(0, rp * 0.12), clampf(rp * 0.04, 0.8, 2.5), Color("#5a1410"), 0.7, 0.3)


## 떠다니는 눈(감시하는 눈알): 흰자 + 빛나는 홍채 — 홍채 빛은 색 보정 뒤에 다시 얹는다(glow_only).
static func eye_orb(p: Paint, room: Room, c: Vector3, r: float, iris: Color, glow_only: bool = false) -> void:
	var q := room.pt(c.x, c.y, c.z)
	var rp := room.px(r, c.z)
	if glow_only:
		Ink.glow(p, q.x, q.y, rp * 3.5, iris, 0.4, false)
		Ink.glow(p, q.x, q.y + rp * 0.1, rp * 0.45, iris.lightened(0.5), 0.9, false)
		return
	var ball := PackedVector2Array()
	for k in 24:
		ball.append(q + Vector2.from_angle(TAU * k / 24.0) * rp)
	var lc := room.lit(c, Vector3(-0.4, 0.4, -0.8).normalized(), Color("#c8c0b0"))
	p.fill_poly(ball, func(x: int, y: int) -> Color:
		var d := Vector2(x - q.x + rp * 0.3, y - q.y + rp * 0.3).length() / (rp * 1.6)
		return p.vary(lc.lerp(lc.darkened(0.7), clampf(d, 0.0, 1.0)), x, y, 0.06))
	var ir := PackedVector2Array()
	for k in 16:
		ir.append(q + Vector2(0, rp * 0.1) + Vector2.from_angle(TAU * k / 16.0) * rp * 0.45)
	p.fill_poly(ir, p.flat(iris.darkened(0.2), 0.1))
	p.fill_rect(q.x - rp * 0.08, q.y - rp * 0.25, rp * 0.16, rp * 0.7, p.flat(Color("#0a0606"), 0.05))
	for k in 5:  # 핏줄
		var a := TAU * k / 5.0 + 0.3
		Ink.line(p, q + Vector2.from_angle(a) * rp * 0.95, q + Vector2.from_angle(a + 0.2) * rp * 0.55, clampf(rp * 0.03, 0.5, 1.4), Color("#7a2a22"), 0.6, 0.6)
	Ink.path(p, ball, clampf(rp * 0.08, 0.8, 2.5), true, Ink.INK, 0.9, 0.3)
