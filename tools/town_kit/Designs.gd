extends RefCounted
## 집 바리에이션 16채(사용자 2026-11-02 "2층 3층 등 층수도 제각각, 지붕 모양이나 건물 형태도 제각각 · 건물 사이를 잇는 다리 · 첨탑 · 높낮이") —
## Kit(3D 조각) + Facade(횡스크롤 붓 면 그림)로. 좌표 칸(X 동, Y 위, Z 남), 원점 둘레. LIST = [id, 이름, 짓는 함수 이름].

const Kit := preload("res://tools/town_kit/Kit.gd")
const F := preload("res://tools/town_kit/Facade.gd")

const LIST := [
	["v01", "좁은 반목조 3층 · 층마다 돌출 · 박공 정면", "_narrow_jetty"],
	["v02", "처마 2층 · 지붕창 둘", "_eaves_dormers"],
	["v03", "4층 탑집 · 모임지붕", "_tall_hip"],
	["v04", "ㄱ자 엇박공", "_cross_gable"],
	["v05", "모퉁이 둥근 탑", "_turret_house"],
	["v06", "종탑 · 첨탑", "_bell_tower"],
	["v07", "작은 예배당", "_chapel"],
	["v08", "두 집 사이 구름다리", "_bridge_pair"],
	["v09", "아치 통로 집", "_arch_house"],
	["v10", "가게집 · 차양 · 간판", "_shop_house"],
	["v11", "바깥 계단 · 회랑", "_gallery_house"],
	["v12", "맨사드 지붕 · 지붕창 셋", "_mansard"],
	["v13", "계단식 박공 벽돌집", "_step_gable"],
	["v14", "외쪽지붕 공방", "_workshop"],
	["v15", "높은 단 위의 집 · 계단", "_podium"],
	["v16", "탑 달린 저택", "_manor"],
]


## 층 묶음 쌓기: levels = [{style, floors, jetty, ci, door, shop, arch, shutters, flowers, sign, base, win}] — 위 묶음은 앞·옆으로 jetty만큼 내민다.
## 돌려줌 [x0, z0, x1, z1, 지붕 높이].
static func stack(k: Kit, x0: float, z0: float, x1: float, z1: float, y0: float, levels: Array) -> Array:
	var y := y0
	for lv: Dictionary in levels:
		var j := float(lv.get("jetty", 0.0))
		x0 -= j
		x1 += j
		z1 += j
		var h := int(lv.get("floors", 1)) * F.storey + float(lv.get("base", 0.0))
		var side := lv.duplicate()
		side.erase("door")
		side.erase("sign")
		side.erase("shop")
		side.erase("arch")
		side["ci"] = int(lv.get("ci", 0)) + 1
		var back := side.duplicate()
		back["lit"] = 0.1
		k.box(x0, z0, x1, z1, y, y + h, {"s": F.wall(lv), "e": F.wall(side), "w": F.wall(side), "n": F.wall(back)}, F.wall(side))
		if lv.has("door") and is_equal_approx(y, y0):
			step(k, x0 + F.door_x(x1 - x0, float(lv["door"])), z1, y)
		y += h
	return [x0, z0, x1, z1, y]


static func gable(k: Kit, r: Array, along_x: bool, pitch: float, ci: int, style: String, over: float = 0.3) -> float:
	var half := (float(r[3]) - float(r[1])) * 0.5 if along_x else (float(r[2]) - float(r[0])) * 0.5
	var rise := half * pitch
	k.gable_roof(r[0], r[1], r[2], r[3], r[4], rise, along_x, over, F.roof(ci), F.gable(style, ci))
	return rise


