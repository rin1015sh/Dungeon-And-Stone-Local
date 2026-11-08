extends EffectHandler
## 물건 빼앗기(말라붙은 순례자 — 2층 새 몬스터): {"type": "steal_item", "items": [먼저 노릴 id …], "categories": ["potion", "food"], "chance": 0.5}
## 대상 가방에서 items 중 가진 것 → 없으면 categories 순서로 첫 물건 하나를 빼앗아 시전자가 쥔다(메타 STOLEN). 그 전투에서
## 시전자를 쓰러뜨리면 되찾는다(BattlePassives.on_down). 도망치거나 지면 잃는다.

const STOLEN := "stolen_items"


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var t := ctx.subject()
	if t == null or t.dead or t.inventory == null or ctx.source == null:
		return false
	if data.has("chance") and not ctx.rng.chance(JsonUtil.get_float(data, "chance", 1.0)):
		return false
	var id := ""
	for v: Variant in JsonUtil.get_array(data, "items"):
		if t.inventory.has(str(v)):
			id = str(v)
			break
	if id.is_empty():
		for c: Variant in JsonUtil.get_array(data, "categories"):
			id = t.inventory.first_where(ctx.db, "category", str(c))
			if not id.is_empty():
				break
	if id.is_empty() or not t.inventory.remove(id, 1):
		return false
	var held: Array = ctx.source.get_meta(STOLEN, [])
	held.append({"item": id, "from": t})
	ctx.source.set_meta(STOLEN, held)
	ctx.say("combat.item_stolen", {"name": ctx.source.display_name, "item": DataNames.entry(ctx.db, "items", id)}, "warn")
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	for v: Variant in JsonUtil.get_array(data, "items"):
		if not db.has_entry("items", str(v)):
			out.append("steal_item: item '%s' 없음" % v)
	if JsonUtil.get_array(data, "items").is_empty() and JsonUtil.get_array(data, "categories").is_empty():
		out.append("steal_item: items나 categories가 필요하다")
	return out
