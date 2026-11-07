class_name FieldEscorts
extends RefCounted
## 무리에 붙는 졸개(지역 escort — 대장 id → {monster, count}) 날짜 조건(전투 개선 CB9 — 사용자 2026-11-07 "1층 무리 섞는 건 3일 차부터").
## 지역 키:
##   "escort_day": n — n일 차부터만 새 무리에 졸개가 붙는다(없으면 늘).
##   "escort_share": 0~1 — n일 차가 되는 순간, 그 지역에 이미 있던 무리 중 그 비율이 한 번 졸개를 데려온다(층이 어지러워져 무리가 섞인다).
## 보스 · 지키는 무리(boss)와 이미 섞인 무리(대장 말고 다른 몬스터가 있다)는 건드리지 않는다. 순수 로직(오토로드 비의존).


## 지금(now 시각) 그 지역 escort가 새 무리에 붙는가.
static func applies(region: Dictionary, now: float) -> bool:
	return day_of(now) >= JsonUtil.get_int(region, "escort_day", 0)


static func day_of(now: float) -> int:
	return floori(now / 24.0) + 1


## n일 차가 된 지역마다 한 번: 있던 무리 escort_share만큼에 졸개를 붙인다. 붙였으면 true.
static func mix_by_day(groups: Array, regions: Array[Dictionary], done: Dictionary, now: float, rng: Rng) -> bool:
	var any := false
	for r: Dictionary in regions:
		var rid := JsonUtil.get_str(r, "id")
		var day := JsonUtil.get_int(r, "escort_day", 0)
		if day <= 0 or done.has(rid) or day_of(now) < day:
			continue
		done[rid] = true
		var share := JsonUtil.get_float(r, "escort_share", 0.0)
		var esc_all := JsonUtil.get_dict(r, "escort")
		for v: Variant in groups:
			var g := v as FieldMonsters.Group
			if g == null or g.region != rid or not g.boss.is_empty() or g.monster_ids.is_empty():
				continue
			var lead := str(g.monster_ids[0])
			var esc := JsonUtil.get_dict(esc_all, lead)
			if esc.is_empty() or g.monster_ids.any(func(m: Variant) -> bool: return str(m) != lead) or not rng.chance(share):
				continue
			var er := JsonUtil.get_array(esc, "count")
			for i in (rng.randi_range(int(er[0]), int(er[1])) if er.size() == 2 else 1):
				g.monster_ids.append(JsonUtil.get_str(esc, "monster"))
			any = true
	return any