## 지붕창(남쪽 경사 — 마루가 동서인 박공·모임 위): 가운데 x, 지붕 rect r, rise.
static func dormer(k: Kit, r: Array, rise: float, cx: float, ci: int) -> void:
	var zm := (float(r[1]) + float(r[3])) * 0.5
	var half := (float(r[3]) - float(r[1])) * 0.5
	var zf := zm + half * 0.55
	var yb := float(r[4]) + rise * (1.0 - (zf - zm) / half)
	k.box(cx - 0.42, zm, cx + 0.42, zf, yb - 0.3, yb + 0.62, {"s": F.gable("plaster", ci), "e": F.plain("wood"), "w": F.plain("wood")}, F.gable("plaster", ci, false))
	k.gable_roof(cx - 0.42, zm, cx + 0.42, zf, yb + 0.62, 0.38, false, 0.08, F.roof(ci, true), F.gable("plaster", ci, false))


## 문 앞 디딤돌(문 가운데 x, 벽 앞 z, 바닥 y).
static func step(k: Kit, x: float, z: float, y: float) -> void:
	k.box(x - 0.62, z, x + 0.62, z + 0.36, y, y + 0.12, {"top": F.plain("stone", 2)}, F.plain("stone", 2))


static func chimney(k: Kit, x: float, z: float, y0: float, y1: float) -> void:
	k.box(x - 0.24, z - 0.24, x + 0.24, z + 0.24, y0, y1, {"top": F.plain("dark")}, F.plain("brick"))


static func _narrow_jetty(k: Kit) -> void:
	var r := stack(k, -1.6, -2.6, 1.6, 2.4, 0.0, [
		{"style": "stone", "floors": 1, "base": 0.2, "door": 0.5, "ci": 0, "win": "arch"},
		{"style": "timber", "floors": 1, "jetty": 0.22, "ci": 0},
		{"style": "timber", "floors": 1, "jetty": 0.22, "ci": 0, "flowers": true}])
	var rise := gable(k, r, false, 1.55, 0, "timber")
	chimney(k, 0.8, -1.2, r[4], r[4] + rise + 0.5)


static func _eaves_dormers(k: Kit) -> void:
	var r := stack(k, -3.0, -2.0, 3.0, 2.0, 0.0, [
		{"style": "plaster", "floors": 1, "base": 0.15, "door": 0.3, "ci": 1, "shutters": true},
		{"style": "timber", "floors": 1, "jetty": 0.15, "ci": 1}])
	var rise := gable(k, r, true, 1.1, 1, "timber")
	dormer(k, r, rise, -1.3, 1)
	dormer(k, r, rise, 1.3, 1)
	chimney(k, -2.2, -0.6, r[4], r[4] + rise + 0.4)


static func _tall_hip(k: Kit) -> void:
	var r := stack(k, -1.8, -1.8, 1.8, 1.8, 0.0, [
		{"style": "stone", "floors": 2, "base": 0.2, "door": 0.5, "ci": 2},
		{"style": "plaster", "floors": 2, "ci": 2, "shutters": true}])
	k.hip_roof(r[0], r[1], r[2], r[3], r[4], 2.1, 0.3, F.roof(2))
	chimney(k, 0.7, -0.4, r[4], r[4] + 2.4)


static func _cross_gable(k: Kit) -> void:
	var r := stack(k, -3.0, -1.8, 3.0, 1.8, 0.0, [{"style": "timber", "floors": 3, "base": 0.2, "ci": 0, "door": 0.15}])
	gable(k, r, true, 1.2, 0, "timber")
	var w := stack(k, 0.4, 1.8, 3.0, 4.6, 0.0, [{"style": "timber", "floors": 3, "base": 0.2, "ci": 3, "door": 0.5, "flowers": true}])
	gable(k, w, false, 1.35, 0, "timber")
	chimney(k, -2.0, 0.0, r[4], r[4] + 2.6)


static func _turret_house(k: Kit) -> void:
	var r := stack(k, -2.6, -2.0, 1.6, 2.0, 0.0, [{"style": "stone", "floors": 1, "base": 0.2, "door": 0.3, "ci": 1}, {"style": "timber", "floors": 2, "jetty": 0.15, "ci": 4}])
	gable(k, r, true, 1.2, 3, "timber")
	var yt := 4 * F.storey + 0.2
	k.cylinder(1.75, 2.0, 1.0, 0.0, yt, 14, func(i: int) -> Callable: return F.wall({"style": "stone", "floors": 4, "ci": 0, "base": 0.2, "win": "arch", "lit": 0.4 if i % 2 == 0 else 0.0}))
	k.cone(1.75, 2.0, 1.25, yt - 0.05, 2.8, 14, F.roof(3))


