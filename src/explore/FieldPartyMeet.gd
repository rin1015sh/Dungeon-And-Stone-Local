class_name FieldPartyMeet
extends RefCounted
## 탐험가 무리와 마주쳤을 때의 선택지와 결과(순수 로직 — 화면 ExploreScreen이 선택 창을 띄우고 act를 부른다).
##   신참: 거래(trades {give, n, price} — 9등급 마석 price개) · 소문(가장 가까운 못 찾은 포탈 — 한 번) · 함께 다니기(follow_hours — 한 번) · 지나가기
##   다친 탐험가: 포션 건네기(마석으로 갚고 소문) · 식량 건네기 · 지나가기
##   싸우는 탐험가: 돕기(곁의 몬스터 무리와 전투 — 이기면 thank) · 지나가기
##   약탈자: 가진 마석의 절반을 내기(물러난다) · 싸우기
## 고르지 않고 물러나면(취소) 지나가기와 같다. 약탈자는 취소할 수 없다.
## 값은 층 JSON explorers(rewards 등).

const STONE := "magic_stone_9"


## 선택 창 제목.
static func title(g: FieldMonsters.Group) -> String:
	return Strings.t("explore.party.title." + str(g.party.get("kind")), {"n": int(g.party.get("members", 1))})


## 선택지 [{"id", "text", "enabled", "desc"}].
static func options(s: ExploreSession, g: FieldMonsters.Group) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var inv := s.player.inventory
	match str(g.party.get("kind")):
		FieldParties.ROOKIE:
			var t := JsonUtil.get_dict(g.party, "trade")
			if not t.is_empty() and not bool(g.party.get("traded", false)):
				var price := JsonUtil.get_int(t, "price")
				out.append(_opt("trade", Strings.t("explore.party.opt.trade", {"item": DataNames.entry(s.db, "items", JsonUtil.get_str(t, "give")),
					"n": JsonUtil.get_int(t, "n", 1), "price": price}), inv.count(STONE) >= price, "explore.party.no_stones"))
			if not bool(g.party.get("rumor_told", false)):
				out.append(_opt("rumor", Strings.t("explore.party.opt.rumor")))
			if not bool(g.party.get("followed", false)):
				out.append(_opt("follow", Strings.t("explore.party.opt.follow")))
		FieldParties.WOUNDED:
			out.append(_opt("give_potion", Strings.t("explore.party.opt.give_potion"), inv.count("minor_potion") > 0, "explore.party.no_item"))
			out.append(_opt("give_food", Strings.t("explore.party.opt.give_food"), inv.count("ration") > 0, "explore.party.no_item"))
		FieldParties.FIGHTING:
			out.append(_opt("help", Strings.t("explore.party.opt.help")))
		FieldParties.RAIDER:
			out.append(_opt("pay", Strings.t("explore.party.opt.pay"), _stones(s) > 0, "explore.party.no_stones"))
			out.append(_opt("fight", Strings.t("explore.party.opt.fight")))
			return out
	out.append(_opt("leave", Strings.t("explore.party.opt.leave")))
	return out


static func can_cancel(g: FieldMonsters.Group) -> bool:
	return str(g.party.get("kind")) != FieldParties.RAIDER


## 고른 선택지를 한다(id = "" 이면 취소 = 지나가기, 약탈자는 싸우기).
static func act(s: ExploreSession, g: FieldMonsters.Group, id: String) -> void:
	var rw := JsonUtil.get_dict(s.parties.def, "rewards")
	match id:
		"trade":
			var t := JsonUtil.get_dict(g.party, "trade")
			if s.player.inventory.count(STONE) >= JsonUtil.get_int(t, "price"):
				s.player.inventory.remove(STONE, JsonUtil.get_int(t, "price"))
				g.party["traded"] = true
				FieldFeatureAct.say_line_args(s, "explore.party.traded", {}, "info")
				FieldFeatureAct.give_items(s, [{"item": JsonUtil.get_str(t, "give"), "count": [JsonUtil.get_int(t, "n", 1), JsonUtil.get_int(t, "n", 1)]}])
		"rumor":
			g.party["rumor_told"] = true
			rumor(s, g)
		"follow":
			g.party["followed"] = true
			g.party["follow_until"] = s.clock.total_hours + JsonUtil.get_float(s.parties.def, "follow_hours", 12.0)
			g.route.clear()
			FieldFeatureAct.say_line_args(s, "explore.party.follow_start", {}, "info")
		"give_potion", "give_food":
			var item := "minor_potion" if id == "give_potion" else "ration"
			if s.player.inventory.remove(item, 1):
				FieldFeatureAct.say_line_args(s, "explore.party.healed" if id == "give_potion" else "explore.party.fed", {}, "good")
				FieldFeatureAct.give_items(s, JsonUtil.get_array(rw, id))
				if id == "give_potion":
					rumor(s, g)
				g.party["kind"] = FieldParties.ROOKIE
				g.party.erase("dies_at")
		"help":
			var foe := _foe(s, g)
			if foe != null:
				_pass(s, g)
				s.engage(foe, true)
				return
		"pay":
			_take_half_stones(s)
			g.party["paid"] = true
			g.monster_ids.clear()
			FieldFeatureAct.say_line_args(s, "explore.party.paid", {}, "warn")
			s.monsters.send_to(g, FieldRoutes.random_cell_near(s.map, s.rng, g.pos, 40), s.pos)
		"fight", "":
			if str(g.party.get("kind")) == FieldParties.RAIDER:
				g.party["asked"] = true
				s.engage(g, false)
				return
	_pass(s, g)


