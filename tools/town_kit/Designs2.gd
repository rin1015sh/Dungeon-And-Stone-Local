extends "res://tools/town_kit/Designs.gd"
## 도시 3차 개선 건물(사용자 2026-11-03 "도시 전체 레이아웃 및 환경 개선 3차", CT103) — Designs의 붓 · 조각 그대로.
##   _cathedral = 신전(성당 — 회랑 셋 · 버팀벽 · 정면 종탑 첨탑, 일반 집과 확실히 다른 큰 석조)
##   _town_hall = 관청(윗단 행정 — 3층 석조 · 아케이드 1층 · 가운데 시계탑 · 현수막)
##   _warehouse = 강변 창고(낮고 긴 박공 · 큰 문 · 다락 짐 문과 도르래 들보)
##   _row_timber = 좁은 2층 반목조(작은 주거 — 돌출 2층 · 덧창 · 굴뚝), _corner_shop = 모퉁이 가게(차양 · 간판 · 2층 발코니)

const F2 := preload("res://tools/town_kit/Facade.gd")
const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Deco3D := preload("res://tools/town_kit/Deco3D.gd")


static func _cathedral(k: Kit) -> void:
	# 가운데 회랑(높은 3층 석조 · 첨두창) + 가파른 박공
	var r := stack(k, -3.2, -5.0, 3.2, 2.2, 0.0, [{"style": "stone", "floors": 3, "base": 0.3, "ci": 1, "win": "gothic", "lit": 0.6}])
	gable(k, r, false, 0.95, 1, "stone", 0.2)  # 지붕이 벽 · 탑을 가리지 않게 낮게
	# 옆 회랑 둘(낮은 석조 + 회랑 쪽으로 기운 외쪽지붕) · 버팀벽
	for s: float in [-1.0, 1.0]:
		var x0 := -6.0 if s < 0 else 3.2
		var x1 := -3.2 if s < 0 else 6.0
		var a := stack(k, x0, -4.4, x1, 1.4, 0.0, [{"style": "stone", "floors": 1, "base": 0.3, "ci": 2, "win": "gothic", "lit": 0.5}])
		var y := float(a[4])
		if s < 0:
			k.shed_roof(x0, -4.4, x1, 1.4, y, y + 1.0, 0.15, F2.roof(1), F2.plain("stone", 1))
		else:
			k.shed_roof(x0, -4.4, x1, 1.4, y, y + 1.0, 0.15, F2.roof(1), F2.plain("stone", 1))
		var xb := x0 - 0.35 if s < 0 else x1
		for z: float in [-3.6, -1.6, 0.4]:
			k.box(xb, z, xb + 0.35, z + 0.45, 0.0, y - 0.2, {"top": F2.plain("stone", 2)}, F2.plain("stone", 2))
	# 정면 종탑 + 첨탑 · 모서리 작은 첨탑
	var h := 8 * F2.storey + 0.3
	k.box(-1.5, 2.2, 1.5, 4.6, 0.0, h, {"s": F2.tower(0, 8, true, true), "top": F2.plain("stone")}, F2.tower(1, 8, true))
	step(k, 0.0, 4.6, 0.0)
	k.box(-1.0, 4.6, 1.0, 5.2, 0.0, 0.14, {"top": F2.plain("stone", 2)}, F2.plain("stone", 2))
	k.pyramid(-1.5, 2.2, 1.5, 4.6, h, 4.2, 0.15, F2.roof(1))
	for c: Vector2 in [Vector2(-1.5, 2.2), Vector2(1.5, 2.2), Vector2(1.5, 4.6), Vector2(-1.5, 4.6)]:
		k.box(c.x - 0.2, c.y - 0.2, c.x + 0.2, c.y + 0.2, h, h + 0.5, {}, F2.plain("stone"))
		k.pyramid(c.x - 0.2, c.y - 0.2, c.x + 0.2, c.y + 0.2, h + 0.5, 1.1, 0.03, F2.roof(1, true))


