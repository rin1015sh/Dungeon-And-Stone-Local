class_name Loot
extends RefCounted
## 전리품: 몬스터를 쓰러뜨리면 몸은 빛 먼지로 흩어지고 드롭만 남는다.
##   마석: magic_stone_grade 등급의 "magic_stone_<등급>" 아이템, 확률 loot.magic_stone_chance(1.0 — 늘 떨어진다, 몬스터 magic_stone_chance로 덮을 수 있다)
##   drops: [{"item": id, "chance": 0~1, "count": [최소, 최대]}] — 잡템은 없다(사용자 결정 2026-10-21): 균열 열쇠(rift_bound)만 허용(검증기).
##   정수는 따로(EssenceDrop·DropPickup). 균열 보스 보상은 균열 guardian_drops(RiftRun).


## 몬스터 하나의 전리품 [{id, count}].
static func roll(db: GameDatabase, monster_id: String, rng: Rng) -> Array[Dictionary]:
	var def := db.get_entry("monsters", monster_id)
	var out: Array[Dictionary] = []
	var stone := "magic_stone_%d" % JsonUtil.get_int(def, "magic_stone_grade", 9)
	if def.has("magic_stone_grade") and db.has_entry("items", stone) \
			and rng.chance(JsonUtil.get_float(def, "magic_stone_chance", float(db.bal("loot.magic_stone_chance", 0.85)))):
		out.append({"id": stone, "count": 1})
	for d: Variant in JsonUtil.get_array(def, "drops"):
		var dd: Dictionary = d if d is Dictionary else {}
		var id := JsonUtil.get_str(dd, "item")
		if not db.has_entry("items", id) or not rng.chance(JsonUtil.get_float(dd, "chance", 1.0)):
			continue
		var c := JsonUtil.get_array(dd, "count")
		out.append({"id": id, "count": rng.randi_range(int(c[0]), int(c[1])) if c.size() == 2 else 1})
	return out