static func _bell_tower(k: Kit) -> void:
	var h := 6 * F.storey
	k.box(-1.4, -1.4, 1.4, 1.4, 0.0, h, {"s": F.tower(0, 6, true, true), "e": F.tower(1, 6, true), "w": F.tower(1, 6, true), "n": F.tower(1, 6, true)}, F.tower(0, 6, true))
	step(k, 0.0, 1.4, 0.0)
	k.pyramid(-1.4, -1.4, 1.4, 1.4, h, 5.0, 0.2, F.roof(3))
	for c: Vector2 in [Vector2(-1.4, -1.4), Vector2(1.4, -1.4), Vector2(1.4, 1.4), Vector2(-1.4, 1.4)]:
		k.box(c.x - 0.22, c.y - 0.22, c.x + 0.22, c.y + 0.22, h, h + 0.4, {}, F.plain("stone"))
		k.pyramid(c.x - 0.22, c.y - 0.22, c.x + 0.22, c.y + 0.22, h + 0.4, 1.0, 0.03, F.roof(3, true))


static func _chapel(k: Kit) -> void:
	var r := stack(k, -2.2, -4.0, 2.2, 1.8, 0.0, [{"style": "stone", "floors": 2, "base": 0.25, "ci": 1, "win": "gothic", "lit": 0.5}])
	gable(k, r, false, 1.5, 0, "stone")
	var h := 5 * F.storey
	k.box(-1.2, 1.8, 1.2, 4.0, 0.0, h, {"s": F.tower(0, 5, true, true), "top": F.plain("stone")}, F.tower(0, 5, true))
	step(k, 0.0, 4.0, 0.0)
	k.pyramid(-1.2, 1.8, 1.2, 4.0, h, 4.4, 0.18, F.roof(0))


static func _bridge_pair(k: Kit) -> void:
	var a := stack(k, -5.2, -2.0, -1.6, 2.0, 0.0, [{"style": "stone", "floors": 1, "base": 0.2, "door": 0.5, "ci": 0}, {"style": "timber", "floors": 2, "ci": 0, "jetty": 0.12}])
	gable(k, a, true, 1.2, 1, "timber")
	var b := stack(k, 1.6, -1.8, 5.0, 1.8, 0.0, [{"style": "plaster", "floors": 3, "base": 0.2, "door": 0.4, "ci": 2, "shutters": true}])
	k.hip_roof(b[0], b[1], b[2], b[3], b[4], 1.8, 0.3, F.roof(2))
	var y0 := 2 * F.storey + 0.2
	k.box(-1.6, -0.9, 1.6, 0.9, y0, y0 + F.storey, {"top": F.plain("wood")}, F.wall({"style": "timber", "floors": 1, "ci": 1, "lit": 0.6}))
	k.box(-1.6, -0.95, 1.6, 0.95, y0 - 0.18, y0, {}, F.plain("wood"))
	k.gable_roof(-1.6, -0.9, 1.6, 0.9, y0 + F.storey, 0.7, true, 0.15, F.roof(1, true), F.gable("timber", 1, false))


static func _arch_house(k: Kit) -> void:
	var r := stack(k, -2.6, -2.0, 2.6, 2.0, 0.0, [{"style": "stone", "floors": 1, "base": 0.2, "arch": true, "door": 0.0, "ci": 2}, {"style": "timber", "floors": 2, "jetty": 0.2, "ci": 2}])
	var rise := gable(k, r, true, 1.15, 0, "timber")
	dormer(k, r, rise, 0.0, 0)


