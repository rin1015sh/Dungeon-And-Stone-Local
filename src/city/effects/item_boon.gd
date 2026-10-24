extends CityEffect
## 히든 피스를 도시에서 쓰기(도서관 고서 해독 — 2026-10-24, rift_hidden_pieces §6 R):
## {"type": "item_boon", "item": id, "stat": 스탯 id, "amount": n, "key": 영약 key, "learn_family": 몬스터 계열(그 계열 조사 기록)}
## 물건을 쓰고(팔 수 있던 값을 포기) 영구 스탯 + 그 계열 몬스터 전부의 도감 생명력·스탯. 같은 key는 한 번만(Actor.boons).


func apply(ctx: CityContext, data: Dictionary) -> void:
	var item := JsonUtil.get_str(data, "item")
	var stat := JsonUtil.get_str(data, "stat")
	var key := "%s@%s" % [JsonUtil.get_str(data, "key", item), stat]
	if ctx.pc.inventory.count(item) <= 0:
		ctx.say("city.fx.item_boon_none")
		return
	if int(ctx.pc.boons.get(key, 0)) > 0:
		ctx.say("city.fx.item_boon_known")
		return
	ctx.pc.inventory.remove(item, 1)
	ctx.pc.stats.set_base(stat, ctx.pc.stats.get_base(stat) + CityValues.num(data, "amount"))
	ctx.pc.boons[key] = 1
	var fam := JsonUtil.get_str(data, "learn_family")
	if not fam.is_empty():
		for mid: String in ctx.db.get_collection("monsters"):
			if JsonUtil.get_array(ctx.db.get_entry("monsters", mid), "family").has(fam):
				ctx.pc.knowledge.learn_stats(mid)
	ctx.say("city.fx.item_boon", {"stat": (ctx.db.stats[stat] as StatDef).name_ko}, "good")


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not db.has_entry("items", JsonUtil.get_str(data, "item")):
		out.append("item_boon: item '%s' 없음" % data.get("item"))
	if not db.stats.has(JsonUtil.get_str(data, "stat")):
		out.append("item_boon: stat '%s' 없음" % data.get("stat"))
	return out
