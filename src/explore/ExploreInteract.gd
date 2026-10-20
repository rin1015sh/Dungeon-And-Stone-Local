class_name ExploreInteract
extends RefCounted
## 살피기(interact 키)와 포탈 안내(ExploreSession이 부른다 — 세션 파일을 짧게 유지).
##   층 포탈: 아래층은 아직 잠김(M6) · 균열 포탈: 들어간다(RiftWatch.enter → 세션 transfer)
##   균열 출구: 다음 챕터 / 탈출(RiftRun.use_exit) · 동굴 요소(FieldFeatures — 시체·샘·모닥불 …)
##   대현자 기념비: 마석이 있으면 바쳐 균열을 연다(RiftWatch.try_offer)


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
	for d in FloorMap.DIRS4:
		var def := s.map.def_at(s.pos + d)
		if def != null and def.interact == "hidden_piece" and s.rift_run != null and s.rift_run.take_hidden(s, s.pos + d):
			return
		if def != null and def.interact == "monument":
			if not s.rifts.try_offer(s, s.pos + d):
				s.message.emit("explore.monument", {}, "system")
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
	for d in FloorMap.DIRS4:
		var def := s.map.def_at(s.pos + d)
		if def != null and (def.interact == "monument" or (def.interact == "hidden_piece" and s.rift_run != null)):
			return def.name_ko
	return ""


## 층 포탈: portal["dest"](예: floor2_east)가 다음 층의 도착 지점이다. 2층은 아직 없어서(M6) 안내만 한다.
## 2층이 생기면 여기서 dest로 다음 층 세션을 만들어 s.transfer로 넘기면 된다(포탈 데이터는 그대로).
static func _use_floor_portal(s: ExploreSession, portal: Dictionary) -> void:
	s.message.emit("explore.portal_locked", {"floor": int(portal["to_floor"])}, "system")


static func portal_found(s: ExploreSession, portal: Dictionary) -> void:
	match str(portal.get("kind", "floor")):
		"rift":
			s.message.emit("explore.rift_portal_found", {}, "danger")
		"rift_exit", "rift_back":
			s.message.emit("explore.rift_exit_found", {}, "good")
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