static func _town_hall(k: Kit) -> void:
	var r := stack(k, -5.0, -2.4, 5.0, 2.4, 0.0, [
		{"style": "stone", "floors": 1, "base": 0.3, "ci": 0, "arch": true, "door": 0.2, "win": "arch", "lit": 0.6},
		{"style": "stone", "floors": 2, "ci": 2, "win": "arch", "lit": 0.5, "shutters": false}])
	k.hip_roof(r[0], r[1], r[2], r[3], r[4], 1.5, 0.3, F2.roof(2))
	dormer(k, r, 1.5, -3.2, 2)
	dormer(k, r, 1.5, 3.2, 2)
	var h := 6 * F2.storey + 0.3
	k.box(-1.3, 0.6, 1.3, 3.1, 0.0, h, {"s": F2.tower(0, 6, true, true)}, F2.tower(1, 6, true))
	step(k, 0.0, 3.1, 0.0)
	k.pyramid(-1.3, 0.6, 1.3, 3.1, h, 2.6, 0.2, F2.roof(2))
	k.box(-0.05, 1.8, 0.05, 1.9, h + 2.4, h + 3.4, {}, F2.plain("dark"))
	for x: float in [-3.0, 3.0]:
		k.face(Kit._pts([Vector3(x - 0.45, 1.3, 2.42), Vector3(x + 0.45, 1.3, 2.42), Vector3(x + 0.45, 3.2, 2.42), Vector3(x - 0.45, 3.2, 2.42)]), Vector3(0, 0, 1), F2.banner())
	chimney(k, -4.0, -1.4, r[4], r[4] + 2.0)


static func _warehouse(k: Kit) -> void:
	var r := stack(k, -4.2, -2.3, 4.2, 2.3, 0.0, [
		{"style": "stone", "floors": 1, "base": 0.25, "ci": 2, "door": 0.3, "arch": true, "lit": 0.2},
		{"style": "timber", "floors": 1, "ci": 1, "lit": 0.2}])
	gable(k, r, true, 0.75, 3, "timber", 0.35)
	var y := float(r[4])
	k.box(1.4, 2.3, 2.6, 2.34, F2.storey + 0.35, y - 0.1, {}, F2.plain("wood"))  # 다락 짐 문
	k.box(1.9, 0.5, 2.1, 3.4, y + 0.2, y + 0.4, {"top": F2.plain("wood")}, F2.plain("wood"))  # 도르래 들보
	k.box(1.97, 3.2, 2.03, 3.26, F2.storey + 0.4, y + 0.2, {}, F2.plain("dark"))  # 밧줄
	k.box(1.8, 3.1, 2.2, 3.4, F2.storey + 0.1, F2.storey + 0.45, {"top": F2.plain("wood")}, F2.plain("wood"))  # 매단 짐


static func _row_timber(k: Kit) -> void:
	var r := stack(k, -2.0, -2.0, 2.0, 2.0, 0.0, [
		{"style": "plaster", "floors": 1, "base": 0.15, "door": 0.25, "ci": 4, "shutters": true},
		{"style": "timber", "floors": 1, "jetty": 0.25, "ci": 2, "flowers": true}])
	gable(k, r, false, 1.25, 3, "timber")
	chimney(k, -1.2, -1.0, r[4], r[4] + 2.0)


