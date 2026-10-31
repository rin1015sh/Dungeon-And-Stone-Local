extends CityEffect
## 도서관 서적 읽기(CT52): {"type": "learn_info", "field": 분야 id | "any"}
## 지금 읽을 수 있는 항목(CityInfo.readable) 중 city.json library.per_read[최소, 최대]개를 무작위로 얻는다 — 한 번에 분야 전부를 주지 않는다.
## 읽을 것이 없으면 CityActions.check가 미리 막는다(city.reason_no_books). per_read가 null(미정)이면 얻지 않는다.


func apply(ctx: CityContext, data: Dictionary) -> void:
	var pool := CityInfo.readable(ctx.state, JsonUtil.get_str(data, "field", CityInfo.ANY))
	if pool.is_empty():
		ctx.say("city.fx.book_none")
		return
	var lib := CityValues.city_section(ctx.db, ctx.state.overrides, "library")
	if not lib.get("per_read") is Array:
		ctx.say("city.fx.book_undecided")
		return
	var per: Array = lib["per_read"]
	var lo := int(per[0]) if per.size() > 0 else 1
	var hi := int(per[1]) if per.size() > 1 else lo
	var n := mini(ctx.rng().randi_range(maxi(1, lo), maxi(lo, hi)), pool.size())
	for i in n:
		var id := str(pool.pop_at(ctx.rng().randi_range(0, pool.size() - 1)))
		ctx.state.learn_info(id)
		var e := ctx.db.get_entry("city_info", id)
		ctx.say("city.fx.book_new", {"name": JsonUtil.get_str(e, "name_ko", id), "text": JsonUtil.get_str(e, "text_ko"),
			"field": JsonUtil.get_str(e, "field")}, "good")  # field = 그 분야 책 그림(FacilityView)


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var f := JsonUtil.get_str(data, "field", CityInfo.ANY)
	if f != CityInfo.ANY and not CityInfo.field_ids(db).has(f):
		out.append("learn_info: field는 city.json library.fields의 id 또는 any")
	return out
