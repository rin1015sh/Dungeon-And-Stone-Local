extends CityEffect
## 소문(여관 식사)·정보(도서관 독서) 얻기: {"type": "learn_info", "kind": "rumor"|"lore", "chance": 0~1}
## 성공하면 아직 모르는 그 종류 항목(data/city_info) 하나를 무작위로 얻어 CityState.known_info에 남긴다(다시 볼 수 있다).
## chance null(미정)이면 얻지 않는다.


func apply(ctx: CityContext, data: Dictionary) -> void:
	var kind := JsonUtil.get_str(data, "kind")
	if not CityValues.is_set(data, "chance"):
		ctx.say("city.fx.info_undecided_" + kind)
		return
	if not ctx.rng().chance(clampf(CityValues.num(data, "chance"), 0.0, 1.0)):
		ctx.say("city.fx.info_fail_" + kind)
		return
	var pool: Array = []
	for id: String in ctx.db.get_collection("city_info"):
		if JsonUtil.get_str(ctx.db.get_entry("city_info", id), "kind") == kind and not ctx.state.known_info.has(id):
			pool.append(id)
	if pool.is_empty():
		ctx.say("city.fx.info_none_" + kind)
		return
	pool.sort()
	var id := str(ctx.rng().pick(pool))
	ctx.state.learn_info(id)
	var e := ctx.db.get_entry("city_info", id)
	ctx.say("city.fx.info_new_" + kind, {"name": JsonUtil.get_str(e, "name_ko", id), "text": JsonUtil.get_str(e, "text_ko")}, "good")


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not JsonUtil.get_str(data, "kind") in CityInfo.KINDS:
		out.append("learn_info: kind는 %s 중 하나" % [CityInfo.KINDS])
	return out
