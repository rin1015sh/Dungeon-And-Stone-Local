class_name Monument
extends RefCounted
## 대현자 기념비에서 할 수 있는 일(사용자 2026-10-27, RF22·DF17) — 순수 로직, 화면은 고르기 창만(ExploreScreen._on_monument_choice).
##   계층석 바치기: 그 층 계층석(opens_floor_rift — 계층군주 보상)이 있으면 균열 하나(가중 무작위).
##   마석 바치기: 층 JSON rift_offering {item, count, kills[]} — 이번 원정에서 kills의 몬스터를 모두 한 번 이상 잡았고
##     item이 count개 있으면, 그만큼 바치고 균열 하나(가중 무작위)를 연다. 바치면 처치 표시는 지워진다(다음은 다시 잡아야).
##   계층군주 부르기: 층 JSON lord.monument가 참이고 그 층 균열의 수호자(또는 변종 수호자)를 모두 쓰러뜨린 적이 있으면
##     (플레이어 처치 기록) 군주를 곁에 부른다(LordWatch.summon — 군주가 이미 있거나 다시 깨어나기 전이면 못 부른다).
## 할 수 있는 일이 하나도 없으면 options()가 비고, 기념비는 평소 문구만.

const STONE := "floor_stone"
const OFFER := "offer"
const LORD := "lord"


## 고를 것 [{id, key, args, enabled, why}] — key·args = 칸 이름 문구, why = 못 하는 이유 키(되면 "").
static func options(s: ExploreSession) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var stone := floor_stone(s)
	if not stone.is_empty() and not RiftWatch.rifts_for(s).is_empty():
		out.append({"id": STONE, "key": "explore.monument_opt_stone", "args": {"item": DataNames.entry(s.db, "items", stone)}, "enabled": true, "why": ""})
	var off := offering(s)
	if not off.is_empty() and s.player.inventory.count(JsonUtil.get_str(off, "item")) >= JsonUtil.get_int(off, "count", 1) \
			and not RiftWatch.rifts_for(s).is_empty():
		var ready := kills_ready(s)
		out.append({"id": OFFER, "key": "explore.monument_opt_offer", "args": {"item": DataNames.entry(s.db, "items", JsonUtil.get_str(off, "item")),
			"n": JsonUtil.get_int(off, "count", 1)}, "enabled": ready, "why": "" if ready else "explore.monument_why_kills"})
	if s.lord.enabled() and JsonUtil.get_bool(s.lord.def, "monument") and guardians_cleared(s):
		var idle := s.lord.state == LordWatch.IDLE
		out.append({"id": LORD, "key": "explore.monument_opt_lord", "args": {"name": DataNames.entry(s.db, "monsters", JsonUtil.get_str(s.lord.def, "monster"))},
			"enabled": idle, "why": "" if idle else "explore.monument_why_lord"})
	return out


## 고른 일을 한다. 했으면 true.
static func act(s: ExploreSession, at: Vector2i, id: String) -> bool:
	match id:
		STONE:
			var stone := floor_stone(s)
			if stone.is_empty():
				return false
			s.message.emit("explore.rift_offer", {"item": DataNames.entry(s.db, "items", stone)}, "system")
			if s.rifts.force_open(s, s.rifts.pick_rift(s), at):
				s.player.inventory.remove(stone, 1)
				return true
			s.message.emit("explore.rift_offer_failed", {}, "warn")
		OFFER:
			var off := offering(s)
			var item := JsonUtil.get_str(off, "item")
			var n := JsonUtil.get_int(off, "count", 1)
			if off.is_empty() or not kills_ready(s) or s.player.inventory.count(item) < n:
				return false
			if s.rifts.force_open(s, s.rifts.pick_rift(s), at):
				s.player.inventory.remove(item, n)  # 열렸을 때만 마석을 쓴다(자리를 못 찾으면 그대로 남는다)
				for m: Variant in JsonUtil.get_array(off, "kills"):
					s.kills.erase(str(m))
				return true
			s.message.emit("explore.rift_offer_failed", {}, "warn")
		LORD:
			if not guardians_cleared(s) or s.lord.state != LordWatch.IDLE:
				return false
			s.message.emit("explore.monument_lord_call", {}, "warn")
			return s.lord.summon(s)
	return false


## 가방에 있는 그 층 계층석(없으면 "").
static func floor_stone(s: ExploreSession) -> String:
	var fl := JsonUtil.get_int(s.floor_def, "floor", 0)
	for item in s.player.inventory.ids():
		if fl > 0 and JsonUtil.get_int(s.db.get_entry("items", item), "opens_floor_rift") == fl:
			return item
	return ""


static func offering(s: ExploreSession) -> Dictionary:
	return JsonUtil.get_dict(s.floor_def, "rift_offering")


## 이번 원정에서 rift_offering.kills의 몬스터를 모두 한 번 이상 잡았는가.
static func kills_ready(s: ExploreSession) -> bool:
	for m: Variant in JsonUtil.get_array(offering(s), "kills"):
		if int(s.kills.get(str(m), 0)) <= 0:
			return false
	return true


## 그 층 균열마다 수호자(또는 변종 수호자)를 쓰러뜨린 적이 있는가(플레이어 처치 기록).
static func guardians_cleared(s: ExploreSession) -> bool:
	var ids := RiftWatch.rifts_for(s)
	if ids.is_empty():
		return false
	for rid in ids:
		var r := s.db.get_entry("rifts", rid)
		var done := s.player.progression.kill_count(JsonUtil.get_str(r, "guardian")) > 0
		var variant := JsonUtil.get_str(JsonUtil.get_dict(r, "variant"), "monster")
		if not variant.is_empty() and s.player.progression.kill_count(variant) > 0:
			done = true
		if not done:
			return false
	return true