static func _corner_shop(k: Kit) -> void:
	var r := stack(k, -2.8, -2.0, 2.8, 2.0, 0.0, [
		{"style": "stone", "floors": 1, "base": 0.2, "shop": true, "door": 0.15, "sign": "bag", "ci": 1},
		{"style": "timber", "floors": 1, "jetty": 0.18, "ci": 0, "shutters": true}])
	gable(k, r, true, 0.95, 0, "timber")
	awning(k, -2.8, 2.8, 2.0, -2.8 + F2.door_x(5.6, 0.15))
	var yb := F2.storey + 0.2
	k.box(-2.0, 2.18, 0.4, 2.8, yb, yb + 0.1, {"top": F2.plain("wood")}, F2.plain("wood"))  # 2층 발코니
	k.face(PackedVector3Array([Vector3(-2.0, yb + 0.1, 2.8), Vector3(0.4, yb + 0.1, 2.8), Vector3(0.4, yb + 0.5, 2.8), Vector3(-2.0, yb + 0.5, 2.8)]), Vector3(0, 0, 1), F2.gallery())
	chimney(k, 2.0, -1.2, r[4], r[4] + 1.8)


## 도서관(사용자 2026-11-03 "천문관 같다 — 박물관 같은 느낌, 일반 건물 위에 돔을 얹은 느낌", CT104):
## 2층 석조 본관(낮은 모임지붕) + 정면 기둥 현관(계단 · 기둥 여섯 · 삼각 박공) + 지붕 가운데 둥근 받침(창) 위 돔 + 꼭대기 작은 탑.
static func _museum(k: Kit) -> void:
	var r := stack(k, -6.4, -4.4, 6.4, 3.0, 0.0, [{"style": "stone", "floors": 2, "base": 0.45, "ci": 0, "win": "arch", "lit": 0.55, "door": 0.5}])
	var y := float(r[4])
	k.hip_roof(r[0], r[1], r[2], r[3], y, 0.9, 0.25, F2.roof(2))
	# 정면 현관: 계단 둘 · 기둥 여섯 · 들보 · 삼각 박공
	k.box(-3.3, 3.0, 3.3, 5.0, 0.0, 0.2, {"top": F2.plain("stone", 2)}, F2.plain("stone", 2))
	k.box(-3.0, 3.0, 3.0, 4.7, 0.2, 0.4, {"top": F2.plain("stone", 2)}, F2.plain("stone", 2))
	var col := F2.plain("stone", 2)
	for i in 6:
		var x := -2.6 + i * 1.04
		k.cylinder(x, 4.3, 0.17, 0.4, y - 0.35, 10, func(_j: int) -> Callable: return col)
	k.box(-3.0, 3.0, 3.0, 4.6, y - 0.35, y + 0.05, {"top": F2.plain("stone")}, F2.plain("stone"))
	k.gable_roof(-3.0, 3.0, 3.0, 4.6, y + 0.05, 1.0, false, 0.08, F2.roof(2), F2.gable("stone", 0, false))
	# 돔: 둥근 받침(창) + 반구 + 꼭대기 작은 탑
	var dy := y + 0.6
	k.cylinder(0.0, -0.8, 2.3, y - 0.1, dy + 0.75, 18, func(i: int) -> Callable: return F2.wall({"style": "stone", "floors": 1, "ci": 1, "win": "arch", "lit": 0.6 if i % 2 == 0 else 0.0}))
	dome(k, Vector3(0.0, dy + 0.75, -0.8), 2.45, 1.45, _copper())  # 낮은 반구(3/4에서 달걀처럼 솟지 않게)
	var top := dy + 2.2
	k.cylinder(0.0, -0.8, 0.42, top - 0.1, top + 0.7, 10, func(_j: int) -> Callable: return F2.plain("stone", 1))
	k.cone(0.0, -0.8, 0.55, top + 0.7, 0.6, 10, _copper())
	chimney(k, -5.2, -3.0, y, y + 1.3)
	chimney(k, 5.2, -3.0, y, y + 1.3)


