class_name OrcAltar
extends RefCounted
## 오크 군락지 제단(3층 — 층 JSON "orc_altar", docs/plans/floor3.md §3). 순수 로직(오토로드 비의존).
## 제단(tile) 옆에서 살피면 가방의 오크 대전사 마석(stone)을 모두 바친다(한 원정 동안 쌓인다). 모두 offer_count개가 되면
## 히든 보스가 제단 앞에 선다: 오크 히어로 셋(hero), lord_chance로 대신 오크 로드(lord). 한 원정에 한 번 — 무작위로 나오지 않는다.
## 원작 777개를 그대로 두었다(offer_count — 사용자 결정 전 임시, 출현 조건 · 전투 능력은 원문에 없어 몬스터 데이터가 임시값).

var offered: int = 0
var risen: bool = false
var _cfg: Dictionary = {}


static func setup(s: ExploreSession) -> OrcAltar:
	var d := JsonUtil.get_dict(s.floor_def, "orc_altar")
	if d.is_empty():
		return null
	var a := OrcAltar.new()
	a._cfg = d
	return a


func need() -> int:
	return JsonUtil.get_int(_cfg, "offer_count", 777)


func interact(s: ExploreSession) -> bool:
	var tile := JsonUtil.get_str(_cfg, "tile", "f3_orc_altar")
	for d in FloorMap.DIRS4:
		var q: Vector2i = s.pos + d
		if s.map.tile_id_at(q) == tile:
			_use(s, q)
			return true
	return false


func target_name(s: ExploreSession) -> String:
	var tile := JsonUtil.get_str(_cfg, "tile", "f3_orc_altar")
	for d in FloorMap.DIRS4:
		if s.map.tile_id_at(s.pos + d) == tile:
			return s.map.def_at(s.pos + d).name_ko
	return ""


func _use(s: ExploreSession, at: Vector2i) -> void:
	var lines := JsonUtil.get_dict(_cfg, "lines")
	if risen:
		s.message.emit(JsonUtil.get_str(lines, "look"), {"n": offered, "need": need()}, "info")
		return
	var stone := JsonUtil.get_str(_cfg, "stone", "magic_stone_7")
	var have := s.player.inventory.count(stone)
	if have <= 0:
		s.message.emit(JsonUtil.get_str(lines, "look"), {"n": offered, "need": need()}, "info")
		return
	var give := mini(have, need() - offered)
	s.player.inventory.remove(stone, give)
	offered += give
	s.fx.emit("burst", at, -1)
	s.message.emit(JsonUtil.get_str(lines, "offer"), {"n": offered, "need": need()}, "info")
	if offered >= need():
		_rise(s, at)


## 히든 보스(테스트 · 디버그도 부른다).
func _rise(s: ExploreSession, at: Vector2i) -> void:
	risen = true
	var lord := s.rng.chance(JsonUtil.get_float(_cfg, "lord_chance", 0.02))
	var ids := JsonUtil.get_array(_cfg, "lord" if lord else "hero")
	var lines := JsonUtil.get_dict(_cfg, "lines")
	s.sound.emit("war_drum", at)
	s.message.emit(JsonUtil.get_str(lines, "rise_lord" if lord else "rise"), {}, "danger")
	if not s.monsters_enabled or ids.is_empty():
		return
	var g := s.monsters.add_fixed(ids, at + Vector2i(0, 3))
	if g != null:
		g.state = FieldMonsters.STATE_CHASE
		g.alert_until = s.clock.total_hours + 2.0