## 싸우던 몬스터를 플레이어가 쓰러뜨렸다: 살아남은 탐험가들이 고마워한다(신참이 된다).
static func thank(s: ExploreSession, g: FieldMonsters.Group) -> void:
	g.party["kind"] = FieldParties.ROOKIE
	g.party.erase("foe")
	FieldFeatureAct.say_line_args(s, "explore.party.thanks", {}, "good")
	FieldFeatureAct.give_items(s, JsonUtil.get_array(JsonUtil.get_dict(s.parties.def, "rewards"), "help"))


## 소문: 가장 가까운 못 찾은 포탈(균열 포함)이 있는 방향.
static func rumor(s: ExploreSession, _g: FieldMonsters.Group) -> void:
	var best: Dictionary = {}
	for p: Dictionary in s.map.portals:
		if not bool(p.get("found", false)) and (best.is_empty() or (p["pos"] - s.pos).length_squared() < (best["pos"] - s.pos).length_squared()):
			best = p
	if best.is_empty():
		FieldFeatureAct.say_line_args(s, "explore.party.rumor_none", {}, "info")
		return
	var key := "explore.party.rumor_rift" if str(best.get("kind", "")) == "rift" else "explore.party.rumor_portal"
	FieldFeatureAct.say_line_args(s, key, {"dir": FieldParties.dir_word(s.pos, best["pos"])}, "info")


## 함께 다니는 무리: 곁(3칸)을 벗어나면 짧은 길로 따라온다. 시간이 다 되면 떠난다.
static func follow(s: ExploreSession, parties: FieldParties) -> void:
	for g in parties.all(s):
		var until := float(g.party.get("follow_until", -1.0))
		if until < 0.0:
			continue
		if until <= s.clock.total_hours:
			g.party.erase("follow_until")
			FieldFeatureAct.say_line_args(s, "explore.party.follow_end", {}, "info")
			s.monsters.send_to(g, FieldRoutes.random_cell_near(s.map, s.rng, g.pos, 40), s.pos)
		elif g.route.is_empty() and g.fpos.distance_to(s.fpos) > 3.0:
			g.home = s.pos
			g.route = FieldRoutes.path(s.map, g.pos, s.pos, JsonUtil.get_int(parties.def, "follow_path_tiles", 30))
			if g.route.is_empty() and not s.monsters.is_awake(g, s.pos):
				s.monsters.send_to(g, s.pos, s.pos)
			elif not g.route.is_empty():
				g.route.pop_back()  # 플레이어 칸까지는 들어가지 않는다


# ── 내부 ─────────────────────────────────────────────────

static func _opt(id: String, text: String, enabled: bool = true, why: String = "") -> Dictionary:
	return {"id": id, "text": text, "enabled": enabled, "desc": Strings.t(why) if not enabled and not why.is_empty() else ""}


## 이야기가 끝났다: 잠시 다시 말을 걸지 않는다(FieldMonsters.touching).
static func _pass(s: ExploreSession, g: FieldMonsters.Group) -> void:
	g.grace_until = s.clock.total_hours + JsonUtil.get_float(s.parties.def, "talk_grace_hours", 0.3)


static func _foe(s: ExploreSession, g: FieldMonsters.Group) -> FieldMonsters.Group:
	var id := int(g.party.get("foe", -1))
	for m in s.monsters.groups:
		if m.id == id:
			return m
	return null


## 가진 마석(magic_stone_*) 아이템 수.
static func _stones(s: ExploreSession) -> int:
	var n := 0
	for id in _stone_ids(s):
		n += s.player.inventory.count(id)
	return n


static func _stone_ids(s: ExploreSession) -> Array[String]:
	var out: Array[String] = []
	for id: String in s.db.get_collection("items"):
		if id.begins_with("magic_stone_") and id.trim_prefix("magic_stone_").is_valid_int() and s.player.inventory.count(id) > 0:
			out.append(id)
	return out


static func _take_half_stones(s: ExploreSession) -> void:
	for id in _stone_ids(s):
		s.player.inventory.remove(id, ceili(s.player.inventory.count(id) / 2.0))