## 반구 돔(위도 띠 면) — 가운데 c(밑면 높이), 반지름 r, 높이 h.
static func dome(k: Kit, c: Vector3, r: float, h: float, painter: Callable, segs: int = 18, rings: int = 5) -> void:
	var n0 := k.root.get_child_count()
	var faces: Array[int] = []
	for j in rings:
		var t0 := (PI * 0.5) * j / rings
		var t1 := (PI * 0.5) * (j + 1) / rings
		for i in segs:
			var a0 := TAU * i / segs
			var a1 := TAU * (i + 1) / segs
			var q := PackedVector3Array()
			for ta: Vector2 in [Vector2(t0, a0), Vector2(t0, a1), Vector2(t1, a1), Vector2(t1, a0)]:
				q.append(c + Vector3(cos(ta.x) * cos(ta.y) * r, sin(ta.x) * h, cos(ta.x) * sin(ta.y) * r))
			if j == rings - 1:
				q = PackedVector3Array([q[0], q[1], q[2]])
			k.face(q, (q[0] + q[1]) * 0.5 - c, painter)
			faces.append(i / 3)
	for n in range(n0, k.root.get_child_count()):  # 세 칸씩 한 면(갈빗대 여섯 — 칸마다 먹선이 그물처럼 보이지 않게)
		k.root.get_child(n).set_meta("gid", 9000 + faces[mini(n - n0, faces.size() - 1)])


## 녹슨 구리 · 납 지붕(차분한 청록 잿빛 — 채도 낮게).
static func _copper() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, p.flat(Color("#2e3836"), 0.06))  # 납 · 녹슨 구리(무늬 없이 — 면 먹선은 갈빗대만)


## 여관(CT104 — 길드와 헷갈리지 않게): 3층 반목조 · 층마다 돌출 · 2층 회랑 발코니 · 술잔 간판 · 창빛 많이 · 굴뚝 둘.
static func _inn(k: Kit) -> void:
	var r := stack(k, -5.0, -1.2, 5.0, 2.2, 0.0, [  # 얕게(3/4에서 지붕이 덜 보이게) · 4층으로 벽을 넉넉히
		{"style": "stone", "floors": 1, "base": 0.25, "door": 0.5, "ci": 1, "lit": 0.85, "sign": "mug", "win": "arch"},
		{"style": "timber", "floors": 2, "jetty": 0.22, "ci": 2, "shutters": true, "flowers": true, "lit": 0.7},
		{"style": "timber", "floors": 1, "jetty": 0.18, "ci": 4, "lit": 0.6}])
	var rise := gable(k, r, true, 0.55, 1, "timber")  # 낮은 지붕(3/4에서 지붕이 벽 · 발코니를 덮지 않게)
	var w := stack(k, -1.7, 2.2, 1.7, 2.62, 3 * F2.storey + 0.25, [{"style": "timber", "floors": 1, "ci": 3, "lit": 0.8}])  # 가운데 앞 박공(술집 다락)
	k.gable_roof(-1.7, 0.6, 1.7, w[3], w[4], 1.0, false, 0.15, F2.roof(1), F2.gable("timber", 3))
	var y := F2.storey + 0.25
	k.box(-3.6, 2.42, 3.6, 3.1, y - 0.12, y, {"top": F2.plain("wood")}, F2.plain("wood"))  # 2층 발코니
	k.face(PackedVector3Array([Vector3(-3.6, y, 3.1), Vector3(3.6, y, 3.1), Vector3(3.6, y + 0.45, 3.1), Vector3(-3.6, y + 0.45, 3.1)]), Vector3(0, 0, 1), F2.gallery())
	for x: float in [-3.5, 0.0, 3.5]:
		k.box(x - 0.07, 2.96, x + 0.07, 3.1, 0.0, y - 0.12, {}, F2.plain("wood"))
	chimney(k, -3.8, -1.2, r[4], r[4] + rise + 0.6)
	chimney(k, 3.8, -1.2, r[4], r[4] + rise + 0.6)