static func _shop_house(k: Kit) -> void:
	var r := stack(k, -2.2, -2.0, 2.2, 2.0, 0.0, [{"style": "plaster", "floors": 1, "base": 0.15, "shop": true, "door": 0.99, "sign": "bag", "ci": 3}, {"style": "timber", "floors": 2, "jetty": 0.2, "ci": 3, "flowers": true}])
	gable(k, r, false, 1.45, 2, "timber")
	var y := F.storey * 0.98
	k.face(PackedVector3Array([Vector3(-2.2, y, 2.0), Vector3(2.2, y, 2.0), Vector3(2.2, y - 0.35, 2.9), Vector3(-2.2, y - 0.35, 2.9)]), Vector3(0, 1, 0.4), F.awning())


static func _gallery_house(k: Kit) -> void:
	var r := stack(k, -2.8, -2.0, 2.8, 2.0, 0.0, [{"style": "stone", "floors": 1, "base": 0.2, "door": 0.85, "ci": 0}, {"style": "plaster", "floors": 1, "ci": 4, "door": 0.5, "shutters": true}])
	var y := F.storey + 0.2
	k.box(-1.0, 2.0, 2.8, 2.8, y - 0.12, y, {"top": F.plain("wood")}, F.plain("wood"))
	k.face(PackedVector3Array([Vector3(-1.0, y, 2.8), Vector3(2.8, y, 2.8), Vector3(2.8, y + 0.45, 2.8), Vector3(-1.0, y + 0.45, 2.8)]), Vector3(0, 0, 1), F.gallery())
	for i in 6:
		var x := -2.8 + i * 0.3
		k.box(x, 2.0, x + 0.3, 2.8, 0.0, y * (i + 1) / 6.0, {"top": F.plain("stone", 1)}, F.plain("stone", 1))
	gable(k, r, true, 1.0, 1, "plaster", 0.3)
	for x: float in [-0.9, 1.0, 2.7]:  # 회랑 기둥
		k.box(x - 0.07, 2.66, x + 0.07, 2.8, y, y + F.storey - 0.1, {}, F.plain("wood"))


static func _mansard(k: Kit) -> void:
	var r := stack(k, -3.0, -2.4, 3.0, 2.4, 0.0, [{"style": "stone", "floors": 2, "base": 0.25, "door": 0.5, "ci": 1, "win": "arch"}])
	var y := float(r[4])
	var i := 0.55
	var yt := y + 1.4
	var o := 0.2
	var a := Vector3(-3.0 - o, y - 0.1, 2.4 + o)
	var b := Vector3(3.0 + o, y - 0.1, 2.4 + o)
	var c := Vector3(3.0 + o, y - 0.1, -2.4 - o)
	var d := Vector3(-3.0 - o, y - 0.1, -2.4 - o)
	var ta := Vector3(-3.0 + i, yt, 2.4 - i)
	var tb := Vector3(3.0 - i, yt, 2.4 - i)
	var tc := Vector3(3.0 - i, yt, -2.4 + i)
	var td := Vector3(-3.0 + i, yt, -2.4 + i)
	k.face(Kit._pts([a, b, tb, ta]), Vector3(0, 0.4, 1), F.roof(2))
	k.face(Kit._pts([b, c, tc, tb]), Vector3(1, 0.4, 0), F.roof(2))
	k.face(Kit._pts([c, d, td, tc]), Vector3(0, 0.4, -1), F.roof(2))
	k.face(Kit._pts([d, a, ta, td]), Vector3(-1, 0.4, 0), F.roof(2))
	k.hip_roof(-3.0 + i, -2.4 + i, 3.0 - i, 2.4 - i, yt, 0.7, 0.05, F.roof(2))
	for cx: float in [-1.8, 0.0, 1.8]:
		k.box(cx - 0.4, 1.0, cx + 0.4, 2.3, y - 0.05, y + 0.75, {"s": F.gable("plaster", 1), "e": F.plain("wood"), "w": F.plain("wood")}, F.plain("wood"))
		k.gable_roof(cx - 0.4, 1.0, cx + 0.4, 2.3, y + 0.75, 0.4, false, 0.08, F.roof(2, true), F.gable("plaster", 1, false))
	chimney(k, -2.0, -1.4, y, yt + 1.2)
	chimney(k, 2.0, -1.4, y, yt + 1.2)


