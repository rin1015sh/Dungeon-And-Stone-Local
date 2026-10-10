class_name Vision
extends RefCounted
## 유효 시야(m) 규칙 (DESIGN §6):
##   기본 = max(주변광, 들고 있는 광원, 최소 시야)   — 주변광: 층의 ambient_light_m(암흑지대에서는 0)
##   유효 = min(층 상한 visibility_cap_m, 기본 + 시야 스탯 보정)
## 미궁은 빛을 먹으므로 상한은 광원이 있어도 넘지 못한다(대부분 10m 미만).


static func radius_m(db: GameDatabase, floor_def: Dictionary, map: FloorMap, actor: Actor, at: Vector2i) -> float:
	var cap := JsonUtil.get_float(floor_def, "visibility_cap_m", 9.0)
	var ambient := 0.0 if map.is_dark(at) else JsonUtil.get_float(floor_def, "ambient_light_m")
	var base := maxf(maxf(ambient, actor.light.radius()), float(db.bal("explore.min_vision_m", 1.0)))
	var bonus := Formula.value(db.bal("explore.vision_bonus_formula", 0.0), actor.pool.resolve)
	return clampf(base + bonus, 0.0, cap)


## 지금 시야를 만드는 빛의 종류: "torch"(들고 있는 광원) / "ambient"(수정 빛) / "dark"(암흑).
static func light_kind(floor_def: Dictionary, map: FloorMap, actor: Actor, at: Vector2i) -> String:
	var ambient := 0.0 if map.is_dark(at) else JsonUtil.get_float(floor_def, "ambient_light_m")
	if actor.light.is_lit() and actor.light.radius() >= ambient:
		return "torch"
	if ambient > 0.0:
		return "ambient"
	return "dark"