## 차양(문 위는 비운다 — 3/4에서 차양이 문을 가리지 않게, 사용자 2026-11-03 "잡화점 천막 때문에 문이 안 보임", CT105): x0~x1 벽 앞 z, 문 가운데 door.
static func awning(k: Kit, x0: float, x1: float, z: float, door: float) -> void:
	var y := F2.storey * 1.02
	for seg: Vector2 in [Vector2(x0, door - 0.7), Vector2(door + 0.7, x1)]:
		if seg.y - seg.x < 0.6:
			continue
		k.face(PackedVector3Array([Vector3(seg.x, y, z), Vector3(seg.y, y, z), Vector3(seg.y, y - 0.18, z + 0.55), Vector3(seg.x, y - 0.18, z + 0.55)]), Vector3(0, 1, 0.4), F2.awning())


## 가게집(잡화점 · 시장 가게 — Designs._shop_house를 차양만 고쳐서): 문 위 차양을 비운다.
static func _shop_house2(k: Kit) -> void:
	var r := stack(k, -2.2, -2.0, 2.2, 2.0, 0.0, [{"style": "plaster", "floors": 1, "base": 0.15, "shop": true, "door": 0.99, "sign": "bag", "ci": 3}, {"style": "timber", "floors": 2, "jetty": 0.2, "ci": 3, "flowers": true}])
	gable(k, r, false, 1.45, 2, "timber")
	awning(k, -2.2, 2.2, 2.0, -2.2 + F2.door_x(4.4, 0.99))


## 대장간(CT105 — 사용자 "대장간 연기랑 모루"): 돌 공방 + 열린 화덕 아치(불빛) + 큰 벽돌 굴뚝 · 굴뚝 연기 덩이 + 옆 외쪽지붕 작업 처마.
static func _smithy(k: Kit) -> void:
	k.box(-2.4, -1.8, 2.0, 1.8, 0.0, F2.storey + 0.3, {"s": F2.wall({"style": "stone", "floors": 1, "base": 0.25, "door": 0.25, "arch": true, "ci": 2, "lit": 1.0})},
		F2.wall({"style": "stone", "floors": 1, "base": 0.25, "ci": 1}))
	step(k, -2.4 + F2.door_x(4.4, 0.25), 1.8, 0.0)
	k.shed_roof(-2.4, -1.8, 2.0, 1.8, F2.storey + 0.3, F2.storey + 1.4, 0.25, F2.roof(3), F2.plain("wood"))
	# 옆 작업 처마(기둥 둘 · 낮은 외쪽지붕)
	for z: float in [-1.4, 1.5]:
		k.box(3.25, z - 0.07, 3.39, z + 0.07, 0.0, F2.storey * 0.95, {}, F2.plain("wood"))
	k.shed_roof(2.0, -1.6, 3.5, 1.7, F2.storey * 0.95, F2.storey + 0.3, 0.1, F2.roof(3, true), F2.plain("wood"))
	# 큰 굴뚝 + 연기(잿빛 덩이 셋이 비스듬히 오른다)
	var cy := F2.storey + 3.2
	k.box(0.6, -1.3, 1.5, -0.4, 0.0, cy, {"top": F2.plain("dark")}, F2.plain("brick"))
	k.box(0.5, -1.4, 1.6, -0.3, cy, cy + 0.2, {"top": F2.plain("dark")}, F2.plain("stone", 1))
	var smoke := func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, p.flat(Color("#8c8882"), 0.1))
	for i in 4:
		Deco3D.blob(k, Vector3(1.05 + i * 0.55, cy + 0.6 + i * 0.85, -0.85 - i * 0.15), Vector3(0.5 + i * 0.16, 0.4 + i * 0.1, 0.45 + i * 0.12), smoke, 8, 4)
	# 화덕 불빛(열린 아치 안 아래쪽 — 벌건 숯불)
	var ax := -2.4 + 4.4 * 2.5 / 4.0
	k.face(PackedVector3Array([Vector3(ax - 0.36, 0.05, 1.82), Vector3(ax + 0.36, 0.05, 1.82), Vector3(ax + 0.36, 0.55, 1.82), Vector3(ax - 0.36, 0.55, 1.82)]), Vector3(0, 0, 1), Deco3D.Props3D.glow())