static func _step_gable(k: Kit) -> void:
	var r := stack(k, -1.7, -2.6, 1.7, 2.6, 0.0, [{"style": "brick", "floors": 4, "base": 0.2, "door": 0.5, "ci": 0, "win": "arch"}])
	var y := float(r[4])
	var rise := 1.7 * 1.5
	k.gable_roof(-1.7, -2.6, 1.7, 2.6, y, rise, false, 0.0, F.roof(1), F.gable("brick", 0))
	var n := 4
	var pts: Array[Vector3] = [Vector3(-1.7, y, 2.62), Vector3(1.7, y, 2.62)]
	for s in range(n, 0, -1):
		var x1 := 1.7 * float(s) / n
		var x0 := 1.7 * float(s - 1) / n
		var yy := y + rise * (1.0 - float(s) / n) + 0.4
		pts.append(Vector3(x1, yy, 2.62))
		pts.append(Vector3(x0 if s > 1 else 0.25, yy, 2.62))
	pts.append(Vector3(0.25, y + rise + 0.6, 2.62))
	pts.append(Vector3(-0.25, y + rise + 0.6, 2.62))
	for s in range(1, n + 1):
		var x0 := -1.7 * float(s - 1) / n
		var x1 := -1.7 * float(s) / n
		var yy := y + rise * (1.0 - float(s) / n) + 0.4
		pts.append(Vector3(x0 if s > 1 else -0.25, yy, 2.62))
		pts.append(Vector3(x1, yy, 2.62))
	k.face(Kit._pts(pts), Vector3(0, 0, 1), F.gable("brick", 0))  # 계단식 박공(볼록이 아니다 — Kit가 삼각분할)
	chimney(k, -0.9, -1.6, y, y + rise + 0.2)


static func _workshop(k: Kit) -> void:
	k.box(-2.2, -1.6, 2.2, 1.6, 0.0, F.storey + 0.2, {"s": F.wall({"style": "stone", "floors": 1, "base": 0.2, "door": 0.3, "ci": 2, "lit": 0.8})}, F.wall({"style": "stone", "floors": 1, "base": 0.2, "ci": 1}))
	step(k, -2.2 + F.door_x(4.4, 0.3), 1.6, 0.0)
	k.shed_roof(-2.2, -1.6, 2.2, 1.6, F.storey + 0.2, F.storey + 1.6, 0.25, F.roof(1), F.plain("wood"))
	chimney(k, 1.3, -0.9, F.storey, F.storey + 2.8)


static func _podium(k: Kit) -> void:
	k.box(-3.2, -2.8, 3.2, 2.8, 0.0, 1.0, {"top": F.plain("cobble")}, F.plain("stone", 1))
	for i in 5:
		var z := 2.8 + 0.3 * (5 - i)
		k.box(-1.0, 2.8, 1.0, z, 0.0, 0.2 * (i + 1), {"top": F.plain("stone", 2)}, F.plain("stone", 2))
	var r := stack(k, -2.2, -2.2, 2.2, 1.8, 1.0, [{"style": "timber", "floors": 2, "base": 0.15, "door": 0.5, "ci": 2, "flowers": true}])
	k.hip_roof(r[0], r[1], r[2], r[3], r[4], 1.9, 0.3, F.roof(0))


static func _manor(k: Kit) -> void:
	var r := stack(k, -3.6, -2.0, 2.4, 2.0, 0.0, [{"style": "stone", "floors": 3, "base": 0.25, "door": 0.4, "ci": 0, "win": "arch"}])
	k.hip_roof(r[0], r[1], r[2], r[3], r[4], 1.6, 0.3, F.roof(2))
	dormer(k, r, 1.6, -1.6, 2)
	dormer(k, r, 1.6, 0.2, 2)
	var h := 5 * F.storey
	k.box(2.0, 0.4, 4.2, 2.6, 0.0, h, {"s": F.wall({"style": "stone", "floors": 5, "ci": 1, "win": "arch", "base": 0.25})}, F.tower(1, 5, false))
	k.pyramid(2.0, 0.4, 4.2, 2.6, h, 4.0, 0.2, F.roof(3))
