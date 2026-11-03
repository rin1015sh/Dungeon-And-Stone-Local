extends "res://tools/town_kit/Designs.gd"
## 도시 3차 개선 건물(사용자 2026-11-03 "도시 전체 레이아웃 및 환경 개선 3차", CT103) — Designs의 붓 · 조각 그대로.
##   _cathedral = 신전(성당 — 회랑 셋 · 버팀벽 · 정면 종탑 첨탑, 일반 집과 확실히 다른 큰 석조)
##   _town_hall = 관청(윗단 행정 — 3층 석조 · 아케이드 1층 · 가운데 시계탑 · 현수막)
##   _warehouse = 강변 창고(낮고 긴 박공 · 큰 문 · 다락 짐 문과 도르래 들보)
##   _row_timber = 좁은 2층 반목조(작은 주거 — 돌출 2층 · 덧창 · 굴뚝), _corner_shop = 모퉁이 가게(차양 · 간판 · 2층 발코니)

const F2 := preload("res://tools/town_kit/Facade.gd")


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
	var y := F2.storey * 0.96
	k.face(PackedVector3Array([Vector3(-2.8, y, 2.0), Vector3(2.8, y, 2.0), Vector3(2.8, y - 0.3, 2.75), Vector3(-2.8, y - 0.3, 2.75)]), Vector3(0, 1, 0.4), F2.awning())
	var yb := F2.storey + 0.2
	k.box(-2.0, 2.18, 0.4, 2.8, yb, yb + 0.1, {"top": F2.plain("wood")}, F2.plain("wood"))  # 2층 발코니
	k.face(PackedVector3Array([Vector3(-2.0, yb + 0.1, 2.8), Vector3(0.4, yb + 0.1, 2.8), Vector3(0.4, yb + 0.5, 2.8), Vector3(-2.0, yb + 0.5, 2.8)]), Vector3(0, 0, 1), F2.gallery())
	chimney(k, 2.0, -1.2, r[4], r[4] + 1.8)
