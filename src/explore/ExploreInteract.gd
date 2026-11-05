class_name ExploreInteract
extends RefCounted
## 살피기(interact 키)와 포탈 안내(ExploreSession이 부른다 — 세션 파일을 짧게 유지).
##   층 포탈: 위층으로 오르기 · 도착 비석: 아래층으로(FloorTravel) · 균열 포탈: 들어간다(RiftWatch.enter → 세션 transfer)
##   균열 출구: 다음 챕터 / 탈출(RiftRun.use_exit) · 동굴 요소(FieldFeatures — 시체·샘·모닥불 …)
##   대현자 기념비: 마석이 있으면 바쳐 균열을 연다(RiftWatch.try_offer) · 균열에 놓인 물건 줍기(RiftLoot) · 균열 장식: 잡템 뒤지기(RiftScavenge)


static func run(s: ExploreSession) -> void:
	var portal := s.map.portal_at(s.pos)
	if not portal.is_empty():
		match str(portal.get("kind", "floor")):
			"rift":
				var first := s.rifts.enter(s, portal)
				if first != null:
					s.transfer.emit(first)
			"rift_exit":
				if s.rift_run != null:
					var next := s.rift_run.use_exit(s)
					if next != null:
						s.transfer.emit(next)
			"rift_back":  # 지나온 챕터로 가는 길목(보통은 걸어 들어가면 넘어간다)
				if s.rift_run != null:
					s.rift_run.passage_step(s, s.pos + Vector2i(99, 99))
			_:
				_use_floor_portal(s, portal)
		return
	if s.features.interact(s):
		return
	if RiftLoot.run(s):
		return
	for d in FloorMap.DIRS4:
		var def := s.map.def_at(s.pos + d)
		if def != null and def.interact == "hidden_piece" and s.rift_run != null and s.rift_run.take_hidden(s, s.pos + d):
			return
		if def != null and def.interact == "monument":
			if Monument.options(s).is_empty():
				s.message.emit("explore.monument", {}, "system")
			else:
				s.monument_choice.emit(s.pos + d)  # 마석·계층석 바치기·계층군주 부르기 — 화면이 고르게 한다
			return
	if RiftScavenge.run(s):
		return
	s.message.emit("explore.nothing_here", {}, "info")


## 지금 살피기를 누르면 다룰 대상의 이름(HUD 안내). 없으면 "". run과 같은 순서로 본다.
static func target_name(s: ExploreSession) -> String:
	if not s.map.portal_at(s.pos).is_empty():
		if bool(s.map.portal_at(s.pos).get("passage", false)):
			return ""  # 길목은 걸어 들어가면 넘어간다
		var here := s.map.def_at(s.pos)
		return here.name_ko if here != null else ""
	var feature := s.features.target_name(s)
	if not feature.is_empty():
		return feature
	var loot := RiftLoot.target_name(s)
	if not loot.is_empty():
		return loot
	for d in FloorMap.DIRS4:
		var def := s.map.def_at(s.pos + d)
		if def != null and (def.interact == "monument" or (def.interact == "hidden_piece" and s.rift_run != null)):
			return def.name_ko
	var sp := RiftScavenge.target(s)
	if sp.x >= 0:
		return s.map.def_at(sp).name_ko
	return ""


## 층 포탈: portal["dest"](예: floor2_east)에 도착하는 층(층 JSON "arrival")이 있으면 오른다(FloorTravel), 없으면 잠김 안내. 도착 비석(kind "floor_down")은 아래층으로.
static func _use_floor_portal(s: ExploreSession, portal: Dictionary) -> void:
	var next := FloorTravel.down(s) if str(portal.get("kind", "")) == "floor_down" else FloorTravel.up(s, portal)
	if next != null:
		s.transfer.emit(next)
		return
	s.message.emit("explore.portal_locked", {"floor": int(portal.get("to_floor", 0))}, "system")


static func portal_found(s: ExploreSession, portal: Dictionary) -> void:
	match str(portal.get("kind", "floor")):
		"rift":
			s.message.emit("explore.rift_portal_found", {}, "danger")
		"rift_exit", "rift_back":
			s.message.emit("explore.rift_exit_found", {}, "good")
		"floor_down":
			pass  # 도착 비석은 올라오자마자 발밑에 보인다
		_:
			s.message.emit("explore.portal_found", {"dir": DataNames.tag(s.db, "directions", str(portal["dir"]))}, "good")


static func portal_here(s: ExploreSession, portal: Dictionary) -> void:
	match str(portal.get("kind", "floor")):
		"rift":
			s.message.emit("explore.rift_portal_here", {}, "system")
		"rift_exit", "rift_back":
			s.message.emit("explore.rift_exit_here", {}, "system")
		_:
			s.message.emit("explore.portal_here", {}, "system")
