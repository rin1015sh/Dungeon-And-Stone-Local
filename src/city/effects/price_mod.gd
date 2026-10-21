extends CityEffect
## 이번 순 값 배율(거리 사건 — 마석 시세·품귀·역병): {"type": "price_mod", "key": "<buy|sell>:<아이템 분류>" | "fee:<시설 id>", "mult": x}.
## buy = 상점·대장간 사는 값, sell = 파는 값, fee = 그 시설 활동 이용료. 같은 키가 겹치면 곱한다. 순이 바뀌면 사라진다(CityState.price_mods).

const KINDS := ["buy", "sell", "fee"]


func apply(ctx: CityContext, data: Dictionary) -> void:
	var key := JsonUtil.get_str(data, "key")
	if key.is_empty() or not CityValues.is_set(data, "mult"):
		return
	ctx.state.price_mods[key] = ctx.state.price_mult(key) * maxf(0.0, CityValues.num(data, "mult"))


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var key := JsonUtil.get_str(data, "key")
	var kind := key.get_slice(":", 0)
	if not kind in KINDS or key.get_slice_count(":") != 2:
		out.append("price_mod: key는 <%s>:<대상>" % "|".join(KINDS))
	elif kind == "fee" and not db.has_entry("facilities", key.get_slice(":", 1)):
		out.append("price_mod: 시설 '%s' 없음" % key.get_slice(":", 1))
	return out
