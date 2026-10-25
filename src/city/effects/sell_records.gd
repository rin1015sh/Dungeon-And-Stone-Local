extends CityEffect
## 조사 기록 넘기기(탐험가 길드): {"type": "sell_records", "stats_stones": n, "affinity_stones": n}.
## 아직 넘기지 않은 도감 기록(조사로 알아낸 생명력·스탯, 쳐 봐서 알아낸 상성 하나하나)마다 값 × (10 − 등급)을 받는다.
## 넘긴 기록은 Knowledge 사실(sold_stats:<몬스터>, sold_aff:<몬스터>:<피해 유형>)로 남아 다시 팔리지 않는다.


func apply(ctx: CityContext, data: Dictionary) -> void:
	var k := ctx.pc.knowledge
	var per_stats := maxi(0, int(CityValues.num(data, "stats_stones")))
	var per_aff := maxi(0, int(CityValues.num(data, "affinity_stones")))
	var n := 0
	var pay := 0
	for id in k.seen_ids():
		var scale := maxi(1, 10 - JsonUtil.get_int(ctx.db.get_entry("monsters", id), "grade", 9))
		if k.knows_stats(id) and k.learn_fact("sold_stats:" + id):
			n += 1
			pay += per_stats * scale
		for t: String in k.affinities(id):
			if k.learn_fact("sold_aff:%s:%s" % [id, t]):
				n += 1
				pay += per_aff * scale
	if n == 0:
		ctx.say("city.fx.no_records", {}, "warn")
		return
	ctx.pc.inventory.add_money(pay)
	ctx.say("city.fx.records_sold", {"n": n, "stones": pay}, "good")
