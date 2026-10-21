extends CityEffect
## 이번 순 시설 하나를 닫는다(거리 사건 — 검문·화재): {"type": "close_facility", "from": [시설 id…]}.
## from 가운데 오늘의 거리 사건이 걸리지 않았고 아직 열린 곳 하나를 무작위로(CityState.rng). 닫힌 곳은 들어갈 수 없고 거리에서 흐리게 보인다.


func apply(ctx: CityContext, data: Dictionary) -> void:
	var pool: Array = []
	for v: Variant in JsonUtil.get_array(data, "from"):
		var id := str(v)
		if ctx.db.has_entry("facilities", id) and not ctx.state.closed.has(id) and not CityHappenings.lit(ctx.state, id):
			pool.append(id)
	if pool.is_empty():
		return
	var id := str(ctx.rng().pick(pool))
	ctx.state.closed.append(id)
	ctx.say("city.fx.closed", {"name": JsonUtil.get_str(ctx.db.get_entry("facilities", id), "name_ko", id)}, "warn")


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	for v: Variant in JsonUtil.get_array(data, "from"):
		if not db.has_entry("facilities", str(v)):
			out.append("close_facility: 시설 '%s' 없음" % v)
	if JsonUtil.get_array(data, "from").has("bank"):
		out.append("close_facility: 은행은 닫지 않는다(세금)")
	return out
